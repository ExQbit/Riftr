import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/card_model.dart';
import '../models/card_fingerprint.dart';
import '../services/ocr_service.dart';
import '../services/card_lookup_service.dart';
import '../services/phash_service.dart';
import '../services/native_rect_service.dart';
import '../services/promo_classifier_service.dart';
import '../services/set_classifier_service.dart';
import '../services/suffix_classifier_service.dart';
import '../services/mana_classifier_service.dart';
import '../services/card_present_classifier_service.dart';
import '../services/card_name_classifier_service.dart';
import '../services/training_frame_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../widgets/card_image.dart';
import '../widgets/riftr_drag_handle.dart';
import 'scan_results_screen.dart';

/// Scanned card entry with metadata.
class ScannedCardEntry {
  RiftCard card;
  List<RiftCard> alternatives;
  int quantity;
  bool isFoil;
  /// Match confidence at scan time. Used to color-code the bottom-strip
  /// thumbnail so the user can see at a glance which scans need verification.
  /// Persists through editor (changing variant doesn't change "how confident
  /// the original detection was").
  final ScanConfidence confidence;

  /// Whether foil is relevant for this card.
  /// Normal runes (OGN/SFD/OGS) have no foil. Promo runes (OGNX/SFDX) are foil.
  bool get hasFoil {
    if (card.type?.toLowerCase() != 'rune') return true;
    return card.isPromo; // promo runes are foil
  }

  /// Whether the user can toggle foil status.
  /// Common/Uncommon + OGS: editable. Rare+: always foil, not editable.
  /// Runes: no foil at all.
  bool get isFoilEditable {
    if (!hasFoil) return false;
    if (card.setId == 'OGS') return true;
    final r = card.rarity?.toLowerCase() ?? '';
    return r == 'common' || r == 'uncommon';
  }

  ScannedCardEntry({
    required this.card,
    this.alternatives = const [],
    this.quantity = 1,
    bool? isFoil,
    this.confidence = ScanConfidence.high,
  }) : isFoil = isFoil ?? _defaultFoil(card);

  static bool _defaultFoil(RiftCard card) {
    if (card.type?.toLowerCase() == 'rune') return card.isPromo; // promo runes = foil
    if (card.setId == 'OGS') return false;
    final r = card.rarity?.toLowerCase() ?? '';
    return r != 'common' && r != 'uncommon';
  }
}

/// OCR Grid anchor — a recognized text element with known Y-position on the card.
class GridAnchor {
  final String label;       // 'mana', 'type', 'name', 'cn'
  final double yPct;        // expected Y% on card (e.g. 0.03 for mana, 0.97 for CN)
  final double xPct;        // expected X% on card (e.g. 0.09 for CN left edge)
  final double observedCX;  // observed X center in camera frame
  final double observedCY;  // observed Y center in camera frame
  final double observedLeft; // observed left edge (for X offset calculation)

  const GridAnchor({
    required this.label,
    required this.yPct,
    required this.xPct,
    required this.observedCX,
    required this.observedCY,
    required this.observedLeft,
  });
}

/// Scanner states.
enum ScanState { waiting, stable, motion, settling, scanning }

/// Full-screen card scanner with motion-detection state machine.
class ScannerScreen extends StatefulWidget {
  final bool defaultToListings;
  const ScannerScreen({super.key, this.defaultToListings = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  // ── Debug mode (set false for production) ──
  // Compile-time-Schalter — wenn true sind die Debug-Overlays ueberhaupt
  // potenziell sichtbar. Der zweite Schalter `_isAdmin` (runtime) gated
  // sie zusaetzlich auf den Riftr-Admin-Account, damit Beta-Tester die
  // bunten OCR-Boxen, FPS-Counter, Trainingsframe-Buttons etc. NICHT sehen.
  // Hardcode auf true lassen — die Admin-Check uebernimmt den User-Filter.
  static const _debugMode = true;

  /// Async-evaluated Custom-Claim-Cache. Selber Pattern wie social_screen
  /// (Phase 6.5 Admin-Disputes-UI). Default `false` — Beta-Tester sehen
  /// kein Debug-Overlay ohne explizit-gesetzten Admin-Claim.
  bool _isAdmin = false;

  /// Anzahl konsekutiver Frames im `waiting`-State ohne Classifier-Pass.
  /// Wenn die Schwelle erreicht ist, forcieren wir einen OCR-Versuch
  /// auch wenn der Classifier negativ ist — Fallback fuer Devices wo
  /// das Card-Present-Modell consistent zu niedrige prob zurueckgibt
  /// (z.B. iPhone 13 mini mit anderer Sensor-/HDR-Charakteristik als
  /// das Trainings-Set). Reset bei jedem state-change weg von waiting.
  int _waitingStuckFrames = 0;
  /// ~30 processed Frames bei 10fps = ~3s. Bei `_processedFrames % 3 == 0`
  /// klassifizieren wir nur jedes 3. processed Frame, also ~10 Klassifizierungen
  /// in 3s — genug Zeit fuer den Classifier sich zu zeigen, oder
  /// fuer den Fallback einzugreifen.
  static const _waitingStuckThreshold = 30;

  // ── Camera ──
  CameraController? _controller;
  bool _isInitialized = false;
  bool _torchOn = false;
  /// Camera-init Fehler — null wenn alles ok. Differenziert nach Ursache so
  /// die UI den richtigen Aktions-Button zeigen kann (Settings vs Retry).
  _CameraInitError? _initError;

  // ── State machine ──
  ScanState _state = ScanState.waiting;
  final List<ScannedCardEntry> _scannedCards = [];
  final _ocr = OcrService.instance;
  final _lookup = CardLookupService.instance;
  OcrMatch? _waitingMatch; // WAITING match with variants → deferred to SCANNING

  // ── pHash variant detection ──
  final _phash = PhashService.instance;
  final _promoClassifier = PromoClassifierService.instance;
  final _setClassifier = SetClassifierService.instance;
  final _suffixClassifier = SuffixClassifierService.instance;
  final _manaClassifier = ManaClassifierService.instance;
  final _cardPresentClassifier = CardPresentClassifierService.instance;
  final _cardNameClassifier = CardNameClassifierService.instance;
  final _trainingFrames = TrainingFrameService.instance;
  /// Persistent Y-plane buffer reused every frame (memcpy via setRange).
  /// Pre-fix this was `Uint8List.fromList(luma)` per frame — at 1080p × 10fps
  /// that's ~20 MB/s of GC pressure. The buffer is shared by all consumers,
  /// but every async consumer (ML Kit OCR, pHash compute() isolate, training
  /// frame save) already copies before async work, so in-place reuse is safe.
  Uint8List? _lastYPlane;
  int _lastYWidth = 0;
  int _lastYHeight = 0;
  int _lastYStride = 0;
  final List<List<int>> _nativeRects = []; // native rect samples during SCANNING

  // ── Motion detection ──
  Uint8List? _prevLuminance;
  double _motionPercent = 0;
  static const _motionThreshold = 18.0;
  static const _motionThresholdAfterScan = 22.0; // higher threshold after scan to prevent double-scan
  static const _stableThreshold = 8.0; // hand-held: 3-8% trembling is normal, not movement
  bool _justScanned = false; // true after successful scan, reset when entering WAITING
  double _lastCardPresentProb = 0.0; // cached from last card-present check
  static const _rectMotionLimit = 10.0; // collect native rects during hand trembles (card still visible)
  Timer? _settlingTimer;

  /// True while a modal sheet (variant editor, results screen) is open.
  /// stopImageStream() prevents NEW frames from entering _onFrame, but
  /// already-dispatched OCR calls (50-200ms ML Kit latency) keep their
  /// .then callbacks running and would otherwise add duplicate scans
  /// while the user picks a variant. All async entry points (_onFrame,
  /// processImage.then, extractFrame.then, _acceptMatch, _addCard) check
  /// this flag and bail out instead of calling _addCard mid-edit.
  bool _scanPaused = false;

  /// When true, render the "tap to scan / hold steady" hint in WAITING.
  /// Set by an 8-second timer started on WAITING entry — gives the user
  /// guidance if auto-detection doesn't kick in (low-light, classifier
  /// underestimates on this device, etc.). Reset on any state change.
  bool _showWaitingHint = false;
  Timer? _waitingHintTimer;

  /// True while _acceptMatch is running its variant-resolution chain.
  /// _acceptMatch can take 300-500ms (TFLite classifiers + pHash compute
  /// in isolate) and during that time the state has already flipped to
  /// STABLE — without a visible indicator the user sees a frozen frame
  /// and might think the scan failed. Renders a subtle spinner overlay.
  bool _identifying = false;

  // ── Multi-frame cumulative scoring ──
  int _scanCycleId = 0; // incremented each new scan cycle to invalidate stale callbacks
  int _scanFrameCount = 0;
  static const _earlyExitScore = 70;
  static const _maxScanFrames = 20;
  static const _minAcceptScore = 20;

  // Cumulative extraction across frames
  String? _cumSetCode;
  int? _cumCN;
  String? _cumCNSuffix;
  String? _cumCNRaw;
  final List<({int cn, String? suffix, String? raw})> _cnReadings = [];
  int? _cumMana;
  final Set<String> _cumNames = {};
  final Set<String> _cumKeywords = {};
  final Set<String> _cumTypes = {};
  final Set<String> _cumRegions = {};
  List<double>? _cumNameBox;  // OCR-anchor: best name bounding box (paired with CN)
  List<double>? _cumCnBox;    // OCR-anchor: best CN bounding box (paired with name)
  List<double>? _cumNameBoxSolo; // name box without requiring CN in same frame
  bool _cumPromoDetected = false; // OCR saw "PROMO" text on badge
  bool _cumChampionDetected = false; // OCR saw "CHAMPION" text on card
  final StringBuffer _cumText = StringBuffer();

  // ── OCR Grid: cross-frame anchor accumulation ──
  final Map<String, GridAnchor> _gridAnchors = {}; // best anchor per label

  // ── Debug stats ──
  int _processedFrames = 0;
  int _frameCount = 0;
  String _debugOcr = '';
  int _debugScore = 0;
  String _debugBreakdown = '';
  int _debugScanFrame = 0;
  final DateTime _fpsStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_lookup.isReady) _lookup.build();
    _phash.load();
    _promoClassifier.load();
    _setClassifier.load();
    _suffixClassifier.load();
    _manaClassifier.load();
    _cardPresentClassifier.load();
    _cardNameClassifier.load();
    OcrService.instance.debugMode = true; // ON for mana debug
    _initCamera();
    _checkAdminClaim();
  }

  /// Liest den Custom-Claim `admin: true` aus dem Firebase-ID-Token und
  /// setzt `_isAdmin`. Ohne diesen Claim bleibt `_isAdmin = false` und
  /// keine Debug-UI wird gerendert. Mirror von `social_screen._checkAdminClaim`.
  Future<void> _checkAdminClaim() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final tokenResult = await user.getIdTokenResult();
      final isAdmin = tokenResult.claims?['admin'] == true;
      if (mounted && isAdmin != _isAdmin) {
        setState(() => _isAdmin = isAdmin);
      }
    } catch (_) {
      // Token-Read fail → assume non-admin (= sicherer Default).
    }
  }

  Future<void> _initCamera() async {
    // Reset Error-State waehrend Re-Init laeuft (zeigt Spinner statt Error-UI).
    if (mounted) setState(() => _initError = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _initError = _CameraInitError.noCamera);
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.veryHigh, // 1080p for better gem crop + rect detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
      await _controller!.startImageStream(_onFrame);
      setState(() {
        _isInitialized = true;
        _initError = null;
      });
    } catch (e) {
      debugPrint('Scanner: Camera error: $e');
      if (!mounted) return;
      // CameraException-Codes per camera-plugin docs:
      //   'CameraAccessDenied'        — User hat Permission verweigert
      //   'CameraAccessDeniedWithoutPrompt' — System hat es ohne Prompt geblockt (Restricted Mode)
      //   'CameraAccessRestricted'    — z.B. unter Parental Controls / MDM
      //   'AudioAccessDenied' / 'AudioAccessRestricted' — wenn audio:true (haben wir off)
      _CameraInitError err;
      if (e is CameraException) {
        final code = e.code;
        if (code.contains('AccessDenied') ||
            code.contains('AccessRestricted') ||
            code.toLowerCase().contains('permission')) {
          err = _CameraInitError.permissionDenied;
        } else {
          err = _CameraInitError.other;
        }
      } else {
        err = _CameraInitError.other;
      }
      setState(() {
        _isInitialized = false;
        _initError = err;
      });
    }
  }

  // ══════════════════════════════════════════════
  // ── Frame processing: motion + OCR ──
  // ══════════════════════════════════════════════

  void _onFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount == 3) {
      // Log camera image dimensions once
      debugPrint('CAMERA: ${image.width}x${image.height} planes=${image.planes.length} '
          'format=${image.format.group} bytesPerRow=${image.planes.first.bytesPerRow}');
      final previewSize = _controller?.value.previewSize;
      debugPrint('CAMERA preview: ${previewSize?.width}x${previewSize?.height}');
    }
    if (_frameCount % 3 != 0) return; // ~10 fps processing
    if (_controller == null) return;
    if (_scanPaused) return; // user is editing — don't start new processing
    if (_processedFrames == 0) debugPrint('Scanner: First processed frame');

    _processedFrames++;

    // Extract luminance plane (Y channel, first plane)
    final luma = image.planes.first.bytes;
    final width = image.width;
    final height = image.height;

    // Reuse buffer across frames — allocate once, memcpy per frame.
    // Reallocate if camera dims change (rare; e.g., orientation toggle).
    if (_lastYPlane == null || _lastYPlane!.length != luma.length) {
      _lastYPlane = Uint8List(luma.length);
    }
    _lastYPlane!.setRange(0, luma.length, luma);
    _lastYWidth = width;
    _lastYHeight = height;
    _lastYStride = image.planes.first.bytesPerRow;

    // ── Collect native rects (throttled to every 3rd processed frame) ──
    // Vision-API isn't free; 30 rects is the cap and we process at ~10 fps,
    // so collecting every frame gives 30 rects in 3s — overkill. Every 3rd
    // frame still fills the cap in ~9s, well within typical scan duration,
    // and frees CPU/GPU for OCR + classifiers in the other 2/3 of frames.
    // Skip during active MOTION (>10%) since rects from a moving card are
    // junk anyway.
    final canCollect = _state != ScanState.motion || _motionPercent < _rectMotionLimit;
    if (_processedFrames % 3 == 0 && _nativeRects.length < 30 && canCollect) {
      // Strip stride padding and send full frame to Vision
      final stripped = Uint8List(width * height);
      final stride = image.planes.first.bytesPerRow;
      for (int row = 0; row < height; row++) {
        stripped.setRange(row * width, row * width + width, luma, row * stride);
      }

      NativeRectService.instance.detectCardRects(
        yPlane: stripped, width: width, height: height, bytesPerRow: width,
      ).then((rects) {
        if (rects != null && rects.isNotEmpty) {
          _nativeRects.addAll(rects);
        }
      }).catchError((e) {
        if (_debugMode) debugPrint('Native rect error: $e');
      });
    }

    // ── Motion detection ──
    if (_prevLuminance != null && _prevLuminance!.length == luma.length) {
      _motionPercent = _calculateMotion(luma, _prevLuminance!, width, height);
    }
    _prevLuminance = Uint8List.fromList(luma);

    // ── State transitions ──
    switch (_state) {
      case ScanState.waiting:
        // Card-Present-Classifier als CPU-Optimierung (skip OCR auf leeren
        // Frames). DREI Fallback-Pfade damit der Classifier nie zum
        // Hard-Gate wird (Bug-Report iPhone 13 mini 2026-04-29 — Scanner
        // löste nie aus weil Classifier auf der Sensor-Charakteristik des
        // 13 mini consistent zu niedrige prob lieferte):
        //
        //   Fallback 1: Classifier !isReady → skip-the-gate (lasse OCR direkt)
        //   Fallback 2: stuck-in-waiting > 3s → force OCR auch bei low-prob
        //   Fallback 3: bei jedem forced-OCR loggen damit man im Xcode-Log sieht
        //               warum's nicht klappt
        if (_processedFrames % 3 == 0 && _cardPresentClassifier.isReady && _lastYPlane != null) {
          final prob = _cardPresentClassifier.classify(
            _lastYPlane!, _lastYWidth, _lastYHeight, _lastYStride,
          );
          _lastCardPresentProb = prob ?? 0.0;
          if (_debugMode && _processedFrames % 30 == 0) {
            debugPrint('CardPresent: prob=${prob?.toStringAsFixed(3) ?? "null"}');
          }
        }

        final classifierReady = _cardPresentClassifier.isReady;
        final classifierPassed = _lastCardPresentProb >=
            CardPresentClassifierService.cardPresentThreshold;
        _waitingStuckFrames++;

        // Diagnose-Log alle 30 frames (~3s) — auch in Release-Build sichtbar
        // in Xcode-Console damit User Bug-Reports einreichen kann.
        if (_processedFrames % 30 == 0) {
          // ignore: avoid_print
          print('[Scanner] waiting: stuck=$_waitingStuckFrames '
              'classifierReady=$classifierReady '
              'lastProb=${_lastCardPresentProb.toStringAsFixed(3)}');
        }

        // Fallback-1: Classifier nie geladen → Gate ueberspringen.
        // Fallback-2: zu lange im waiting ohne Classifier-Pass → forciere OCR-Versuch.
        final shouldForceOcr = !classifierReady ||
            _waitingStuckFrames >= _waitingStuckThreshold;

        if (!classifierPassed && !shouldForceOcr) {
          if (_debugMode && mounted) setState(() {}); // still update overlay
          return;
        }

        if (!classifierPassed && shouldForceOcr) {
          // ignore: avoid_print
          print('[Scanner] FORCE OCR (classifierReady=$classifierReady, '
              'stuck=$_waitingStuckFrames, prob=${_lastCardPresentProb.toStringAsFixed(3)}) — '
              'classifier-Gate uebersprungen');
        }

        // Counter reset — wenn OCR scheitert und wir bleiben in waiting,
        // baut sich der Counter wieder auf bis zum naechsten Force-Versuch.
        _waitingStuckFrames = 0;

        // First scan attempt — try flip for upside-down cards
        _runOcr(image, tryFlip: true);

      case ScanState.stable:
        // Card already scanned, waiting for motion
        // After a successful scan, require more movement to prevent double-scan
        final threshold = _justScanned ? _motionThresholdAfterScan : _motionThreshold;
        if (_motionPercent > threshold) {
          _setState(ScanState.motion);
        }

      case ScanState.motion:
        // Movement detected, wait for it to stop
        if (_motionPercent < _stableThreshold) {
          _setState(ScanState.settling);
          _settlingTimer?.cancel();
          _settlingTimer = Timer(const Duration(milliseconds: 300), () {
            if (_state == ScanState.settling && mounted) {
              _justScanned = false; // reset — user moved enough for a new scan
              _setState(ScanState.scanning);
            }
          });
        }

      case ScanState.settling:
        // Checking stability — if motion returns, go back
        if (_motionPercent > _motionThreshold) {
          _settlingTimer?.cancel();
          _setState(ScanState.motion);
        }

      case ScanState.scanning:
        // Run OCR on this frame
        _runOcr(image);
    }

    if (_debugMode && mounted) setState(() {}); // Update debug overlay
  }

  /// Calculate motion between two luminance buffers.
  /// Samples every 8th pixel for performance (~15k comparisons instead of ~1M).
  double _calculateMotion(Uint8List current, Uint8List previous, int width, int height) {
    const step = 8;
    const pixelThreshold = 30; // intensity difference per pixel
    int changed = 0;
    int sampled = 0;

    for (int y = 0; y < height; y += step) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x += step) {
        final idx = rowOffset + x;
        if (idx >= current.length || idx >= previous.length) continue;
        sampled++;
        if ((current[idx] - previous[idx]).abs() > pixelThreshold) {
          changed++;
        }
      }
    }

    return sampled > 0 ? (changed / sampled * 100) : 0;
  }

  /// Run OCR with cumulative multi-frame extraction.
  void _runOcr(CameraImage image, {bool tryFlip = false}) {
    // WAITING state: full processImage with optional flip
    if (_state == ScanState.waiting) {
      _ocr.processImage(image, _controller!.description, tryFlip: tryFlip).then((match) {
        if (match == null || !mounted || _scanPaused) return;
        _updateDebug(match);

        // Name or title required: reject matches without card text recognized
        // Title counts too (e.g., "Vi" is 2 chars → scored as title, not name)
        final hasName = match.breakdown.containsKey('name') ||
            match.breakdown.containsKey('name_fuzzy') ||
            match.breakdown.containsKey('title') ||
            match.breakdown.containsKey('title_fuzzy');
        if (!hasName) return; // ignore garbage CN-only matches

        // Check if this card has multiple variants
        final nameLower = match.card.name.toLowerCase();
        final variantCount = (_lookup.nameIndex[nameLower] ?? []).length;

        if (variantCount > 1) {
          // Variants exist, confident match → enter SCANNING to collect
          // more OCR frames (for CN suffix) and native rects (for pHash).
          _waitingMatch = match;
          _setState(ScanState.scanning);
          // Seed grid anchors from WAITING extraction (has mana box etc. that SCANNING may not see)
          final waitingExtraction = _ocr.lastExtraction;
          if (waitingExtraction != null) {
            _accumulateGridAnchors(waitingExtraction);
            if (_debugMode && _gridAnchors.isNotEmpty) {
              debugPrint('Scanner: seeded grid from WAITING: [${_gridAnchors.keys.join(",")}]');
            }
          }
          if (_debugMode) {
            debugPrint('Scanner: WAITING match "${match.card.name}" has $variantCount variants → entering SCANNING for refinement');
          }
        } else {
          // Single variant → accept immediately
          _acceptMatch(match);
        }
      });
      return;
    }

    // SCANNING state: extract only (no scoring per frame), accumulate.
    // Rotation handled inside OcrService via _lastWorkingRotation +
    // alt-rotation auto-discovery (covers landscape battlefields and
    // multi-card scans where each card may be a different orientation).
    final cycleAtStart = _scanCycleId;
    _ocr.extractFrame(image, _controller!.description).then((extraction) async {
      if (!mounted || _state != ScanState.scanning || _scanCycleId != cycleAtStart || _scanPaused) return;

      _scanFrameCount++;
      _debugScanFrame = _scanFrameCount;

      // Native rects collected in _onFrame for all states. pHash compute
      // happens once at acceptance (in _acceptMatch) when we have OCR-anchored
      // card rect — per-frame pHash collection during SCANNING was tried but
      // disabled (over-budget on CPU; OCR Grid + final compute is sufficient).

      // Debug: dump raw text at frame 10 (always, to diagnose OCR issues)
      if (_debugMode && _scanFrameCount == 10 && extraction != null) {
        debugPrint('Scanner F10 RAW: "${extraction.rawTextLower.substring(0, extraction.rawTextLower.length.clamp(0, 400))}"');
        debugPrint('Scanner F10 namesFound: ${extraction.namesFound}');
      }

      // Current frame text for fuzzyContains (NOT cumulated)
      final currentFrameText = extraction?.rawTextLower ?? '';

      // Merge this frame's extraction into cumulative
      if (extraction != null) {
        if (extraction.setCode != null) _cumSetCode ??= extraction.setCode;
        if (extraction.collectorNumber != null) {
          // Collect ALL CN readings for later validation against matched card
          _cnReadings.add((
            cn: extraction.collectorNumber!,
            suffix: extraction.cnSuffix,
            raw: extraction.cnRaw,
          ));
          // First-wins for scoring, with prefix-upgrade:
          // "15" → "153" is a more complete reading of the same CN
          if (_cumCN == null) {
            _cumCN = extraction.collectorNumber;
            _cumCNSuffix = extraction.cnSuffix;
            _cumCNRaw = extraction.cnRaw;
          } else {
            final newRaw = extraction.cnRaw ?? '';
            final oldRaw = _cumCNRaw ?? '';
            // Upgrade if new CN contains old as prefix (15 → 153)
            if (newRaw.length > oldRaw.length && newRaw.startsWith(oldRaw)) {
              _cumCN = extraction.collectorNumber;
              _cumCNSuffix = extraction.cnSuffix;
              _cumCNRaw = extraction.cnRaw;
            }
          }
        }
        if (extraction.manaCost != null) _cumMana ??= extraction.manaCost;
        // Promo badge OCR detection — sticky (once seen = promo)
        if (extraction.promoDetected) {
          if (!_cumPromoDetected && _debugMode) {
            debugPrint('Scanner: PROMO badge detected via OCR!');
          }
          _cumPromoDetected = true;
        }
        // Solo name box: store name position even without CN (for name-only fallback)
        if (extraction.nameBox != null) {
          _cumNameBoxSolo ??= extraction.nameBox;
        }
        // Locked anchor pair: only save when BOTH name and CN are in the same frame,
        // CN is below name, distance > 80px (prevents two lines from same text block),
        // and horizontal alignment is plausible.
        if (extraction.nameBox != null && extraction.cnBox != null) {
          final nameY = (extraction.nameBox![1] + extraction.nameBox![3]) / 2;
          final cnY = (extraction.cnBox![1] + extraction.cnBox![3]) / 2;
          final dist = cnY - nameY;
          final hDiff = (extraction.nameBox![0] - extraction.cnBox![0]).abs();
          if (dist > 80 && hDiff < _lastYWidth * 0.35) {
            // Valid pair — save (or replace with better pair)
            if (_cumNameBox == null) {
              _cumNameBox = extraction.nameBox;
              _cumCnBox = extraction.cnBox;
            } else {
              // Keep the pair with smaller horizontal diff (more likely same card)
              final oldHDiff = (_cumNameBox![0] - (_cumCnBox?[0] ?? 0)).abs();
              if (hDiff < oldHDiff) {
                _cumNameBox = extraction.nameBox;
                _cumCnBox = extraction.cnBox;
              }
            }
          }
        }
        // ── OCR Grid: accumulate anchors from this frame ──
        _accumulateGridAnchors(extraction);

        // ── Mana crop OCR: if we have type+cn but no mana after 5 frames,
        // calculate where mana should be and OCR just that region ──
        // Skip for card types that don't have a mana diamond (rune, legend, battlefield).
        final _noManaDiamond = _cumTypes.contains('rune') ||
            _cumTypes.contains('legend') || _cumTypes.contains('battlefield');
        if (!_noManaDiamond &&
            !_gridAnchors.containsKey('mana') &&
            _gridAnchors.containsKey('type') &&
            _gridAnchors.containsKey('cn') &&
            _scanFrameCount == 5 &&
            _lastYPlane != null) {
          _tryManaCropOcr();
        }

        // ── Badge crop OCR: detect PROMO text on the badge ──
        // Run every 3rd frame if we have enough grid anchors
        if (!_cumPromoDetected &&
            _scanFrameCount >= 3 &&
            _scanFrameCount % 3 == 0 &&
            (_gridAnchors.containsKey('type') || _gridAnchors.containsKey('name')) &&
            _gridAnchors.containsKey('cn') &&
            _lastYPlane != null) {
          if (_debugMode) debugPrint('Badge OCR: attempting F$_scanFrameCount');
          _tryBadgeCropOcr();
        }

        // ── Champion crop OCR: detect "CHAMPION" text in artwork area ──
        // Run every 4th frame, offset from badge OCR
        if (!_cumChampionDetected &&
            _scanFrameCount >= 4 &&
            _scanFrameCount % 4 == 0 &&
            (_gridAnchors.containsKey('type') || _gridAnchors.containsKey('name')) &&
            _gridAnchors.containsKey('cn') &&
            _lastYPlane != null) {
          _tryChampionCropOcr();
        }

        _cumNames.addAll(extraction.namesFound);
        for (final kw in extraction.keywordsFound) {
          if (_cumKeywords.length >= 10) break;
          _cumKeywords.add(kw);
        }
        _cumTypes.addAll(extraction.typesFound);
        _cumRegions.addAll(extraction.regionsFound);
        _cumText.write(' ');
        _cumText.write(extraction.rawTextLower);
      }

      // Build cumulative extraction and score
      final cumExtraction = OcrExtraction(
        setCode: _cumSetCode,
        collectorNumber: _cumCN,
        cnSuffix: _cumCNSuffix,
        cnRaw: _cumCNRaw,
        namesFound: _cumNames,
        keywordsFound: _cumKeywords,
        typesFound: _cumTypes,
        regionsFound: _cumRegions,
        manaCost: _cumMana,
        rawTextLower: _cumText.toString(),
        fuzzyTextLower: currentFrameText, // current frame only for fuzzyContains
        softSetHint: extraction?.softSetHint, // latest frame's hint, not cumulated
      );

      if (_debugMode) {
        debugPrint('Scanner F$_scanFrameCount cum: set=$_cumSetCode cn=$_cumCN raw=$_cumCNRaw '
            'names=$_cumNames kw=$_cumKeywords types=$_cumTypes${_cumPromoDetected ? ' PROMO✓' : ''} '
            'grid=[${_gridAnchors.keys.join(",")}]');
      }

      final lookup = CardLookupService.instance;
      final matches = await lookup.findBestMatches(cumExtraction);
      if (!mounted || _state != ScanState.scanning || _scanCycleId != cycleAtStart || _scanPaused) return;

      final bestScore = matches.isNotEmpty ? matches.first.score : 0;

      if (matches.isNotEmpty) {
        final best = matches.first;
        _debugOcr = '${best.fingerprint.card.setId}-${best.fingerprint.card.collectorNumber} ${best.fingerprint.card.name}';
        _debugScore = best.score;
        _debugBreakdown = best.breakdown.entries.map((e) => '${e.key}:${e.value}').join(' ');
        if (_debugMode) {
          debugPrint('Scanner F$_scanFrameCount score=$bestScore '
              '${best.fingerprint.card.name} ${best.breakdown}');
        }
      } else if (_debugMode) {
        debugPrint('Scanner F$_scanFrameCount score=0 (no candidates)');
      }

      // ── Variant refinement: WAITING already identified the card ──
      if (_waitingMatch != null) {
        if (_scanFrameCount >= _maxScanFrames) {
          if (_debugMode) debugPrint('Scanner: Variant refinement done F$_scanFrameCount');
          final wm = _waitingMatch!;
          _waitingMatch = null;
          _acceptMatch(wm);
          return;
        }
        if (mounted) setState(() {});
        return;
      }

      // ── Normal SCANNING: early-exit or max frames ──

      // Name or title required for early-exit too
      final earlyHasName = matches.isNotEmpty &&
          (matches.first.breakdown.containsKey('name') ||
           matches.first.breakdown.containsKey('name_fuzzy') ||
           matches.first.breakdown.containsKey('title') ||
           matches.first.breakdown.containsKey('title_fuzzy'));
      if (bestScore >= _earlyExitScore && earlyHasName) {
        final best = matches.first;
        final card = best.fingerprint.card;
        final nameLower = card.name.toLowerCase();
        final variantCount = (_lookup.nameIndex[nameLower] ?? []).length;

        // Variant cards: don't early-exit, enter refinement to collect more rects
        if (variantCount > 1 && _waitingMatch == null) {
          _waitingMatch = OcrMatch(card: card, confidence: ScanConfidence.high,
              score: best.score, breakdown: best.breakdown);
          if (_debugMode) {
            debugPrint('Scanner: F$_scanFrameCount score=$bestScore '
                '"${card.name}" ($variantCount variants) → refinement');
          }
          // Continue scanning — don't return
        } else if (_waitingMatch == null) {
          debugPrint('Scanner: Early-exit F$_scanFrameCount score=$bestScore');
          _acceptMatch(OcrMatch(card: card, confidence: ScanConfidence.high,
              score: best.score, breakdown: best.breakdown));
          return;
        }
      }

      if (_scanFrameCount >= _maxScanFrames) {
        // Name or title required: no match without card text recognized
        final hasName = matches.isNotEmpty &&
            (matches.first.breakdown.containsKey('name') ||
             matches.first.breakdown.containsKey('name_fuzzy') ||
             matches.first.breakdown.containsKey('title') ||
             matches.first.breakdown.containsKey('title_fuzzy'));
        if (bestScore >= _minAcceptScore && hasName) {
          final best = matches.first;
          final card = best.fingerprint.card;
          debugPrint('Scanner: Accept F$_scanFrameCount score=$bestScore');
          _acceptMatch(OcrMatch(card: card,
              confidence: bestScore >= 50 ? ScanConfidence.medium : ScanConfidence.low,
              score: best.score, breakdown: best.breakdown));
        } else {
          debugPrint('Scanner: No match after $_scanFrameCount frames (cumBest=$bestScore)');
          _debugOcr = 'no match (cum=$bestScore)';
          // Negative training data now comes from rect crops (automatic)
          _setState(ScanState.stable);
        }
        return;
      }

      if (mounted) setState(() {});
    });
  }

  void _updateDebug(OcrMatch match) {
    final card = match.card;
    _debugOcr = '${card.setId}-${card.collectorNumber} ${card.name}';
    _debugScore = match.score;
    _debugBreakdown = match.breakdown.entries.map((e) => '${e.key}:${e.value}').join(' ');
  }

  void _acceptMatch(OcrMatch match) async {
    if (_scanPaused) return; // user is editing — drop stale match
    _setState(ScanState.stable);
    HapticFeedback.mediumImpact();
    // Show "identifying" spinner while async variant-resolution runs
    // (TFLite classifiers + pHash compute() — typically 300-500ms).
    // Cleared in finally so any early return still clears the spinner.
    if (mounted) setState(() => _identifying = true);

    try {
      await _resolveAndAddCard(match);
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  /// The full variant-resolution chain. Extracted from _acceptMatch so the
  /// _identifying spinner can be wrapped via try/finally without restructuring
  /// every early-return inside.
  Future<void> _resolveAndAddCard(OcrMatch match) async {
    var resolvedCard = match.card;

    final nameLower = match.card.name.toLowerCase();
    final variantFps = _lookup.nameIndex[nameLower] ?? [];
    final allVariants = variantFps.map((fp) => fp.card).toList();

    // Metal-Cards Exclusion (User-Request 2026-04-29):
    // Niemand scannt Metal-Karten real-world (zu teuer/seltener Sammlerwert).
    // Scanner darf nie auto-pick auf Metal switchen, auch nicht ueber
    // pHash/Promo-CNN/CN-Suffix-Pfade. Metal BLEIBT in `allVariants` —
    // wird aber unten in `resolvedAlts` (= Variant-Picker-Liste) vorhanden,
    // sodass User manuell waehlen kann nach erfolgtem Scan.
    final resolutionVariants = allVariants.where((c) => !c.metal).toList();
    final resolutionVariantFps = variantFps.where((fp) => !fp.card.metal).toList();

    // Validate cumulative CN against matched card — pick the reading that
    // actually belongs to this card. Prefer readings WITH suffix (more specific).
    if (_cnReadings.isNotEmpty && variantFps.isNotEmpty) {
      final validCNs = variantFps.map((fp) => fp.collectorNumber).whereType<int>().toSet();

      // First pass: find reading with suffix (most specific)
      ({int cn, String? suffix, String? raw})? bestReading;
      for (final r in _cnReadings) {
        if (validCNs.contains(r.cn)) {
          bestReading ??= r; // first valid match as fallback
          if (r.suffix != null) {
            bestReading = r; // suffix wins
            break;
          }
        }
      }

      if (bestReading != null) {
        _cumCN = bestReading.cn;
        _cumCNSuffix = bestReading.suffix;
        _cumCNRaw = bestReading.raw;
        if (_debugMode) {
          debugPrint('CN validated: cn=${bestReading.cn} suffix=${bestReading.suffix} '
              '(from ${_cnReadings.length} readings)');
        }
      }
    }

    // CN-Suffix variant resolution — if suffix found, use directly (no pHash needed)
    // Metal-Cards skipped via resolutionVariantFps (User-Request 2026-04-29)
    if (resolutionVariants.length > 1 && _cumCNSuffix != null && _cumCN != null) {
      for (final fp in resolutionVariantFps) {
        if (fp.cnSuffix == _cumCNSuffix && fp.collectorNumber == _cumCN) {
          resolvedCard = fp.card;
          if (_debugMode) {
            debugPrint('Variant resolved by CN suffix: '
                '${resolvedCard.setId}#${resolvedCard.collectorNumber} (suffix=$_cumCNSuffix)');
          }
          final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
          _addCard(resolvedCard, resolvedAlts, confidence: match.confidence);
          return;
        }
      }
    }

    // Badge OCR promo detection — if "PROMO" or "CHAMPION" was read, pick promo variant
    // Metal-Cards excluded from auto-pick (User-Request 2026-04-29)
    if (resolutionVariants.length > 1 && _cumPromoDetected) {
      final promoVariant = resolutionVariants.where((c) => c.isPromo).toList();
      if (promoVariant.isNotEmpty) {
        // If CHAMPION was detected and there's a champion edition, pick that one
        if (_cumChampionDetected) {
          final championVariant = promoVariant.where((c) => c.isChampionEdition).toList();
          if (championVariant.isNotEmpty) {
            resolvedCard = championVariant.first;
            if (_debugMode) {
              debugPrint('Variant resolved by champion OCR: '
                  '${resolvedCard.setId}#${resolvedCard.collectorNumber} (CHAMPION edition)');
            }
            final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
            _addCard(resolvedCard, resolvedAlts, confidence: match.confidence);
            return;
          }
        }
        // Regular promo — pick non-champion promo if available, else first promo
        final regularPromo = promoVariant.where((c) => !c.isChampionEdition).toList();
        resolvedCard = regularPromo.isNotEmpty ? regularPromo.first : promoVariant.first;
        if (_debugMode) {
          debugPrint('Variant resolved by badge OCR: '
              '${resolvedCard.setId}#${resolvedCard.collectorNumber} (PROMO detected)');
        }
        final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
        _addCard(resolvedCard, resolvedAlts, confidence: match.confidence);
        return;
      }
    }

    // ══════════════════════════════════════════════
    // ── Card rect + pHash compute + CNNs (ALWAYS run) ──
    // ══════════════════════════════════════════════
    PhashComputeResult? computeResult;
    List<int>? cardRect;

    if (_phash.isReady && _lastYPlane != null) {
      try {
        String rectMethod = '';

        // Card rect: 4-step fallback chain
        // 1. OCR Grid (primary) — uses any 2+ text anchors with 20%+ vertical distance
        final gridResult = _calculateCardRectFromGrid();
        if (gridResult != null) {
          cardRect = gridResult.rect;
          rectMethod = 'grid(${gridResult.pair})';
        }

        // 2. Best scored native rect (validated by OCR)
        if (cardRect == null) {
          final calibrated = _calibrateCardRect(match.card.type?.toLowerCase());
          if (calibrated != null) {
            cardRect = calibrated.rect;
            rectMethod = calibrated.method;
          }
        }

        // 3. OCR name-only fallback (rougher estimate from just the name position)
        if (cardRect == null && _cumNameBoxSolo != null) {
          final nameLeft = _cumNameBoxSolo![0];
          final nameCY = (_cumNameBoxSolo![1] + _cumNameBoxSolo![3]) / 2;
          double nameYPct = 0.58;
          final ct = match.card.type?.toLowerCase() ?? '';
          if (ct == 'legend') nameYPct = 0.62;
          else if (ct == 'rune') nameYPct = 0.72;
          if (ct != 'battlefield') {
            final cardW = (_lastYWidth * 0.47).roundToDouble();
            final cardH = cardW / 0.716;
            final cardTop = nameCY - nameYPct * cardH;
            final cardLeft = nameLeft - cardW * 0.09;
            cardRect = [
              cardLeft.round().clamp(0, _lastYWidth - 1),
              cardTop.round().clamp(0, _lastYHeight - 1),
              cardW.round().clamp(1, _lastYWidth),
              cardH.round().clamp(1, _lastYHeight),
            ];
            rectMethod = 'name-only';
            if (_debugMode) debugPrint('pHash name-only anchor rect: (${cardRect[0]},${cardRect[1]}) ${cardRect[2]}x${cardRect[3]}');
          }
        }

        // 4. Center-crop fallback (assume card is roughly centered in frame)
        if (cardRect == null) {
          final cardW = (_lastYWidth * 0.47).round();
          final cardH = (cardW / 0.716).round();
          final cardX = (_lastYWidth - cardW) ~/ 2;
          final cardY = (_lastYHeight - cardH) ~/ 2;
          cardRect = [cardX, cardY, cardW, cardH];
          rectMethod = 'center-crop';
          if (_debugMode) debugPrint('pHash center-crop fallback rect: ($cardX,$cardY) ${cardW}x$cardH');
        }

        if (_debugMode) debugPrint('Card rect via $rectMethod → (${cardRect[0]},${cardRect[1]}) ${cardRect[2]}x${cardRect[3]}');

        // Log ALL native rects for debugging
        if (_debugMode && _nativeRects.isNotEmpty) {
          debugPrint('Native rects: ${_nativeRects.length} collected:');
          for (int i = 0; i < _nativeRects.length && i < 10; i++) {
            final r = _nativeRects[i];
            final ratio = r[2] > 0 && r[3] > 0 ? (r[2] / r[3]).toStringAsFixed(3) : '?';
            debugPrint('  [$i]: (${r[0]},${r[1]}) ${r[2]}x${r[3]} ratio=$ratio');
          }
          if (_nativeRects.length > 10) debugPrint('  ... +${_nativeRects.length - 10} more');
        }

        // Save debug frame with ALL rects drawn (not just the best)
        if (_debugMode && _nativeRects.isNotEmpty && _lastYPlane != null) {
          _saveRejectedRectsDebug(match.card.name, _nativeRects);
        }

        // Strip stride padding from last Y-plane
        Uint8List yPlane;
        if (_lastYStride == _lastYWidth) {
          yPlane = _lastYPlane!;
        } else {
          yPlane = Uint8List(_lastYWidth * _lastYHeight);
          for (int y = 0; y < _lastYHeight; y++) {
            yPlane.setRange(
              y * _lastYWidth, y * _lastYWidth + _lastYWidth,
              _lastYPlane!, y * _lastYStride,
            );
          }
        }

        // pHash compute with OCR-anchored card rect
        // debug=true to always get card pixels (needed for CNNs + training)
        computeResult = await compute(computePhashIsolate, PhashPayload(
          yPlane: yPlane,
          width: _lastYWidth,
          height: _lastYHeight,
          cardRect: cardRect,
          debug: true,
        ));

        // Save debug images: card crop + full frame with rect overlay
        if (_debugMode && computeResult != null) {
          if (computeResult.debugFullPixels != null) {
            _saveDebugCrops(computeResult, match.card.name);
          }
          _saveFullFrameDebug(match.card.name, cardRect);
        }
      } catch (e) {
        debugPrint('Card rect/pHash compute error: $e');
      }
    }

    // ══════════════════════════════════════════════
    // ── Training frame collection (ALWAYS run) ──
    // ══════════════════════════════════════════════
    if (_debugMode) {
      debugPrint('TrainingFrame: computeResult=${computeResult != null}, '
          'pixels=${computeResult?.debugFullPixels != null}, '
          'yPlane=${_lastYPlane != null}');
    }
    // Training data now collected via manual POS/NEG buttons

    // Silent Card Rect training data collection — copy Y-plane before async
    if (cardRect != null && _lastYPlane != null) {
      final yPlaneCopy = Uint8List.fromList(_lastYPlane!);
      final yW = _lastYWidth;
      final yH = _lastYHeight;
      final yS = _lastYStride;
      final rectCopy = List<int>.from(cardRect);
      final name = match.card.name;
      debugPrint('CardRect: saving sample (rect=${rectCopy[0]},${rectCopy[1]} ${rectCopy[2]}x${rectCopy[3]})');
      _trainingFrames.saveCardRectSample(yPlaneCopy, yW, yH, yS, rectCopy, name);
    }

    // ══════════════════════════════════════════════
    // ── TFLite CNN classifiers (ALWAYS run) ──
    // ══════════════════════════════════════════════

    // ── TFLite Set Code Classifier ──
    if (computeResult?.debugFullPixels != null && _setClassifier.isReady) {
      final setResult = _setClassifier.classify(
        computeResult!.debugFullPixels!,
        computeResult.debugFullW,
        computeResult.debugFullH,
      );
      if (setResult != null) {
        if (_debugMode) {
          debugPrint('TFLite set: ${setResult.setCode} '
              '(conf=${setResult.confidence.toStringAsFixed(3)}, '
              'OCR was: ${match.card.setId})');
        }
        _cumSetCode = setResult.setCode;
      }
    }

    // ── TFLite Suffix Classifier ──
    if (computeResult?.debugFullPixels != null && _suffixClassifier.isReady) {
      final suffixResult = _suffixClassifier.classify(
        computeResult!.debugFullPixels!,
        computeResult.debugFullW,
        computeResult.debugFullH,
      );
      if (suffixResult != null) {
        final detectedSuffix = suffixResult.suffix == 'none' ? null : suffixResult.suffix;
        if (_debugMode) {
          debugPrint('TFLite suffix: ${suffixResult.suffix} '
              '(conf=${suffixResult.confidence.toStringAsFixed(3)}, '
              'OCR was: ${_cumCNSuffix ?? "none"})');
        }
        _cumCNSuffix = detectedSuffix;
      }
    }

    // ── TFLite Mana Classifier ──
    // Skip for card types without a mana diamond (rune, legend, battlefield).
    final cardTypeLower = match.card.type?.toLowerCase() ?? '';
    final noMana = _cumTypes.contains('rune') ||
        _cumTypes.contains('legend') || _cumTypes.contains('battlefield') ||
        cardTypeLower == 'rune' || cardTypeLower == 'legend' || cardTypeLower == 'battlefield';
    if (!noMana && computeResult?.debugFullPixels != null && _manaClassifier.isReady) {
      final manaResult = _manaClassifier.classify(
        computeResult!.debugFullPixels!,
        computeResult.debugFullW,
        computeResult.debugFullH,
      );
      if (manaResult != null) {
        if (_debugMode) {
          debugPrint('TFLite mana: ${manaResult.mana} '
              '(conf=${manaResult.confidence.toStringAsFixed(3)}, '
              'OCR was: ${_cumMana ?? "none"})');
        }
        _cumMana = manaResult.mana;
      }
    }

    // ── TFLite Promo Badge Classifier ──
    // Skip for runes — they have a completely different layout, the badge region
    // at 38%X/88%Y captures unrelated content and causes false positives.
    // Rune promos are still detected via badge OCR ("PROMO" text).
    // Skip for runes — check both OCR-detected type AND the matched card's type
    // (OCR might not have read "RUNE" in every scan session)
    final skipPromoCnn = _cumTypes.contains('rune') ||
        match.card.type?.toLowerCase() == 'rune';
    // Metal excluded (User-Request 2026-04-29) — never auto-pick metal as promo variant
    final promoIds = resolutionVariants.where((c) => c.isPromo).map((c) => c.id).toSet();
    if (!skipPromoCnn && promoIds.isNotEmpty && computeResult?.debugFullPixels != null && _promoClassifier.isReady) {
      final prob = _promoClassifier.classify(
        computeResult!.debugFullPixels!,
        computeResult.debugFullW,
        computeResult.debugFullH,
      );
      if (prob != null) {
        final isPromoBadge = prob >= PromoClassifierService.promoThreshold;
        if (_debugMode) {
          debugPrint('TFLite badge: prob=${prob.toStringAsFixed(3)} '
              '(thresh=${PromoClassifierService.promoThreshold} → ${isPromoBadge ? "PROMO" : "base"})');
        }
        if (isPromoBadge && resolutionVariants.length > 1) {
          // Constrain promo selection to variants matching confirmed set+CN
          // (same logic as pHash constraint — prevents cross-set false matches)
          // Metal excluded (User-Request 2026-04-29)
          var promoVariant = resolutionVariants.where((c) => c.isPromo).toList();
          final badgeSet = _cumSetCode;
          final badgeCN = _cumCN?.toString();
          if (badgeSet != null && badgeCN != null && promoVariant.length > 1) {
            final setFamily = <String>{badgeSet};
            const promoMap = {'OGN': 'OGNX', 'SFD': 'SFDX', 'OGS': 'OGSX'};
            const baseMap = {'OGNX': 'OGN', 'SFDX': 'SFD', 'OGSX': 'OGS'};
            if (promoMap.containsKey(badgeSet)) setFamily.add(promoMap[badgeSet]!);
            if (baseMap.containsKey(badgeSet)) setFamily.add(baseMap[badgeSet]!);

            final filtered = promoVariant.where((c) {
              if (!setFamily.contains(c.setId)) return false;
              final cardCNNum = c.collectorNumber?.replaceAll(RegExp(r'[^0-9]'), '');
              return cardCNNum == badgeCN;
            }).toList();
            if (filtered.isNotEmpty) {
              if (_debugMode && filtered.length < promoVariant.length) {
                debugPrint('TFLite badge: constrained to ${filtered.length}/${promoVariant.length} promo variants '
                    '(set=$badgeSet cn=$badgeCN)');
              }
              promoVariant = filtered;
            }
          }
          if (promoVariant.isNotEmpty) {
            // Champion edition detection via OCR
            if (_cumChampionDetected) {
              final championVariant = promoVariant.where((c) => c.isChampionEdition).toList();
              if (championVariant.isNotEmpty) {
                resolvedCard = championVariant.first;
                if (_debugMode) {
                  debugPrint('TFLite badge: resolved to ${resolvedCard.setId}#${resolvedCard.collectorNumber} (CHAMPION)');
                }
                final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
                _addCard(resolvedCard, resolvedAlts, confidence: match.confidence);
                return;
              }
            }
            // Regular promo — prefer non-champion
            final regularPromo = promoVariant.where((c) => !c.isChampionEdition).toList();
            resolvedCard = regularPromo.isNotEmpty ? regularPromo.first : promoVariant.first;
            if (_debugMode) {
              debugPrint('TFLite badge: resolved to ${resolvedCard.setId}#${resolvedCard.collectorNumber}');
            }
            final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
            _addCard(resolvedCard, resolvedAlts, confidence: match.confidence);
            return;
          }
        }
      }
    }

    // ── Card Name CNN as confidence cross-validator ──
    // Was previously debug-log-only. Now actively boosts/reduces the
    // displayed confidence so the user knows whether OCR + CNN agree.
    // The 932 KB model wasn't earning its bundle weight before — this
    // is OCR's only independent second opinion. Variant decisions
    // stay with OCR (CNN doesn't know variants, only names), but the
    // confidence-tier on the bottom-strip thumbnail is informed by
    // both signals. Saved into nameAgrees/nameStronglyDisagrees so
    // the final _addCard at function end can consume it.
    bool nameAgrees = false;
    bool nameStronglyDisagrees = false;
    if (computeResult?.debugFullPixels != null && _cardNameClassifier.isReady) {
      final nameResult = _cardNameClassifier.classify(
        computeResult!.debugFullPixels!,
        computeResult.debugFullW,
        computeResult.debugFullH,
      );
      if (nameResult != null) {
        final agrees = nameResult.name.toLowerCase() == match.card.name.toLowerCase();
        // Boost: CNN strongly confirms the OCR pick.
        if (agrees && nameResult.confidence >= 0.80) nameAgrees = true;
        // Demote: CNN strongly disagrees and points elsewhere — likely
        // a wrong OCR identification. Threshold higher (0.85) since false-
        // positive disagreements would needlessly downgrade good scans.
        if (!agrees && nameResult.confidence >= 0.85) nameStronglyDisagrees = true;
        if (_debugMode) {
          debugPrint('TFLite cardName: "${nameResult.name}" '
              '(conf=${nameResult.confidence.toStringAsFixed(3)}) '
              '${agrees ? "✓ agrees" : "✗ disagrees"} with OCR "${match.card.name}"');
        }
      } else if (_debugMode) {
        debugPrint('TFLite cardName: below threshold');
      }
    }
    // Compute CNN-adjusted final confidence used by all _addCard exits below.
    // High + agree → stays high. Low + agree → bumps to medium.
    // High + disagree → drops to medium (encourage verification).
    final ScanConfidence finalConfidence = nameAgrees
        ? switch (match.confidence) {
            ScanConfidence.low => ScanConfidence.medium,
            ScanConfidence.medium => ScanConfidence.high,
            ScanConfidence.high => ScanConfidence.high,
          }
        : nameStronglyDisagrees
            ? switch (match.confidence) {
                ScanConfidence.high => ScanConfidence.medium,
                ScanConfidence.medium => ScanConfidence.low,
                ScanConfidence.low => ScanConfidence.low,
              }
            : match.confidence;

    // ══════════════════════════════════════════════
    // ── pHash variant resolution (only for multi-variant cards) ──
    // ══════════════════════════════════════════════
    // Uses resolutionVariants (= allVariants WITHOUT metal) — pHash darf nie
    // auf Metal switchen (User-Request 2026-04-29). Metal hat anderen Foil-
    // Finish + Gem-Layout, pHash-Score koennte zufaellig hoch sein → wuerde
    // sonst Metal als Match liefern obwohl User nicht-Metal gescannt hat.
    if (resolutionVariants.length > 1 && computeResult != null) {
      // Constrain pHash to variants matching the confirmed set+CN.
      final confirmedSet = _cumSetCode;
      final confirmedCN = _cumCN?.toString();
      List<RiftCard> phashCandidates = resolutionVariants;
      if (confirmedSet != null && confirmedCN != null) {
        final setFamily = <String>{confirmedSet};
        const promoMap = {'OGN': 'OGNX', 'SFD': 'SFDX', 'OGS': 'OGSX'};
        const baseMap = {'OGNX': 'OGN', 'SFDX': 'SFD', 'OGSX': 'OGS'};
        if (promoMap.containsKey(confirmedSet)) setFamily.add(promoMap[confirmedSet]!);
        if (baseMap.containsKey(confirmedSet)) setFamily.add(baseMap[confirmedSet]!);

        final filtered = resolutionVariants.where((c) {
          if (!setFamily.contains(c.setId)) return false;
          final cardCNNum = c.collectorNumber?.replaceAll(RegExp(r'[^0-9]'), '');
          return cardCNNum == confirmedCN;
        }).toList();
        if (filtered.isNotEmpty) {
          phashCandidates = filtered;
          if (_debugMode && filtered.length < resolutionVariants.length) {
            debugPrint('pHash: constrained to ${filtered.length}/${resolutionVariants.length} variants '
                '(set=$confirmedSet cn=$confirmedCN)');
          }
        }
      }

      final phashVariantIds = phashCandidates.map((c) => c.id).toList();
      final phashPromoIds = phashCandidates.where((c) => c.isPromo).map((c) => c.id).toSet();
      final result = _phash.findBestVariant(computeResult.hash, phashVariantIds, promoIds: phashPromoIds);

      if (result != null) {
        if (_debugMode) {
          debugPrint('pHash: ${phashCandidates.length} variants of "${match.card.name}", '
              'Stage ${result.stage} → ${result.reason}');
          for (final c in result.comparisons) {
            final card = phashCandidates.firstWhere((v) => v.id == c.cardId, orElse: () => match.card);
            final selected = c.cardId == result.bestId ? ' ✓' : '';
            final gemInfo = result.stage >= 2 || c.fullDist <= PhashService.fullHashThreshold
                ? ' gem=${c.gemDist}' : '';
            debugPrint('  ${card.setId}#${card.collectorNumber}: full=${c.fullDist}$gemInfo$selected');
          }
        }

        final r = result;
        if (r.bestId != null && r.bestId != match.card.id) {
          final bestCard = allVariants.firstWhere((c) => c.id == r.bestId, orElse: () => match.card);
          resolvedCard = bestCard;
        }
      }
    }

    // Build alternatives list
    final resolvedAlts = allVariants
        .where((c) => c.id != resolvedCard.id)
        .toList();

    // Final pHash-fallthrough path uses CNN-adjusted confidence — this is
    // the path with the LEAST signal (no CN-suffix, no badge-OCR-promo, no
    // promo-CNN-trigger), so CNN cross-validation matters most here. Earlier
    // exits (CN-suffix, badge-OCR, promo-CNN branches) keep raw match.confidence
    // since those resolved via strong specific signals.
    _addCard(resolvedCard, resolvedAlts, confidence: finalConfidence);
  }

  // ══════════════════════════════════════════════
  // ── Badge crop OCR: detect PROMO text on the badge ──
  // ══════════════════════════════════════════════

  /// Crop the badge region from the Y-plane and run OCR to detect "PROMO" text.
  /// Uses the Grid to calculate where the badge should be.
  void _tryBadgeCropOcr() async {
    // Use any two anchors to get card geometry
    final gridRect = _calculateCardRectFromGrid();
    if (gridRect == null) return;

    final cx = gridRect.rect[0].toDouble();
    final cy = gridRect.rect[1].toDouble();
    final cw = gridRect.rect[2].toDouble();
    final ch = gridRect.rect[3].toDouble();

    // Badge region: generous crop of the bottom portion of the card.
    // PROMO text sits curved on/above the gem at the very bottom.
    // Crop the full bottom 15% of the card with full width to ensure
    // we capture the text regardless of exact position or curve.
    final badgeX = cx.round().clamp(0, _lastYWidth - 1);
    final badgeY = (cy + ch * 0.83).round().clamp(0, _lastYHeight - 1);
    final badgeW = cw.round().clamp(1, _lastYWidth - badgeX);
    final badgeH = (ch * 0.14).round().clamp(1, _lastYHeight - badgeY);

    if (_debugMode) debugPrint('Badge crop: ($badgeX,$badgeY) ${badgeW}x$badgeH');
    if (badgeW < 30 || badgeH < 15) {
      if (_debugMode) debugPrint('Badge crop: too small, skipping');
      return;
    }

    // Crop Y-plane and convert to 4x upscaled BGRA grayscale
    // Higher upscale gives ML Kit more pixels to work with for small curved text
    const scale = 4;
    final scaledW = badgeW * scale;
    final scaledH = badgeH * scale;
    final bgra = Uint8List(scaledW * scaledH * 4);
    for (int sy = 0; sy < scaledH; sy++) {
      for (int sx = 0; sx < scaledW; sx++) {
        final origX = badgeX + (sx ~/ scale);
        final origY = badgeY + (sy ~/ scale);
        final srcIdx = origY * _lastYStride + origX;
        final v = srcIdx >= 0 && srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
        final idx = (sy * scaledW + sx) * 4;
        bgra[idx] = v; bgra[idx + 1] = v; bgra[idx + 2] = v; bgra[idx + 3] = 255;
      }
    }

    try {
      final recognized = await _ocr.recognizeCrop(bgra, scaledW, scaledH);
      if (recognized == null || recognized.blocks.isEmpty) return;

      final text = recognized.blocks.map((b) => b.text.toLowerCase()).join(' ');

      // Check for PROMO and common OCR misreads (full + partial matches)
      final promoPatterns = [
        'promo', 'prom0', 'pr0mo', 'promd', 'promq', 'prgmo',
        'promo', 'prómo', 'prömo', // accented variants
        'rom0', 'romo', // partial: missing P
        'prom', 'pro mo', 'pr omo', // partial: split by space
      ];
      for (final p in promoPatterns) {
        if (text.contains(p)) {
          _cumPromoDetected = true;
          if (_debugMode) {
            debugPrint('Badge crop OCR: PROMO detected! text="$text" at ($badgeX,$badgeY) ${badgeW}x$badgeH');
          }
          return;
        }
      }

      // Check for CHAMPION text (Champion edition promos)
      final championPatterns = [
        'champion', 'champi0n', 'champ1on', 'champlon',
        'champio', 'hampion', 'champi', // partial reads
      ];
      for (final p in championPatterns) {
        if (text.contains(p)) {
          _cumChampionDetected = true;
          _cumPromoDetected = true; // Champion implies promo
          if (_debugMode) {
            debugPrint('Badge crop OCR: CHAMPION detected! text="$text" at ($badgeX,$badgeY) ${badgeW}x$badgeH');
          }
          return;
        }
      }

      if (_debugMode) {
        debugPrint('Badge crop OCR: no promo in "$text" at ($badgeX,$badgeY) ${badgeW}x$badgeH');
      }
    } catch (e) {
      if (_debugMode) debugPrint('Badge crop OCR error: $e');
    }
  }

  // ══════════════════════════════════════════════
  // ── Champion crop OCR: detect "CHAMPION" text in artwork area ──
  // ══════════════════════════════════════════════

  /// Crop the right side of the artwork area to detect "CHAMPION" text.
  /// Champion edition promos have large gold "CHAMPION" text at ~40-50% Y, 55-90% X.
  void _tryChampionCropOcr() async {
    final gridRect = _calculateCardRectFromGrid();
    if (gridRect == null) return;

    final cx = gridRect.rect[0].toDouble();
    final cy = gridRect.rect[1].toDouble();
    final cw = gridRect.rect[2].toDouble();
    final ch = gridRect.rect[3].toDouble();

    // Champion text region: right half of artwork area (~35-55% Y, 50-95% X)
    final cropX = (cx + cw * 0.50).round().clamp(0, _lastYWidth - 1);
    final cropY = (cy + ch * 0.35).round().clamp(0, _lastYHeight - 1);
    final cropW = (cw * 0.45).round().clamp(1, _lastYWidth - cropX);
    final cropH = (ch * 0.20).round().clamp(1, _lastYHeight - cropY);

    if (cropW < 30 || cropH < 15) return;

    // Crop Y-plane and convert to 3x upscaled BGRA grayscale
    const scale = 3;
    final scaledW = cropW * scale;
    final scaledH = cropH * scale;
    final bgra = Uint8List(scaledW * scaledH * 4);
    for (int sy = 0; sy < scaledH; sy++) {
      for (int sx = 0; sx < scaledW; sx++) {
        final origX = cropX + (sx ~/ scale);
        final origY = cropY + (sy ~/ scale);
        final srcIdx = origY * _lastYStride + origX;
        final v = srcIdx >= 0 && srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
        final idx = (sy * scaledW + sx) * 4;
        bgra[idx] = v; bgra[idx + 1] = v; bgra[idx + 2] = v; bgra[idx + 3] = 255;
      }
    }

    try {
      final recognized = await _ocr.recognizeCrop(bgra, scaledW, scaledH);
      if (recognized == null || recognized.blocks.isEmpty) return;

      final text = recognized.blocks.map((b) => b.text.toLowerCase()).join(' ');

      final championPatterns = [
        'champion', 'champi0n', 'champ1on', 'champlon',
        'champio', 'hampion', 'champi', // partial reads
      ];
      for (final p in championPatterns) {
        if (text.contains(p)) {
          _cumChampionDetected = true;
          _cumPromoDetected = true; // Champion implies promo
          if (_debugMode) {
            debugPrint('Champion crop OCR: CHAMPION detected! text="$text"');
          }
          return;
        }
      }

      if (_debugMode) {
        debugPrint('Champion crop OCR: no champion in "$text"');
      }
    } catch (e) {
      if (_debugMode) debugPrint('Champion crop OCR error: $e');
    }
  }

  // ══════════════════════════════════════════════
  // ── Mana crop OCR: targeted read of the mana region ──
  // ══════════════════════════════════════════════

  /// Crop the mana region from the Y-plane and detect mana cost.
  /// Uses the Grid (type+cn) to calculate where mana should be.
  /// Strategy: OCR first, CNN fallback if OCR fails.
  void _tryManaCropOcr() async {
    final typeAnchor = _gridAnchors['type'];
    final cnAnchor = _gridAnchors['cn'];
    if (typeAnchor == null || cnAnchor == null) return;

    // Calculate card geometry from type+cn
    final observedDist = cnAnchor.observedCY - typeAnchor.observedCY;
    if (observedDist <= 0) return;
    final cardH = observedDist / (_gridCnYPct - _gridTypeYPct);
    final cardW = cardH * _idealRatio;
    final cardTop = typeAnchor.observedCY - _gridTypeYPct * cardH;
    final cardLeft = cnAnchor.observedLeft - _gridCnXPct * cardW;

    // Mana sits at ~3% of card height, ~8% from left, in a diamond ~12% wide, ~8% tall
    final manaX = (cardLeft + cardW * 0.02).round().clamp(0, _lastYWidth - 1);
    final manaY = (cardTop + cardH * 0.0).round().clamp(0, _lastYHeight - 1);
    final manaW = (cardW * 0.18).round().clamp(1, _lastYWidth - manaX);
    final manaH = (cardH * 0.12).round().clamp(1, _lastYHeight - manaY);

    if (manaW < 20 || manaH < 20) return;

    // ── Step 1: Try OCR on the mana crop ──
    // Crop Y-plane and convert to BGRA for ML Kit
    final bgra = Uint8List(manaW * manaH * 4);
    for (int y = 0; y < manaH; y++) {
      for (int x = 0; x < manaW; x++) {
        final srcIdx = (manaY + y) * _lastYStride + (manaX + x);
        final v = srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
        final idx = (y * manaW + x) * 4;
        bgra[idx] = v; bgra[idx + 1] = v; bgra[idx + 2] = v; bgra[idx + 3] = 255;
      }
    }

    bool ocrFound = false;
    try {
      final recognized = await _ocr.recognizeCrop(bgra, manaW, manaH);
      if (recognized != null && recognized.blocks.isNotEmpty) {
        for (final block in recognized.blocks) {
          final trimmed = block.text.trim();
          if (trimmed.length <= 2 && RegExp(r'^\d{1,2}$').hasMatch(trimmed)) {
            final manaCost = int.tryParse(trimmed);
            if (manaCost != null) {
              _setManaAnchor(manaCost, manaX, manaY, manaW, manaH, 'OCR');
              ocrFound = true;
              break;
            }
          }
        }
        if (!ocrFound && _debugMode) {
          final text = recognized.blocks.map((b) => b.text).join(' | ');
          debugPrint('Mana crop OCR: no digit in "$text"');
        }
      }
    } catch (e) {
      if (_debugMode) debugPrint('Mana crop OCR error: $e');
    }

    if (ocrFound) return;

    // ── Step 2: CNN fallback — extract card pixels and classify ──
    if (!_manaClassifier.isReady) return;

    // Extract estimated card region from Y-plane
    final cardX = cardLeft.round().clamp(0, _lastYWidth - 1);
    final cardY2 = cardTop.round().clamp(0, _lastYHeight - 1);
    final cw = cardW.round().clamp(1, _lastYWidth - cardX);
    final ch = cardH.round().clamp(1, _lastYHeight - cardY2);

    if (cw < 50 || ch < 50) return;

    final cardPixels = Uint8List(cw * ch);
    for (int y = 0; y < ch; y++) {
      for (int x = 0; x < cw; x++) {
        final srcIdx = (cardY2 + y) * _lastYStride + (cardX + x);
        cardPixels[y * cw + x] =
            srcIdx >= 0 && srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
      }
    }

    final result = _manaClassifier.classify(cardPixels, cw, ch);
    if (result != null) {
      _setManaAnchor(result.mana, manaX, manaY, manaW, manaH, 'CNN(${result.confidence.toStringAsFixed(2)})');
    } else if (_debugMode) {
      debugPrint('Mana CNN: low confidence, skipping');
    }
  }

  /// Helper: set mana value + create grid anchor from crop coordinates.
  void _setManaAnchor(int manaCost, int manaX, int manaY, int manaW, int manaH, String source) {
    _cumMana ??= manaCost;
    final cx = manaX + manaW / 2.0;
    final cy = manaY + manaH / 2.0;
    _gridAnchors['mana'] = GridAnchor(
      label: 'mana',
      yPct: _gridManaYPct,
      xPct: _gridManaXPct,
      observedCX: cx,
      observedCY: cy,
      observedLeft: manaX.toDouble(),
    );
    if (_debugMode) {
      debugPrint('Mana $source: found $manaCost at ($manaX,$manaY) ${manaW}x$manaH');
    }
  }

  // ══════════════════════════════════════════════
  // ── OCR Grid: anchor accumulation + card rect calculation ──
  // ══════════════════════════════════════════════

  /// Y-percentages per card element (typ-independent unless noted).
  static const _gridManaYPct = 0.03;
  static const _gridTypeYPct = 0.52;
  static const _gridCnYPct = 0.97;
  // Name Y% varies by card type — resolved at accumulation time.
  static double _gridNameYPct(String? cardType) {
    final ct = cardType ?? '';
    if (ct == 'legend') return 0.62;
    if (ct == 'rune') return 0.72;
    return 0.58;
  }

  /// X-percentages (where the left edge of the text sits on the card).
  static const _gridManaXPct = 0.08;  // mana top-left
  static const _gridTypeXPct = 0.12;  // type line left
  static const _gridNameXPct = 0.08;  // name left
  static const _gridCnXPct = 0.09;    // CN left

  /// Accumulate grid anchors from a single OCR frame extraction.
  void _accumulateGridAnchors(OcrExtraction extraction) {
    if (_debugMode && _gridAnchors.isEmpty) {
      final has = <String>[];
      if (extraction.manaBox != null) has.add('mana');
      if (extraction.typeBox != null) has.add('type');
      if (extraction.nameBox != null) has.add('name');
      if (extraction.cnBox != null) has.add('cn');
      if (has.isNotEmpty) debugPrint('Grid: first anchors from this frame: ${has.join(",")}');
    }
    void _addAnchor(String label, double yPct, double xPct, List<double>? box) {
      if (box == null) return;
      final cx = (box[0] + box[2]) / 2;
      final cy = (box[1] + box[3]) / 2;
      _gridAnchors[label] = GridAnchor(
        label: label,
        yPct: yPct,
        xPct: xPct,
        observedCX: cx,
        observedCY: cy,
        observedLeft: box[0],
      );
    }

    _addAnchor('mana', _gridManaYPct, _gridManaXPct, extraction.manaBox);
    _addAnchor('type', _gridTypeYPct, _gridTypeXPct, extraction.typeBox);
    // Name Y% depends on card type — use best known type so far
    final bestType = _cumTypes.isNotEmpty ? _cumTypes.first : null;
    _addAnchor('name', _gridNameYPct(bestType), _gridNameXPct, extraction.nameBox);
    _addAnchor('cn', _gridCnYPct, _gridCnXPct, extraction.cnBox);
  }

  /// Calculate card rect from accumulated grid anchors.
  /// Returns null if not enough anchors with sufficient vertical distance.
  ({List<int> rect, double score, String method, String pair})? _calculateCardRectFromGrid() {
    if (_gridAnchors.length < 2) return null;

    final fw = _lastYWidth.toDouble();
    final fh = _lastYHeight.toDouble();
    if (fw <= 0 || fh <= 0) return null;

    final anchors = _gridAnchors.values.toList();
    const minYGap = 0.20; // minimum 20% vertical distance between anchors

    // Evaluate all pairs, pick best by vertical distance
    GridAnchor? bestA, bestB;
    double bestGap = 0;

    for (int i = 0; i < anchors.length; i++) {
      for (int j = i + 1; j < anchors.length; j++) {
        final a = anchors[i];
        final b = anchors[j];
        final yGap = (a.yPct - b.yPct).abs();
        if (yGap < minYGap) continue;

        // Horizontal consistency check: both should predict similar cardLeft
        // Skip if horizontal difference is too large (different cards)
        final hDiff = (a.observedLeft - b.observedLeft).abs();
        if (hDiff > fw * 0.35) continue;

        if (yGap > bestGap) {
          bestGap = yGap;
          // Ensure a is the upper anchor (smaller yPct)
          if (a.yPct < b.yPct) {
            bestA = a;
            bestB = b;
          } else {
            bestA = b;
            bestB = a;
          }
        }
      }
    }

    if (bestA == null || bestB == null) return null;

    // Calculate card dimensions from the anchor pair
    final observedDist = bestB.observedCY - bestA.observedCY;
    if (observedDist <= 0) return null;

    final cardH = observedDist / (bestB.yPct - bestA.yPct);
    final cardW = cardH * _idealRatio;
    final cardTop = bestA.observedCY - bestA.yPct * cardH;

    // X offset: use the lower anchor's left edge (usually CN, most reliable)
    final cardLeft = bestB.observedLeft - bestB.xPct * cardW;

    // Clamp to frame bounds
    final rect = [
      cardLeft.round().clamp(0, _lastYWidth - 1),
      cardTop.round().clamp(0, _lastYHeight - 1),
      cardW.round().clamp(1, _lastYWidth),
      cardH.round().clamp(1, _lastYHeight),
    ];

    // Score: based on vertical gap (more = better)
    final score = (bestGap / 0.94).clamp(0.0, 1.0); // 94% gap = perfect score

    final pair = '${bestA.label}(${bestA.yPct})+${bestB.label}(${bestB.yPct})';

    if (_debugMode) {
      debugPrint('Grid rect: $pair gap=${(bestGap * 100).round()}% '
          '(${rect[0]},${rect[1]}) ${rect[2]}x${rect[3]} score=${score.toStringAsFixed(2)} '
          '[${_gridAnchors.length} anchors: ${_gridAnchors.keys.join(",")}]');
    }

    return (rect: rect, score: score, method: 'grid', pair: pair);
  }

  // ══════════════════════════════════════════════
  // ── Calibrated card rect: score + OCR cross-validation ──
  // ══════════════════════════════════════════════

  static const _idealRatio = 0.716; // card w/h = 63mm / 88mm

  /// Select the best native rect for pHash/SAD.
  ///
  /// 1. Hard filter: ratio 0.68-0.75, width ≥ 30% frame, center in middle 70%
  /// 2. Score: ratio (70%) + size (30%) → sort descending
  /// 3. OCR gate: from best down, first rect where card name sits at ~58% → use it
  /// 4. Calibrate: nudge rect ±20px to align OCR landmarks
  ({List<int> rect, double score, String method})? _calibrateCardRect(String? cardType) {
    if (_nativeRects.isEmpty) return null;

    final fw = _lastYWidth.toDouble();
    final fh = _lastYHeight.toDouble();
    if (fw <= 0 || fh <= 0) return null;

    // Layout profile
    double nameYPct = 0.58;
    const cnYPct = 0.97;
    final ct = cardType ?? '';
    if (ct == 'legend') nameYPct = 0.62;
    else if (ct == 'rune') nameYPct = 0.72;

    // OCR anchors
    final hasOcr = _cumNameBox != null && _cumCnBox != null && ct != 'battlefield';
    double? nameCY, cnCY, cnLeft;
    if (hasOcr) {
      nameCY = (_cumNameBox![1] + _cumNameBox![3]) / 2;
      cnCY = (_cumCnBox![1] + _cumCnBox![3]) / 2;
      cnLeft = _cumCnBox![0];
    }

    // ── Step 1: Hard filter ──
    final minWidth = fw * 0.30;
    final centerXMin = fw * 0.15, centerXMax = fw * 0.85;
    final centerYMin = fh * 0.15, centerYMax = fh * 0.85;

    final candidates = <({List<int> rect, double score, int idx})>[];

    for (int i = 0; i < _nativeRects.length; i++) {
      final r = _nativeRects[i];
      final rw = r[2].toDouble(), rh = r[3].toDouble();
      if (rw <= 0 || rh <= 0) continue;

      final ratio = rw / rh;
      if (ratio < 0.68 || ratio > 0.75) continue; // hard ratio filter
      if (rw < minWidth) continue; // hard min width
      final cx = r[0] + rw / 2, cy = r[1] + rh / 2;
      if (cx < centerXMin || cx > centerXMax || cy < centerYMin || cy > centerYMax) continue;

      // ── Step 2: Score = ratio 70% + size 30% ──
      final ratioErr = (ratio - _idealRatio).abs() / _idealRatio;
      final ratioScore = (1.0 - ratioErr * 5.0).clamp(0.0, 1.0);
      final sizeScore = (rw / fw).clamp(0.0, 1.0); // bigger = better
      final score = ratioScore * 0.70 + sizeScore * 0.30;

      candidates.add((rect: r, score: score, idx: i));
    }

    if (candidates.isEmpty) return null;

    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // ── Step 3: OCR gate — from best down, find first with valid OCR alignment ──
    List<int>? bestRect;
    double bestScore = 0;
    int bestIdx = -1;

    if (hasOcr) {
      for (final c in candidates) {
        final ry = c.rect[1].toDouble(), rh = c.rect[3].toDouble();
        final predNameY = ry + nameYPct * rh;
        final nameErr = (nameCY! - predNameY).abs();
        // Name must be within 40px of expected position
        if (nameErr < 40) {
          bestRect = c.rect;
          bestScore = c.score;
          bestIdx = c.idx;
          break;
        }
      }
    }

    // No OCR or no rect passed OCR gate → use best scoring rect
    if (bestRect == null) {
      final best = candidates.first;
      bestRect = best.rect;
      bestScore = best.score;
      bestIdx = best.idx;
    }

    // ── Step 4: Calibration — nudge rect to align OCR landmarks ──
    var method = 'scored';
    var finalRect = bestRect;

    if (hasOcr) {
      var rx = bestRect[0].toDouble(), ry = bestRect[1].toDouble();
      var rw = bestRect[2].toDouble(), rh = bestRect[3].toDouble();

      final predNameY = ry + nameYPct * rh;
      final yShift = (nameCY! - predNameY).clamp(-20.0, 20.0);

      final observedSpan = cnCY! - nameCY;
      final expectedSpan = (cnYPct - nameYPct) * rh;
      if (expectedSpan > 0 && observedSpan > 0) {
        final spanRatio = (observedSpan / expectedSpan).clamp(0.90, 1.10);
        final calH = rh * spanRatio;
        final calW = calH * _idealRatio;
        final calTop = ry + yShift;
        final predCnLeft = rx + 0.09 * rw;
        final xShift = (cnLeft! - predCnLeft).clamp(-15.0, 15.0);
        final calLeft = rx + xShift;

        // Only apply if calibration improves alignment
        final origErr = (nameCY - predNameY).abs() + (cnCY - (ry + cnYPct * rh)).abs();
        final calErr = (nameCY - (calTop + nameYPct * calH)).abs() + (cnCY - (calTop + cnYPct * calH)).abs();

        if (calErr < origErr) {
          finalRect = [
            calLeft.round().clamp(0, _lastYWidth - 1),
            calTop.round().clamp(0, _lastYHeight - 1),
            calW.round().clamp(1, _lastYWidth),
            calH.round().clamp(1, _lastYHeight),
          ];
          method = 'scored+calibrated';
        }
      }
    }

    if (_debugMode) {
      debugPrint('pHash rect $method score=${bestScore.toStringAsFixed(2)} '
          '(${finalRect[0]},${finalRect[1]}) ${finalRect[2]}x${finalRect[3]} '
          '[best of ${_nativeRects.length} rects, idx=$bestIdx, ${candidates.length} passed filter]');
      if (hasOcr) {
        final fy = finalRect[1].toDouble(), fh2 = finalRect[3].toDouble();
        final nameErr = (nameCY! - (fy + nameYPct * fh2)).abs().round();
        final cnErr = (cnCY! - (fy + cnYPct * fh2)).abs().round();
        debugPrint('  nameY: expected=${(fy + nameYPct * fh2).round()} actual=${nameCY.round()} (${nameErr}px off)');
        debugPrint('  cnY: expected=${(fy + cnYPct * fh2).round()} actual=${cnCY.round()} (${cnErr}px off)');
      }
    }

    return (rect: finalRect, score: bestScore, method: method);
  }

  /// Save frame with ALL rejected native rects drawn in different colors.
  void _saveRejectedRectsDebug(String cardName, List<List<int>> rects) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/phash_debug');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final safeName = cardName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;

      final w = _lastYWidth;
      final h = _lastYHeight;
      final rgba = Uint8List(w * h * 4);

      // Fill with grayscale Y-plane
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final srcIdx = y * _lastYStride + x;
          final v = srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
          final dstIdx = (y * w + x) * 4;
          rgba[dstIdx] = v; rgba[dstIdx + 1] = v; rgba[dstIdx + 2] = v; rgba[dstIdx + 3] = 255;
        }
      }

      // Draw each rect in a different color
      final colors = [
        [255, 0, 0],     // red
        [0, 255, 0],     // green
        [0, 0, 255],     // blue
        [255, 255, 0],   // yellow
        [255, 0, 255],   // magenta
        [0, 255, 255],   // cyan
        [255, 128, 0],   // orange
        [128, 0, 255],   // purple
        [0, 255, 128],   // mint
        [255, 128, 128], // pink
      ];

      for (int ri = 0; ri < rects.length; ri++) {
        final r = rects[ri];
        final cx = r[0], cy = r[1], cw = r[2], ch = r[3];
        final color = colors[ri % colors.length];

        // Draw rect border (3px thick)
        for (int t = 0; t < 3; t++) {
          for (int x = cx; x < (cx + cw).clamp(0, w); x++) {
            for (final yy in [cy + t, cy + ch - 1 - t]) {
              if (yy >= 0 && yy < h) {
                final idx = (yy * w + x) * 4;
                rgba[idx] = color[0]; rgba[idx + 1] = color[1]; rgba[idx + 2] = color[2];
              }
            }
          }
          for (int y = cy; y < (cy + ch).clamp(0, h); y++) {
            for (final xx in [cx + t, cx + cw - 1 - t]) {
              if (xx >= 0 && xx < w) {
                final idx = (y * w + xx) * 4;
                rgba[idx] = color[0]; rgba[idx + 1] = color[1]; rgba[idx + 2] = color[2];
              }
            }
          }
        }
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, completer.complete);
      final image = await completer.future;
      final path = '${dir.path}/${safeName}_${ts}_rejected.png';
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await File(path).writeAsBytes(byteData.buffer.asUint8List());
        debugPrint('pHash debug: saved ${rects.length} rejected rects to $path');
      }
      image.dispose();
    } catch (e) {
      debugPrint('pHash debug rejected rects failed: $e');
    }
  }

  /// Save full frame with card rect (green) and gem crop (red) drawn as overlay.
  void _saveFullFrameDebug(String cardName, List<int> cardRect) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/phash_debug');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final safeName = cardName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Build RGBA image from Y-plane with rects drawn
      final w = _lastYWidth;
      final h = _lastYHeight;
      final rgba = Uint8List(w * h * 4);

      // Fill with grayscale Y-plane (stripped of stride)
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final srcIdx = y * _lastYStride + x;
          final v = srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
          final dstIdx = (y * w + x) * 4;
          rgba[dstIdx] = v;
          rgba[dstIdx + 1] = v;
          rgba[dstIdx + 2] = v;
          rgba[dstIdx + 3] = 255;
        }
      }

      // Draw card rect in green
      final cx = cardRect[0], cy = cardRect[1], cw = cardRect[2], ch = cardRect[3];
      for (int x = cx; x < (cx + cw).clamp(0, w); x++) {
        for (int t = 0; t < 3; t++) {
          final topIdx = ((cy + t).clamp(0, h - 1) * w + x) * 4;
          rgba[topIdx] = 0; rgba[topIdx + 1] = 255; rgba[topIdx + 2] = 0;
          final botIdx = ((cy + ch - 1 - t).clamp(0, h - 1) * w + x) * 4;
          rgba[botIdx] = 0; rgba[botIdx + 1] = 255; rgba[botIdx + 2] = 0;
        }
      }
      for (int y = cy; y < (cy + ch).clamp(0, h); y++) {
        for (int t = 0; t < 3; t++) {
          final leftIdx = (y * w + (cx + t).clamp(0, w - 1)) * 4;
          rgba[leftIdx] = 0; rgba[leftIdx + 1] = 255; rgba[leftIdx + 2] = 0;
          final rightIdx = (y * w + (cx + cw - 1 - t).clamp(0, w - 1)) * 4;
          rgba[rightIdx] = 0; rgba[rightIdx + 1] = 255; rgba[rightIdx + 2] = 0;
        }
      }

      // Draw gem crop in red
      final gx = cx + (cw * 0.44).round();
      final gy = cy + (ch * 0.91).round();
      final gw = (cw * 0.12).round();
      final gh = (ch * 0.06).round();
      for (int x = gx; x < (gx + gw).clamp(0, w); x++) {
        for (int t = 0; t < 2; t++) {
          final topIdx = ((gy + t).clamp(0, h - 1) * w + x) * 4;
          rgba[topIdx] = 255; rgba[topIdx + 1] = 0; rgba[topIdx + 2] = 0;
          final botIdx = ((gy + gh - 1 - t).clamp(0, h - 1) * w + x) * 4;
          rgba[botIdx] = 255; rgba[botIdx + 1] = 0; rgba[botIdx + 2] = 0;
        }
      }
      for (int y = gy; y < (gy + gh).clamp(0, h); y++) {
        for (int t = 0; t < 2; t++) {
          final leftIdx = (y * w + (gx + t).clamp(0, w - 1)) * 4;
          rgba[leftIdx] = 255; rgba[leftIdx + 1] = 0; rgba[leftIdx + 2] = 0;
          final rightIdx = (y * w + (gx + gw - 1 - t).clamp(0, w - 1)) * 4;
          rgba[rightIdx] = 255; rgba[rightIdx + 1] = 0; rgba[rightIdx + 2] = 0;
        }
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, completer.complete);
      final image = await completer.future;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final path = '${dir.path}/${safeName}_${ts}_frame.png';
        await File(path).writeAsBytes(byteData.buffer.asUint8List());
        debugPrint('pHash debug: full frame saved to $path');
      }
      image.dispose();
    } catch (e) {
      debugPrint('pHash debug: full frame save failed: $e');
    }
  }

  /// Save debug crop images as PNGs to the app's documents directory.
  void _saveDebugCrops(PhashComputeResult result, String cardName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/phash_debug');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final safeName = cardName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Save full crop (grayscale Y-plane → PNG)
      if (result.debugFullPixels != null) {
        await _saveGrayscalePng(
          result.debugFullPixels!, result.debugFullW, result.debugFullH,
          '${dir.path}/${safeName}_${ts}_full.png',
        );
      }

      // Save gem crop
      if (result.debugGemPixels != null) {
        await _saveGrayscalePng(
          result.debugGemPixels!, result.debugGemW, result.debugGemH,
          '${dir.path}/${safeName}_${ts}_gem.png',
        );
      }

      debugPrint('pHash debug: saved to ${dir.path}/${safeName}_${ts}_*.png '
          '(full: ${result.debugFullW}x${result.debugFullH}, '
          'gem: ${result.debugGemW}x${result.debugGemH})');
    } catch (e) {
      debugPrint('pHash debug: save failed: $e');
    }
  }

  /// Write grayscale pixels as a PNG file.
  Future<void> _saveGrayscalePng(Uint8List pixels, int w, int h, String path) async {
    // Convert grayscale to RGBA (ui.Image requires 4 bytes per pixel)
    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      final v = i < pixels.length ? pixels[i] : 0;
      rgba[i * 4] = v;     // R
      rgba[i * 4 + 1] = v; // G
      rgba[i * 4 + 2] = v; // B
      rgba[i * 4 + 3] = 255; // A
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
    }
    image.dispose();
  }

  /// Add card to scanned list — every scan gets its own entry.
  /// Merging happens later in ScanResultsScreen.
  void _addCard(RiftCard card, List<RiftCard> alternatives,
      {ScanConfidence confidence = ScanConfidence.high}) {
    // Last-line defense — if user opened the editor sheet between OCR
    // dispatch and this call, drop the stale scan instead of duplicating.
    if (_scanPaused) return;
    _justScanned = true; // require higher motion threshold before next scan
    setState(() {
      _scannedCards.add(ScannedCardEntry(
        card: card,
        alternatives: alternatives,
        confidence: confidence,
      ));
    });
  }

  /// Show bottom sheet to edit a scanned card entry (variant, foil, quantity).
  void _showCardEditor(ScannedCardEntry entry) {
    // Build stable list of ALL variants (deduplicated by ID) — doesn't change on switch
    final seen = <String>{};
    final allVariants = <RiftCard>[];
    for (final c in [entry.card, ...entry.alternatives]) {
      if (seen.add(c.id)) allVariants.add(c);
    }
    // Pause scanning while editing. _scanPaused stops new processing
    // immediately + drops any in-flight OCR results before they reach
    // _addCard — without this, ML Kit's 50-200ms latency creates a window
    // where a "stale" match still gets added behind the open sheet.
    _scanPaused = true;
    _controller?.stopImageStream();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle (V2 sheet pattern)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: RiftrDragHandle(style: RiftrDragHandleStyle.sheet),
              ),
              // ── Header: card image + name + set info ──
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: CardImage(
                    imageUrl: entry.card.imageUrl,
                    fallbackText: entry.card.name,
                    width: 80, height: 112, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.card.displayName,
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${entry.card.setId ?? ''} #${entry.card.collectorNumber ?? ''} · ${entry.card.rarity ?? ''}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                  ],
                )),
              ]),

              // ── Variant picker (only if alternatives exist) ──
              if (allVariants.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Variant', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                ...allVariants.map((card) {
                  final isSelected = card.id == entry.card.id;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.minimal),
                      child: CardImage(imageUrl: card.imageUrl, fallbackText: card.name,
                        width: 36, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(card.displayName, style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                    subtitle: Text('${card.setId} #${card.collectorNumber ?? ''} · ${card.rarity}',
                      style: AppTextStyles.micro.copyWith(color: AppColors.textMuted)),
                    trailing: isSelected ? Icon(Icons.check, color: AppColors.amber400, size: 20) : null,
                    onTap: () {
                      setState(() {
                        entry.card = card;
                        entry.alternatives = allVariants.where((c) => c.id != card.id).toList();
                        entry.isFoil = ScannedCardEntry._defaultFoil(card);
                      });
                      setSheetState(() {});
                    },
                  );
                }),
              ],

              // ── Foil toggle (hidden for runes — no foil variants) ──
              if (entry.hasFoil) ...[
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Text('★', style: AppTextStyles.titleMedium.copyWith(color: AppColors.amber300)),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Foil', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  if (entry.isFoilEditable)
                    Switch.adaptive(
                      value: entry.isFoil,
                      activeThumbColor: AppColors.amber400,
                      onChanged: (v) {
                        setState(() => entry.isFoil = v);
                        setSheetState(() {});
                      },
                    )
                  else
                    Text('Yes', style: AppTextStyles.bodySmall.copyWith(color: AppColors.amber400)),
                ]),
              ],

              // ── Remove button ──
              const SizedBox(height: AppSpacing.md),
              RiftrButton(
                label: 'Remove',
                icon: Icons.delete_outline,
                style: RiftrButtonStyle.danger,
                onPressed: () {
                  setState(() => _scannedCards.remove(entry));
                  Navigator.pop(ctx);
                },
              ),

              SizedBox(height: MediaQuery.of(ctx).padding.bottom + AppSpacing.sm),
            ],
          ),
        )),  // Padding, DraggableScrollableSheet builder
      ),  // StatefulBuilder
    ).then((_) {
      // Resume scanning when sheet closes. Bump _scanCycleId to invalidate
      // any cumulative SCANNING state from before — the user may have edited
      // the previous match, and stale frames must not leak through.
      if (mounted && _controller != null) {
        _prevLuminance = null; // reset so motion detection starts fresh
        _lastCardPresentProb = 0.0;
        _scanCycleId++;
        _controller!.startImageStream(_onFrame);
        _setState(ScanState.waiting);
        _scanPaused = false;
      }
    });
  }

  void _setState(ScanState newState) {
    if (_state == newState) return;
    debugPrint('Scanner: $_state → $newState (motion: ${_motionPercent.toStringAsFixed(1)}%)');
    // Counter reset wenn wir waiting verlassen — beim naechsten Re-Entry
    // (nach motion → settling → scanning → match → zurueck zu waiting)
    // bauen wir den Stuck-Counter wieder von 0 auf.
    if (_state == ScanState.waiting && newState != ScanState.waiting) {
      _waitingStuckFrames = 0;
      _waitingHintTimer?.cancel();
      _waitingHintTimer = null;
      if (_showWaitingHint) _showWaitingHint = false;
    }
    // Start the 8s WAITING hint timer when entering WAITING.
    // Gives the user guidance if auto-detect doesn't fire (low-light,
    // classifier underestimates) — they can tap the camera preview to
    // force an OCR attempt.
    if (newState == ScanState.waiting && _state != ScanState.waiting) {
      _waitingHintTimer?.cancel();
      _waitingHintTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && _state == ScanState.waiting) {
          setState(() => _showWaitingHint = true);
        }
      });
    }
    // Clear native rects and waiting match when motion starts (new card)
    if (newState == ScanState.motion) {
      _nativeRects.clear();
      _waitingMatch = null;
      _ocr.resetStickyMana(); // new card → reset sticky mana from previous scan
    }
    // Reset cumulative extraction when entering SCANNING
    if (newState == ScanState.scanning) {
      _scanCycleId++;
      _scanFrameCount = 0;
      _cumSetCode = null;
      _cumCN = null;
      _cumCNSuffix = null;
      _cumCNRaw = null;
      _cnReadings.clear();
      _cumMana = null;
      _cumNames.clear();
      _cumKeywords.clear();
      _cumTypes.clear();
      _cumRegions.clear();
      _cumText.clear();
      _cumNameBox = null;
      _cumCnBox = null;
      _cumNameBoxSolo = null;
      _cumPromoDetected = false;
      _cumChampionDetected = false;
      _gridAnchors.clear();
      // Native rects are NOT cleared on SCANNING entry — rects from SETTLING
      // are valid (card is already still). Only MOTION clears them (new card).
    }
    _state = newState;
  }

  /// Tap-to-rescan: force OCR on next frame.
  ///   STABLE → re-enter SCANNING for the next OCR cycle
  ///   WAITING → trip the stuck-counter so the next frame bypasses
  ///             the Card-Present-Classifier gate (same path that
  ///             auto-fires after 3s, but on user demand).
  void _tapToRescan() {
    if (_state == ScanState.stable) {
      _setState(ScanState.scanning);
    } else if (_state == ScanState.waiting) {
      // Force-OCR on next frame regardless of classifier prob.
      _waitingStuckFrames = _waitingStuckThreshold;
      HapticFeedback.lightImpact();
    }
  }

  void _toggleTorch() async {
    if (_controller == null) return;
    _torchOn = !_torchOn;
    await _controller!.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _finishScanning() async {
    if (_scannedCards.isEmpty) {
      Navigator.pop(context);
      return;
    }
    _scanPaused = true;
    _controller?.stopImageStream();

    // Push ScanResults — it may return entries to continue scanning
    final returnedEntries = await Navigator.push<List<ScannedCardEntry>>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultsScreen(
          entries: _scannedCards,
          defaultToListings: widget.defaultToListings,
        ),
      ),
    );

    if (!mounted) return;

    if (returnedEntries != null) {
      // User tapped "Scan+" — resume scanning with existing cards
      setState(() {
        _scannedCards.clear();
        _scannedCards.addAll(returnedEntries);
      });
      _prevLuminance = null;
      _lastCardPresentProb = 0.0;
      _scanCycleId++;
      _setState(ScanState.waiting);
      _controller?.startImageStream(_onFrame);
      _scanPaused = false;
    } else {
      // User finished or cancelled — close scanner
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ALT: `if (_controller == null || !_controller!.value.isInitialized) return;`
    // Bug — wenn die initiale Camera-Init fehlschlug (z.B. Permission denied),
    // war das Guard immer true und Re-Init nach Settings-Grant + Resume nie
    // moeglich. User musste die App komplett neustarten.
    if (state == AppLifecycleState.inactive) {
      // Nur disposen wenn aktiv — sonst war eh nix zu releasen.
      if (_controller != null && _controller!.value.isInitialized) {
        _controller?.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-Init in zwei Faellen: (a) wir waren initialisiert und disposed
      // wegen App in Background, (b) wir waren in Error-State und User
      // koennte zwischenzeitlich Permission gewaehrt haben.
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settlingTimer?.cancel();
    _waitingHintTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════
  // ── UI ──
  // ══════════════════════════════════════════════

  Color get _frameColor => switch (_state) {
    ScanState.waiting => Colors.white.withValues(alpha: 0.4),
    ScanState.stable => AppColors.win.withValues(alpha: 0.6),
    ScanState.motion => AppColors.amber400,
    ScanState.settling => Colors.blue.withValues(alpha: 0.6),
    ScanState.scanning => AppColors.amber400,
  };

  double get _frameWidth => switch (_state) {
    ScanState.stable => 2.5,
    ScanState.scanning => 3,
    _ => 1.5,
  };

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW * 0.65;
    final cardH = cardW * 7 / 5;

    // Error-State hat eigenen UI-Pfad ohne Stack-Overlays — kein Camera-
    // Frame, kein Top-Bar, nur Error-Screen + Close-Button.
    if (_initError != null) {
      return _buildErrorScaffold();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _tapToRescan,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            )
          else
            Center(child: CircularProgressIndicator(color: AppColors.amber400)),

          // Card frame guide
          if (_isInitialized)
            Center(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cardW, height: cardH,
                  decoration: BoxDecoration(
                    border: Border.all(color: _frameColor, width: _frameWidth),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_scannedCards.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: Text('Discard scans?', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                          content: Text('${_scannedCards.length} scanned card${_scannedCards.length > 1 ? 's' : ''} will be lost.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: Text('Discard', style: AppTextStyles.body.copyWith(color: AppColors.loss)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.close, color: AppColors.textPrimary, size: 28),
                  ),
                  Text('SCAN',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary, letterSpacing: 2)),
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? AppColors.amber400 : AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap to rescan hint (only in STABLE state, and not while
          // _acceptMatch is still running its variant-resolution chain
          // — the spinner already conveys "working on it").
          if (_state == ScanState.stable && _scannedCards.isNotEmpty && !_identifying)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              left: 0, right: 0,
              child: Center(
                child: Text('Tap to scan again',
                  style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
              ),
            ),

          // "Identifying card..." spinner during _acceptMatch's async
          // variant-resolution. Subtle pill at the same vertical position
          // as the tap-to-rescan hint, to avoid layout shift when it
          // disappears and the rescan hint takes its place.
          if (_identifying)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.amber400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Identifying...',
                        style: AppTextStyles.small.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // WAITING hint after 8s of no auto-detection. Tells the user they
          // can manually force a scan attempt by tapping the camera preview —
          // covers low-light scenarios and devices where the Card-Present
          // classifier underestimates (iPhone 13 mini-class issue, BACKLOG #86).
          if (_showWaitingHint && _state == ScanState.waiting)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              left: AppSpacing.md, right: AppSpacing.md,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                  ),
                  child: Text(
                    'Hold card in frame — or tap to scan now',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),

          // Training frame buttons (debug only — admin)
          if (_debugMode && _isAdmin)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Export button
                  GestureDetector(
                    onTap: () async {
                      final count = await _trainingFrames.frameCount();
                      if (!mounted) return;
                      if (count.total == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No training frames collected yet')),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exporting ${count.total} frames (${count.positive}pos ${count.negative}neg ${count.rects}rects)...')),
                      );
                      await _trainingFrames.exportFrames();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_upload_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('Frames', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear all training frames button
                  GestureDetector(
                    onTap: () async {
                      await _trainingFrames.clearAll();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cleared'), duration: Duration(milliseconds: 400)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('CLR', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Manual POS button (left side, centered vertically — admin only)
          if (_debugMode && _isAdmin)
            Positioned(
              left: 8,
              top: MediaQuery.of(context).size.height * 0.45,
              child: GestureDetector(
                onTap: () {
                  if (_lastYPlane == null) return;
                  _trainingFrames.saveManualFrame(
                    _lastYPlane!, _lastYWidth, _lastYHeight, _lastYStride,
                    isPositive: true,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('POS saved'), duration: Duration(milliseconds: 400)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      Text('POS', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          // Manual NEG button (right side, centered vertically — admin only)
          if (_debugMode && _isAdmin)
            Positioned(
              right: 8,
              top: MediaQuery.of(context).size.height * 0.45,
              child: GestureDetector(
                onTap: () {
                  if (_lastYPlane == null) return;
                  _trainingFrames.saveManualFrame(
                    _lastYPlane!, _lastYWidth, _lastYHeight, _lastYStride,
                    isPositive: false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('NEG saved'), duration: Duration(milliseconds: 400)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      Text('NEG', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          // Debug overlay — admin only (Beta-Tester sehen es nicht)
          if (_debugMode && _isAdmin && _isInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: AppSpacing.sm,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (_state) {
                              ScanState.waiting => Colors.grey,
                              ScanState.stable => Colors.green,
                              ScanState.motion => Colors.orange,
                              ScanState.settling => Colors.blue,
                              ScanState.scanning => AppColors.amber400,
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_state.name.toUpperCase()}  Motion: ${_motionPercent.toStringAsFixed(1)}%',
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontFamily: "monospace"),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        'OCR: $_debugOcr',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontFamily: "monospace"),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (_debugScore > 0)
                        Text(
                          'Score: $_debugScore  F:$_debugScanFrame  $_debugBreakdown',
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontFamily: "monospace"),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        'Cards: ${_scannedCards.fold<int>(0, (t, e) => t + e.quantity)}  '
                        'FPS: ${_fps.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontFamily: "monospace"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom bar: thumbnails + finish button
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                left: AppSpacing.md, right: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scannedCards.isNotEmpty)
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        itemCount: _scannedCards.length,
                        itemBuilder: (context, index) {
                          final entry = _scannedCards[_scannedCards.length - 1 - index];
                          return GestureDetector(
                            onTap: () => _showCardEditor(entry),
                            child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Stack(children: [
                              // Wrap thumbnail in a colored Container that
                              // acts as a confidence-frame. Border colors:
                              //   high   → transparent (no border, default look)
                              //   medium → amber (= "verify before adding")
                              //   low    → red (= "probably wrong, check")
                              // Border is 2px so the thumbnail stays readable.
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                                  border: Border.all(
                                    color: switch (entry.confidence) {
                                      ScanConfidence.high => Colors.transparent,
                                      ScanConfidence.medium => AppColors.amber400,
                                      ScanConfidence.low => AppColors.loss,
                                    },
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.rounded - 2),
                                  child: entry.card.type?.toLowerCase() == 'battlefield'
                                      ? SizedBox(
                                          width: 48, height: 67,
                                          child: RotatedBox(
                                            quarterTurns: 1,
                                            child: CardImage(
                                              imageUrl: entry.card.imageUrl,
                                              fallbackText: entry.card.name,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : CardImage(
                                          imageUrl: entry.card.imageUrl,
                                          fallbackText: entry.card.name,
                                          width: 48, height: 67, fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              if (entry.quantity > 1)
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber500,
                                      borderRadius: BorderRadius.circular(AppRadius.rounded),
                                    ),
                                    child: Text('×${entry.quantity}',
                                      style: AppTextStyles.micro.copyWith(
                                        color: AppColors.textOnPrimary, fontWeight: FontWeight.w800,
                                      )),
                                  ),
                                ),
                            ]),
                          ));
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_scannedCards.fold<int>(0, (t, e) => t + e.quantity)} scanned',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.amber400),
                      ),
                      GestureDetector(
                        onTap: _finishScanning,
                        child: SizedBox(
                          height: 48, // M3 button minimum
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.amber500,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_scannedCards.isEmpty ? 'Close' : 'Overview',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.background)),
                              if (_scannedCards.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 18, color: AppColors.background),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _fps {
    final elapsed = DateTime.now().difference(_fpsStart).inMilliseconds;
    if (elapsed <= 0) return 0;
    return _processedFrames / (elapsed / 1000);
  }

  // ══════════════════════════════════════════════
  // ── Error UI ──
  // ══════════════════════════════════════════════

  /// Error-Screen wenn Camera-Init fehlschlug. 3 Pfade:
  ///   1. permissionDenied → grosser Hinweis + „App-Einstellungen" Button.
  ///      Wenn der User dort die Permission gewaehrt und zur App zurueck-
  ///      kehrt, triggert `didChangeAppLifecycleState(resumed)` automatisch
  ///      einen Re-Init.
  ///   2. noCamera → Geraet hat gar keine Kamera (sehr selten, vermutlich
  ///      Simulator). Nur Close-Button.
  ///   3. other → unbekannter Fehler. Retry-Button bietet manuellen Re-Init.
  Widget _buildErrorScaffold() {
    final err = _initError!;
    final isPermission = err == _CameraInitError.permissionDenied;
    final title = switch (err) {
      _CameraInitError.permissionDenied => 'Camera access required',
      _CameraInitError.noCamera => 'No camera detected',
      _CameraInitError.other => 'Camera unavailable',
    };
    final body = switch (err) {
      _CameraInitError.permissionDenied =>
          'Riftr needs camera access to scan cards. '
              'Tap below to open Settings, enable Camera, then come back.',
      _CameraInitError.noCamera =>
          'This device doesn\'t expose a camera the scanner can use.',
      _CameraInitError.other =>
          'Something went wrong starting the camera. '
              'Try again or restart the app.',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button — top-left, mirrors the in-scanner top-bar Close.
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.amberMuted,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.amberBorderMuted),
                      ),
                      child: Icon(
                        isPermission
                            ? Icons.no_photography_outlined
                            : Icons.camera_alt_outlined,
                        color: AppColors.amber400,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (isPermission)
                      RiftrButton(
                        label: 'Open Settings',
                        onPressed: _openAppSettings,
                        fullWidth: false,
                      ),
                    if (err != _CameraInitError.noCamera) ...[
                      if (isPermission) const SizedBox(height: AppSpacing.sm),
                      RiftrButton(
                        label: 'Try again',
                        style: isPermission
                            ? RiftrButtonStyle.secondary
                            : RiftrButtonStyle.primary,
                        onPressed: _initCamera,
                        fullWidth: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Oeffnet die OS-Einstellungs-Seite fuer diese App. iOS: `app-settings:`
  /// landet direkt auf der Riftr-App-Settings (mit Camera-Toggle). Android:
  /// `package:` URI mit externalApplication mode oeffnet Apps-Settings (etwas
  /// indirekter — User muss dort „Permissions" antippen).
  Future<void> _openAppSettings() async {
    HapticFeedback.lightImpact();
    Uri? uri;
    if (Platform.isIOS) {
      uri = Uri.parse('app-settings:');
    } else if (Platform.isAndroid) {
      // Use package URI; the launcher resolves it to the app's settings page.
      // Need package id — read from somewhere. Default fallback.
      // url_launcher accepts the generic intent for opening app settings.
      uri = Uri.parse('package:com.riftr.app');
    }
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Differenzierte Camera-Init-Fehler. Steuert welche Buttons + Texts der
/// Error-Screen zeigt.
enum _CameraInitError {
  /// User hat Camera-Zugriff verweigert (oder MDM-/Restricted-Mode).
  /// → "Open Settings"-Button ist sinnvoll.
  permissionDenied,

  /// `availableCameras()` lieferte leere Liste (Simulator, ungewoehnliche Devices).
  /// → Kein Action-Button, nur Hinweis.
  noCamera,

  /// Anderer CameraException oder unbekannter Fehler.
  /// → Retry-Button.
  other,
}

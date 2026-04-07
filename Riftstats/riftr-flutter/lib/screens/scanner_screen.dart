import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';
import '../models/card_fingerprint.dart';
import '../services/ocr_service.dart';
import '../services/card_lookup_service.dart';
import '../services/phash_service.dart';
import '../services/native_rect_service.dart';
import '../services/promo_classifier_service.dart';
import '../services/set_classifier_service.dart';
import '../services/training_frame_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import 'scan_results_screen.dart';

/// Scanned card entry with metadata.
class ScannedCardEntry {
  final RiftCard card;
  final List<RiftCard> alternatives;
  int quantity;

  ScannedCardEntry({required this.card, this.alternatives = const [], this.quantity = 1});
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
  static const _debugMode = true;

  // ── Camera ──
  CameraController? _controller;
  bool _isInitialized = false;
  bool _torchOn = false;

  // ── State machine ──
  ScanState _state = ScanState.waiting;
  final List<ScannedCardEntry> _scannedCards = [];
  final _ocr = OcrService.instance;
  final _lookup = CardLookupService.instance;
  String? _lastMatchedCardId;
  OcrMatch? _waitingMatch; // WAITING match with variants → deferred to SCANNING

  // ── pHash variant detection ──
  final _phash = PhashService.instance;
  final _promoClassifier = PromoClassifierService.instance;
  final _setClassifier = SetClassifierService.instance;
  final _trainingFrames = TrainingFrameService.instance;
  Uint8List? _lastYPlane;  // updated every frame (for motion detection)
  int _lastYWidth = 0;
  int _lastYHeight = 0;
  int _lastYStride = 0;
  final List<Future<PhashComputeResult>> _phashFrames = []; // collected during SCANNING
  final List<List<int>> _nativeRects = []; // native rect samples during SCANNING

  // ── Motion detection ──
  Uint8List? _prevLuminance;
  double _motionPercent = 0;
  static const _motionThreshold = 18.0;
  static const _stableThreshold = 8.0; // hand-held: 3-8% trembling is normal, not movement
  static const _rectMotionLimit = 10.0; // collect native rects during hand trembles (card still visible)
  Timer? _settlingTimer;

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
    OcrService.instance.debugMode = true; // ON for mana debug
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

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
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Scanner: Camera error: $e');
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
    if (_processedFrames == 0) debugPrint('Scanner: First processed frame');

    _processedFrames++;

    // Extract luminance plane (Y channel, first plane)
    final luma = image.planes.first.bytes;
    final width = image.width;
    final height = image.height;

    // Keep raw Y-plane reference for pHash (stride-stripped on demand in _acceptMatch)
    _lastYPlane = Uint8List.fromList(luma);
    _lastYWidth = width;
    _lastYHeight = height;
    _lastYStride = image.planes.first.bytesPerRow;

    // ── Collect native rects every frame (full frame, no crop) ──
    // Collect when not in active movement (MOTION > 10%)
    final canCollect = _state != ScanState.motion || _motionPercent < _rectMotionLimit;
    if (_nativeRects.length < 30 && canCollect) {
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
        // First scan attempt — try flip for upside-down cards
        _runOcr(image, tryFlip: true);

      case ScanState.stable:
        // Card already scanned, waiting for motion
        if (_motionPercent > _motionThreshold) {
          _setState(ScanState.motion);
        }

      case ScanState.motion:
        // Movement detected, wait for it to stop
        if (_motionPercent < _stableThreshold) {
          _setState(ScanState.settling);
          _settlingTimer?.cancel();
          _settlingTimer = Timer(const Duration(milliseconds: 300), () {
            if (_state == ScanState.settling && mounted) {
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
      // Only one pHash frame for WAITING (first processed frame)
      // TODO: Re-enable after OCR performance verified
      if (false && _phashFrames.isEmpty && _lastYPlane != null && _phash.isReady) {
        Uint8List ySnap;
        if (_lastYStride == _lastYWidth) {
          ySnap = Uint8List.fromList(_lastYPlane!);
        } else {
          ySnap = Uint8List(_lastYWidth * _lastYHeight);
          for (int row = 0; row < _lastYHeight; row++) {
            ySnap.setRange(row * _lastYWidth, row * _lastYWidth + _lastYWidth,
                _lastYPlane!, row * _lastYStride);
          }
        }
        final cardW = (_lastYWidth * 0.65).round();
        final cardH = (cardW * 7 / 5).round();
        final cardX = (_lastYWidth - cardW) ~/ 2;
        final cardY = (_lastYHeight - cardH) ~/ 2;
        _phashFrames.add(compute(computePhashIsolate, PhashPayload(
          yPlane: ySnap, width: _lastYWidth, height: _lastYHeight,
          cardRect: [cardX, cardY, cardW, cardH], debug: _debugMode,
        )));
      }
      _ocr.processImage(image, _controller!.description, tryFlip: tryFlip).then((match) {
        if (match == null || !mounted) return;
        _updateDebug(match);

        // Name required: reject matches without card name recognized
        final hasName = match.breakdown.containsKey('name') ||
            match.breakdown.containsKey('name_fuzzy');
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

    // SCANNING state: extract only (no scoring per frame), accumulate
    // Every 2nd scanning frame: also try 90° rotation for landscape battlefields
    final tryRotate = _scanFrameCount % 2 == 0;
    final cycleAtStart = _scanCycleId;
    _ocr.extractFrame(image, _controller!.description, tryRotate90: tryRotate).then((extraction) async {
      if (!mounted || _state != ScanState.scanning || _scanCycleId != cycleAtStart) return;

      _scanFrameCount++;
      _debugScanFrame = _scanFrameCount;

      // Native rect collection now runs in _onFrame for all states (line ~172).

      // Launch pHash compute for this frame in background isolate
      // TODO: Re-enable after OCR performance verified
      if (false && _lastYPlane != null && _phash.isReady && _phashFrames.length < _maxScanFrames) {
        // Strip stride and snapshot Y-plane
        Uint8List ySnap;
        if (_lastYStride == _lastYWidth) {
          ySnap = Uint8List.fromList(_lastYPlane!);
        } else {
          ySnap = Uint8List(_lastYWidth * _lastYHeight);
          for (int row = 0; row < _lastYHeight; row++) {
            ySnap.setRange(
              row * _lastYWidth, row * _lastYWidth + _lastYWidth,
              _lastYPlane!, row * _lastYStride,
            );
          }
        }
        final cardW = (_lastYWidth * 0.65).round();
        final cardH = (cardW * 7 / 5).round();
        final cardX = (_lastYWidth - cardW) ~/ 2;
        final cardY = (_lastYHeight - cardH) ~/ 2;
        _phashFrames.add(compute(computePhashIsolate, PhashPayload(
          yPlane: ySnap,
          width: _lastYWidth,
          height: _lastYHeight,
          cardRect: [cardX, cardY, cardW, cardH],
          debug: _debugMode, // save debug image for every frame
        )));
      }

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
        if (!_gridAnchors.containsKey('mana') &&
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
      if (!mounted || _state != ScanState.scanning || _scanCycleId != cycleAtStart) return;

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

      // Name required for early-exit too
      final earlyHasName = matches.isNotEmpty &&
          (matches.first.breakdown.containsKey('name') ||
           matches.first.breakdown.containsKey('name_fuzzy'));
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
        // Name required: no match without the card name being recognized
        final hasName = matches.isNotEmpty &&
            (matches.first.breakdown.containsKey('name') ||
             matches.first.breakdown.containsKey('name_fuzzy'));
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
          // Collect negative training frame (scan timeout)
          if (_lastYPlane != null) {
            _trainingFrames.saveNegativeFrame(
              _lastYPlane!, _lastYWidth, _lastYHeight, _lastYStride,
            );
          }
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
    _setState(ScanState.stable);
    _lastMatchedCardId = match.card.id;
    HapticFeedback.mediumImpact();

    var resolvedCard = match.card;

    final nameLower = match.card.name.toLowerCase();
    final variantFps = _lookup.nameIndex[nameLower] ?? [];
    final allVariants = variantFps.map((fp) => fp.card).toList();

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
    if (allVariants.length > 1 && _cumCNSuffix != null && _cumCN != null) {
      for (final fp in variantFps) {
        if (fp.cnSuffix == _cumCNSuffix && fp.collectorNumber == _cumCN) {
          resolvedCard = fp.card;
          if (_debugMode) {
            debugPrint('Variant resolved by CN suffix: '
                '${resolvedCard.setId}#${resolvedCard.collectorNumber} (suffix=$_cumCNSuffix)');
          }
          final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
          _addCard(resolvedCard, resolvedAlts);
          return;
        }
      }
    }

    // Badge OCR promo detection — if "PROMO" was read on the badge, pick promo variant
    if (allVariants.length > 1 && _cumPromoDetected) {
      final promoVariant = allVariants.where((c) => c.isPromo).toList();
      if (promoVariant.isNotEmpty) {
        resolvedCard = promoVariant.first;
        if (_debugMode) {
          debugPrint('Variant resolved by badge OCR: '
              '${resolvedCard.setId}#${resolvedCard.collectorNumber} (PROMO detected)');
        }
        final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
        _addCard(resolvedCard, resolvedAlts);
        return;
      }
    }

    // pHash variant detection (fallback when no suffix and no badge OCR)
    if (allVariants.length > 1 && _phash.isReady && _lastYPlane != null) {
      try {
        final variantIds = allVariants.map((c) => c.id).toList();
        final promoIds = allVariants.where((c) => c.isPromo).map((c) => c.id).toSet();

        // Card rect: 4-step fallback chain
        List<int>? cardRect;
        String rectMethod = '';

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

        if (_debugMode) debugPrint('pHash: rect via $rectMethod → (${cardRect[0]},${cardRect[1]}) ${cardRect[2]}x${cardRect[3]}');

        // Log ALL native rects for debugging
        if (_debugMode && _nativeRects.isNotEmpty) {
          debugPrint('pHash: ${_nativeRects.length} native rects collected:');
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

        {
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

        // Single pHash compute with OCR-anchored card rect
        // debug=true to always get card pixels (needed for badge detection)
        final computeResult = await compute(computePhashIsolate, PhashPayload(
          yPlane: yPlane,
          width: _lastYWidth,
          height: _lastYHeight,
          cardRect: cardRect,
          debug: true,
        ));

        // Save debug images: card crop + full frame with rect overlay
        if (_debugMode) {
          if (computeResult.debugFullPixels != null) {
            _saveDebugCrops(computeResult, match.card.name);
          }
          _saveFullFrameDebug(match.card.name, cardRect);
        }

        // Save full-res card crop for training (set/suffix/promo models)
        if (computeResult.debugFullPixels != null) {
          _trainingFrames.savePositiveFrame(
            _lastYPlane!, _lastYWidth, _lastYHeight, _lastYStride,
            match.card.name,
            cardCrop: computeResult.debugFullPixels!,
            cardCropW: computeResult.debugFullW,
            cardCropH: computeResult.debugFullH,
          );
        }

        // ── TFLite Set Code Classifier ──
        // Overrides OCR-detected set code with CNN classification
        if (computeResult.debugFullPixels != null && _setClassifier.isReady) {
          final setResult = _setClassifier.classify(
            computeResult.debugFullPixels!,
            computeResult.debugFullW,
            computeResult.debugFullH,
          );
          if (setResult != null) {
            if (_debugMode) {
              debugPrint('TFLite set: ${setResult.setCode} '
                  '(conf=${setResult.confidence.toStringAsFixed(3)}, '
                  'OCR was: ${match.card.setId})');
            }
            // Override cumulative set code with CNN result for downstream matching.
            // This fixes OCR misreads like "SFO"→"SFD", "O6S"→"OGS".
            _cumSetCode = setResult.setCode;
          }
        }

        // ── TFLite Promo Badge Classifier ──
        // CNN-based detection: 48×48 grayscale crop → promo probability
        if (promoIds.isNotEmpty && computeResult.debugFullPixels != null && _promoClassifier.isReady) {
          final prob = _promoClassifier.classify(
            computeResult.debugFullPixels!,
            computeResult.debugFullW,
            computeResult.debugFullH,
          );
          if (prob != null) {
            final isPromoBadge = prob >= PromoClassifierService.promoThreshold;
            if (_debugMode) {
              debugPrint('TFLite badge: prob=${prob.toStringAsFixed(3)} '
                  '(thresh=${PromoClassifierService.promoThreshold} → ${isPromoBadge ? "PROMO" : "base"})');
            }
            if (isPromoBadge) {
              final promoVariant = allVariants.where((c) => c.isPromo).toList();
              if (promoVariant.isNotEmpty) {
                resolvedCard = promoVariant.first;
                if (_debugMode) {
                  debugPrint('TFLite badge: resolved to ${resolvedCard.setId}#${resolvedCard.collectorNumber}');
                }
                final resolvedAlts = allVariants.where((c) => c.id != resolvedCard.id).toList();
                _addCard(resolvedCard, resolvedAlts);
                return;
              }
            }
          }
        }

        // ── pHash variant detection (fallback) ──
        final result = _phash.findBestVariant(computeResult.hash, variantIds, promoIds: promoIds);

        if (result != null) {
          if (_debugMode) {
            debugPrint('pHash: ${allVariants.length} variants of "${match.card.name}", '
                'Stage ${result.stage} → ${result.reason}');
            for (final c in result.comparisons) {
              final card = allVariants.firstWhere((v) => v.id == c.cardId, orElse: () => match.card);
              final selected = c.cardId == result.bestId ? ' ✓' : '';
              final gemInfo = result.stage >= 2 || c.fullDist <= PhashService.fullHashThreshold
                  ? ' gem=${c.gemDist}' : '';
              debugPrint('  ${card.setId}#${card.collectorNumber}: full=${c.fullDist}$gemInfo$selected');
            }
          }

          final r = result!;
          if (r.bestId != null && r.bestId != match.card.id) {
            final bestCard = allVariants.firstWhere((c) => c.id == r.bestId, orElse: () => match.card);
            resolvedCard = bestCard;
          }
        }
        } // end rect block
      } catch (e) {
        debugPrint('pHash: Error: $e');
      }
    }

    // Build alternatives list
    final resolvedAlts = allVariants
        .where((c) => c.id != resolvedCard.id)
        .toList();

    _addCard(resolvedCard, resolvedAlts);
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

      if (_debugMode) {
        debugPrint('Badge crop OCR: no promo in "$text" at ($badgeX,$badgeY) ${badgeW}x$badgeH');
      }
    } catch (e) {
      if (_debugMode) debugPrint('Badge crop OCR error: $e');
    }
  }

  // ══════════════════════════════════════════════
  // ── Mana crop OCR: targeted read of the mana region ──
  // ══════════════════════════════════════════════

  /// Crop the mana region from the Y-plane and run OCR on just that area.
  /// Uses the Grid (type+cn) to calculate where mana should be.
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

    // Crop Y-plane and convert to BGRA
    final bgra = Uint8List(manaW * manaH * 4);
    for (int y = 0; y < manaH; y++) {
      for (int x = 0; x < manaW; x++) {
        final srcIdx = (manaY + y) * _lastYStride + (manaX + x);
        final v = srcIdx < _lastYPlane!.length ? _lastYPlane![srcIdx] : 0;
        final idx = (y * manaW + x) * 4;
        bgra[idx] = v; bgra[idx + 1] = v; bgra[idx + 2] = v; bgra[idx + 3] = 255;
      }
    }

    try {
      final recognized = await _ocr.recognizeCrop(bgra, manaW, manaH);
      if (recognized == null || recognized.blocks.isEmpty) return;

      for (final block in recognized.blocks) {
        final trimmed = block.text.trim();
        if (trimmed.length <= 2 && RegExp(r'^\d{1,2}$').hasMatch(trimmed)) {
          final manaCost = int.tryParse(trimmed);
          if (manaCost != null) {
            _cumMana ??= manaCost;
            // Create mana anchor in ORIGINAL frame coordinates
            final box = [
              manaX.toDouble(), manaY.toDouble(),
              (manaX + manaW).toDouble(), (manaY + manaH).toDouble(),
            ];
            final cx = (box[0] + box[2]) / 2;
            final cy = (box[1] + box[3]) / 2;
            _gridAnchors['mana'] = GridAnchor(
              label: 'mana',
              yPct: _gridManaYPct,
              xPct: _gridManaXPct,
              observedCX: cx,
              observedCY: cy,
              observedLeft: box[0],
            );
            if (_debugMode) {
              debugPrint('Mana crop OCR: found "$trimmed" at crop (${manaX},${manaY}) ${manaW}x${manaH}');
            }
            return;
          }
        }
      }

      if (_debugMode) {
        final text = recognized.blocks.map((b) => b.text).join(' | ');
        debugPrint('Mana crop OCR: no digit found in "$text" at (${manaX},${manaY}) ${manaW}x${manaH}');
      }
    } catch (e) {
      if (_debugMode) debugPrint('Mana crop OCR error: $e');
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

  /// Add card to scanned list or increment quantity.
  void _addCard(RiftCard card, List<RiftCard> alternatives) {
    final existingIndex = _scannedCards.indexWhere((e) => e.card.id == card.id);
    if (existingIndex >= 0) {
      setState(() => _scannedCards[existingIndex].quantity++);
    } else {
      setState(() {
        _scannedCards.add(ScannedCardEntry(card: card, alternatives: alternatives));
      });
    }
  }

  void _setState(ScanState newState) {
    if (_state == newState) return;
    debugPrint('Scanner: $_state → $newState (motion: ${_motionPercent.toStringAsFixed(1)}%)');
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
      _gridAnchors.clear();

      // Reset cumulative pHash frames for new scan cycle.
      // Native rects are NOT cleared — rects from SETTLING are valid
      // (card is already still). Only MOTION clears them (new card).
      _phashFrames.clear();
    }
    _state = newState;
  }

  /// Tap-to-rescan: force a new OCR pass in STABLE state.
  void _tapToRescan() {
    if (_state == ScanState.stable) {
      _setState(ScanState.scanning);
      // The next frame will trigger OCR
    }
  }

  void _toggleTorch() async {
    if (_controller == null) return;
    _torchOn = !_torchOn;
    await _controller!.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _finishScanning() {
    if (_scannedCards.isEmpty) {
      Navigator.pop(context);
      return;
    }
    _controller?.stopImageStream();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultsScreen(
          entries: _scannedCards,
          defaultToListings: widget.defaultToListings,
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settlingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════
  // ── UI ──
  // ══════════════════════════════════════════════

  Color get _frameColor => switch (_state) {
    ScanState.waiting => Colors.white.withValues(alpha: 0.4),
    ScanState.stable => AppColors.win.withValues(alpha: 0.6),
    ScanState.motion => AppColors.amber400.withValues(alpha: 0.6),
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
            const Center(child: CircularProgressIndicator(color: AppColors.amber400)),

          // Card frame guide
          if (_isInitialized)
            Center(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cardW, height: cardH,
                  decoration: BoxDecoration(
                    border: Border.all(color: _frameColor, width: _frameWidth),
                    borderRadius: BorderRadius.circular(12),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  Text('SCAN',
                    style: AppTextStyles.bodyBold.copyWith(color: Colors.white, letterSpacing: 2)),
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? AppColors.amber400 : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap to rescan hint (only in STABLE state)
          if (_state == ScanState.stable && _scannedCards.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              left: 0, right: 0,
              child: Center(
                child: Text('Tap to scan again',
                  style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
              ),
            ),

          // Training frame export button (debug only)
          if (_debugMode)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: 16,
              child: GestureDetector(
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
                    SnackBar(content: Text('Exporting ${count.total} frames (${count.positive} pos, ${count.negative} neg)...')),
                  );
                  await _trainingFrames.exportFrames();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_upload_outlined, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text('Frames', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),

          // Debug overlay
          if (_debugMode && _isInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: AppSpacing.sm,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
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
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        'OCR: $_debugOcr',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (_debugScore > 0)
                        Text(
                          'Score: $_debugScore  F:$_debugScanFrame  $_debugBreakdown',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        'Cards: ${_scannedCards.fold<int>(0, (t, e) => t + e.quantity)}  '
                        'FPS: ${_fps.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
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
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
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
                              if (entry.quantity > 1)
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber500,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('×${entry.quantity}',
                                      style: AppTextStyles.micro.copyWith(
                                        color: Colors.black, fontWeight: FontWeight.w800,
                                      )),
                                  ),
                                ),
                            ]),
                          );
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.amber500,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(_scannedCards.isEmpty ? 'Close' : 'Done',
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.background)),
                            if (_scannedCards.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18, color: AppColors.background),
                            ],
                          ]),
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
}

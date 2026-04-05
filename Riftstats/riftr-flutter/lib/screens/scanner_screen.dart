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
  static const _maxScanFrames = 10;
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
  List<double>? _cumNameBox;  // OCR-anchor: best name bounding box
  List<double>? _cumCnBox;    // OCR-anchor: best CN bounding box
  final StringBuffer _cumText = StringBuffer();

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
    OcrService.instance.debugMode = false; // OCR raw lines off (too noisy)
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

      NativeRectService.instance.detectCardRect(
        yPlane: stripped, width: width, height: height, bytesPerRow: width,
      ).then((rect) {
        if (rect != null) {
          _nativeRects.add(rect);
        }
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

        // Check if this card has multiple variants
        final nameLower = match.card.name.toLowerCase();
        final variantCount = (_lookup.nameIndex[nameLower] ?? []).length;

        if (variantCount > 1) {
          // Variants exist, confident match → enter SCANNING to collect
          // more OCR frames (for CN suffix) and native rects (for pHash).
          _waitingMatch = match;
          _setState(ScanState.scanning);
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
          // First-wins for scoring (so OCR scoring can use CN during accumulation)
          if (_cumCN == null) {
            _cumCN = extraction.collectorNumber;
            _cumCNSuffix = extraction.cnSuffix;
            _cumCNRaw = extraction.cnRaw;
          }
        }
        if (extraction.manaCost != null) _cumMana ??= extraction.manaCost;
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
            'names=$_cumNames kw=$_cumKeywords types=$_cumTypes');
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

      if (bestScore >= _earlyExitScore && matches.isNotEmpty) {
        final best = matches.first;
        final card = best.fingerprint.card;
        debugPrint('Scanner: Early-exit F$_scanFrameCount score=$bestScore');
        _acceptMatch(OcrMatch(card: card, confidence: ScanConfidence.high,
            score: best.score, breakdown: best.breakdown));
        return;
      }

      if (_scanFrameCount >= _maxScanFrames) {
        if (bestScore >= _minAcceptScore && matches.isNotEmpty) {
          final best = matches.first;
          final card = best.fingerprint.card;
          debugPrint('Scanner: Accept F$_scanFrameCount score=$bestScore');
          _acceptMatch(OcrMatch(card: card,
              confidence: bestScore >= 50 ? ScanConfidence.medium : ScanConfidence.low,
              score: best.score, breakdown: best.breakdown));
        } else {
          debugPrint('Scanner: No match after $_scanFrameCount frames (cumBest=$bestScore)');
          _debugOcr = 'no match (cum=$bestScore)';
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

    // pHash variant detection (fallback when no suffix available)
    if (allVariants.length > 1 && _phash.isReady && _lastYPlane != null) {
      try {
        final variantIds = allVariants.map((c) => c.id).toList();
        final promoIds = allVariants.where((c) => c.isPromo).map((c) => c.id).toSet();

        // Card rect: best calibrated native rect, or OCR-anchor fallback
        List<int>? cardRect;

        // 1. Best scored native rect
        final calibrated = _calibrateCardRect(match.card.type?.toLowerCase());
        if (calibrated != null) {
          cardRect = calibrated.rect;
        }

        // 2. OCR-anchor fallback (from name + CN text positions)
        if (cardRect == null && _cumNameBox != null && _cumCnBox != null) {
          final nameCY = (_cumNameBox![1] + _cumNameBox![3]) / 2;
          final cnCY = (_cumCnBox![1] + _cumCnBox![3]) / 2;
          final cnLeft = _cumCnBox![0];
          final dist = (cnCY - nameCY).abs();
          if (dist > 80) {
            double nameYPct = 0.58;
            final ct = match.card.type?.toLowerCase() ?? '';
            if (ct == 'legend') nameYPct = 0.62;
            else if (ct == 'rune') nameYPct = 0.72;
            if (ct != 'battlefield') {
              final cardH = dist / (0.97 - nameYPct);
              final cardW = cardH * 0.716;
              cardRect = [
                (cnLeft - cardW * 0.09).round().clamp(0, _lastYWidth - 1),
                (nameCY - nameYPct * cardH).round().clamp(0, _lastYHeight - 1),
                cardW.round().clamp(1, _lastYWidth),
                cardH.round().clamp(1, _lastYHeight),
              ];
              if (_debugMode) debugPrint('pHash OCR-anchor rect: (${cardRect[0]},${cardRect[1]}) ${cardRect[2]}x${cardRect[3]}');
            }
          }
        }

        if (cardRect == null && _debugMode) {
          debugPrint('pHash: no rect → skipping variant detection');
        }

        if (cardRect != null) {
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
        // debug=true to always get card pixels (needed for SAD template matching)
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

        var result = _phash.findBestVariant(computeResult.hash, variantIds, promoIds: promoIds);

        // Stage 2 (gem pHash): try SAD template matching for better accuracy
        if (result != null && result.stage == 2 && computeResult.debugFullPixels != null) {
          final sadResult = _phash.findBestVariantSAD(
            computeResult.debugFullPixels!,
            computeResult.debugFullW, computeResult.debugFullH,
            variantIds, promoIds: promoIds,
          );
          if (sadResult != null) {
            result = sadResult; // SAD overrides pHash gem result
          }
        }

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
        } // end if (cardRect != null)
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
  // ── Calibrated card rect: score + OCR cross-validation ──
  // ══════════════════════════════════════════════

  static const _idealRatio = 0.716; // card w/h = 63mm / 88mm
  static const _idealWidthPct = 0.48; // card fills ~48% of frame width (measured from debug images)

  /// Score native rects against ideal geometry, cross-validate with OCR anchors,
  /// and optionally calibrate for sub-pixel alignment.
  /// Returns null if no native rect scores above threshold.
  ({List<int> rect, double score, String method})? _calibrateCardRect(String? cardType) {
    if (_nativeRects.isEmpty) return null;

    final fw = _lastYWidth.toDouble();
    final fh = _lastYHeight.toDouble();
    if (fw <= 0 || fh <= 0) return null;

    final expectedW = fw * _idealWidthPct;
    final frameCX = fw / 2;
    final frameCY = fh / 2;

    // Layout profile
    double nameYPct = 0.58;
    const cnYPct = 0.97;
    final ct = cardType ?? '';
    if (ct == 'legend') nameYPct = 0.62;
    else if (ct == 'rune') nameYPct = 0.72;

    final hasOcr = _cumNameBox != null && _cumCnBox != null && ct != 'battlefield';
    final nameBox = _cumNameBox;
    final cnBox = _cumCnBox;
    double? nameCY, cnCY, cnLeft;
    if (hasOcr) {
      nameCY = (nameBox![1] + nameBox[3]) / 2;
      cnCY = (cnBox![1] + cnBox[3]) / 2;
      cnLeft = cnBox[0];
    }

    // Size filter: keep rects ≥50% of max area
    final areas = _nativeRects.map((r) => r[2] * r[3]).toList();
    final maxArea = areas.reduce((a, b) => a > b ? a : b);

    double bestScore = -1;
    List<int>? bestRect;
    int bestIdx = -1;

    for (int i = 0; i < _nativeRects.length; i++) {
      if (areas[i] < maxArea * 0.50) continue;

      final r = _nativeRects[i];
      final rx = r[0].toDouble(), ry = r[1].toDouble();
      final rw = r[2].toDouble(), rh = r[3].toDouble();
      if (rw <= 0 || rh <= 0) continue;

      // ── Geometry score ──
      final ratio = rw / rh;
      final ratioErr = (ratio - _idealRatio).abs() / _idealRatio;
      final ratioScore = (1.0 - ratioErr * 5.0).clamp(0.0, 1.0);

      final widthErr = (rw - expectedW).abs() / expectedW;
      final sizeScore = (1.0 - widthErr * 3.0).clamp(0.0, 1.0);

      final cx = rx + rw / 2, cy = ry + rh / 2;
      final dxNorm = (cx - frameCX).abs() / (fw * 0.15);
      final dyNorm = (cy - frameCY).abs() / (fh * 0.10);
      final dist = (dxNorm * dxNorm + dyNorm * dyNorm);
      final centerScore = (1.0 - (dist > 0 ? sqrt(dist) : 0.0)).clamp(0.0, 1.0);

      final geoScore = ratioScore * 0.35 + sizeScore * 0.30 + centerScore * 0.35;
      if (geoScore < 0.40) continue;

      // ── OCR cross-validation ──
      double totalScore;
      if (hasOcr) {
        final predNameY = ry + nameYPct * rh;
        final nameYErr = (nameCY! - predNameY).abs();
        final nameYScore = (1.0 - nameYErr / 30.0).clamp(0.0, 1.0);

        final predCnY = ry + cnYPct * rh;
        final cnYErr = (cnCY! - predCnY).abs();
        final cnYScore = (1.0 - cnYErr / 30.0).clamp(0.0, 1.0);

        final predCnLeft = rx + 0.09 * rw;
        final leftErr = (cnLeft! - predCnLeft).abs();
        final leftScore = (1.0 - leftErr / 40.0).clamp(0.0, 1.0);

        final ocrScore = nameYScore * 0.40 + cnYScore * 0.35 + leftScore * 0.25;
        totalScore = geoScore * 0.50 + ocrScore * 0.50;
      } else {
        totalScore = geoScore;
      }

      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestRect = r;
        bestIdx = i;
      }
    }

    if (bestRect == null || bestScore < 0.40) return null;

    // ── Calibration: nudge rect to align OCR landmarks ──
    var method = 'scored';
    var finalRect = bestRect;

    if (hasOcr && bestScore >= 0.40 && bestScore < 0.90) {
      var rx = bestRect[0].toDouble(), ry = bestRect[1].toDouble();
      var rw = bestRect[2].toDouble(), rh = bestRect[3].toDouble();

      // Y-shift: move top so name lands at expected position
      final predNameY = ry + nameYPct * rh;
      final yShift = (nameCY! - predNameY).clamp(-20.0, 20.0);

      // Height correction: adjust so name-CN span matches layout profile
      final observedSpan = cnCY! - nameCY;
      final expectedSpan = (cnYPct - nameYPct) * rh;
      if (expectedSpan > 0 && observedSpan > 0) {
        final spanRatio = (observedSpan / expectedSpan).clamp(0.90, 1.10);
        final calH = rh * spanRatio;
        final calW = calH * _idealRatio;
        final calTop = ry + yShift;

        // X-shift: align CN left edge
        final predCnLeft = rx + 0.09 * rw;
        final xShift = (cnLeft! - predCnLeft).clamp(-15.0, 15.0);
        final calLeft = rx + xShift;

        // Validate calibration improved alignment
        final origNameErr = (nameCY - predNameY).abs();
        final origCnErr = (cnCY - (ry + cnYPct * rh)).abs();
        final calNameErr = (nameCY - (calTop + nameYPct * calH)).abs();
        final calCnErr = (cnCY - (calTop + cnYPct * calH)).abs();

        if (calNameErr + calCnErr < origNameErr + origCnErr) {
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
          '[best of ${_nativeRects.length} rects, idx=$bestIdx]');
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

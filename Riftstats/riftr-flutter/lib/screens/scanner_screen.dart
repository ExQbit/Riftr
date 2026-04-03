import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../models/card_model.dart';
import '../models/card_fingerprint.dart';
import '../services/ocr_service.dart';
import '../services/card_lookup_service.dart';
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

  // ── Motion detection ──
  Uint8List? _prevLuminance;
  double _motionPercent = 0;
  static const _motionThreshold = 18.0;
  static const _stableThreshold = 2.0;
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
  int? _cumMana;
  final Set<String> _cumNames = {};
  final Set<String> _cumKeywords = {};
  final Set<String> _cumTypes = {};
  final Set<String> _cumRegions = {};
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
    OcrService.instance.debugMode = _debugMode;
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
        ResolutionPreset.high,
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

    _processedFrames++;

    // Extract luminance plane (Y channel, first plane)
    final luma = image.planes.first.bytes;
    final width = image.width;
    final height = image.height;

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
      _ocr.processImage(image, _controller!.description, tryFlip: tryFlip).then((match) {
        if (match == null || !mounted) return;
        _updateDebug(match);
        _acceptMatch(match);
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

      // Current frame text for fuzzyContains (NOT cumulated)
      final currentFrameText = extraction?.rawTextLower ?? '';

      // Merge this frame's extraction into cumulative
      if (extraction != null) {
        if (extraction.setCode != null) _cumSetCode = extraction.setCode;
        if (extraction.collectorNumber != null) {
          _cumCN = extraction.collectorNumber;
          _cumCNSuffix = extraction.cnSuffix;
          _cumCNRaw = extraction.cnRaw;
        }
        if (extraction.manaCost != null) _cumMana = extraction.manaCost;
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

      // Early-exit: high cumulative score
      if (bestScore >= _earlyExitScore && matches.isNotEmpty) {
        final best = matches.first;
        debugPrint('Scanner: Early-exit frame $_scanFrameCount score=$bestScore');
        _acceptMatch(OcrMatch(
          card: best.fingerprint.card,
          confidence: ScanConfidence.high,
          score: best.score,
          breakdown: best.breakdown,
        ));
        return;
      }

      // Max frames reached
      if (_scanFrameCount >= _maxScanFrames) {
        if (bestScore >= _minAcceptScore && matches.isNotEmpty) {
          final best = matches.first;
          debugPrint('Scanner: Accept after $_scanFrameCount frames cumScore=$bestScore');
          _acceptMatch(OcrMatch(
            card: best.fingerprint.card,
            confidence: bestScore >= 50 ? ScanConfidence.medium : ScanConfidence.low,
            score: best.score,
            breakdown: best.breakdown,
          ));
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

  void _acceptMatch(OcrMatch match) {
    _addCard(match.card, match.alternatives);
    _setState(ScanState.stable);
    _lastMatchedCardId = match.card.id;
    HapticFeedback.mediumImpact();
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
    // Reset cumulative extraction when entering SCANNING
    if (newState == ScanState.scanning) {
      _scanCycleId++;
      _scanFrameCount = 0;
      _cumSetCode = null;
      _cumCN = null;
      _cumCNSuffix = null;
      _cumCNRaw = null;
      _cumMana = null;
      _cumNames.clear();
      _cumKeywords.clear();
      _cumTypes.clear();
      _cumRegions.clear();
      _cumText.clear();
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

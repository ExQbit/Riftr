import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'scan_telemetry_service.dart';

/// TFLite-based card name classifier.
///
/// Identifies cards by their artwork region (top half of card).
/// Input: 96×96 grayscale artwork crop.
/// Output: card name + confidence.
///
/// ~816KB model, 736 classes, trained on all sets including UNL.
class CardNameClassifierService {
  CardNameClassifierService._();
  static final CardNameClassifierService instance = CardNameClassifierService._();

  Interpreter? _interpreter;
  List<String>? _classNames;
  bool get isReady => _interpreter != null && _classNames != null;
  int get numClasses => _classNames?.length ?? 0;

  // Artwork crop coordinates (fraction of card dimensions)
  static const _cropX = 0.05;
  static const _cropY = 0.05;
  static const _cropW = 0.90;
  static const _cropH = 0.45;
  static const _inputW = 96;
  static const _inputH = 96;

  /// Minimum confidence to trust the classification.
  static const confidenceThreshold = 0.40;

  /// Load the TFLite model and class mapping from assets.
  ///
  /// Tries platform-optimized delegates first (Core ML on iOS, NNAPI on
  /// Android), falls back to CPU on any failure. Failures are common on
  /// older devices, in iOS Simulator, on Mediatek SoCs with float16-quant
  /// bugs, etc. — so the fallback path is part of the design, not an
  /// emergency. Telemetry tracks which path was taken so we can see the
  /// real-world success rate across the beta-tester device fleet.
  Future<void> load() async {
    if (_interpreter != null && _classNames != null) return;

    // Load class names
    try {
      final jsonStr = await rootBundle.loadString('assets/card_name_classes.json');
      _classNames = List<String>.from(json.decode(jsonStr));
    } catch (e) {
      debugPrint('CardNameClassifier: failed to load classes: $e');
      return;
    }

    // ── Attempt 1: with platform delegate (Core ML / NNAPI / Metal-GPU) ──
    String? delegateUsed;
    try {
      final options = InterpreterOptions();
      if (Platform.isIOS) {
        // CoreMlDelegate uses Apple's Neural Engine on supported devices
        // (iPhone X+) and falls back to GPU on older models.
        options.addDelegate(CoreMlDelegate());
        delegateUsed = 'coreml';
      } else if (Platform.isAndroid) {
        // NNAPI requires Android 8.1+ (API 27); on older devices the
        // tflite layer falls back to CPU automatically.
        options.useNnApiForAndroid = true;
        delegateUsed = 'nnapi';
      }
      _interpreter = await Interpreter.fromAsset(
        'assets/card_name_classifier.tflite',
        options: options,
      );
      debugPrint('CardNameClassifier: loaded with delegate=$delegateUsed '
          '(${_classNames!.length} classes)');
      ScanTelemetryService.instance.recordDelegateInit(
        modelName: 'card_name',
        path: delegateUsed ?? 'cpu',
      );
      return;
    } catch (e) {
      debugPrint('CardNameClassifier: delegate=$delegateUsed init failed → CPU fallback: $e');
    }

    // ── Attempt 2: CPU-only (delegate failed or unsupported platform) ──
    try {
      _interpreter = await Interpreter.fromAsset('assets/card_name_classifier.tflite');
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/card_name_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/card_name_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('CardNameClassifier: CPU fallback also failed: $e');
        return;
      }
    }

    if (_interpreter != null && _classNames != null) {
      debugPrint('CardNameClassifier: loaded with CPU fallback '
          '(${_classNames!.length} classes)');
      ScanTelemetryService.instance.recordDelegateInit(
        modelName: 'card_name',
        path: 'cpu_fallback',
      );
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _classNames = null;
  }

  /// Classify the card name from a full card crop.
  ///
  /// [cardPixels] is grayscale pixel data (1 byte per pixel, row-major).
  /// [cardW] and [cardH] are the dimensions of the card crop.
  ///
  /// Returns the top prediction with name and confidence,
  /// or null if classifier not ready or confidence too low.
  ({String name, double confidence})? classify(
    Uint8List cardPixels, int cardW, int cardH,
  ) {
    if (_interpreter == null || _classNames == null) return null;

    // Extract artwork region
    final cropX = (_cropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_cropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_cropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_cropH * cardH).round().clamp(1, cardH - cropY);

    if (cropW < 8 || cropH < 8) return null;

    // Resize artwork to 96×96 using nearest-neighbor
    final resized = Float32List(_inputW * _inputH);
    for (int y = 0; y < _inputH; y++) {
      final srcY = cropY + (y * cropH ~/ _inputH);
      for (int x = 0; x < _inputW; x++) {
        final srcX = cropX + (x * cropW ~/ _inputW);
        final srcIdx = srcY * cardW + srcX;
        resized[y * _inputW + x] =
            srcIdx < cardPixels.length ? cardPixels[srcIdx] / 255.0 : 0.0;
      }
    }

    // Run inference: [1, 96, 96, 1] → [1, numClasses]
    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputH, _inputW, 1]);
    final output = List.filled(1, List.filled(_classNames!.length, 0.0));
    _interpreter!.run(inputTensor, output);

    // Find best class
    final probs = output[0];
    int bestIdx = 0;
    double bestProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestProb) {
        bestProb = probs[i];
        bestIdx = i;
      }
    }

    if (bestProb < confidenceThreshold) return null;

    return (name: _classNames![bestIdx], confidence: bestProb);
  }

  /// Get top-N predictions for debugging.
  List<({String name, double confidence})> classifyTopN(
    Uint8List cardPixels, int cardW, int cardH, {int n = 5}
  ) {
    if (_interpreter == null || _classNames == null) return [];

    final cropX = (_cropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_cropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_cropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_cropH * cardH).round().clamp(1, cardH - cropY);

    if (cropW < 8 || cropH < 8) return [];

    final resized = Float32List(_inputW * _inputH);
    for (int y = 0; y < _inputH; y++) {
      final srcY = cropY + (y * cropH ~/ _inputH);
      for (int x = 0; x < _inputW; x++) {
        final srcX = cropX + (x * cropW ~/ _inputW);
        final srcIdx = srcY * cardW + srcX;
        resized[y * _inputW + x] =
            srcIdx < cardPixels.length ? cardPixels[srcIdx] / 255.0 : 0.0;
      }
    }

    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputH, _inputW, 1]);
    final output = List.filled(1, List.filled(_classNames!.length, 0.0));
    _interpreter!.run(inputTensor, output);

    // Sort by probability descending
    final probs = output[0];
    final indices = List.generate(probs.length, (i) => i);
    indices.sort((a, b) => probs[b].compareTo(probs[a]));

    return indices.take(n).map((i) =>
      (name: _classNames![i], confidence: probs[i])
    ).toList();
  }
}

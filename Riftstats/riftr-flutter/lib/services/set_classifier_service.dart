import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based set code classifier.
///
/// Classifies the printed set code (OGN, SFD, OGS, UNL) from a crop
/// of the bottom-left region of the card where the set code is printed.
///
/// 33KB model, 4 classes, >99% accuracy on validation data.
class SetClassifierService {
  SetClassifierService._();
  static final SetClassifierService instance = SetClassifierService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  // Set code crop coordinates (fraction of card dimensions)
  // Bottom-left: captures "SFD", "OGN", "OGS", "UNL" text
  static const _cropX = 0.02;
  static const _cropY = 0.94;
  static const _cropW = 0.18;
  static const _cropH = 0.06;
  static const _inputW = 64;
  static const _inputH = 32;

  /// Class labels in order matching the training script.
  static const classes = ['OGN', 'SFD', 'OGS', 'UNL'];

  /// Minimum confidence to trust the classification.
  static const confidenceThreshold = 0.60;

  /// Load the TFLite model from assets.
  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/set_code_classifier.tflite');
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/set_code_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/set_code_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('SetClassifier: failed to load: $e');
        return;
      }
    }
    if (_interpreter != null) {
      debugPrint('SetClassifier: loaded (${classes.length} classes: ${classes.join(", ")})');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Classify the set code from a card crop.
  ///
  /// Returns the set code string (e.g., "SFD") and confidence,
  /// or null if classifier not ready or confidence too low.
  ({String setCode, double confidence})? classify(
    Uint8List cardPixels, int cardW, int cardH,
  ) {
    if (_interpreter == null) return null;

    // Extract set code region
    final cropX = (_cropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_cropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_cropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_cropH * cardH).round().clamp(1, cardH - cropY);

    if (cropW < 4 || cropH < 4) return null;

    // Resize to 64×32 using nearest-neighbor
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

    // Run inference: [1, 32, 64, 1] → [1, 4]
    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputH, _inputW, 1]);
    final output = List.filled(1, List.filled(classes.length, 0.0));
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

    return (setCode: classes[bestIdx], confidence: bestProb);
  }
}

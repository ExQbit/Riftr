import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based mana cost classifier.
///
/// Classifies the mana diamond (energy cost) from the top-left region
/// of a card crop. 12 classes: 0-10 and 12.
///
/// 33KB model, ~96% accuracy on validation data.
class ManaClassifierService {
  ManaClassifierService._();
  static final ManaClassifierService instance = ManaClassifierService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  // Mana crop coordinates (fraction of card dimensions)
  // Top-left diamond region — must match training script exactly.
  static const _cropX = 0.02;
  static const _cropY = 0.00;
  static const _cropW = 0.18;
  static const _cropH = 0.12;
  static const _inputSize = 48;

  /// Class labels in order matching the training script.
  static const classes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12];

  /// Minimum confidence to trust the classification.
  static const confidenceThreshold = 0.60;

  /// Load the TFLite model from assets.
  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/mana_classifier.tflite');
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/mana_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/mana_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('ManaClassifier: failed to load: $e');
        return;
      }
    }
    if (_interpreter != null) {
      debugPrint('ManaClassifier: loaded (${classes.length} classes: ${classes.join(", ")})');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Classify the mana cost from a card crop.
  ///
  /// [cardPixels] is the grayscale Y-plane of the card crop.
  /// [cardW], [cardH] are the card crop dimensions.
  ///
  /// Returns the mana value and confidence, or null if not ready / low confidence.
  ({int mana, double confidence})? classify(
    Uint8List cardPixels, int cardW, int cardH,
  ) {
    if (_interpreter == null) return null;

    // Extract mana diamond region
    final cropX = (_cropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_cropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_cropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_cropH * cardH).round().clamp(1, cardH - cropY);

    if (cropW < 4 || cropH < 4) return null;

    // Resize to 48×48 using nearest-neighbor
    final resized = Float32List(_inputSize * _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      final srcY = cropY + (y * cropH ~/ _inputSize);
      for (int x = 0; x < _inputSize; x++) {
        final srcX = cropX + (x * cropW ~/ _inputSize);
        final srcIdx = srcY * cardW + srcX;
        resized[y * _inputSize + x] =
            srcIdx < cardPixels.length ? cardPixels[srcIdx] / 255.0 : 0.0;
      }
    }

    // Run inference: [1, 48, 48, 1] → [1, 12]
    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputSize, _inputSize, 1]);
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

    return (mana: classes[bestIdx], confidence: bestProb);
  }
}

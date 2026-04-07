import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based CN suffix classifier.
///
/// Classifies whether a card's collector number has a suffix (a, b, *)
/// from a crop of the CN area at the bottom of the card.
///
/// 33KB model, 4 classes, ~97% accuracy on validation data.
class SuffixClassifierService {
  SuffixClassifierService._();
  static final SuffixClassifierService instance = SuffixClassifierService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  // CN area crop (fraction of card) — after set code, bottom of card
  static const _cropX = 0.15;
  static const _cropY = 0.94;
  static const _cropW = 0.35;
  static const _cropH = 0.06;
  static const _inputW = 96;
  static const _inputH = 32;

  static const classes = ['none', 'a', 'b', '*'];
  static const confidenceThreshold = 0.60;

  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/suffix_classifier.tflite');
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/suffix_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/suffix_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('SuffixClassifier: failed to load: $e');
        return;
      }
    }
    if (_interpreter != null) {
      debugPrint('SuffixClassifier: loaded (${classes.length} classes)');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Classify the CN suffix from a card crop.
  /// Returns the suffix string ("none", "a", "b", "*") and confidence,
  /// or null if not ready or low confidence.
  ({String suffix, double confidence})? classify(
    Uint8List cardPixels, int cardW, int cardH,
  ) {
    if (_interpreter == null) return null;

    final cropX = (_cropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_cropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_cropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_cropH * cardH).round().clamp(1, cardH - cropY);
    if (cropW < 4 || cropH < 4) return null;

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

    final input = resized.buffer.asFloat32List().reshape([1, _inputH, _inputW, 1]);
    final output = List.filled(1, List.filled(classes.length, 0.0));
    _interpreter!.run(input, output);

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
    return (suffix: classes[bestIdx], confidence: bestProb);
  }
}

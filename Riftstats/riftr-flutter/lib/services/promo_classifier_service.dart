import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based promo badge classifier.
///
/// Uses a tiny CNN (14K params, 33KB) to detect the PROMO badge on cards.
/// Input: 48×48 grayscale crop of the badge region from the card.
/// Output: promo probability (0.0 = base, 1.0 = promo).
///
/// The model was trained on augmented reference images with simulated
/// camera conditions (blur, noise, brightness jitter, downscale artifacts).
class PromoClassifierService {
  PromoClassifierService._();
  static final PromoClassifierService instance = PromoClassifierService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  // Badge crop coordinates (fraction of card dimensions)
  // Must match the training script's BADGE_X/Y/W/H exactly.
  static const _badgeCropX = 0.38;
  static const _badgeCropY = 0.88;
  static const _badgeCropW = 0.24;
  static const _badgeCropH = 0.10;
  static const _inputSize = 48;

  /// Promo threshold: probability >= this = promo.
  /// High threshold to minimize false positives (better to miss a promo
  /// than to falsely label a base card as promo).
  /// Camera Y-plane images have lower confidence than clean references.
  /// Reference validation: promo mean=0.979, base mean=0.002.
  /// Camera reality: promo ~0.25-0.47, base ~0.00.
  /// Threshold 0.15 separates cleanly while leaving margin.
  static const promoThreshold = 0.15;

  /// Load the TFLite model from assets.
  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      // Try fromAsset first (standard tflite_flutter approach)
      _interpreter = await Interpreter.fromAsset('assets/promo_badge_classifier.tflite');
    } catch (_) {
      try {
        // Fallback: copy asset to temp file and load from there
        final data = await rootBundle.load('assets/promo_badge_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/promo_badge_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('PromoClassifier: failed to load: $e');
        return;
      }
    }
    if (_interpreter != null) {
      debugPrint('PromoClassifier: loaded (input=${_interpreter!.getInputTensor(0).shape})');
    }
  }

  /// Dispose the interpreter.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Classify whether the card has a promo badge.
  ///
  /// [cardPixels] is grayscale Y-plane of the card crop (same as pHash debugFullPixels).
  /// [cardW], [cardH] are the card crop dimensions.
  ///
  /// Returns promo probability [0.0, 1.0], or null if classifier not ready.
  double? classify(Uint8List cardPixels, int cardW, int cardH) {
    if (_interpreter == null) return null;

    // 1. Extract badge region from card crop
    final cropX = (_badgeCropX * cardW).round().clamp(0, cardW - 1);
    final cropY = (_badgeCropY * cardH).round().clamp(0, cardH - 1);
    final cropW = (_badgeCropW * cardW).round().clamp(1, cardW - cropX);
    final cropH = (_badgeCropH * cardH).round().clamp(1, cardH - cropY);

    if (cropW < 4 || cropH < 4) return null;

    // 2. Resize to 48×48 using nearest-neighbor sampling
    final resized = Float32List(_inputSize * _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      final srcY = cropY + (y * cropH ~/ _inputSize);
      for (int x = 0; x < _inputSize; x++) {
        final srcX = cropX + (x * cropW ~/ _inputSize);
        final srcIdx = srcY * cardW + srcX;
        // Normalize to [0.0, 1.0]
        resized[y * _inputSize + x] =
            srcIdx < cardPixels.length ? cardPixels[srcIdx] / 255.0 : 0.0;
      }
    }

    // 3. Reshape to [1, 48, 48, 1] for the model
    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputSize, _inputSize, 1]);

    // 4. Run inference
    final output = List.filled(1, List.filled(1, 0.0));
    _interpreter!.run(inputTensor, output);

    return output[0][0];
  }

  /// Convenience: returns true if promo probability >= threshold.
  bool isPromo(Uint8List cardPixels, int cardW, int cardH) {
    final prob = classify(cardPixels, cardW, cardH);
    return prob != null && prob >= promoThreshold;
  }
}

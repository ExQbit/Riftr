import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based card-present classifier.
///
/// Classifies whether the center region of a camera frame contains a card.
/// Input: 192×256 grayscale center crop of the camera frame.
/// Output: probability of card present (0.0 = no card, 1.0 = card).
///
/// 92% accuracy, ~33KB model.
class CardPresentClassifierService {
  CardPresentClassifierService._();
  static final CardPresentClassifierService instance = CardPresentClassifierService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  static const _inputW = 192;
  static const _inputH = 256;

  /// Minimum confidence to consider a card present.
  static const cardPresentThreshold = 0.55;

  /// Load the TFLite model from assets.
  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/card_present_classifier.tflite');
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/card_present_classifier.tflite');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/card_present_classifier.tflite');
        await file.writeAsBytes(data.buffer.asUint8List());
        _interpreter = Interpreter.fromFile(file);
      } catch (e) {
        debugPrint('CardPresentClassifier: failed to load: $e');
        return;
      }
    }
    if (_interpreter != null) {
      debugPrint('CardPresentClassifier: loaded');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Classify whether the center of the camera frame contains a card.
  ///
  /// [yPlane] is the full camera Y-plane (grayscale).
  /// Returns the probability of a card being present, or null if not ready.
  double? classify(Uint8List yPlane, int frameW, int frameH, int stride) {
    if (_interpreter == null) return null;

    // Crop center 50% of the frame (same as training data)
    final cropX = frameW ~/ 4;
    final cropY = frameH ~/ 4;
    final cropW = frameW ~/ 2;
    final cropH = frameH ~/ 2;

    // Resize center crop to 192×256 and normalize to [0,1]
    final resized = Float32List(_inputW * _inputH);
    for (int y = 0; y < _inputH; y++) {
      final srcY = cropY + (y * cropH ~/ _inputH);
      for (int x = 0; x < _inputW; x++) {
        final srcX = cropX + (x * cropW ~/ _inputW);
        final srcIdx = srcY * stride + srcX;
        resized[y * _inputW + x] =
            srcIdx >= 0 && srcIdx < yPlane.length ? yPlane[srcIdx] / 255.0 : 0.0;
      }
    }

    // Run inference: [1, 256, 192, 1] → [1, 1]
    final input = resized.buffer.asFloat32List();
    final inputTensor = input.reshape([1, _inputH, _inputW, 1]);
    final output = List.filled(1, List.filled(1, 0.0));
    _interpreter!.run(inputTensor, output);

    return output[0][0];
  }
}

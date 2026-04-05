import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Native rectangle detection via platform-specific Vision APIs.
///
/// iOS: VNDetectRectanglesRequest (Vision framework, hardware-accelerated)
/// Android: ML Kit / OpenCV (TBD)
///
/// Returns the 4 corners of the detected card rectangle in pixel coordinates,
/// or null if no card-like rectangle found.
class NativeRectService {
  NativeRectService._();
  static final NativeRectService instance = NativeRectService._();

  static const _channel = MethodChannel('com.riftr.scanner/rect_detection');

  /// Detect a card rectangle in a Y-plane image.
  ///
  /// [yPlane] is the luminance plane (grayscale) from the camera.
  /// [width] and [height] are the image dimensions.
  /// [bytesPerRow] is the stride (may differ from width due to padding).
  ///
  /// Returns [x, y, width, height] of the detected rectangle in pixel
  /// coordinates, or null if no card found.
  Future<List<int>?> detectCardRect({
    required Uint8List yPlane,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('detectRect', {
        'yPlane': yPlane,
        'width': width,
        'height': height,
        'bytesPerRow': bytesPerRow,
      });

      if (result == null) return null;

      final x = (result['x'] as num).toInt();
      final y = (result['y'] as num).toInt();
      final w = (result['w'] as num).toInt();
      final h = (result['h'] as num).toInt();

      // Sanity check
      if (w < 50 || h < 50) return null;

      return [x, y, w, h];
    } on PlatformException catch (e) {
      // Native API not available or failed
      return null;
    } catch (e) {
      return null;
    }
  }
}

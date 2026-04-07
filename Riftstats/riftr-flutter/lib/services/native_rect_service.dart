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
  /// Returns list of [x, y, width, height] for ALL card-ratio rectangles,
  /// or null if none found.
  Future<List<List<int>>?> detectCardRects({
    required Uint8List yPlane,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async {
    try {
      final result = await _channel.invokeMethod('detectRect', {
        'yPlane': yPlane,
        'width': width,
        'height': height,
        'bytesPerRow': bytesPerRow,
      });

      if (result == null) return null;

      // Handle both array of rects and single rect
      List<Map> maps = [];
      if (result is List) {
        for (final r in result) {
          if (r is Map) maps.add(r);
        }
      } else if (result is Map) {
        maps.add(result);
      }

      if (maps.isEmpty) return null;

      final rects = <List<int>>[];
      for (final m in maps) {
        final x = (m['x'] as num?)?.toInt();
        final y = (m['y'] as num?)?.toInt();
        final w = (m['w'] as num?)?.toInt();
        final h = (m['h'] as num?)?.toInt();
        if (x != null && y != null && w != null && h != null && w >= 50 && h >= 50) {
          rects.add([x, y, w, h]);
        }
      }
      return rects.isNotEmpty ? rects : null;
    } on PlatformException {
      return null;
    } catch (e) {
      return null;
    }
  }
}

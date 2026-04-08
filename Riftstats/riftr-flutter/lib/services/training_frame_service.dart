import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Collects downscaled camera frames for training a Card-Present classifier.
///
/// Positive frames: card successfully scanned (OCR score ≥ 70).
/// Negative frames: scan timeout with no match after 20 frames.
///
/// Frames are saved as 96×128 grayscale PNGs (~12KB each).
/// Max 2000 frames (1000 positive + 1000 negative), FIFO eviction.
class TrainingFrameService {
  TrainingFrameService._();
  static final TrainingFrameService instance = TrainingFrameService._();

  static const _targetW = 96;
  static const _targetH = 128;
  static const _maxPerCategory = 1000;

  Directory? _baseDir;
  bool _saving = false; // prevent concurrent saves (pos/neg frames)
  bool _savingRects = false; // separate lock for rect crops

  /// Initialize base directory lazily.
  Future<Directory> _getBaseDir() async {
    if (_baseDir != null) return _baseDir!;
    final docs = await getApplicationDocumentsDirectory();
    _baseDir = Directory('${docs.path}/training_frames');
    return _baseDir!;
  }

  Future<Directory> _positiveDir() async {
    final dir = Directory('${(await _getBaseDir()).path}/positive');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<Directory> _negativeDir() async {
    final dir = Directory('${(await _getBaseDir()).path}/negative');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Save a positive frame (card successfully scanned).
  /// Save a positive frame (card successfully scanned).
  /// [cardCrop] is the full-resolution card crop (grayscale) for set/suffix training.
  Future<void> savePositiveFrame(
    Uint8List yPlane, int width, int height, int stride, String cardName,
    {Uint8List? cardCrop, int cardCropW = 0, int cardCropH = 0}
  ) async {
    if (_saving) {
      if (kDebugMode) debugPrint('TrainingFrame: skip positive (save in progress)');
      return;
    }
    _saving = true;
    try {
      final dir = await _positiveDir();
      final safeName = cardName
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Low-res full frame (96×128) for card-present classifier
      await _saveDownscaledFrame(yPlane, width, height, stride,
          '${dir.path}/${ts}_pos_$safeName.png');

      // Full-resolution card crop for set/suffix/promo training
      if (cardCrop != null && cardCropW > 0 && cardCropH > 0) {
        await _saveGrayscalePng(cardCrop, cardCropW, cardCropH,
            '${dir.path}/${ts}_crop_$safeName.png');
      }

      await _enforceLimit(dir);

      final count = await frameCount();
      if (kDebugMode) debugPrint('TrainingFrame: saved positive → $safeName (${count.total}/2000: ${count.positive}pos ${count.negative}neg)');
    } catch (e) {
      if (kDebugMode) debugPrint('TrainingFrame: save positive failed: $e');
    } finally {
      _saving = false;
    }
  }

  /// Save native rect crops for Card-Present classifier training.
  ///
  /// Crops each native rect from the Y-plane, resizes to 96×128, and saves.
  /// Rects overlapping with [cardRect] → positive, others → negative.
  Future<void> saveRectCrops(
    Uint8List yPlane, int width, int height, int stride,
    List<List<int>> nativeRects, List<int>? cardRect,
  ) async {
    if (_savingRects || nativeRects.isEmpty) return;
    _savingRects = true;
    try {
      final posDir = await _positiveDir();
      final negDir = await _negativeDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      int posSaved = 0, negSaved = 0;

      for (int i = 0; i < nativeRects.length; i++) {
        final r = nativeRects[i];
        if (r.length < 4) continue;
        final rx = r[0], ry = r[1], rw = r[2], rh = r[3];
        if (rw < 50 || rh < 50) continue; // skip tiny rects

        // Check if this rect overlaps with the card rect (IoU > 0.3)
        final isCard = cardRect != null && _rectsOverlap(r, cardRect);

        // Clamp rect to frame bounds
        final cx = rx.clamp(0, width - 1);
        final cy = ry.clamp(0, height - 1);
        final cw = rw.clamp(1, width - cx);
        final ch = rh.clamp(1, height - cy);
        if (cw < 50 || ch < 50) continue;

        // Downscale rect directly to 96×128 grayscale pixels
        final pixels = Uint8List(_targetW * _targetH);
        for (int dy = 0; dy < _targetH; dy++) {
          final srcY = cy + (dy * ch ~/ _targetH);
          for (int dx = 0; dx < _targetW; dx++) {
            final srcX = cx + (dx * cw ~/ _targetW);
            final srcIdx = srcY * stride + srcX;
            pixels[dy * _targetW + dx] =
                srcIdx >= 0 && srcIdx < yPlane.length ? yPlane[srcIdx] : 0;
          }
        }

        // Save as raw grayscale binary (96×128 = 12288 bytes)
        // Training script reads these directly — no PNG overhead
        final dir = isCard ? posDir : negDir;
        final label = isCard ? 'rect_pos' : 'rect_neg';
        await File('${dir.path}/${ts}_${label}_$i.raw').writeAsBytes(pixels);

        if (isCard) posSaved++; else negSaved++;
      }

      if (kDebugMode && (posSaved > 0 || negSaved > 0)) {
        debugPrint('TrainingFrame: rect crops saved ${posSaved}pos ${negSaved}neg '
            '(from ${nativeRects.length} rects)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TrainingFrame: rect crops failed: $e');
    } finally {
      _savingRects = false;
    }
  }

  /// Check if two rects overlap significantly (IoU > 0.3).
  bool _rectsOverlap(List<int> a, List<int> b) {
    final ax1 = a[0], ay1 = a[1], ax2 = a[0] + a[2], ay2 = a[1] + a[3];
    final bx1 = b[0], by1 = b[1], bx2 = b[0] + b[2], by2 = b[1] + b[3];

    final ix1 = ax1 > bx1 ? ax1 : bx1;
    final iy1 = ay1 > by1 ? ay1 : by1;
    final ix2 = ax2 < bx2 ? ax2 : bx2;
    final iy2 = ay2 < by2 ? ay2 : by2;

    if (ix1 >= ix2 || iy1 >= iy2) return false;

    final intersection = (ix2 - ix1) * (iy2 - iy1);
    final aArea = a[2] * a[3];
    final bArea = b[2] * b[3];
    final union = aArea + bArea - intersection;

    return union > 0 && intersection / union > 0.3;
  }

  /// Save grayscale pixels as PNG (no downscaling, already correct size).
  Future<void> _saveGrayscalePixels(Uint8List pixels, int w, int h, String path) async {
    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      final v = pixels[i];
      rgba[i * 4] = v;
      rgba[i * 4 + 1] = v;
      rgba[i * 4 + 2] = v;
      rgba[i * 4 + 3] = 255;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba, w, h, ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );
    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;
    await File(path).writeAsBytes(byteData.buffer.asUint8List());
  }

  /// Save a negative frame (scan timeout, no card matched).
  Future<void> saveNegativeFrame(
    Uint8List yPlane, int width, int height, int stride,
  ) async {
    if (_saving) return;
    _saving = true;
    try {
      final dir = await _negativeDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/${ts}_neg.png';

      await _saveDownscaledFrame(yPlane, width, height, stride, path);
      await _enforceLimit(dir);

      final count = await frameCount();
      if (kDebugMode) debugPrint('TrainingFrame: saved negative (${count.total}/2000: ${count.positive}pos ${count.negative}neg)');
    } catch (e) {
      if (kDebugMode) debugPrint('TrainingFrame: save negative failed: $e');
    } finally {
      _saving = false;
    }
  }

  /// Downscale Y-plane to 96×128 and save as grayscale PNG.
  Future<void> _saveDownscaledFrame(
    Uint8List yPlane, int srcW, int srcH, int stride, String path,
  ) async {
    // Downscale with nearest-neighbor sampling
    final pixels = Uint8List(_targetW * _targetH);
    for (int y = 0; y < _targetH; y++) {
      final srcY = y * srcH ~/ _targetH;
      for (int x = 0; x < _targetW; x++) {
        final srcX = x * srcW ~/ _targetW;
        final srcIdx = srcY * stride + srcX;
        pixels[y * _targetW + x] =
            srcIdx < yPlane.length ? yPlane[srcIdx] : 0;
      }
    }

    // Convert grayscale to RGBA for PNG encoding
    final rgba = Uint8List(_targetW * _targetH * 4);
    for (int i = 0; i < _targetW * _targetH; i++) {
      final v = pixels[i];
      rgba[i * 4] = v;
      rgba[i * 4 + 1] = v;
      rgba[i * 4 + 2] = v;
      rgba[i * 4 + 3] = 255;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba, _targetW, _targetH, ui.PixelFormat.rgba8888, completer.complete,
    );
    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData != null) {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
    }
  }

  /// Save grayscale pixels as PNG (no downscaling).
  Future<void> _saveGrayscalePng(Uint8List pixels, int w, int h, String path) async {
    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      final v = i < pixels.length ? pixels[i] : 0;
      rgba[i * 4] = v;
      rgba[i * 4 + 1] = v;
      rgba[i * 4 + 2] = v;
      rgba[i * 4 + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData != null) {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
    }
  }

  /// Delete oldest files if directory exceeds max count.
  Future<void> _enforceLimit(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();

    if (files.length <= _maxPerCategory) return;

    // Sort by name (timestamp prefix = chronological order)
    files.sort((a, b) => a.path.compareTo(b.path));

    // Delete oldest
    final toDelete = files.length - _maxPerCategory;
    for (int i = 0; i < toDelete; i++) {
      try {
        await files[i].delete();
      } catch (_) {}
    }
  }

  /// Delete all old training frames (both positive and negative).
  Future<void> clearAll() async {
    try {
      final base = await _getBaseDir();
      if (base.existsSync()) {
        await base.delete(recursive: true);
        _baseDir = null;
        if (kDebugMode) debugPrint('TrainingFrame: cleared all frames');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TrainingFrame: clear failed: $e');
    }
  }

  /// Count total collected frames.
  Future<({int positive, int negative, int total})> frameCount() async {
    int pos = 0, neg = 0;
    try {
      final posDir = await _positiveDir();
      pos = posDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png') || f.path.endsWith('.raw')).length;
    } catch (_) {}
    try {
      final negDir = await _negativeDir();
      neg = negDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png') || f.path.endsWith('.raw')).length;
    } catch (_) {}
    return (positive: pos, negative: neg, total: pos + neg);
  }

  /// Export all collected frames via Share Sheet.
  Future<void> exportFrames() async {
    final base = await _getBaseDir();
    if (!base.existsSync()) {
      debugPrint('TrainingFrame: no frames to export');
      return;
    }

    // Collect all PNG files from both directories
    final files = <XFile>[];
    for (final subDir in ['positive', 'negative']) {
      final dir = Directory('${base.path}/$subDir');
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.png') || file.path.endsWith('.raw')) {
          files.add(XFile(file.path));
        }
      }
    }

    if (files.isEmpty) {
      debugPrint('TrainingFrame: no frames to export');
      return;
    }

    debugPrint('TrainingFrame: exporting ${files.length} frames...');

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: 'Riftr Training Frames (${files.length} frames)',
      ),
    );
  }
}

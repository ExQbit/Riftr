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
  bool _saving = false; // prevent concurrent saves

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
    if (_saving) return;
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

  /// Count total collected frames.
  Future<({int positive, int negative, int total})> frameCount() async {
    int pos = 0, neg = 0;
    try {
      final posDir = await _positiveDir();
      pos = posDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length;
    } catch (_) {}
    try {
      final negDir = await _negativeDir();
      neg = negDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length;
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
        if (file.path.endsWith('.png')) {
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

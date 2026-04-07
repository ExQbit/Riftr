import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'contour_service.dart';

/// Perceptual Hash service for card variant detection.
///
/// After OCR identifies a card, pHash compares the camera image against
/// precomputed reference hashes to determine which variant (Base, Alt Art,
/// Promo, Metal, etc.) is being scanned.
///
/// Two-stage comparison:
///   1. Full-image pHash → detects different artwork (Base vs Alt Art, Metal)
///   2. Gem-crop pHash → detects Base vs Promo (same artwork, different frame)
///
/// pHash is a VARIANT SELECTOR only — it does NOT affect OCR scoring.
class PhashService {
  PhashService._();
  static final PhashService instance = PhashService._();

  /// Precomputed dual hashes keyed by card ID.
  /// Each entry has "f" (full hash) and "g" (gem hash).
  Map<String, DualHash> _lookup = {};

  /// Gem pixel templates for SAD matching (32×22 normalized grayscale).
  Map<String, Uint8List> _gemTemplates = {};
  int _gemTemplateW = 32;
  int _gemTemplateH = 22;

  bool get isReady => _lookup.isNotEmpty;

  // ── Config ──
  static const _imgSize = 32;
  static const _hashSize = 8;

  /// Full-image threshold: ≤ this = same artwork variant.
  static const fullHashThreshold = 10;

  /// Gem-crop threshold: > this = promo variant (when full hash says same artwork).
  static const gemHashThreshold = 12;

  /// Confidence gate: best full Hamming must be ≤ this to trust pHash.
  static const confidenceMaxDist = 25;

  /// Confidence gate: gap between best and second-best must be ≥ this.
  static const confidenceMinGap = 5;

  /// Gem crop coordinates (percentage of card dimensions).
  /// Small crop for maximum discriminative power. Multi-probes (±10px)
  /// compensate for rect boundary variance.
  static const _gemCropX = 0.44;
  static const _gemCropY = 0.91;
  static const _gemCropW = 0.12;
  static const _gemCropH = 0.06;

  // ── Precomputed DCT matrix (32×32) ──
  static late final Float64List _dctFlat;
  static bool _dctReady = false;

  static void _ensureDct() {
    if (_dctReady) return;
    final n = _imgSize;
    final mat = Float64List(n * n);
    final scale0 = 1.0 / sqrt(n);
    final scaleK = sqrt(2.0 / n);
    for (int k = 0; k < n; k++) {
      final scale = k == 0 ? scale0 : scaleK;
      for (int i = 0; i < n; i++) {
        mat[k * n + i] = scale * cos(pi * k * (2 * i + 1) / (2 * n));
      }
    }
    _dctFlat = mat;
    _dctReady = true;
  }

  /// Load precomputed dual-hash lookup from assets.
  Future<void> load() async {
    if (_lookup.isNotEmpty) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/phash_lookup.json');
      final Map<String, dynamic> raw = json.decode(jsonStr);
      _lookup = raw.map((k, v) {
        final m = v as Map<String, dynamic>;
        return MapEntry(k, DualHash(
          full: _parseHash64(m['f'] as String),
          gem: _parseHash64(m['g'] as String),
        ));
      });
      debugPrint('PhashService: ${_lookup.length} dual hashes loaded');
    } catch (e) {
      debugPrint('PhashService: Failed to load lookup: $e');
    }

    // Load gem pixel templates for SAD matching
    try {
      final tplStr = await rootBundle.loadString('assets/gem_templates.json');
      final Map<String, dynamic> tplRaw = json.decode(tplStr);
      _gemTemplateW = tplRaw['w'] as int;
      _gemTemplateH = tplRaw['h'] as int;
      final templates = tplRaw['templates'] as Map<String, dynamic>;
      _gemTemplates = templates.map((k, v) =>
          MapEntry(k, base64Decode(v as String)));
      debugPrint('PhashService: ${_gemTemplates.length} gem templates loaded (${_gemTemplateW}x$_gemTemplateH)');
    } catch (e) {
      debugPrint('PhashService: Failed to load gem templates: $e');
    }
  }

  /// Parse a 16-char hex string as 64-bit hash.
  /// Dart int is signed 64-bit — parse as two 32-bit halves to avoid overflow.
  static int _parseHash64(String hex) {
    if (hex.length != 16) return 0;
    final hi = int.parse(hex.substring(0, 8), radix: 16);
    final lo = int.parse(hex.substring(8, 16), radix: 16);
    return (hi << 32) | lo;
  }

  /// Get precomputed dual hash for a card ID.
  DualHash? getHash(String cardId) => _lookup[cardId];

  /// Compute 64-bit DCT perceptual hash from a Y-plane region.
  ///
  /// [pixels] is the pixel data (grayscale).
  /// [pw], [ph] are the region dimensions.
  static int _computeHashFromPixels(Uint8List pixels, int pw, int ph) {
    _ensureDct();
    final n = _imgSize;

    // Downsample to 32×32 (bilinear interpolation)
    final resized = Float64List(n * n);
    final scaleX = pw / n;
    final scaleY = ph / n;

    for (int y = 0; y < n; y++) {
      final srcY = y * scaleY;
      final y0 = srcY.floor().clamp(0, ph - 2);
      final fy = srcY - y0;
      for (int x = 0; x < n; x++) {
        final srcX = x * scaleX;
        final x0 = srcX.floor().clamp(0, pw - 2);
        final fx = srcX - x0;
        final idx00 = y0 * pw + x0;
        final idx01 = y0 * pw + (x0 + 1).clamp(0, pw - 1);
        final idx10 = (y0 + 1).clamp(0, ph - 1) * pw + x0;
        final idx11 = (y0 + 1).clamp(0, ph - 1) * pw + (x0 + 1).clamp(0, pw - 1);
        final v = (1 - fx) * (1 - fy) * pixels[idx00] +
            fx * (1 - fy) * pixels[idx01] +
            (1 - fx) * fy * pixels[idx10] +
            fx * fy * pixels[idx11];
        resized[y * n + x] = v;
      }
    }

    // 2D DCT
    final dct = _dctFlat;
    final temp = Float64List(n * n);
    for (int k = 0; k < n; k++) {
      for (int j = 0; j < n; j++) {
        double sum = 0;
        for (int i = 0; i < n; i++) {
          sum += dct[k * n + i] * resized[i * n + j];
        }
        temp[k * n + j] = sum;
      }
    }
    final result = Float64List(n * n);
    for (int k = 0; k < n; k++) {
      for (int j = 0; j < n; j++) {
        double sum = 0;
        for (int i = 0; i < n; i++) {
          sum += temp[k * n + i] * dct[j * n + i];
        }
        result[k * n + j] = sum;
      }
    }

    // Extract 8×8 low-frequency, median threshold → 64-bit hash
    final hs = _hashSize;
    final lowFreq = Float64List(hs * hs);
    for (int y = 0; y < hs; y++) {
      for (int x = 0; x < hs; x++) {
        lowFreq[y * hs + x] = result[y * n + x];
      }
    }
    final sorted = Float64List.fromList(lowFreq.sublist(1))..sort();
    final median = sorted.length.isEven
        ? (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2
        : sorted[sorted.length ~/ 2];

    int hash = 0;
    for (int i = 0; i < hs * hs; i++) {
      hash = (hash << 1) | (lowFreq[i] > median ? 1 : 0);
    }
    return hash;
  }

  /// Compute dual hash (full + gem crop) from a camera Y-plane.
  ///
  /// [yPlane] is the luminance plane from YUV420 camera image.
  /// [width] and [height] are the Y-plane dimensions.
  /// [cardRect] is the estimated card area (x, y, w, h) in pixels,
  /// or null to use the full frame.
  /// [debug] if true, returns raw crop pixels in the result for inspection.
  static PhashComputeResult computeDualHash(Uint8List yPlane, int width, int height,
      {List<int>? cardRect, bool debug = false}) {
    _ensureDct();

    // Determine card region
    int cx, cy, cw, ch;
    if (cardRect != null && cardRect.length == 4) {
      cx = cardRect[0].clamp(0, width - 1);
      cy = cardRect[1].clamp(0, height - 1);
      cw = cardRect[2].clamp(1, width - cx);
      ch = cardRect[3].clamp(1, height - cy);
    } else {
      cx = 0;
      cy = 0;
      cw = width;
      ch = height;
    }

    // Extract card region pixels
    final cardPixels = Uint8List(cw * ch);
    for (int y = 0; y < ch; y++) {
      final srcOffset = (cy + y) * width + cx;
      final dstOffset = y * cw;
      cardPixels.setRange(dstOffset, dstOffset + cw, yPlane, srcOffset);
    }

    // Full hash
    final fullHash = _computeHashFromPixels(cardPixels, cw, ch);

    // Gem crop hash — multi-position: center + 8 directions (±10px)
    // compensates for VNDetectRectanglesRequest boundary variance
    final baseGx = (_gemCropX * cw).round();
    final baseGy = (_gemCropY * ch).round();
    final gw = (_gemCropW * cw).round().clamp(1, cw);
    final gh = (_gemCropH * ch).round().clamp(1, ch);
    const s = 10;

    final offsets = [
      [0, 0],    // center
      [0, -s],   // up
      [0, s],    // down
      [-s, 0],   // left
      [s, 0],    // right
      [-s, -s],  // up-left
      [s, -s],   // up-right
      [-s, s],   // down-left
      [s, s],    // down-right
    ];

    int? centerGemHash;
    Uint8List? centerGemPixels;
    final gemProbes = <int>[];

    for (final off in offsets) {
      final gx = (baseGx + off[0]).clamp(0, cw - gw);
      final gy = (baseGy + off[1]).clamp(0, ch - gh);

      final gemPixels = Uint8List(gw * gh);
      for (int y = 0; y < gh; y++) {
        final srcOffset = (gy + y) * cw + gx;
        final dstOffset = y * gw;
        if (srcOffset + gw <= cardPixels.length) {
          gemPixels.setRange(dstOffset, dstOffset + gw, cardPixels, srcOffset);
        }
      }
      final h = _computeHashFromPixels(gemPixels, gw, gh);
      gemProbes.add(h);

      if (centerGemHash == null) {
        centerGemHash = h;
        centerGemPixels = gemPixels;
      }
    }

    return PhashComputeResult(
      hash: DualHash(full: fullHash, gem: centerGemHash!, gemProbes: gemProbes),
      cardRect: [cx, cy, cw, ch],
      debugFullPixels: debug ? cardPixels : null,
      debugFullW: cw, debugFullH: ch,
      debugGemPixels: debug ? centerGemPixels : null,
      debugGemW: gw, debugGemH: gh,
    );
  }

  /// Hamming distance between two 64-bit hashes.
  /// Uses unsigned right shift (>>>) to handle negative ints (signed bit 63).
  static int hammingDistance(int h1, int h2) {
    int x = h1 ^ h2;
    int count = 0;
    while (x != 0) {
      count += x & 1;
      x = x >>> 1; // unsigned shift — fills with 0, not sign bit
    }
    return count;
  }

  /// Full-hash spread threshold: if all variants within this spread,
  /// full hash can't distinguish → go to Stage 2 gem crop.
  static const fullSpreadThreshold = 5;

  /// Find the best matching variant using two-stage comparison.
  ///
  /// Stage 1: Full-image hash → different artwork? (with confidence gate)
  /// Stage 2: Gem-crop hash → base vs promo? (triggered by same artwork OR promo spread)
  ///
  /// [promoIds] = card IDs that are promo variants (OGNX/SFDX/OGSX).
  /// Returns a [PhashResult] with the best match and debug details.
  PhashResult? findBestVariant(DualHash cameraHash, List<String> variantIds, {Set<String> promoIds = const {}}) {
    if (variantIds.isEmpty) return null;

    // Compute distances for ALL variants
    final comparisons = <PhashComparison>[];
    final probes = cameraHash.gemProbes.isNotEmpty ? cameraHash.gemProbes : [cameraHash.gem];
    for (final id in variantIds) {
      final ref = _lookup[id];
      if (ref == null) continue;
      // Best gem distance across all probe positions (center + 4 offsets)
      int bestGemDist = 64;
      for (final probe in probes) {
        final d = hammingDistance(probe, ref.gem);
        if (d < bestGemDist) bestGemDist = d;
      }
      comparisons.add(PhashComparison(
        cardId: id,
        fullDist: hammingDistance(cameraHash.full, ref.full),
        gemDist: bestGemDist,
      ));
    }
    if (comparisons.isEmpty) return null;

    // Sort by full distance
    comparisons.sort((a, b) => a.fullDist.compareTo(b.fullDist));
    final bestFull = comparisons.first;
    final worstFull = comparisons.last;
    final fullSpread = worstFull.fullDist - bestFull.fullDist;
    final secondFull = comparisons.length > 1 ? comparisons[1].fullDist : 64;
    final fullGap = secondFull - bestFull.fullDist;

    // Check if promo variants exist in the list
    final hasPromo = promoIds.isNotEmpty && comparisons.any((c) => promoIds.contains(c.cardId));

    // Stage 2 trigger: promo variant present + full hash can't distinguish (small spread)
    if (hasPromo && fullSpread <= fullSpreadThreshold) {
      // All full hashes are close — use gem crop to decide Base vs Promo
      final sorted = List<PhashComparison>.from(comparisons)
        ..sort((a, b) => a.gemDist.compareTo(b.gemDist));
      final bestGem = sorted.first;

      return PhashResult(
        bestId: bestGem.cardId,
        stage: 2,
        reason: '${bestGem.gemDist > gemHashThreshold ? "promo" : "base"} (spread=$fullSpread)',
        comparisons: comparisons,
      );
    }

    // Stage 1: Confidence gate — reject if best distance too high
    if (bestFull.fullDist > confidenceMaxDist) {
      return PhashResult(
        bestId: null,
        stage: 1,
        reason: 'low-confidence (best=${bestFull.fullDist} > $confidenceMaxDist)',
        comparisons: comparisons,
      );
    }

    // Stage 1: If best full hash > threshold → different artwork
    if (bestFull.fullDist > fullHashThreshold) {
      // Confidence: gap must be sufficient to trust the pick
      if (fullGap < confidenceMinGap) {
        return PhashResult(
          bestId: null,
          stage: 1,
          reason: 'low-confidence (gap=$fullGap < $confidenceMinGap)',
          comparisons: comparisons,
        );
      }
      return PhashResult(
        bestId: bestFull.cardId,
        stage: 1,
        reason: 'diff-artwork',
        comparisons: comparisons,
      );
    }

    // Stage 2: Same artwork (fullDist ≤ 10) — pick by gem
    final sameArt = comparisons.where((c) => c.fullDist <= fullHashThreshold).toList();
    sameArt.sort((a, b) => a.gemDist.compareTo(b.gemDist));
    final bestGem = sameArt.first;

    return PhashResult(
      bestId: bestGem.cardId,
      stage: 2,
      reason: bestGem.gemDist > gemHashThreshold ? 'promo' : 'base',
      comparisons: comparisons,
    );
  }

  // ══════════════════════════════════════════════
  // ── SAD Template Matching for Promo detection ──
  // ══════════════════════════════════════════════

  /// Compare camera gem crop against reference gem templates using SAD
  /// (Sum of Absolute Differences) with multi-position sliding window.
  /// Returns the variant ID with the lowest SAD, or null if no templates.
  PhashResult? findBestVariantSAD(
    Uint8List cameraCardPixels, int cardW, int cardH,
    List<String> variantIds, {Set<String>? promoIds}
  ) {
    if (_gemTemplates.isEmpty) return null;

    // Check which variants have templates
    final withTemplates = variantIds.where((id) => _gemTemplates.containsKey(id)).toList();
    if (withTemplates.length < 2) return null;

    // Extract camera gem crops at multiple positions (sliding window)
    final baseGx = (_gemCropX * cardW).round();
    final baseGy = (_gemCropY * cardH).round();
    final gw = (_gemCropW * cardW).round().clamp(1, cardW);
    final gh = (_gemCropH * cardH).round().clamp(1, cardH);

    // Sliding window: ±15px in 3px steps = 11×11 = 121 probes
    // Balance: enough for rect boundary error, not so much that false matches occur
    const step = 3;
    const range = 15;

    // Strategy: Base is default. Only search for PROMO indicators.
    // If any probe position matches a promo template well → Promo.
    // If not → Base.
    final promoVars = promoIds != null
        ? withTemplates.where((id) => promoIds.contains(id)).toList()
        : <String>[];
    final baseVars = withTemplates.where((id) => !promoVars.contains(id)).toList();

    if (promoVars.isEmpty) return null;

    // Search: does any probe position match a promo template?
    String? bestPromoId;
    double bestPromoSad = double.infinity;

    for (final promoId in promoVars) {
      final template = _gemTemplates[promoId]!;
      if (template.length != _gemTemplateW * _gemTemplateH) continue;

      for (int dy = -range; dy <= range; dy += step) {
        for (int dx = -range; dx <= range; dx += step) {
          final gx = (baseGx + dx).clamp(0, cardW - gw);
          final gy = (baseGy + dy).clamp(0, cardH - gh);

          final cropPixels = _extractAndResize(
            cameraCardPixels, cardW, cardH, gx, gy, gw, gh,
            _gemTemplateW, _gemTemplateH,
          );
          if (cropPixels == null) continue;

          final normalized = _normalize(cropPixels);

          double sum = 0;
          for (int i = 0; i < normalized.length; i++) {
            sum += (normalized[i] - template[i]).abs();
          }
          final meanSad = sum / normalized.length;

          if (meanSad < bestPromoSad) {
            bestPromoSad = meanSad;
            bestPromoId = promoId;
          }
        }
      }
    }

    // Promo threshold: if best SAD < 35, promo badge was found
    const promoThreshold = 60.0;
    final isPromo = bestPromoSad < promoThreshold;
    final defaultBaseId = baseVars.isNotEmpty ? baseVars.first : withTemplates.first;
    final resultId = isPromo ? bestPromoId! : defaultBaseId;

    final comparisons = withTemplates.map((id) => PhashComparison(
      cardId: id,
      fullDist: 0,
      gemDist: id == bestPromoId ? bestPromoSad.round() : 99,
    )).toList();

    return PhashResult(
      bestId: resultId,
      stage: 3,
      reason: 'SAD promo-detect (best=${bestPromoSad.toStringAsFixed(1)}, thresh=$promoThreshold → ${isPromo ? "PROMO" : "base"})',
      comparisons: comparisons,
    );
  }

  /// Extract a sub-region from pixels and resize to target dimensions
  /// using simple bilinear-ish nearest-neighbor sampling.
  static Uint8List? _extractAndResize(
    Uint8List src, int srcW, int srcH,
    int cropX, int cropY, int cropW, int cropH,
    int targetW, int targetH,
  ) {
    final result = Uint8List(targetW * targetH);
    for (int ty = 0; ty < targetH; ty++) {
      final sy = cropY + (ty * cropH ~/ targetH);
      if (sy >= srcH) return null;
      for (int tx = 0; tx < targetW; tx++) {
        final sx = cropX + (tx * cropW ~/ targetW);
        if (sx >= srcW) return null;
        final srcIdx = sy * srcW + sx;
        if (srcIdx >= src.length) return null;
        result[ty * targetW + tx] = src[srcIdx];
      }
    }
    return result;
  }

  /// Normalize pixel array to 0-255 range.
  static Uint8List _normalize(Uint8List pixels) {
    int mn = 255, mx = 0;
    for (final p in pixels) {
      if (p < mn) mn = p;
      if (p > mx) mx = p;
    }
    if (mx == mn) return pixels;
    final result = Uint8List(pixels.length);
    final range = mx - mn;
    for (int i = 0; i < pixels.length; i++) {
      result[i] = ((pixels[i] - mn) * 255 ~/ range);
    }
    return result;
  }
}

/// Per-variant comparison result.
class PhashComparison {
  final String cardId;
  final int fullDist;
  final int gemDist;
  const PhashComparison({required this.cardId, required this.fullDist, required this.gemDist});
}

/// Result of variant detection with debug details.
class PhashResult {
  final String? bestId;       // null = low confidence, fall back to OCR default
  final int stage;            // 1 = full hash decided, 2 = gem hash decided
  final String reason;        // "diff-artwork", "promo", "base", "low-confidence (...)"
  final List<PhashComparison> comparisons;
  const PhashResult({required this.bestId, required this.stage, required this.reason, required this.comparisons});
}

/// Dual hash: full image + gem crop.
class DualHash {
  final int full;
  final int gem; // center gem hash
  final List<int> gemProbes; // multi-position gem hashes (center + 4 offsets)
  const DualHash({required this.full, required this.gem, this.gemProbes = const []});
}

/// Result from computeDualHash with optional debug pixels.
class PhashComputeResult {
  final DualHash hash;
  final List<int>? cardRect; // detected card rectangle [x, y, w, h]
  final Uint8List? debugFullPixels;
  final int debugFullW;
  final int debugFullH;
  final Uint8List? debugGemPixels;
  final int debugGemW;
  final int debugGemH;

  const PhashComputeResult({
    required this.hash,
    this.cardRect,
    this.debugFullPixels,
    this.debugFullW = 0,
    this.debugFullH = 0,
    this.debugGemPixels,
    this.debugGemW = 0,
    this.debugGemH = 0,
  });
}

/// Payload for compute() isolate.
class PhashPayload {
  final Uint8List yPlane;
  final int width;
  final int height;
  final List<int>? cardRect;
  final bool debug;

  const PhashPayload({
    required this.yPlane,
    required this.width,
    required this.height,
    this.cardRect,
    this.debug = false,
  });
}

/// Top-level function for compute() isolate.
/// Contour detection → card rect → pHash. UI-rect as fallback.
PhashComputeResult computePhashIsolate(PhashPayload payload) {
  try {
    // Use the provided card rect (from OCR-Anchoring)
    final cardRect = payload.cardRect;

    return PhashService.computeDualHash(
      payload.yPlane,
      payload.width,
      payload.height,
      cardRect: cardRect,
      debug: payload.debug,
    );
  } catch (e) {
    // Fallback: return empty hash if anything crashes
    return PhashComputeResult(
      hash: DualHash(full: 0, gem: 0),
      cardRect: payload.cardRect,
    );
  }
}

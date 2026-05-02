import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Lightweight scanner-event telemetry. One Firestore doc per UTC day with
/// incremented counter fields — no user IDs, no card IDs, no PII. The point
/// is data-driven prioritization of future scanner work: which strategies
/// actually fire in real beta-tester sessions, where do scans timeout, what
/// fraction of scans are battlefield/legend/rune/portrait, etc.
///
/// Path: `artifacts/riftr-v1/scanner_metrics/{YYYY-MM-DD}`
///
/// All writes are best-effort fire-and-forget — failures get logged in debug
/// but never throw to the caller (telemetry must never break the scanner).
class ScanTelemetryService {
  ScanTelemetryService._();
  static final ScanTelemetryService instance = ScanTelemetryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// UTC date for bucketing (so counters across timezones align).
  String _todayKey() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DocumentReference<Map<String, dynamic>> _todayDoc() {
    return _db
        .collection('artifacts')
        .doc('riftr-v1')
        .collection('scanner_metrics')
        .doc(_todayKey());
  }

  /// Record a single scan-success event.
  ///
  /// [strategy] = 'default' / 'physical-180' / 'physical-90cw' / 'physical-270cw'
  /// [confidence] = 'high' / 'medium' / 'low'
  /// [cardType] = 'unit' / 'spell' / 'gear' / 'rune' / 'battlefield' / 'legend' / etc.
  /// [variantPath] = which path picked the variant: 'cn_suffix', 'badge_ocr',
  ///                 'champion_ocr', 'promo_cnn', 'phash', 'default'
  /// [latencyMs] = total time from WAITING-detect to _addCard (acceptance)
  void recordScanSuccess({
    required String strategy,
    required String confidence,
    required String cardType,
    required String variantPath,
    required int latencyMs,
  }) {
    _writeUpdate({
      'date': _todayKey(),
      'success_total': FieldValue.increment(1),
      'success_strategy_$strategy': FieldValue.increment(1),
      'success_confidence_$confidence': FieldValue.increment(1),
      'success_type_$cardType': FieldValue.increment(1),
      'success_variant_$variantPath': FieldValue.increment(1),
      // Latency bucketing: <500, 500-1000, 1000-2000, >2000.
      'success_latency_${_latencyBucket(latencyMs)}': FieldValue.increment(1),
    });
  }

  /// Record a SCANNING-state timeout (= 20 frames without a match).
  /// Useful to spot when the scanner runs out of frames without finding a card.
  void recordScanTimeout({required int cumScore}) {
    _writeUpdate({
      'date': _todayKey(),
      'timeout_total': FieldValue.increment(1),
      'timeout_cumScore_${_scoreBucket(cumScore)}': FieldValue.increment(1),
    });
  }

  /// Record that the user manually changed the variant after acceptance.
  /// High signal that auto-resolution picked the wrong variant.
  void recordVariantOverride({required String fromCardType}) {
    _writeUpdate({
      'date': _todayKey(),
      'variant_override_total': FieldValue.increment(1),
      'variant_override_type_$fromCardType': FieldValue.increment(1),
    });
  }

  String _latencyBucket(int ms) {
    if (ms < 500) return 'lt500';
    if (ms < 1000) return '500-1000';
    if (ms < 2000) return '1000-2000';
    return 'gt2000';
  }

  String _scoreBucket(int score) {
    if (score == 0) return '0';
    if (score < 20) return 'lt20';
    if (score < 40) return '20-40';
    if (score < 60) return '40-60';
    return 'gte60';
  }

  void _writeUpdate(Map<String, dynamic> updates) {
    // Fire-and-forget. Catch + debug-log so a network blip never crashes
    // the scanner, but engineers see failures in beta-tester logs.
    _todayDoc().set(updates, SetOptions(merge: true)).catchError((Object e) {
      if (kDebugMode) debugPrint('ScanTelemetry: write failed: $e');
      return null;
    });
  }
}

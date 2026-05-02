import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/deck_model.dart';
import '../models/market/seller_profile.dart';
import '../theme/app_theme.dart';
import 'card_service.dart';

/// Stateless helper for Social Tab calculations.
///
/// All methods are pure functions — no Firestore, no state.
/// This makes them unit-testable and keeps social_screen.dart lean.
class SocialHelpers {
  SocialHelpers._();

  // ── Total cards per base set (including tokens, excluding promo sets) ──
  static const baseSets = <String, int>{
    'OGN': 353,
    'SFD': 302,
    'OGS': 24,
    'UNL': 246,
  };

  /// App Store launch date — used for Beta Tester / Founding Seller badges.
  /// Update this when the app launches.
  static final DateTime launchDate = DateTime(2026, 5, 8);

  // ── Main Legend ──────────────────────────────────────

  /// Determine the user's "main" legend from match history.
  ///
  /// Returns `({String? name, String? imageUrl})`.
  /// Fallback chain: Most played legend → Legend from first deck → null.
  static ({String? name, String? imageUrl}) mainLegend(
    List<MatchData> matches,
    List<DeckData> decks,
  ) {
    // 1. Count legendName frequency across all matches
    if (matches.isNotEmpty) {
      final counts = <String, int>{};
      for (final m in matches) {
        if (m.legendName.isNotEmpty) {
          counts[m.legendName] = (counts[m.legendName] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        final topLegend =
            counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        return (name: topLegend, imageUrl: _legendImageUrl(topLegend));
      }
    }

    // 2. Fallback: Legend from first deck
    if (decks.isNotEmpty) {
      final legendName = decks.first.legendName;
      if (legendName != null && legendName.isNotEmpty) {
        return (name: legendName, imageUrl: decks.first.legendImageUrl ?? _legendImageUrl(legendName));
      }
    }

    // 3. No legend found
    return (name: null, imageUrl: null);
  }

  static String? _legendImageUrl(String legendName) {
    final lookup = CardService.getLookup();
    return lookup[legendName]?.imageUrl;
  }

  // ── Win Rate ────────────────────────────────────────

  /// Calculate win rate as percentage (0–100).
  static double winRate(List<MatchData> matches) {
    if (matches.isEmpty) return 0;
    final wins = matches.where((m) => m.isWin).length;
    return wins / matches.length * 100;
  }

  /// Color for win rate display.
  static Color winRateColor(double rate) {
    if (rate >= 60) return AppColors.win;
    if (rate < 40) return AppColors.loss;
    return AppColors.textPrimary;
  }

  // ── Collection Progress ─────────────────────────────

  /// Calculate collection progress per base set.
  ///
  /// Takes the raw card/foil maps from FirestoreCollectionService.
  /// Returns only sets where the user owns at least 1 card.
  static Map<String, ({int owned, int total, double percent})> collectionBySet(
    Map<String, int> cards,
    Map<String, int> foils,
  ) {
    final lookup = CardService.getLookup();

    // Count unique owned cards per set
    final ownedBySet = <String, Set<String>>{};
    final allIds = {...cards.keys, ...foils.keys};
    for (final id in allIds) {
      final qty = (cards[id] ?? 0) + (foils[id] ?? 0);
      if (qty <= 0) continue;

      final card = lookup[id];
      if (card == null) continue;

      final setId = card.setId;
      if (setId == null || !baseSets.containsKey(setId)) continue;

      (ownedBySet[setId] ??= {}).add(id);
    }

    // Build result map
    final result = <String, ({int owned, int total, double percent})>{};
    for (final entry in ownedBySet.entries) {
      final total = baseSets[entry.key]!;
      final owned = entry.value.length;
      result[entry.key] = (
        owned: owned,
        total: total,
        percent: total > 0 ? owned / total * 100 : 0,
      );
    }

    return result;
  }

  /// Total collection percent across all base sets.
  static double totalCollectionPercent(
      Map<String, ({int owned, int total, double percent})> bySet) {
    if (bySet.isEmpty) return 0;
    final totalOwned = bySet.values.fold(0, (t, s) => t + s.owned);
    final totalCards = baseSets.values.fold(0, (t, v) => t + v);
    if (totalCards <= 0) return 0;
    return totalOwned / totalCards * 100;
  }

  // ── Get Started Checklist ───────────────────────────

  static List<({String label, bool done})> checklist({
    required int matchCount,
    required int uniqueOwned,
    required int deckCount,
  }) {
    return [
      (label: 'Play your first match', done: matchCount > 0),
      (label: 'Add cards to your collection', done: uniqueOwned > 0),
      (label: 'Build your first deck', done: deckCount > 0),
    ];
  }

  /// Whether checklist should be visible (≥ 2 items not done).
  static bool showChecklist(List<({String label, bool done})> items) {
    return items.where((i) => !i.done).length >= 2;
  }

  // ── Badges ──────────────────────────────────────────

  static List<({String label, Color bgColor, Color textColor})> badges({
    required DateTime? memberSince,
    required Map<String, ({int owned, int total, double percent})> collectionBySet,
    required SellerProfile? sellerProfile,
  }) {
    final result = <({String label, Color bgColor, Color textColor})>[];

    // Beta Tester: memberSince before launch
    if (memberSince != null && memberSince.isBefore(launchDate)) {
      result.add((
        label: 'Beta Tester',
        bgColor: AppColors.amber500,
        textColor: AppColors.background,
      ));
    }

    // Founding Seller: has seller profile + memberSince before launch
    if (sellerProfile != null &&
        sellerProfile.memberSince != null &&
        sellerProfile.memberSince!.isBefore(launchDate)) {
      result.add((
        label: 'Founding Seller',
        bgColor: AppColors.successMuted,
        textColor: AppColors.success,
      ));
    }

    // Commercial seller status — shown to the user themselves on their
    // own profile so they can verify their declared status (BACKLOG
    // Ticket 1, 2026-05-02). Gold accent matches the SellerStatusBadge
    // used for commercial sellers in listing tiles + order details.
    if (sellerProfile?.isCommercialSeller == true) {
      result.add((
        label: 'Commercial seller',
        bgColor: AppColors.amberMuted,
        textColor: AppColors.amber500,
      ));
    }

    // Collector I: any set ≥ 50%
    final hasCollector =
        collectionBySet.values.any((s) => s.percent >= 50);
    if (hasCollector) {
      result.add((
        label: 'Collector I',
        bgColor: AppColors.orderMuted,
        textColor: AppColors.order,
      ));
    }

    return result;
  }
}

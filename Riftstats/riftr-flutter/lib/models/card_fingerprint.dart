import '../models/card_model.dart';

/// Pre-computed fingerprint for fast scan matching.
/// All strings lowercase for instant comparison.
class CardFingerprint {
  final String cardId;
  final String setId;
  final int? collectorNumber;
  final String? cnSuffix;
  final String nameLower;         // "sivir"
  final String? titleLower;       // "mercenary"
  final String fullNameLower;     // "sivir, mercenary"
  final String rarity;            // "Rare"
  final int? energy;
  final int? power;
  final int? might;
  final String? type;             // "Unit"
  final String? supertype;        // "Champion"
  final List<String> domains;     // ["fury"] — rune colors, NOT readable by OCR
  final List<String> keywords;    // ["mercenary", "accelerate"]
  final List<String> tags;        // ["sivir"]
  final List<String> regionTags;  // ["noxus", "demacia"] — region tags readable by OCR
  final RiftCard card;

  const CardFingerprint({
    required this.cardId,
    required this.setId,
    this.collectorNumber,
    this.cnSuffix,
    required this.nameLower,
    this.titleLower,
    required this.fullNameLower,
    required this.rarity,
    this.energy,
    this.power,
    this.might,
    this.type,
    this.supertype,
    required this.domains,
    required this.keywords,
    required this.tags,
    required this.regionTags,
    required this.card,
  });

  /// Build fingerprint from a RiftCard.
  factory CardFingerprint.fromCard(RiftCard card) {
    // Split "Sivir, Mercenary" → name="sivir", title="mercenary"
    final parts = card.name.split(',');
    final name = parts.first.trim().toLowerCase();
    final title = parts.length > 1 ? parts.sublist(1).join(',').trim().toLowerCase() : null;

    // Parse collector number
    final cnRaw = card.collectorNumber ?? '';
    final cnDigits = cnRaw.replaceAll(RegExp(r'[^0-9]'), '');
    final cnNum = cnDigits.isNotEmpty ? int.tryParse(cnDigits) : null;
    final cnSuffix = RegExp(r'[a-z*]+$').firstMatch(cnRaw.toLowerCase())?.group(0);

    return CardFingerprint(
      cardId: card.id,
      setId: card.setId ?? '',
      collectorNumber: cnNum,
      cnSuffix: cnSuffix,
      nameLower: name,
      titleLower: title,
      fullNameLower: card.name.toLowerCase(),
      rarity: card.rarity ?? '',
      energy: card.energy,
      power: card.power,
      might: card.might,
      type: card.type,
      supertype: card.supertype,
      domains: card.domains.map((d) => d.toLowerCase()).toList(),
      keywords: card.keywords.map((k) => k.toLowerCase()).toList(),
      tags: card.tags.map((t) => t.toLowerCase()).toList(),
      regionTags: card.tags
          .map((t) => t.toLowerCase())
          .where((t) => _regionNames.contains(t))
          .toList(),
      card: card,
    );
  }

  /// Known region/faction names that appear as text on cards.
  static const _regionNames = {
    'noxus', 'demacia', 'piltover', 'zaun', 'shurima', 'ionia',
    'freljord', 'bilgewater', 'shadow isles', 'targon', 'bandle city',
    'ixtal', 'void',
  };
}

/// Extracted data points from one OCR frame.
class OcrExtraction {
  final String? setCode;
  final int? collectorNumber;
  final String? cnSuffix;
  final String? cnRaw;            // raw CN string for fuzzy
  final bool cnHasSetPrefix;     // true if CN was found WITH set code prefix
  final Set<String> namesFound;   // known card names found in text
  final Set<String> keywordsFound;
  final Set<String> typesFound;   // "spell", "unit", "gear", "rune" etc.
  final Set<String> regionsFound; // "noxus", "demacia", "piltover" etc.
  final int? manaCost;
  final String rawTextLower;
  final String fuzzyTextLower;   // current frame only (for fuzzyContains — not cumulated)
  final String? softSetHint;    // Levenshtein-1 resolved set (e.g. "SED"→"SFD"), not cumulated

  const OcrExtraction({
    this.setCode,
    this.collectorNumber,
    this.cnSuffix,
    this.cnRaw,
    this.cnHasSetPrefix = true,
    required this.namesFound,
    required this.keywordsFound,
    required this.typesFound,
    required this.regionsFound,
    this.manaCost,
    required this.rawTextLower,
    this.fuzzyTextLower = '',
    this.softSetHint,
  });
}

/// Scored match result.
class ScoredMatch {
  final CardFingerprint fingerprint;
  final int score;
  final Map<String, int> breakdown; // "cn" → 50, "name" → 20, etc.

  const ScoredMatch({
    required this.fingerprint,
    required this.score,
    required this.breakdown,
  });
}

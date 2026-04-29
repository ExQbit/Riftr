import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../models/card_fingerprint.dart';
import 'card_service.dart';

/// Scan result from OCR CN parsing.
class ScanResult {
  final String setCode;
  final String number;
  final String? suffix;

  const ScanResult({required this.setCode, required this.number, this.suffix});

  String get lookupKey => '$setCode-$number${suffix ?? ''}';
  String get baseKey => '$setCode-$number';
  int? get numericValue => int.tryParse(number.replaceFirst(RegExp(r'^0+'), ''));

  @override
  String toString() => lookupKey;
}

// ══════════════════════════════════════════════
// ── Top-level functions for compute() isolate ──
// ══════════════════════════════════════════════

/// Payload sent to the scoring isolate.
class _ScoringPayload {
  final List<CardFingerprint> candidates;
  final OcrExtraction extraction;
  final Set<String> cnFuzzyIds; // cardIds that matched via fuzzy CN keys
  final int minScore;

  const _ScoringPayload({
    required this.candidates,
    required this.extraction,
    required this.cnFuzzyIds,
    required this.minScore,
  });
}

/// Map internal setId to what OCR reads on the physical card.
String _ocrSetCode(String setId) => switch (setId) {
  'OGN' || 'OGNX' || 'OGSX' => 'OGN',
  'SFD' || 'SFDX' => 'SFD',
  'OGS' => 'OGS',
  'UNL' => 'UNL',
  _ => setId,
};

/// Top-level entry point for compute() — scores all candidates in a separate isolate.
List<ScoredMatch> _scoreCandidatesIsolate(_ScoringPayload payload) {
  final scored = <ScoredMatch>[];
  for (final fp in payload.candidates) {
    final result = _scoreCandidateStatic(fp, payload.extraction, payload.cnFuzzyIds);
    if (result.score >= payload.minScore) {
      scored.add(result);
    }
  }
  scored.sort((a, b) {
    final cmp = b.score.compareTo(a.score);
    if (cmp != 0) return cmp;
    // Tiebreaker: name match wins
    final aName = a.breakdown.containsKey('name') || a.breakdown.containsKey('name_fuzzy') ? 1 : 0;
    final bName = b.breakdown.containsKey('name') || b.breakdown.containsKey('name_fuzzy') ? 1 : 0;
    return bName.compareTo(aName);
  });
  return scored;
}

/// Score a single candidate against the extraction.
/// Uses [cnFuzzyIds] instead of live _cnIndex lookup (isolate-safe).
/// Uses [extraction.fuzzyTextLower] for fuzzyContains (current frame only).
ScoredMatch _scoreCandidateStatic(CardFingerprint fp, OcrExtraction extraction, Set<String> cnFuzzyIds) {
  int score = 0;
  final breakdown = <String, int>{};

  // ── CN match (50 exact with set, 25 fuzzy or without set prefix) ──
  if (extraction.collectorNumber != null && extraction.setCode != null) {
    final ocrSet = extraction.setCode!;
    final fpSet = _ocrSetCode(fp.setId);
    final cnPoints = extraction.cnHasSetPrefix ? 50 : 25;
    if (fpSet == ocrSet && fp.collectorNumber == extraction.collectorNumber) {
      score += cnPoints;
      breakdown[cnPoints == 50 ? 'cn' : 'cn_noset'] = cnPoints;
    } else if (fpSet == ocrSet && cnFuzzyIds.contains(fp.cardId)) {
      score += 25;
      breakdown['cn_fuzzy'] = 25;
    }
  }

  // ── Name match (20 exact, 15 fuzzy) ──
  // fuzzyContains uses fuzzyTextLower (current frame only)
  if (extraction.namesFound.contains(fp.nameLower)) {
    score += 20;
    breakdown['name'] = 20;
  } else if (fp.nameLower.length >= 5) {
    final maxDist = fp.nameLower.length ~/ 4;
    if (maxDist >= 1 && CardLookupService.fuzzyContains(extraction.fuzzyTextLower, fp.nameLower, maxDist: maxDist)) {
      score += 15;
      breakdown['name_fuzzy'] = 15;
    }
  }

  // ── Title match (15 points) ──
  if (fp.titleLower != null) {
    final title = fp.titleLower!;
    if (extraction.rawTextLower.contains(title)) {
      score += 15;
      breakdown['title'] = 15;
    } else {
      final titleNoSpace = title.replaceAll(' ', '');
      final textNoSpace = extraction.rawTextLower.replaceAll(' ', '');
      if (titleNoSpace.length >= 4 && textNoSpace.contains(titleNoSpace)) {
        score += 15;
        breakdown['title'] = 15;
      } else if (title.length >= 5) {
        final titleMaxDist = title.length ~/ 4;
        if (titleMaxDist >= 1 && CardLookupService.fuzzyContains(extraction.fuzzyTextLower, title, maxDist: titleMaxDist)) {
          score += 15;
          breakdown['title_fuzzy'] = 15;
        }
      }
    }
  }

  // ── Set code match (10 points) ──
  if (extraction.setCode != null && _ocrSetCode(fp.setId) == extraction.setCode) {
    score += 10;
    breakdown['set'] = 10;
  } else {
    final fpSet = _ocrSetCode(fp.setId);
    final setVars = CardLookupService.setCodeVariants(fpSet);
    if (setVars.any((v) => extraction.rawTextLower.contains(v))) {
      score += 10;
      breakdown['set'] = 10;
    }
  }

  // ── Keyword match (10 points) ──
  bool kwMatch = fp.keywords.any((k) => extraction.keywordsFound.contains(k));
  if (!kwMatch) {
    kwMatch = fp.keywords.any((fpKw) =>
        extraction.keywordsFound.any((ocrKw) => CardLookupService.levenshtein(fpKw, ocrKw) <= 1));
  }
  if (!kwMatch) {
    // fuzzyContains on current frame text only
    kwMatch = fp.keywords.where((k) => k.length >= 5).any((fpKw) =>
        CardLookupService.fuzzyContains(extraction.fuzzyTextLower, fpKw));
  }
  if (kwMatch) {
    score += 10;
    breakdown['keywords'] = 10;
  }

  // ── Card type match (5 points) ──
  final fpType = fp.type?.toLowerCase() ?? '';
  final fpFull = fp.supertype != null ? '${fp.supertype!.toLowerCase()} $fpType' : fpType;
  bool typeMatch = extraction.typesFound.any((t) => fpFull.contains(t) || fpType == t);
  if (!typeMatch) {
    typeMatch = CardLookupService.typeVariants(fpType).any((v) => extraction.rawTextLower.contains(v));
  }
  if (typeMatch) {
    score += 5;
    breakdown['type'] = 5;
  } else if (extraction.typesFound.isNotEmpty && fpType.isNotEmpty) {
    score -= 15;
    breakdown['type_mismatch'] = -15;
  }

  // ── Region/tag match (5 points) ──
  if (fp.regionTags.any((r) => extraction.regionsFound.contains(r))) {
    score += 5;
    breakdown['region'] = 5;
  }

  // ── Mana cost match (5 points) ──
  if (extraction.manaCost != null && fp.energy == extraction.manaCost) {
    score += 5;
    breakdown['mana'] = 5;
  }

  // ── CN cross-validation penalty ──
  if (breakdown.containsKey('cn') || breakdown.containsKey('cn_fuzzy') || breakdown.containsKey('cn_noset')) {
    final cnKey = breakdown.containsKey('cn') ? 'cn' : (breakdown.containsKey('cn_noset') ? 'cn_noset' : 'cn_fuzzy');
    final cnPoints = breakdown[cnKey] ?? 0;
    final hasNameSignal = breakdown.containsKey('name') || breakdown.containsKey('name_fuzzy')
        || breakdown.containsKey('title') || breakdown.containsKey('title_fuzzy');
    if (cnPoints > 0 && !hasNameSignal) {
      final namePrefix = fp.nameLower.length >= 6 ? fp.nameLower.substring(0, 6) : fp.nameLower;
      final prefixInText = extraction.rawTextLower.contains(namePrefix);
      if (!prefixInText) {
        score -= 30;
        breakdown['cn_penalty'] = -30;
      }
    }
  }

  // ── Promo set handling ──
  const promoSets = {'OGNX', 'SFDX', 'OGSX'};
  if (promoSets.contains(fp.setId)) {
    final hasPromoSignal = extraction.rawTextLower.contains('promo') ||
        extraction.rawTextLower.contains('alt art') ||
        extraction.rawTextLower.contains('signature') ||
        extraction.rawTextLower.contains('collector') ||
        extraction.rawTextLower.contains('nexus night');
    if (hasPromoSignal) {
      score += 10;
      breakdown['promo_signal'] = 10;
    } else {
      score -= 5;
      breakdown['promo_penalty'] = -5;
    }
  }

  return ScoredMatch(fingerprint: fp, score: score, breakdown: breakdown);
}

/// Generate CN candidate keys for fuzzy matching.
List<String> _cnCandidateKeys(String set, int cn, String suffix) {
  final keys = <String>[
    '$set-$cn$suffix',
    '$set-$cn',
    '$set-${cn.toString().padLeft(3, '0')}$suffix',
  ];

  // OCR digit loss: "04" could be 84, 104 etc.
  if (cn < 100) {
    for (int d = 1; d <= 9; d++) {
      final candidate = cn < 10 ? d * 10 + cn : d * 100 + cn;
      keys.add('$set-$candidate$suffix');
      keys.add('$set-$candidate');
    }
  }

  return keys;
}

// ══════════════════════════════════════════════
// ── CardLookupService ──
// ══════════════════════════════════════════════

/// Fingerprint-based card lookup with multi-point scoring.
class CardLookupService {
  CardLookupService._();
  static final CardLookupService instance = CardLookupService._();

  List<CardFingerprint> _fingerprints = [];
  Map<String, List<CardFingerprint>> _cnIndex = {};
  Map<String, List<CardFingerprint>> _nameIndex = {};
  Map<String, List<CardFingerprint>> _keywordIndex = {};

  // Known values for extraction
  Set<String> _allKeywords = {};
  Set<String> _allRegions = {};

  bool get isReady => _fingerprints.isNotEmpty;

  /// All known card types for OCR extraction.
  static const cardTypes = {
    'spell', 'unit', 'gear', 'rune', 'battlefield', 'legend',
    'champion unit', 'champion', 'token',
  };

  /// Region/faction names that appear as text on cards (NOT rune domains).
  static const regionNames = {
    'noxus', 'demacia', 'piltover', 'zaun', 'shurima', 'ionia',
    'freljord', 'bilgewater', 'shadow isles', 'targon', 'bandle city',
    'ixtal', 'void', 'yordle', 'dragon',
  };

  /// Build fingerprint database from loaded cards.
  void build() {
    final lookup = CardService.getLookup();
    if (lookup.isEmpty) return;

    final fps = <CardFingerprint>[];
    final cnIdx = <String, List<CardFingerprint>>{};
    final nameIdx = <String, List<CardFingerprint>>{};
    final kwIdx = <String, List<CardFingerprint>>{};
    final allKw = <String>{};

    // Deduplicate: getLookup() stores cards by both ID and name,
    // so the same card appears twice. Use a seen-set on card.id to skip dupes.
    final seen = <String>{};
    for (final card in lookup.values) {
      if (!seen.add(card.id)) continue; // already processed this card

      final fp = CardFingerprint.fromCard(card);
      fps.add(fp);

      // CN index: map OCR set code + number
      if (fp.collectorNumber != null) {
        final ocrSet = _ocrSetCode(fp.setId);
        final cn = fp.collectorNumber!;
        final suffix = fp.cnSuffix ?? '';

        // Store multiple key variants
        final keys = <String>{
          '$ocrSet-$cn$suffix',
          '$ocrSet-$cn',
        };
        // With leading zero padding
        final padded = cn.toString().padLeft(3, '0');
        keys.add('$ocrSet-$padded$suffix');

        for (final key in keys) {
          (cnIdx[key] ??= []).add(fp);
        }
      }

      // Name index: full name + first part (before comma)
      (nameIdx[fp.nameLower] ??= []).add(fp);
      if (fp.titleLower != null) {
        (nameIdx[fp.fullNameLower] ??= []).add(fp);
      }

      // Keyword index
      for (final kw in fp.keywords) {
        (kwIdx[kw] ??= []).add(fp);
        allKw.add(kw);
      }
    }

    _fingerprints = fps;
    _cnIndex = cnIdx;
    _nameIndex = nameIdx;
    _keywordIndex = kwIdx;
    _allKeywords = allKw;
    _allRegions = regionNames;

    debugPrint('CardLookup: ${fps.length} fingerprints, ${cnIdx.length} CN keys, '
        '${nameIdx.length} name keys, ${kwIdx.length} keyword keys');
  }

  /// Fix common OCR misreads in set codes.
  static String fixSetCode(String raw) => switch (raw.toUpperCase()) {
    'SFO' || 'SFE' || 'SF0' || 'S0' || 'SO' || 'SD' || 'SED' => 'SFD',
    'OGM' || '0GN' || 'OGH' || 'O6N' || '06N' || 'DGN' || '0N' || 'GN' => 'OGN',
    'OG5' || '0GS' || '0G5' || 'O6S' || '06S' || '065' || 'O65' || 'D6S' || 'DGS' => 'OGS',
    _ => raw.toUpperCase(),
  };

  /// Known OCR set codes (targets for soft alias resolution).
  static const _knownOcrSets = {'OGN', 'SFD', 'OGS', 'UNL'};

  /// Resolve an unknown set prefix via Levenshtein distance 1.
  /// Returns the known set code or null if no match.
  static String? softAliasResolve(String rawSet) {
    final upper = rawSet.toUpperCase();
    if (_knownOcrSets.contains(upper)) return null; // already known, no alias needed
    for (final known in _knownOcrSets) {
      if (levenshtein(upper, known) == 1) return known;
    }
    return null;
  }

  /// All known keywords (lowercase) for extraction.
  Set<String> get allKeywords => _allKeywords;
  Set<String> get allRegions => _allRegions;

  /// Name index for external access (OCR name matching + alternatives).
  Map<String, List<CardFingerprint>> get nameIndex => _nameIndex;

  // ══════════════════════════════════════════════
  // ── Score-based matching (async — runs in isolate) ──
  // ══════════════════════════════════════════════

  /// Find best matching cards using multi-point scoring.
  /// Phase 1 (main thread): collect candidates from indices.
  /// Phase 2 (compute isolate): score all candidates.
  Future<List<ScoredMatch>> findBestMatches(OcrExtraction extraction, {int minScore = 25}) async {
    // ── Phase 1: Collect candidates (main thread, fast map lookups) ──
    final candidateMap = <String, CardFingerprint>{};
    final cnFuzzyIds = <String>{};

    // Track resolved set for scoring (may differ from extraction.setCode)
    var resolvedSetCode = extraction.setCode;

    // From CN index (highest priority)
    if (extraction.collectorNumber != null && extraction.setCode != null) {
      final set = extraction.setCode!;
      final cn = extraction.collectorNumber!;
      final suffix = extraction.cnSuffix ?? '';

      for (final key in _cnCandidateKeys(set, cn, suffix)) {
        for (final fp in _cnIndex[key] ?? []) {
          candidateMap.putIfAbsent(fp.cardId, () => fp);
          cnFuzzyIds.add(fp.cardId); // pre-tag for isolate
        }
      }
    }

    // Soft-alias: CN extracted with unknown set prefix → try resolved set
    if (candidateMap.isEmpty && extraction.collectorNumber != null && extraction.softSetHint != null) {
      final resolved = extraction.softSetHint!;
      final cn = extraction.collectorNumber!;
      final suffix = extraction.cnSuffix ?? '';

      for (final key in _cnCandidateKeys(resolved, cn, suffix)) {
        for (final fp in _cnIndex[key] ?? []) {
          candidateMap.putIfAbsent(fp.cardId, () => fp);
          cnFuzzyIds.add(fp.cardId);
        }
      }

      // Corroborate: name from extraction matches a card in the resolved set
      if (candidateMap.isNotEmpty) {
        final hasNameSignal = extraction.namesFound.any((n) =>
            _nameIndex[n]?.any((fp) => _ocrSetCode(fp.setId) == resolved) == true);
        if (hasNameSignal) {
          resolvedSetCode = resolved;
          debugPrint('Scanner: Soft-alias accepted → $resolved (name corroborated)');
        } else {
          candidateMap.clear();
          cnFuzzyIds.clear();
          debugPrint('Scanner: Soft-alias rejected → $resolved (no name corroboration)');
        }
      }
    }

    // From name index
    for (final name in extraction.namesFound) {
      for (final fp in _nameIndex[name] ?? []) {
        candidateMap.putIfAbsent(fp.cardId, () => fp);
      }
    }

    // From keyword index — only as gap-filler when CN+Name found < 20
    if (candidateMap.length < 20) {
      for (final kw in extraction.keywordsFound) {
        if (candidateMap.length >= 20) break;
        for (final fp in _keywordIndex[kw] ?? []) {
          if (candidateMap.length >= 20) break;
          candidateMap.putIfAbsent(fp.cardId, () => fp);
        }
      }
    }

    if (candidateMap.isEmpty) return [];

    // Metal-Cards Exclusion (User-Request 2026-04-29):
    // PLATED_LEGEND (Metal) sind extrem teure Sammlerkarten — niemand
    // scannt sie real-world. Scanner soll sie nie als Primary-Match
    // ausgeben. Sie bleiben in `_nameIndex` (fuer den Variant-Picker
    // post-scan via _acceptMatch.allVariants), werden aber HIER vor
    // dem Scoring rausgefiltert, sodass sie nie Top-1 sein koennen.
    final metalCount = candidateMap.values.where((fp) => fp.card.metal).length;
    if (metalCount > 0) {
      candidateMap.removeWhere((_, fp) => fp.card.metal);
      debugPrint('Scanner: filtered $metalCount metal candidate(s) from scoring');
    }
    if (candidateMap.isEmpty) return [];

    debugPrint('Scanner: ${candidateMap.length} candidates for scoring');

    // ── Phase 2: Score in isolate (off main thread) ──
    // If soft alias resolved, update extraction with resolved set for scoring
    final scoringExtraction = resolvedSetCode != extraction.setCode
        ? OcrExtraction(
            setCode: resolvedSetCode,
            collectorNumber: extraction.collectorNumber,
            cnSuffix: extraction.cnSuffix,
            cnRaw: extraction.cnRaw,
            cnHasSetPrefix: extraction.cnHasSetPrefix,
            namesFound: extraction.namesFound,
            keywordsFound: extraction.keywordsFound,
            typesFound: extraction.typesFound,
            regionsFound: extraction.regionsFound,
            manaCost: extraction.manaCost,
            rawTextLower: extraction.rawTextLower,
            fuzzyTextLower: extraction.fuzzyTextLower,
            softSetHint: extraction.softSetHint,
          )
        : extraction;

    final scored = await compute(
      _scoreCandidatesIsolate,
      _ScoringPayload(
        candidates: candidateMap.values.toList(),
        extraction: scoringExtraction,
        cnFuzzyIds: cnFuzzyIds,
        minScore: minScore,
      ),
    );
    return scored;
  }

  // ══════════════════════════════════════════════
  // ── Legacy API (kept for compatibility) ──
  // ══════════════════════════════════════════════

  Future<RiftCard?> findPrimaryCard(ScanResult scan) async {
    final extraction = OcrExtraction(
      setCode: scan.setCode,
      collectorNumber: scan.numericValue,
      cnSuffix: scan.suffix,
      cnRaw: scan.number,
      namesFound: const {},
      keywordsFound: const {},
      typesFound: const {},
      regionsFound: const {},
      rawTextLower: '',
    );
    final matches = await findBestMatches(extraction, minScore: 40);
    return matches.isNotEmpty ? matches.first.fingerprint.card : null;
  }

  Future<List<RiftCard>> getAlternatives(ScanResult scan) async {
    final primary = await findPrimaryCard(scan);
    if (primary == null) return [];
    final fps = _nameIndex[primary.name.toLowerCase()] ?? [];
    return fps.where((fp) => fp.cardId != primary.id).map((fp) => fp.card).toList();
  }

  // ══════════════════════════════════════════════
  // ── Fuzzy matching helpers (static — isolate-safe) ──
  // ══════════════════════════════════════════════

  /// Common OCR misreads for set codes. Returns lowercase variants to search in text.
  static List<String> setCodeVariants(String set) => switch (set) {
    'OGN' => ['ogn', 'o6n', 'ogm', 'ogh', '0gn'],
    'SFD' => ['sfd', 'sfo', 'sfe', 'sf0', 'sfo-', 'sfd-'],
    'OGS' => ['ogs', 'og5', '0gs'],
    'UNL' => ['unl', 'unl-'],
    _ => [set.toLowerCase()],
  };

  /// Common OCR misreads for card types.
  static List<String> typeVariants(String type) => switch (type) {
    'spell' => ['spell', 'spel', 'speli', 'speul'],
    'unit' => ['unit', 'unlt', 'uwit', 'unt'],
    'gear' => ['gear', 'geat', 'geai', 'goar'],
    'rune' => ['rune', 'bune', 'aune'],
    'legend' => ['legend', 'legand'],
    'battlefield' => ['battlefield', 'batlefield', 'battlefeld'],
    _ => [type],
  };

  /// Levenshtein distance between two strings.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final la = a.length, lb = b.length;
    // Use single-row optimization
    var prev = List.generate(lb + 1, (i) => i);
    var curr = List.filled(lb + 1, 0);

    for (int i = 1; i <= la; i++) {
      curr[0] = i;
      for (int j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[lb];
  }

  /// Check if `text` contains a fuzzy match for `word`.
  /// [maxDist] = max Levenshtein distance (default 1, use 2 for names).
  /// Slides a window of word.length ± maxDist across the text.
  static bool fuzzyContains(String text, String word, {int maxDist = 1}) {
    if (text.contains(word)) return true;
    final wl = word.length;
    for (int start = 0; start <= text.length - wl + maxDist; start++) {
      for (int len = wl - maxDist; len <= wl + maxDist && start + len <= text.length; len++) {
        if (len < 3) continue;
        final sub = text.substring(start, start + len);
        if (levenshtein(sub, word) <= maxDist) return true;
      }
    }
    return false;
  }
}

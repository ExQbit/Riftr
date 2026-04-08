class RiftCard {
  final String id;
  final String name;
  final String displayName;
  final String? riftboundId;
  final String? tcgplayerId;
  final String? publicCode;
  final String? collectorNumber;
  final int? energy;
  final int? might;
  final int? power;
  final String? type;
  final String? supertype;
  final String? rarity;
  final List<String> domains;
  final String? textPlain;
  final String? imageUrl;
  final String? setId;
  final String? setLabel;
  final String orientation;
  final bool alternateArt;
  final bool overnumbered;
  final bool signature;
  final bool metal;
  final int? deckLimit;
  final List<String> keywords;
  final List<String> tags;

  const RiftCard({
    required this.id,
    required this.name,
    required this.displayName,
    this.riftboundId,
    this.tcgplayerId,
    this.publicCode,
    this.collectorNumber,
    this.energy,
    this.might,
    this.power,
    this.type,
    this.supertype,
    this.rarity,
    this.domains = const [],
    this.textPlain,
    this.imageUrl,
    this.setId,
    this.setLabel,
    this.orientation = 'portrait',
    this.alternateArt = false,
    this.overnumbered = false,
    this.signature = false,
    this.metal = false,
    this.deckLimit,
    this.keywords = const [],
    this.tags = const [],
  });

  factory RiftCard.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? {};
    final classification = json['classification'] as Map<String, dynamic>? ?? {};
    final text = json['text'] as Map<String, dynamic>? ?? {};
    final media = json['media'] as Map<String, dynamic>? ?? {};
    final setData = json['set'] as Map<String, dynamic>? ?? {};
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    final plainText = text['plain'] as String? ?? '';
    final keywordRegex = RegExp(r'\[(\w+)\]');
    final keywords = keywordRegex
        .allMatches(plainText)
        .map((m) {
          final k = m.group(1)!;
          return k[0].toUpperCase() + k.substring(1).toLowerCase();
        })
        .toSet()
        .toList();

    final domainList = classification['domain'] as List<dynamic>? ?? [];
    final tagList = json['tags'] as List<dynamic>? ?? [];

    return RiftCard(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
      riftboundId: json['riftbound_id'] as String?,
      tcgplayerId: json['tcgplayer_id'] as String?,
      publicCode: json['public_code'] as String?,
      collectorNumber: json['collector_number']?.toString(),
      energy: attrs['energy'] as int?,
      might: attrs['might'] as int?,
      power: attrs['power'] as int?,
      type: classification['type'] as String?,
      supertype: classification['supertype'] as String?,
      rarity: classification['rarity'] as String?,
      domains: domainList.map((d) => d.toString()).toList(),
      textPlain: plainText.isEmpty ? null : plainText,
      imageUrl: media['image_url'] as String?,
      setId: setData['set_id'] as String?,
      setLabel: setData['label'] as String?,
      orientation: json['orientation'] as String? ?? 'portrait',
      alternateArt: metadata['alternate_art'] as bool? ?? false,
      overnumbered: metadata['overnumbered'] as bool? ?? false,
      signature: metadata['signature'] as bool? ?? false,
      metal: metadata['metal'] as bool? ?? false,
      deckLimit: json['deck_limit'] as int?,
      keywords: keywords,
      tags: tagList.map((t) => t.toString()).toList(),
    );
  }

  /// Fake "Unknown" opponent legend
  factory RiftCard.unknown() => const RiftCard(id: '_unknown', name: 'Unknown', displayName: 'Unknown', type: 'Legend');

  /// Custom-named opponent legend
  factory RiftCard.custom(String name) => RiftCard(id: '_custom_$name', name: name, displayName: name, type: 'Legend');

  /// Numeric part of collector number for sorting (e.g. "195a" → 195)
  int get collectorNumberInt => int.tryParse(
      (collectorNumber ?? '0').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get isLegend => type == 'Legend';
  bool get isChampion => supertype == 'Champion';
  bool get isBattlefield => type == 'Battlefield';

  /// The primary champion tag (e.g. 'Jinx', 'Jax') — first element of tags.
  String? get championTag => tags.isNotEmpty ? tags.first : null;
  bool get isLandscape => orientation == 'landscape';
  bool get isStandard => !alternateArt && !overnumbered && !signature;
  bool get isPromo => setId == 'OGNX' || setId == 'SFDX' || setId == 'OGSX';
  bool get isChampionEdition => riftboundId?.contains('champion') ?? false;
  bool get isMetal => metal;
  bool get isToken => type == 'Token';
  bool get isSpecialVariant => isPromo || isMetal;
  String? get primaryDomain => domains.isNotEmpty ? domains.first : null;
}

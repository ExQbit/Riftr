import 'price_point.dart';

class CardPriceData {
  final String cardId;
  final String cardName;
  final String? imageUrl;
  final String? rarity;
  final String? setId;
  final String? cardType;
  final double currentPrice;
  final double previousClose;
  final double dayChange;     // percentage
  final double weekChange;    // percentage
  final double monthChange;   // percentage
  final double low30d;
  final double high30d;
  final double foilPrice;     // 0 if no foil data
  final double nonFoilPrice;  // 0 if no non-foil data
  // Per-variant stats (from Cardmarket price guide)
  final double foilLow;          // lowest foil listing
  final double nonFoilLow;       // lowest non-foil listing
  final double foilTrend;        // foil trend price
  final double nonFoilTrend;     // non-foil trend price
  final double foilDayChange;    // foil 24h change %
  final double nonFoilDayChange; // non-foil 24h change %
  final double foilWeekChange;   // foil vs 7d avg %
  final double nonFoilWeekChange;// non-foil vs 7d avg %
  final double foilMonthChange;  // foil vs 30d avg %
  final double nonFoilMonthChange;// non-foil vs 30d avg %
  final List<PricePoint> priceHistory; // up to 365 daily points (foil/primary)
  final List<PricePoint> nonFoilHistory; // non-foil price history
  final List<PricePoint> sparkline;    // last 30 points for list tiles
  final DateTime lastUpdated;

  double get dayChangeAbs => currentPrice - previousClose;
  bool get isPositive => dayChange >= 0;
  double get totalValue => currentPrice; // single card value
  bool get hasFoilPrice => foilPrice > 0;
  bool get hasNonFoilPrice => nonFoilPrice > 0;
  bool get hasBothVariants => hasFoilPrice && hasNonFoilPrice;
  bool get isBattlefield => cardType?.toLowerCase() == 'battlefield';

  /// Variant-specific accessors — pass true for foil, false for non-foil.
  double getLow(bool foil) => foil ? foilLow : nonFoilLow;
  double getTrend(bool foil) => foil ? foilTrend : nonFoilTrend;
  double getPrice(bool foil) => foil ? foilPrice : nonFoilPrice;
  double getDayChange(bool foil) => foil ? foilDayChange : nonFoilDayChange;
  double getWeekChange(bool foil) => foil ? foilWeekChange : nonFoilWeekChange;
  double getMonthChange(bool foil) => foil ? foilMonthChange : nonFoilMonthChange;

  /// Whether this card's standard variant is non-foil.
  /// OGS cards are always non-foil. Common/Uncommon are non-foil.
  bool get _isNonFoilStandard {
    final s = (setId ?? '').toUpperCase();
    if (s == 'OGS') return true;
    final r = (rarity ?? '').toLowerCase();
    return r == 'common' || r == 'uncommon';
  }

  /// Standard variant price based on rarity/set.
  double get standardPrice {
    if (_isNonFoilStandard) {
      return nonFoilPrice > 0 ? nonFoilPrice : foilPrice;
    }
    return foilPrice > 0 ? foilPrice : nonFoilPrice;
  }

  /// Premium variant price (opposite of standard).
  double get premiumPrice {
    if (_isNonFoilStandard) {
      return foilPrice;
    }
    return nonFoilPrice;
  }

  /// Label for the standard variant.
  String get standardLabel {
    return _isNonFoilStandard ? 'Non-Foil' : 'Foil';
  }

  /// Label for the premium variant.
  String get premiumLabel {
    return _isNonFoilStandard ? 'Foil' : 'Non-Foil';
  }

  const CardPriceData({
    required this.cardId,
    required this.cardName,
    this.imageUrl,
    this.rarity,
    this.setId,
    this.cardType,
    required this.currentPrice,
    required this.previousClose,
    required this.dayChange,
    required this.weekChange,
    required this.monthChange,
    required this.low30d,
    required this.high30d,
    this.foilPrice = 0,
    this.nonFoilPrice = 0,
    this.foilLow = 0,
    this.nonFoilLow = 0,
    this.foilTrend = 0,
    this.nonFoilTrend = 0,
    this.foilDayChange = 0,
    this.nonFoilDayChange = 0,
    this.foilWeekChange = 0,
    this.nonFoilWeekChange = 0,
    this.foilMonthChange = 0,
    this.nonFoilMonthChange = 0,
    required this.priceHistory,
    this.nonFoilHistory = const [],
    required this.sparkline,
    required this.lastUpdated,
  });

  /// Create from Firestore overview doc entry
  factory CardPriceData.fromFirestore(
    String cardId,
    Map<String, dynamic> data, {
    String? imageUrl,
    String? rarity,
    String? cardType,
  }) {
    final price = (data['p'] as num?)?.toDouble() ?? 0;
    final change24 = (data['c24'] as num?)?.toDouble() ?? 0;
    // Estimate previousClose from current price and 24h change %
    final prevClose = change24 != 0 ? price / (1 + change24 / 100) : price;

    return CardPriceData(
      cardId: cardId,
      cardName: data['n'] as String? ?? '',
      imageUrl: imageUrl,
      rarity: rarity ?? (data['r'] as String?),
      setId: data['s'] as String?,
      cardType: cardType,
      currentPrice: price,
      previousClose: prevClose,
      dayChange: change24,
      weekChange: (data['c7'] as num?)?.toDouble() ?? 0,
      monthChange: (data['c30'] as num?)?.toDouble() ?? 0,
      low30d: (data['l30'] as num?)?.toDouble() ?? price,
      high30d: (data['h30'] as num?)?.toDouble() ?? price,
      foilPrice: (data['pF'] as num?)?.toDouble() ?? 0,
      nonFoilPrice: (data['pNf'] as num?)?.toDouble() ?? 0,
      foilLow: (data['l30F'] as num?)?.toDouble() ?? 0,
      nonFoilLow: (data['l30Nf'] as num?)?.toDouble() ?? 0,
      foilTrend: (data['tF'] as num?)?.toDouble() ?? 0,
      nonFoilTrend: (data['tNf'] as num?)?.toDouble() ?? 0,
      foilDayChange: (data['c24F'] as num?)?.toDouble() ?? 0,
      nonFoilDayChange: (data['c24Nf'] as num?)?.toDouble() ?? 0,
      foilWeekChange: (data['c7F'] as num?)?.toDouble() ?? 0,
      nonFoilWeekChange: (data['c7Nf'] as num?)?.toDouble() ?? 0,
      foilMonthChange: (data['c30F'] as num?)?.toDouble() ?? 0,
      nonFoilMonthChange: (data['c30Nf'] as num?)?.toDouble() ?? 0,
      priceHistory: const [], // loaded lazily from market_history
      nonFoilHistory: const [],
      sparkline: _parseSparkline(data['sp']),
      lastUpdated: DateTime.now(),
    );
  }

  static List<PricePoint> _parseSparkline(dynamic sp) {
    // sp is a comma-separated string of prices: "0.5,0.6,0.7,..."
    if (sp is! String || sp.isEmpty) return const [];
    final parts = sp.split(',');
    if (parts.length < 2) return const [];
    return List.generate(parts.length, (i) {
      final price = double.tryParse(parts[i]) ?? 0;
      return PricePoint(
        date: DateTime.now().subtract(Duration(days: parts.length - 1 - i)),
        price: price,
      );
    });
  }

  CardPriceData copyWith({
    String? cardId,
    String? cardName,
    String? imageUrl,
    String? rarity,
    String? setId,
    String? cardType,
    double? currentPrice,
    double? previousClose,
    double? dayChange,
    List<PricePoint>? priceHistory,
    List<PricePoint>? nonFoilHistory,
    List<PricePoint>? sparkline,
  }) {
    return CardPriceData(
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      imageUrl: imageUrl ?? this.imageUrl,
      rarity: rarity ?? this.rarity,
      setId: setId ?? this.setId,
      cardType: cardType ?? this.cardType,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClose: previousClose ?? this.previousClose,
      dayChange: dayChange ?? this.dayChange,
      weekChange: weekChange,
      monthChange: monthChange,
      low30d: low30d,
      high30d: high30d,
      foilPrice: foilPrice,
      nonFoilPrice: nonFoilPrice,
      foilLow: foilLow,
      nonFoilLow: nonFoilLow,
      foilTrend: foilTrend,
      nonFoilTrend: nonFoilTrend,
      foilDayChange: foilDayChange,
      nonFoilDayChange: nonFoilDayChange,
      foilWeekChange: foilWeekChange,
      nonFoilWeekChange: nonFoilWeekChange,
      foilMonthChange: foilMonthChange,
      nonFoilMonthChange: nonFoilMonthChange,
      priceHistory: priceHistory ?? this.priceHistory,
      nonFoilHistory: nonFoilHistory ?? this.nonFoilHistory,
      sparkline: sparkline ?? this.sparkline,
      lastUpdated: lastUpdated,
    );
  }
}

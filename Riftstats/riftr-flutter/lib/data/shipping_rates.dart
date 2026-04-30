// AUTO-GENERATED from Cardmarket help.cardmarket.com/api/shippingCosts
// Source data: scripts/cardmarket-scraper/output/rates-mapped.json
// Scraper:     scripts/cardmarket-scraper/scrape-all.js
// Generator:   scripts/cardmarket-scraper/generate-dart.js
// Reverse-engineering doc: docs/cardmarket-api-reverse-engineering.md
//
// To update: run the scraper, then this generator. Manual edits below
// will be overwritten on the next regenerate.
//
// Fetched: 2026-04-25T23:55:18.823Z
// Re-mapped: 2026-04-26T07:23:50.999Z
// Routes: 1024 of 1024

/// Shipping method options for marketplace listings.
/// Mirrors the canonical Cardmarket categories from the buyer's POV
/// (the actual postal product chosen depends on order weight + value;
/// see ShippingRoute.source for the underlying carrier product name).
enum ShippingMethod { letter, tracked, insured }

extension ShippingMethodExt on ShippingMethod {
  String get label => switch (this) {
        ShippingMethod.letter => 'Brief',
        ShippingMethod.tracked => 'Einschreiben',
        ShippingMethod.insured => 'Versichert',
      };

  String get shortLabel => switch (this) {
        ShippingMethod.letter => 'Letter',
        ShippingMethod.tracked => 'Tracked',
        ShippingMethod.insured => 'Insured',
      };
}

/// One picked Cardmarket shipping product for a (origin, destination, tier)
/// triple. `maxCards` is the realistic card-fit per Cardmarket's FAQ
/// (Standardbrief→4, Kompaktbrief→17, Großbrief→40; other origins fall
/// back to weight brackets at ~2.5g/card). `source` is the original
/// Cardmarket product name kept for debugging and seller-side display.
class ShippingRoute {
  final double price;
  final int maxCards;
  final String source;
  const ShippingRoute({required this.price, required this.maxCards, required this.source});
}

/// All available shipping options on a single (origin → destination) route.
///
/// Letter is a list — most postal services publish multiple letter sub-tiers
/// (Standardbrief/Kompaktbrief/Großbrief in DE, 1st/2nd/Large in GB, etc.).
/// Sorted ascending by [ShippingRoute.maxCards] AND ascending by price (the
/// two correlate since heavier letters cost more), so the optimizer can
/// stop at the first tier whose maxCards covers the bundle and that's
/// also the cheapest fit.
///
/// Tracked and insured stay singular per route — the picker for those
/// already collapsed to one product per route in the mapper.
class RouteOptions {
  final List<ShippingRoute> letterTiers;
  final ShippingRoute? tracked;
  final ShippingRoute? insured;
  const RouteOptions({
    required this.letterTiers,
    required this.tracked,
    required this.insured,
  });
}

class ShippingRates {
  ShippingRates._();

  /// Per-route shipping data scraped from Cardmarket.
  ///
  /// Lookup pattern: `_routes[sellerCountry]?[buyerCountry]`.
  /// Within the [RouteOptions], a `null` tracked/insured means the postal
  /// service doesn't offer that method on that route (e.g. Iceland has no
  /// international tracking). An empty `letterTiers` list means no letter
  /// option at all (rare; ES→CY/MT for instance). UI must branch on null.
  static const Map<String, Map<String, RouteOptions>> _routes = {
    'AT': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.3, maxCards: 4, source: 'Brief S'),
          ShippingRoute(price: 1.85, maxCards: 17, source: 'Brief M'),
        ],
        tracked: ShippingRoute(price: 7.38, maxCards: 400, source: 'Paket'),
        insured: ShippingRoute(price: 7.38, maxCards: 400, source: 'Paket'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.2, maxCards: 17, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 21.3, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.2, maxCards: 17, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 21.3, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.2, maxCards: 17, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 21.3, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.2, maxCards: 17, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 21.3, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.2, maxCards: 17, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 21.3, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.37, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.7, maxCards: 4, source: 'Priority Letter (M)')],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registered Letter (M Einschreiben)'),
        insured: ShippingRoute(price: 18.77, maxCards: 400, source: 'International Plus Parcel (Paket Plus International)'),
      ),
    },
    'BE': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.93, maxCards: 17, source: 'Lettre NON PRIOR'),
          ShippingRoute(price: 3.76, maxCards: 40, source: 'Lettre NON PRIOR'),
          ShippingRoute(price: 5.39, maxCards: 200, source: 'Lettre NON PRIOR'),
        ],
        tracked: ShippingRoute(price: 9.65, maxCards: 800, source: 'Insured Parcel (Online)'),
        insured: ShippingRoute(price: 9.65, maxCards: 800, source: 'Insured Parcel (Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.59, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 22.5, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 22.5, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.59, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 82.02, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.59, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 82.02, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.59, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 82.15, maxCards: 4000, source: 'Colis Standard + Garantie (Insured)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 22.5, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.85, maxCards: 4000, source: 'Colis Standard + Garantie (Insured)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 22.5, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.59, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 82.02, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.37, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 10.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 58.7, maxCards: 4000, source: 'Bpost Parcel - Standard 500€ insured'),
      ),
    },
    'BG': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 22.1, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 22.1, maxCards: 400, source: 'Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.03, maxCards: 17, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 1.31, maxCards: 40, source: 'Large Priority Letter (G)'),
          ShippingRoute(price: 1.44, maxCards: 100, source: 'Large Priority Letter (G)'),
          ShippingRoute(price: 1.57, maxCards: 200, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 1.73, maxCards: 17, source: 'Small Registered Priority Letter (P)'),
        insured: ShippingRoute(price: 5.3, maxCards: 400, source: 'Insured Parcel (400 Leva)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.9, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.9, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 23.68, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 23.68, maxCards: 400, source: 'Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.9, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.9, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.9, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 18.94, maxCards: 400, source: 'Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 19.99, maxCards: 400, source: 'Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.47, maxCards: 4, source: 'Small Priority Letter (P)'),
          ShippingRoute(price: 3.47, maxCards: 40, source: 'Large Priority Letter (G)'),
        ],
        tracked: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
        insured: ShippingRoute(price: 16.31, maxCards: 400, source: 'Parcel'),
      ),
    },
    'CH': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.86, maxCards: 40, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 2.42, maxCards: 200, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 3.32, maxCards: 400, source: 'Priority Letter (A-Post)'),
        ],
        tracked: ShippingRoute(price: 4.89, maxCards: 200, source: 'Tracked Letter (A-Post Plus)'),
        insured: ShippingRoute(price: 8.13, maxCards: 200, source: 'Registered Priority Letter'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.86, maxCards: 40, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 2.42, maxCards: 200, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 3.32, maxCards: 400, source: 'Priority Letter (A-Post)'),
        ],
        tracked: ShippingRoute(price: 4.89, maxCards: 200, source: 'Tracked Letter (A-Post Plus)'),
        insured: ShippingRoute(price: 8.13, maxCards: 200, source: 'Registered Priority Letter'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.56, maxCards: 40, source: 'Large Letter Small Goods (Maxibrief Kleinwaren)')],
        tracked: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
        insured: ShippingRoute(price: 13.17, maxCards: 40, source: 'Registered Large Letter Small Goods (Einschreiben)'),
      ),
    },
    'CY': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 0.71, maxCards: 17, source: 'Letter'),
          ShippingRoute(price: 1.04, maxCards: 40, source: 'Letter'),
          ShippingRoute(price: 1.1, maxCards: 100, source: 'Letter'),
          ShippingRoute(price: 2.2, maxCards: 200, source: 'Letter'),
          ShippingRoute(price: 2.3, maxCards: 400, source: 'Letter'),
          ShippingRoute(price: 2.6, maxCards: 800, source: 'Letter'),
        ],
        tracked: ShippingRoute(price: 2.92, maxCards: 40, source: 'Registered Letter'),
        insured: ShippingRoute(price: 6.4, maxCards: 2000, source: 'Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 0.94, maxCards: 4, source: 'First class Letter (Airmail)')],
        tracked: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
        insured: ShippingRoute(price: 18.5, maxCards: 400, source: 'Parcel (Airmail)'),
      ),
    },
    'CZ': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 25.73, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 27.93, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 25.73, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 27.93, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.63, maxCards: 17, source: 'Regular Letter'),
          ShippingRoute(price: 2.0, maxCards: 40, source: 'Regular Letter'),
          ShippingRoute(price: 2.17, maxCards: 200, source: 'Regular Letter'),
        ],
        tracked: ShippingRoute(price: 3.86, maxCards: 200, source: 'Registered Letter'),
        insured: ShippingRoute(price: 4.28, maxCards: 200, source: 'Insured Letter (Value 5.000 CZK)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter'),
          ShippingRoute(price: 3.35, maxCards: 40, source: 'Regular Letter'),
        ],
        tracked: ShippingRoute(price: 27.76, maxCards: 800, source: 'Registered Parcel (Value 12.000 CZK)'),
        insured: ShippingRoute(price: 27.76, maxCards: 800, source: 'Registered Parcel (Value 12.000 CZK)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 25.73, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 27.93, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 25.73, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 27.93, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter'),
          ShippingRoute(price: 3.35, maxCards: 40, source: 'Regular Letter'),
        ],
        tracked: ShippingRoute(price: 25.73, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 27.93, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 28.99, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 31.19, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter'),
          ShippingRoute(price: 3.35, maxCards: 40, source: 'Regular Letter'),
        ],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 13.72, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 15.92, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 28.99, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 31.19, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 26.11, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 28.31, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 19.56, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 21.76, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.34, maxCards: 17, source: 'Regular Letter')],
        tracked: ShippingRoute(price: 10.76, maxCards: 800, source: 'Priority Standard Parcel'),
        insured: ShippingRoute(price: 12.96, maxCards: 800, source: 'Insured Parcel (Value 13.000 CZK)'),
      ),
    },
    'DE': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 27.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 27.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.25, maxCards: 4, source: 'Standardbrief'),
          ShippingRoute(price: 1.4, maxCards: 17, source: 'Kompaktbrief'),
          ShippingRoute(price: 2.3, maxCards: 40, source: 'Grossbrief'),
        ],
        tracked: ShippingRoute(price: 3.95, maxCards: 17, source: 'Kompaktbrief + Einschreiben EINWURF'),
        insured: ShippingRoute(price: 7.19, maxCards: 800, source: 'DHL Paket (Online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 27.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 27.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
        insured: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
        insured: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
        insured: ShippingRoute(price: 30.99, maxCards: 2000, source: 'Registered Parcel (DHL Paket Welt Online)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.55, maxCards: 4, source: 'Letter (Standardbrief)')],
        tracked: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
        insured: ShippingRoute(price: 15.49, maxCards: 800, source: 'Registered Parcel (DHL Paket Online)'),
      ),
    },
    'DK': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.86, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 5.07, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 9.17, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 9.17, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 21.71, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 30.12, maxCards: 40, source: 'Registered Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.29, maxCards: 40, source: 'Registered Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 18.26, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 6.66, maxCards: 4, source: 'DAO Letter'),
          ShippingRoute(price: 6.86, maxCards: 40, source: 'DAO Letter'),
        ],
        tracked: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
        insured: ShippingRoute(price: 29.29, maxCards: 400, source: 'GLS Parcel (Online)'),
      ),
    },
    'EE': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.1, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 3.55, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 4.7, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 13.25, maxCards: 2000, source: 'Standard Parcel (Insurance 500€)'),
        insured: ShippingRoute(price: 13.25, maxCards: 2000, source: 'Standard Parcel (Insurance 500€)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 10.7, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 18.55, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 18.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 64.3, maxCards: 800, source: 'Insured Parcel (250€)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.2, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 12.05, maxCards: 100, source: 'Maxi Letter'),
          ShippingRoute(price: 17.9, maxCards: 200, source: 'Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 16.45, maxCards: 100, source: 'Registered Parcel'),
      ),
    },
    'ES': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.45, maxCards: 17, source: 'Carta Ordinaria (en buzón)'),
          ShippingRoute(price: 2.25, maxCards: 40, source: 'Carta Ordinaria (en buzón)'),
          ShippingRoute(price: 4.2, maxCards: 200, source: 'Carta Ordinaria (en buzón)'),
        ],
        tracked: ShippingRoute(price: 7.06, maxCards: 100, source: 'Paq Ligero Nacional (en buzón)'),
        insured: ShippingRoute(price: 26.65, maxCards: 400, source: 'Paquete Estándar (Valor declarado 200€)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 33.1, maxCards: 400, source: 'Paq Internacional Standard (Registered Parcel)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Carta ordinaria (Priority Letter)'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Carta ordinaria (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 20.15, maxCards: 100, source: 'Paq Light Internacional (Registered Parcel)'),
        insured: ShippingRoute(price: 34.75, maxCards: 400, source: 'Paq Standard (Registered Parcel)'),
      ),
    },
    'FI': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 6.4, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.05, maxCards: 17, source: 'Letter'),
          ShippingRoute(price: 6.0, maxCards: 100, source: 'Letter'),
          ShippingRoute(price: 11.5, maxCards: 200, source: 'Letter'),
        ],
        tracked: ShippingRoute(price: 8.9, maxCards: 800, source: 'Tracked Parcel XXS (Online)'),
        insured: ShippingRoute(price: 10.9, maxCards: 800, source: 'Postal Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 22.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 46.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 20.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.35, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 4.25, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 6.6, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 14.2, maxCards: 100, source: 'Priority Maxi Letter'),
          ShippingRoute(price: 21.8, maxCards: 200, source: 'Priority Maxi Letter'),
        ],
        tracked: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
        insured: ShippingRoute(price: 23.9, maxCards: 4000, source: 'Parcel S (online)'),
      ),
    },
    'FR': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Prioritaire (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Prioritaire (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 40, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.85, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.82, maxCards: 4, source: 'Lettre Verte'),
          ShippingRoute(price: 3.6, maxCards: 40, source: 'Lettre Verte'),
          ShippingRoute(price: 5.74, maxCards: 100, source: 'Lettre Verte'),
        ],
        tracked: ShippingRoute(price: 2.52, maxCards: 4, source: 'Lettre Verte Suivi'),
        insured: ShippingRoute(price: 10.17, maxCards: 17, source: 'Lettre Prioritaire Recommandé R3'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Prioritaire (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Prioritaire (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 40, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 21.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Prioritaire (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Prioritaire (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 24.4, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Prioritaire (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Prioritaire (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 40, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.85, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Prioritaire (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Prioritaire (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 24.4, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Lettre Internationale (Priority Letter)'),
          ShippingRoute(price: 5.35, maxCards: 40, source: 'Lettre Internationale (Priority Letter)'),
        ],
        tracked: ShippingRoute(price: 8.15, maxCards: 17, source: 'Lettre Suivie Internationale (Tracked Letter)'),
        insured: ShippingRoute(price: 17.99, maxCards: 200, source: 'Colissimo Ad Valorem 200€ (Insured Parcel)'),
      ),
    },
    'GB': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.36, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter'),
        insured: ShippingRoute(price: 19.18, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 15.37, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 15.37, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 15.37, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.4, maxCards: 4, source: 'UK Standard Letter (2nd Class)'),
          ShippingRoute(price: 2.37, maxCards: 40, source: 'UK Standard Large Letter (2nd Class)'),
          ShippingRoute(price: 2.79, maxCards: 100, source: 'UK Standard Large Letter (2nd Class)'),
          ShippingRoute(price: 3.38, maxCards: 200, source: 'UK Standard Large Letter (2nd Class)'),
        ],
        tracked: ShippingRoute(price: 4.75, maxCards: 40, source: 'UK Signed Large Letter (2nd Class Signed For)'),
        insured: ShippingRoute(price: 4.75, maxCards: 40, source: 'UK Signed Large Letter (2nd Class Signed For)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 15.37, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.36, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter'),
        insured: ShippingRoute(price: 19.18, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.36, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter'),
        insured: ShippingRoute(price: 19.18, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.36, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter'),
        insured: ShippingRoute(price: 19.18, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.6, maxCards: 4, source: 'Int. Standard Letter'),
          ShippingRoute(price: 5.05, maxCards: 40, source: 'Int. Standard Large Letter'),
        ],
        tracked: ShippingRoute(price: 12.24, maxCards: 40, source: 'Int. Tracked &amp; Signed Large Letter (Online)'),
        insured: ShippingRoute(price: 16.44, maxCards: 100, source: 'Int. Tracked Small Parcel (250£ compensation) (Online)'),
      ),
    },
    'GR': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
        insured: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
        insured: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
          ShippingRoute(price: 6.5, maxCards: 100, source: 'A\' Priority Letter – Large'),
          ShippingRoute(price: 10.5, maxCards: 200, source: 'A\' Priority Letter – Bulky'),
          ShippingRoute(price: 16.5, maxCards: 400, source: 'A\' Priority Letter – Bulky'),
          ShippingRoute(price: 25.5, maxCards: 800, source: 'A\' Priority Letter – Bulky'),
        ],
        tracked: ShippingRoute(price: 7.5, maxCards: 17, source: 'A\' Priority Letter – Small – Registered'),
        insured: ShippingRoute(price: 9.5, maxCards: 17, source: 'A\' Priority Letter – Small – Registered – Declared Value 200€'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.5, maxCards: 4, source: 'B\' Priority Letter – Small'),
          ShippingRoute(price: 2.0, maxCards: 17, source: 'B\' Priority Letter – Small'),
          ShippingRoute(price: 2.7, maxCards: 40, source: 'B\' Priority Letter – Large'),
          ShippingRoute(price: 3.2, maxCards: 100, source: 'B\' Priority Letter – Large'),
          ShippingRoute(price: 3.7, maxCards: 200, source: 'B\' Priority Letter – Bulky'),
          ShippingRoute(price: 4.2, maxCards: 400, source: 'B\' Priority Letter – Bulky'),
          ShippingRoute(price: 4.7, maxCards: 800, source: 'B\' Priority Letter – Bulky'),
        ],
        tracked: ShippingRoute(price: 2.4, maxCards: 17, source: 'B\' Priority Letter – Small - Tracked (Ιχνηλάτηση)'),
        insured: ShippingRoute(price: 6.0, maxCards: 400, source: 'Registered Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
          ShippingRoute(price: 6.5, maxCards: 100, source: 'A\' Priority Letter – Large'),
          ShippingRoute(price: 10.5, maxCards: 200, source: 'A\' Priority Letter – Bulky'),
          ShippingRoute(price: 16.5, maxCards: 400, source: 'A\' Priority Letter – Bulky'),
          ShippingRoute(price: 25.5, maxCards: 800, source: 'A\' Priority Letter – Bulky'),
        ],
        tracked: ShippingRoute(price: 7.5, maxCards: 17, source: 'A\' Priority Letter – Small – Registered'),
        insured: ShippingRoute(price: 9.5, maxCards: 17, source: 'A\' Priority Letter – Small – Registered – Declared Value 200€'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 33.0, maxCards: 400, source: 'A\' Priority Parcel'),
        insured: ShippingRoute(price: 45.5, maxCards: 400, source: 'A\' Priority Parcel Declared Value 1000€'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
        insured: ShippingRoute(price: 100.0, maxCards: 2000, source: 'UPS Standard Parcel (Insurance 10.000€)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 3.8, maxCards: 17, source: 'A\' Priority Letter – Small'),
          ShippingRoute(price: 4.5, maxCards: 40, source: 'A\' Priority Letter – Large'),
        ],
        tracked: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
        insured: ShippingRoute(price: 23.0, maxCards: 400, source: 'EPG Parcel'),
      ),
    },
    'HR': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.02, maxCards: 4, source: 'Letter (SmalI)'),
          ShippingRoute(price: 1.3, maxCards: 40, source: 'Letter (SmalI)'),
          ShippingRoute(price: 1.54, maxCards: 100, source: 'Letter (SmalI)'),
          ShippingRoute(price: 1.94, maxCards: 200, source: 'Letter (Large)'),
          ShippingRoute(price: 2.46, maxCards: 400, source: 'Letter (Large)'),
          ShippingRoute(price: 3.34, maxCards: 800, source: 'Letter (Large)'),
        ],
        tracked: ShippingRoute(price: 2.75, maxCards: 17, source: 'Registered Letter (Small)'),
        insured: ShippingRoute(price: 6.22, maxCards: 200, source: 'Value Letter (Value 150)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 14.27, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 20.11, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 5.9, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.5, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.5, maxCards: 17, source: 'Priority Letter (Small)')],
        tracked: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
        insured: ShippingRoute(price: 12.95, maxCards: 400, source: 'Premium Parcel + AR'),
      ),
    },
    'HU': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.86, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
        insured: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.86, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
        insured: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.41, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.67, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 3.67, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 3.67, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.86, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
        insured: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.86, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
        insured: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.86, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
        insured: ShippingRoute(price: 38.01, maxCards: 400, source: 'International EMS'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.91, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
        insured: ShippingRoute(price: 11.46, maxCards: 17, source: 'Registered Priority Letter'),
      ),
    },
    'IE': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 40, source: 'Standard Post Letter'),
          ShippingRoute(price: 6.0, maxCards: 100, source: 'Standard Post Packet'),
          ShippingRoute(price: 7.5, maxCards: 200, source: 'Standard Post Packet'),
          ShippingRoute(price: 9.5, maxCards: 800, source: 'Standard Post Packet'),
        ],
        tracked: ShippingRoute(price: 10.5, maxCards: 200, source: 'Registered Post Packet'),
        insured: ShippingRoute(price: 10.5, maxCards: 200, source: 'Registered Post Packet'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 15.9, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.0, maxCards: 40, source: 'Standard Post Letter')],
        tracked: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
        insured: ShippingRoute(price: 17.5, maxCards: 200, source: 'Registered Post Packet (Declared Value 150€)'),
      ),
    },
    'IS': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.39, maxCards: 17, source: 'Letter'),
          ShippingRoute(price: 3.17, maxCards: 100, source: 'Letter'),
          ShippingRoute(price: 5.03, maxCards: 200, source: 'Letter Playmat'),
          ShippingRoute(price: 5.03, maxCards: 800, source: 'Letter'),
        ],
        tracked: ShippingRoute(price: 9.69, maxCards: 40, source: 'Registered Letter'),
        insured: ShippingRoute(price: 9.69, maxCards: 40, source: 'Registered Letter'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.68, maxCards: 17, source: 'Letter')],
        tracked: null,
        insured: null,
      ),
    },
    'IT': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.8, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 8.35, maxCards: 100, source: 'Priority Letter (Postapriority Int.)'),
          ShippingRoute(price: 9.65, maxCards: 200, source: 'Priority Letter (Postapriority Int.)'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.8, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 1.6, maxCards: 4, source: 'Posta Ordinaria')],
        tracked: ShippingRoute(price: 6.5, maxCards: 4, source: 'Posta Raccomandata'),
        insured: ShippingRoute(price: 11.4, maxCards: 17, source: 'Posta Assicurata 250€'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.05, maxCards: 17, source: 'Postapriority Internazionale - Ufficio Postale'),
          ShippingRoute(price: 5.15, maxCards: 40, source: 'Postapriority Internazionale - Ufficio Postale'),
        ],
        tracked: ShippingRoute(price: 10.7, maxCards: 17, source: 'Posta Raccomandata Internazionale (International Registered Mail)'),
        insured: ShippingRoute(price: 17.47, maxCards: 200, source: 'Posteminibox Exprès'),
      ),
    },
    'LI': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.75, maxCards: 40, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 2.09, maxCards: 100, source: 'Priority Letter (A-Post)'),
          ShippingRoute(price: 2.87, maxCards: 200, source: 'Priority Letter (A-Post)'),
        ],
        tracked: ShippingRoute(price: 4.33, maxCards: 100, source: 'Tracked Letter (A-Post Plus)'),
        insured: ShippingRoute(price: 7.57, maxCards: 200, source: 'Registered Priority Letter'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter'),
          ShippingRoute(price: 3.23, maxCards: 17, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
        insured: ShippingRoute(price: 22.31, maxCards: 200, source: 'Registered Minipac International Priority'),
      ),
    },
    'LT': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.05, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.85, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 7.85, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 7.1, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.2, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.8, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 8.3, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.55, maxCards: 40, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.85, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.2, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.9, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.9, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 10.0, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 18.4, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 4.2, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.5, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.9, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.25, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.05, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 10.1, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 9.25, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.95, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.35, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 7.65, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 13.55, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 25.55, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.3, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.2, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.95, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M) (Roll)'),
          ShippingRoute(price: 11.2, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 11.55, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.2, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.2, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.8, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.95, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 8.35, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.75, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.45, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 11.3, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 16.45, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.45, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.2, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.3, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.1, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 13.15, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.7, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.35, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 7.55, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 12.25, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.5, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.6, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 7.45, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 10.95, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 7.3, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.05, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 6.3, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 9.1, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.75, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.6, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.2, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.3, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 7.4, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 11.7, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.5, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.45, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.1, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 13.45, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.15, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.5, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.45, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.8, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 15.8, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 30.0, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 4.7, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.05, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 7.1, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 11.55, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.3, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.55, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.7, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.55, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.45, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 12.2, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 8.0, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.5, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.7, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.15, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.9, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.95, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 8.0, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 7.65, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.5, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.05, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.4, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 7.0, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 9.75, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 7.5, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.55, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.65, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 9.6, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 17.4, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 33.2, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 4.8, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.3, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.05, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.9, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 3.3, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 5.9, maxCards: 400, source: 'Insured Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.3, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.95, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 5.9, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 8.2, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.15, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 7.2, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 11.65, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.35, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.5, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.5, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 9.0, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 16.2, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 30.8, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.45, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.45, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.35, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 13.65, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.65, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.8, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 6.85, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 9.95, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.3, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.35, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.55, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.15, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.15, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 7.7, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 12.7, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.35, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.3, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.65, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.1, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 13.25, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.65, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.25, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.5, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.9, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 6.9, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 11.25, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.15, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.3, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.8, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 8.05, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 10.1, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.85, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.4, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 3.25, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 5.45, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 7.6, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 12.35, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 6.25, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.15, maxCards: 17, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 2.65, maxCards: 40, source: 'Neregistruota pirmenybinė (Priority Letter S)'),
          ShippingRoute(price: 4.1, maxCards: 200, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 5.9, maxCards: 400, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
          ShippingRoute(price: 9.65, maxCards: 800, source: 'Neregistruota pirmenybinė (Priority Letter M)'),
        ],
        tracked: ShippingRoute(price: 5.1, maxCards: 17, source: 'Registruota pirmenybinė (Registered Priority Letter S)'),
        insured: ShippingRoute(price: 16.8, maxCards: 800, source: 'Insured Parcel'),
      ),
    },
    'LU': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 13.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 23.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter (XS)'),
          ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)'),
        ],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 13.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 23.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 13.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 23.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 26.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 36.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 26.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 36.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.5, maxCards: 4, source: 'Lettre (XS)'),
          ShippingRoute(price: 2.9, maxCards: 200, source: 'Lettre (S)'),
          ShippingRoute(price: 7.7, maxCards: 800, source: 'Lettre (L)'),
        ],
        tracked: ShippingRoute(price: 5.7, maxCards: 4, source: 'Lettre FollowMe (XS)'),
        insured: ShippingRoute(price: 10.0, maxCards: 4000, source: 'Colis (XL)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.0, maxCards: 4, source: 'Priority Letter (XS)'),
          ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)'),
        ],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 13.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 23.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 13.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 23.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.0, maxCards: 17, source: 'Priority Letter (XS)')],
        tracked: ShippingRoute(price: 17.0, maxCards: 800, source: 'Registered Parcel (L)'),
        insured: ShippingRoute(price: 27.0, maxCards: 4000, source: 'Insured Parcel (XL 1.000€) SecurPack'),
      ),
    },
    'LV': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.71, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 5.86, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 8.11, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 11.13, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 17.14, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 8.43, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 13.19, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.71, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 5.86, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 8.11, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 11.13, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 17.14, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 8.43, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 13.19, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.71, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 5.86, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 8.11, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 11.13, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 17.14, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 8.43, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 13.19, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.65, maxCards: 4, source: 'Letter'),
          ShippingRoute(price: 3.1, maxCards: 40, source: 'Letter'),
          ShippingRoute(price: 4.7, maxCards: 200, source: 'Letter'),
          ShippingRoute(price: 8.76, maxCards: 800, source: 'Parcel'),
        ],
        tracked: ShippingRoute(price: 4.29, maxCards: 4, source: 'Registered Letter'),
        insured: ShippingRoute(price: 4.29, maxCards: 4, source: 'Registered Letter'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 4.71, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 5.86, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 8.11, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 11.13, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 17.14, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 8.43, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 13.19, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.3, maxCards: 4, source: 'Letter / Small Paket'),
          ShippingRoute(price: 4.35, maxCards: 40, source: 'Letter / Small Paket'),
          ShippingRoute(price: 6.26, maxCards: 200, source: 'Letter / Small Paket (Roll)'),
          ShippingRoute(price: 8.61, maxCards: 400, source: 'Letter / Small Paket'),
          ShippingRoute(price: 12.32, maxCards: 800, source: 'Letter / Small Paket'),
        ],
        tracked: ShippingRoute(price: 6.92, maxCards: 40, source: 'Registered Letter / Small Paket'),
        insured: ShippingRoute(price: 11.68, maxCards: 40, source: 'Insured Letter / Small Paket (200€)'),
      ),
    },
    'MT': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 0.75, maxCards: 17, source: 'Letter'),
          ShippingRoute(price: 1.15, maxCards: 40, source: 'Letter'),
          ShippingRoute(price: 1.35, maxCards: 100, source: 'Letter'),
          ShippingRoute(price: 3.38, maxCards: 200, source: 'Letter'),
          ShippingRoute(price: 5.98, maxCards: 400, source: 'Letter'),
          ShippingRoute(price: 7.98, maxCards: 600, source: 'Letter'),
          ShippingRoute(price: 9.98, maxCards: 800, source: 'Letter'),
        ],
        tracked: ShippingRoute(price: 4.35, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 4.35, maxCards: 17, source: 'Registered Letter'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.51, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
        insured: ShippingRoute(price: 37.5, maxCards: 800, source: 'Registered Parcel'),
      ),
    },
    'NL': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 11.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 21.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.2, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 42.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 33.5, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 28.3, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.55, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 11.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 21.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.55, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 27.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.55, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.05, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 28.3, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 27.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.05, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.55, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 11.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 11.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 19.2, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 28.3, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.7, maxCards: 4, source: 'Brief'),
          ShippingRoute(price: 3.1, maxCards: 17, source: 'Brief'),
          ShippingRoute(price: 4.85, maxCards: 200, source: 'Brief'),
        ],
        tracked: ShippingRoute(price: 6.2, maxCards: 800, source: 'Brievenbuspakje+'),
        insured: ShippingRoute(price: 6.2, maxCards: 800, source: 'Brievenbuspakje+'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 33.5, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 24.05, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.05, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 21.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 33.5, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 10.85, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 26.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 33.5, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.41, maxCards: 4, source: 'Letter')],
        tracked: ShippingRoute(price: 12.45, maxCards: 200, source: 'Brievenbuspakje met track &amp; trace (Tracked Letterbox packet)'),
        insured: ShippingRoute(price: 27.8, maxCards: 800, source: 'Registered Parcel (Pakket aangetekend € 500)'),
      ),
    },
    'NO': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 30.47, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.96, maxCards: 4, source: 'A-Priority Letter (Small)'),
          ShippingRoute(price: 4.65, maxCards: 17, source: 'A-Priority Letter (Large)'),
          ShippingRoute(price: 7.03, maxCards: 40, source: 'A-Priority Letter (Extra Large)'),
        ],
        tracked: ShippingRoute(price: 8.2, maxCards: 2000, source: 'Norgespakke (Online)'),
        insured: ShippingRoute(price: 8.2, maxCards: 2000, source: 'Norgespakke (Online)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 20.84, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 26.5, maxCards: 400, source: 'Parcel (Online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 5.97, maxCards: 17, source: 'Large Letter')],
        tracked: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
        insured: ShippingRoute(price: 23.67, maxCards: 400, source: 'Parcel (Online)'),
      ),
    },
    'PL': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 10.26, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.06, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 44.62, maxCards: 400, source: 'Insured EMS Parcel (20.000 zl)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 20.22, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.93, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 44.62, maxCards: 400, source: 'Insured EMS Parcel (20.000 zl)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.93, maxCards: 200, source: 'Priority Letter S'),
          ShippingRoute(price: 2.08, maxCards: 400, source: 'Priority Letter M'),
          ShippingRoute(price: 2.71, maxCards: 800, source: 'Priority Letter L'),
        ],
        tracked: ShippingRoute(price: 2.9, maxCards: 200, source: 'Registered Priority Letter S'),
        insured: ShippingRoute(price: 4.97, maxCards: 400, source: 'Registered Priority Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 20.22, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.93, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 19.49, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 29.2, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 17.55, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 27.26, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.74, maxCards: 17, source: 'Priority Letter'),
          ShippingRoute(price: 3.8, maxCards: 40, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 10.26, maxCards: 400, source: 'Priority Parcel'),
        insured: ShippingRoute(price: 19.97, maxCards: 400, source: 'Insured Priority Parcel (2000zl)'),
      ),
    },
    'PT': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 40.0, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)')],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 42.0, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
          ShippingRoute(price: 2.85, maxCards: 40, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.94, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 51.92, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 51.92, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 43.0, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter (Correio Normal)'),
          ShippingRoute(price: 2.85, maxCards: 40, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 63.71, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.3, maxCards: 4, source: 'Correio Azul'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
          ShippingRoute(price: 2.4, maxCards: 40, source: 'Correio Azul'),
          ShippingRoute(price: 4.4, maxCards: 200, source: 'Correio Azul'),
          ShippingRoute(price: 8.3, maxCards: 800, source: 'Correio Azul'),
        ],
        tracked: ShippingRoute(price: 4.73, maxCards: 40, source: 'Correio Registado'),
        insured: ShippingRoute(price: 17.6, maxCards: 800, source: 'Correio Registado (Valor 500€)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 50.55, maxCards: 800, source: 'Insured Parcel (Encomenda Valor 500€)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 5.5, maxCards: 4, source: 'Letter (Correio Azul)'),
          ShippingRoute(price: 2.85, maxCards: 17, source: 'Letter (Correio Normal)'),
        ],
        tracked: ShippingRoute(price: 7.2, maxCards: 17, source: 'Registered Letter (Correio Registado)'),
        insured: ShippingRoute(price: 47.08, maxCards: 800, source: 'CTT Expresso Economy (Seguro Extra 500€)'),
      ),
    },
    'RO': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.48, maxCards: 4, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
        insured: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.48, maxCards: 4, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
        insured: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.48, maxCards: 4, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
        insured: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.48, maxCards: 4, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
        insured: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.48, maxCards: 4, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
        insured: ShippingRoute(price: 19.79, maxCards: 400, source: 'Int\'l Priority Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.98, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 2.09, maxCards: 200, source: 'Priority Letter'),
          ShippingRoute(price: 2.29, maxCards: 800, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 2.71, maxCards: 40, source: 'Registered Letter'),
        insured: ShippingRoute(price: 6.04, maxCards: 400, source: 'Insured Parcel (1000 lei)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.86, maxCards: 40, source: 'Priority Letter'),
          ShippingRoute(price: 6.15, maxCards: 200, source: 'Priority Letter'),
        ],
        tracked: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
        insured: ShippingRoute(price: 16.04, maxCards: 400, source: 'International Priority Parcel'),
      ),
    },
    'SE': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
        insured: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
        insured: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
        insured: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
        insured: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
        insured: ShippingRoute(price: 14.24, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 2.41, maxCards: 17, source: 'Priority Letter (1:a-klassbrev)'),
          ShippingRoute(price: 4.71, maxCards: 40, source: 'Priority Letter (1:a-klassbrev)'),
          ShippingRoute(price: 6.81, maxCards: 100, source: 'Priority Letter (1:a-klassbrev)'),
          ShippingRoute(price: 8.9, maxCards: 200, source: 'Priority Letter (1:a-klassbrev)'),
        ],
        tracked: ShippingRoute(price: 10.37, maxCards: 800, source: 'DHL Package size S'),
        insured: ShippingRoute(price: 10.37, maxCards: 800, source: 'DHL Package size S'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 4.51, maxCards: 17, source: 'Priority Letter')],
        tracked: ShippingRoute(price: 15.38, maxCards: 17, source: 'International Registered Letter (Online)'),
        insured: ShippingRoute(price: 15.38, maxCards: 17, source: 'REK 2.000 SEK (Online)'),
      ),
    },
    'SI': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.39, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 6.62, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet) R'),
          ShippingRoute(price: 8.72, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.25, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.57, maxCards: 100, source: 'Blagovno pismo s podpisom (Small Registered Packet)'),
        insured: ShippingRoute(price: 18.85, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 6.4, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 8.64, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.09, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 17.23, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 8.41, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 19.71, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 6.4, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 8.64, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.09, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 17.23, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 8.41, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 19.71, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 6.4, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 8.64, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.09, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 17.23, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 8.41, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 19.71, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 6.4, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 8.64, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.09, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 17.23, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 8.41, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 19.71, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.44, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 6.4, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 8.64, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 12.09, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 17.23, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 8.41, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 19.71, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.88, maxCards: 40, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 2.38, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 3.29, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet) R'),
          ShippingRoute(price: 5.03, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 6.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 3.84, maxCards: 100, source: 'Blagovno pismo s podpisom (Registered Small Packet)'),
        insured: ShippingRoute(price: 3.84, maxCards: 100, source: 'Blagovno pismo s podpisom (Registered Small Packet)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 3.75, maxCards: 4, source: 'Prednostno - navadno pismo (Priority Letter)'),
          ShippingRoute(price: 5.82, maxCards: 100, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 7.27, maxCards: 200, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 9.62, maxCards: 400, source: 'Blagovno pismo brez sledenja (Small Packet)'),
          ShippingRoute(price: 13.28, maxCards: 800, source: 'Blagovno pismo brez sledenja (Small Packet)'),
        ],
        tracked: ShippingRoute(price: 7.85, maxCards: 100, source: 'Blagovno pismo s sledenjem (Small Tracked Packet)'),
        insured: ShippingRoute(price: 17.31, maxCards: 800, source: 'Paket (Parcel)'),
      ),
    },
    'SK': {
      'AT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'BE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'BG': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'CH': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 7.7, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 18.0, maxCards: 400, source: 'Registered Parcel'),
      ),
      'CY': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'CZ': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 2.8, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 7.0, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 11.2, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'DE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'DK': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'EE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'ES': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'FI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'FR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'GB': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 19.0, maxCards: 400, source: 'Registered Parcel'),
      ),
      'GR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'HR': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'HU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'IE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'IS': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 20.7, maxCards: 400, source: 'Parcel (Insurance 500€)'),
        insured: ShippingRoute(price: 20.7, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'IT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'LI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 20.7, maxCards: 400, source: 'Parcel (Insurance 500€)'),
        insured: ShippingRoute(price: 20.7, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'LT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'LU': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'LV': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'MT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'NL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'NO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter'),
        insured: ShippingRoute(price: 19.0, maxCards: 400, source: 'Registered Parcel'),
      ),
      'PL': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'PT': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'RO': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'SE': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'SI': RouteOptions(
        letterTiers: <ShippingRoute>[ShippingRoute(price: 3.5, maxCards: 17, source: 'Letter')],
        tracked: ShippingRoute(price: 6.7, maxCards: 17, source: 'Registered Letter (Online)'),
        insured: ShippingRoute(price: 21.5, maxCards: 400, source: 'Parcel (Insurance 500€)'),
      ),
      'SK': RouteOptions(
        letterTiers: <ShippingRoute>[
          ShippingRoute(price: 1.7, maxCards: 17, source: 'Letter'),
          ShippingRoute(price: 2.9, maxCards: 200, source: 'Letter'),
        ],
        tracked: ShippingRoute(price: 3.4, maxCards: 17, source: 'Insured Letter (150€)'),
        insured: ShippingRoute(price: 3.4, maxCards: 17, source: 'Insured Letter (500€)'),
      ),
    },
  };

  /// Conservative fallback when a (seller, buyer, method) combination has
  /// no data — either an unsupported country or a route Cardmarket genuinely
  /// doesn't cover. Numbers are pessimistic so the optimizer doesn't
  /// silently pick a route that turns out to be expensive at checkout.
  static const _fallback = <ShippingMethod, ShippingRoute>{
    ShippingMethod.letter:  ShippingRoute(price: 2.50,  maxCards: 4,   source: 'Fallback (no data)'),
    ShippingMethod.tracked: ShippingRoute(price: 12.00, maxCards: 800, source: 'Fallback (no data)'),
    ShippingMethod.insured: ShippingRoute(price: 25.00, maxCards: 800, source: 'Fallback (no data)'),
  };

  /// All supported countries with native-language labels.
  static const countries = <String, String>{
    'AT': 'Österreich',
    'BE': 'Belgique',
    'BG': 'България',
    'CH': 'Schweiz',
    'CY': 'Κύπρος',
    'CZ': 'Česko',
    'DE': 'Deutschland',
    'DK': 'Danmark',
    'EE': 'Eesti',
    'ES': 'España',
    'FI': 'Suomi',
    'FR': 'France',
    'GB': 'United Kingdom',
    'GR': 'Ελλάδα',
    'HR': 'Hrvatska',
    'HU': 'Magyarország',
    'IE': 'Ireland',
    'IS': 'Ísland',
    'IT': 'Italia',
    'LI': 'Liechtenstein',
    'LT': 'Lietuva',
    'LU': 'Luxembourg',
    'LV': 'Latvija',
    'MT': 'Malta',
    'NL': 'Nederland',
    'NO': 'Norge',
    'PL': 'Polska',
    'PT': 'Portugal',
    'RO': 'România',
    'SE': 'Sverige',
    'SI': 'Slovenija',
    'SK': 'Slovensko',
  };

  static bool isDomestic(String sellerCountry, String buyerCountry) =>
      sellerCountry.toUpperCase() == buyerCountry.toUpperCase();

  /// All shipping options on a route — full [RouteOptions] including the
  /// letter sub-tier ladder. Use this when the picker needs every available
  /// product (e.g. a method-picker UI listing each letter sub-tier).
  static RouteOptions? routeOptions(
    String sellerCountry,
    String buyerCountry,
  ) {
    final s = sellerCountry.toUpperCase();
    final b = buyerCountry.toUpperCase();
    return _routes[s]?[b];
  }

  /// Rich lookup — the canonical route for one tier, or `null` when the
  /// tier isn't offered on this route.
  ///
  /// Letter semantics: returns the SMALLEST letter sub-tier (cheapest +
  /// lowest cap, e.g. Standardbrief €1.25 / 4 cards in DE→DE). Callers
  /// that need bundle-aware picking must use [quoteForBundle]; callers
  /// that need the full sub-tier ladder must use [routeOptions].
  static ShippingRoute? getRoute(
    String sellerCountry,
    String buyerCountry,
    ShippingMethod method,
  ) {
    final r = routeOptions(sellerCountry, buyerCountry);
    if (r == null) return null;
    switch (method) {
      case ShippingMethod.letter:
        return r.letterTiers.isEmpty ? null : r.letterTiers.first;
      case ShippingMethod.tracked:
        return r.tracked;
      case ShippingMethod.insured:
        return r.insured;
    }
  }

  /// Backwards-compatible `double`-returning lookup. Used by call-sites
  /// that haven't been migrated to null-aware logic yet (Optimizer's
  /// shipping calc, BulkCheckoutSheet's per-seller shipping summary).
  ///
  /// When the route exists, returns the actual price.
  /// When the method isn't offered, falls back to the conservative
  /// `_fallback` value rather than crashing — keeps the optimizer
  /// usable on Iceland-edge-cases while we migrate the UI to handle
  /// null explicitly.
  static double getRate(
    String sellerCountry,
    String buyerCountry,
    ShippingMethod method,
  ) {
    return (getRoute(sellerCountry, buyerCountry, method) ?? _fallback[method]!).price;
  }

  /// Cheapest available shipping option for a bundle of [cardCount] cards.
  ///
  /// Walk strategy: cheapest letter sub-tier that fits → tracked → insured.
  /// Letter is a multi-tier ladder per route (Standard/Kompakt/Großbrief
  /// for DE; 1st/2nd Class × Letter/Large for GB; etc.) — the loop picks
  /// the first tier whose maxCards covers the bundle. Since the mapper
  /// sorts letter tiers by maxCards ascending (and price tracks capacity),
  /// the first fit is also the cheapest.
  ///
  /// Honours:
  ///   - [insuredOnly]: forces insured tier (seller-side rule for
  ///     high-value listings). Returns null if origin has no insured route.
  ///   - [forceTracked]: skips letter sub-tiers entirely. Set this when the
  ///     bundle value triggers [requiresTracking] (Cardmarket policy: orders
  ///     >€25 must ship Tracked). Tracked or insured will be picked instead.
  ///   - [cardCount]: skips any tier whose `maxCards` is below the bundle.
  ///   - `null` routes / empty letterTiers: tiers an origin doesn't offer
  ///     (e.g. IS has no tracked/insured) are skipped during selection.
  ///
  /// Returns `null` when no method can carry the bundle on this route.
  static ShippingQuote? quoteForBundle(
    String sellerCountry,
    String buyerCountry, {
    required int cardCount,
    bool insuredOnly = false,
    bool forceTracked = false,
    double? bundleValue,
  }) {
    final r = routeOptions(sellerCountry, buyerCountry);
    if (r == null) return null;

    // High-Value-Insured-Pflicht (Discogs-Modell, 2026-04-30): bei Bundle-Wert
    // ≥ €300 wird Insured erzwungen — DHL Wert-Einschreiben deckt bis €500.
    // Wenn die Route kein Insured anbietet (z.B. IS), kann der Verkauf nicht
    // versendet werden → null.
    final mustInsure =
        insuredOnly || (bundleValue != null && requiresInsured(bundleValue: bundleValue));
    if (mustInsure) {
      if (r.insured == null) return null;
      return ShippingQuote(r.insured!, ShippingMethod.insured);
    }

    if (!forceTracked) {
      for (final tier in r.letterTiers) {
        if (cardCount <= tier.maxCards) {
          return ShippingQuote(tier, ShippingMethod.letter);
        }
      }
    }
    if (r.tracked != null && cardCount <= r.tracked!.maxCards) {
      return ShippingQuote(r.tracked!, ShippingMethod.tracked);
    }
    if (r.insured != null && cardCount <= r.insured!.maxCards) {
      return ShippingQuote(r.insured!, ShippingMethod.insured);
    }
    return null;
  }

  /// Cheapest available shipping cost honouring an insured-only constraint.
  ///
  /// **Deprecated:** ignores `cardCount` and so silently misprices any bundle
  /// larger than the letter-tier cap (4 cards in DE→DE!). Use
  /// [quoteForBundle] which honours bundle size and route-level nulls.
  @Deprecated('Use quoteForBundle(cardCount: ...). cheapestRate ignores bundle size and underprices large bundles.')
  static double cheapestRate(
    String sellerCountry,
    String buyerCountry, {
    bool insuredOnly = false,
  }) {
    final q = quoteForBundle(
      sellerCountry,
      buyerCountry,
      cardCount: 1,
      insuredOnly: insuredOnly,
    );
    if (q != null) return q.price;
    return _fallback[insuredOnly ? ShippingMethod.insured : ShippingMethod.letter]!.price;
  }

  /// Default method to surface when no buyer override exists.
  ///
  /// **Deprecated:** assumes letter-tier without checking bundle size.
  /// Use [quoteForBundle] which returns the actual chosen tier.
  @Deprecated('Use quoteForBundle(cardCount: ...).method instead.')
  static ShippingMethod cheapestMethod({bool insuredOnly = false}) =>
      insuredOnly ? ShippingMethod.insured : ShippingMethod.letter;

  /// Per-bundle value at which Cardmarket requires Tracked shipping
  /// (`Versand mit Sendungsverfolgung`). At and below the threshold,
  /// untracked Letter is still allowed; above it, Letter is no longer
  /// offered to the buyer and the seller MUST ship Tracked or higher.
  ///
  /// This mirrors Cardmarket's published policy. Insured stays a
  /// buyer-choice / seller-listing-flag concern — it is NOT auto-forced
  /// by bundle value.
  ///
  /// Threshold applies to the SELLER-BUNDLE total (sum of price × qty for
  /// all listings shipped together), not per-listing. A €30 bundle of three
  /// €10 cards triggers Tracked just like a single €30 card.
  static const double highValueThreshold = 25.0;

  /// Does a bundle of [bundleValue] euros require at-minimum Tracked
  /// shipping per Cardmarket policy? Letter is unavailable when this
  /// returns true; Tracked is the new floor.
  ///
  /// Used by the optimizer + checkout. Insured forcing is unrelated —
  /// only the per-listing `insuredOnly` flag forces Insured.
  static bool requiresTracking({required double bundleValue}) =>
      bundleValue > highValueThreshold;

  /// Per-bundle value at which Riftr enforces Insured shipping (Discogs-
  /// Modell, 2026-04-30). DHL Wert-Einschreiben deckt bis €500 — bei Verlust
  /// haftet die Versicherung, nicht die Plattform.
  ///
  /// Threshold applies to the SELLER-BUNDLE total (matches highValueThreshold
  /// semantics). Riftr-Realitaet: Top-Karten ~€100-300, Promos €500+. Bei
  /// €300 fangen wir alle realen High-Value-Bestellungen ab.
  static const double insuredRequiredThreshold = 300.0;

  /// Does a bundle of [bundleValue] euros require Insured shipping?
  /// Letter and Tracked are unavailable when this returns true; Insured is
  /// the only allowed tier. Mirrored server-side in `createPaymentIntent`
  /// + `processMultiSellerCart` (functions/index.js).
  static bool requiresInsured({required double bundleValue}) =>
      bundleValue >= insuredRequiredThreshold;
}

/// One picked shipping option for a (seller, buyer, bundle-size) lookup.
/// Carries the underlying [ShippingRoute] (price + maxCards + source) and
/// the [ShippingMethod] tier the optimizer landed on, so callers can render
/// "Tracked €3.95 (Kompaktbrief + Einschreiben EINWURF)" without a second
/// lookup.
class ShippingQuote {
  final ShippingRoute route;
  final ShippingMethod method;
  const ShippingQuote(this.route, this.method);

  double get price => route.price;
  int get maxCards => route.maxCards;
  String get source => route.source;
}

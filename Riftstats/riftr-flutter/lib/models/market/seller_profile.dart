import 'package:cloud_firestore/cloud_firestore.dart';

class SellerAddress {
  final String? name; // Full name for shipping label
  final String street;
  final String city;
  final String zip;
  final String country; // ISO 2-letter code

  const SellerAddress({
    this.name,
    required this.street,
    required this.city,
    required this.zip,
    required this.country,
  });

  factory SellerAddress.fromMap(Map<String, dynamic> data) => SellerAddress(
        name: data['name'] as String?,
        street: data['street'] as String? ?? '',
        city: data['city'] as String? ?? '',
        zip: data['zip'] as String? ?? '',
        country: data['country'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'street': street,
        'city': city,
        'zip': zip,
        'country': country,
      };

  bool get isComplete =>
      street.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      zip.trim().isNotEmpty &&
      country.trim().isNotEmpty;

  SellerAddress copyWith({
    String? name,
    String? street,
    String? city,
    String? zip,
    String? country,
  }) =>
      SellerAddress(
        name: name ?? this.name,
        street: street ?? this.street,
        city: city ?? this.city,
        zip: zip ?? this.zip,
        country: country ?? this.country,
      );
}

class SellerProfile {
  final String? displayName;
  final String? email;
  final bool emailVerified;
  final String? country;
  final SellerAddress? address;
  final String? stripeAccountId;
  final bool stripeOnboarded;
  final double rating;
  final int reviewCount;
  final int totalSales;
  final double totalRevenue; // in EUR
  final int strikes;
  final bool suspended;
  final DateTime? suspendedUntil;
  final DateTime? memberSince;
  final DateTime? updatedAt;

  /// Gewerblicher Verkaeufer (B2C) — wenn true, hat der Kaeufer in DE
  /// 14-Tage-Widerrufsrecht (§ 312g BGB). Default false (= privat,
  /// kein Widerrufsrecht). Wird seit 2026-05-01 vom User selbst beim
  /// Onboarding gesetzt (Status-Wahl im SellerOnboardingSheet) — keine
  /// stille Re-Klassifizierung durch Riftr (§ 308 Nr. 4 BGB).
  final bool isCommercialSeller;

  /// USt-IdNr des gewerblichen Verkaeufers (z. B. "DE123456789").
  /// Pflichtfeld bei isCommercialSeller=true (DSA Art. 30 + § 5 DDG).
  /// Format-Validation App-seitig; VIES-Live-Verifikation Phase 2.
  final String? vatId;

  /// Firmierung des gewerblichen Verkaeufers (z. B.
  /// "Max Mustermann e. K." oder "Riftr UG (haftungsbeschraenkt)").
  /// Pflichtfeld bei isCommercialSeller=true. Erscheint spaeter in
  /// DSA Art. 30-Pflichtinfos auf Listing/Profile.
  final String? legalEntityName;

  /// ISO-Timestamp der Status-Erklaerung (Audit-Log fuer § 308 Nr. 4 BGB).
  /// Wird gesetzt bei initialem Onboarding (Status-Wahl) und bei
  /// Self-Reclassification (Privat → Gewerblich).
  final DateTime? commercialDeclaredAt;

  const SellerProfile({
    this.displayName,
    this.email,
    this.emailVerified = false,
    this.country,
    this.address,
    this.stripeAccountId,
    this.stripeOnboarded = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalSales = 0,
    this.totalRevenue = 0.0,
    this.strikes = 0,
    this.suspended = false,
    this.suspendedUntil,
    this.memberSince,
    this.updatedAt,
    this.isCommercialSeller = false,
    this.vatId,
    this.legalEntityName,
    this.commercialDeclaredAt,
  });

  /// Seller has completed full onboarding (name, address, verified email, Stripe).
  bool get isComplete =>
      displayName != null &&
      displayName!.trim().isNotEmpty &&
      address != null &&
      address!.isComplete &&
      emailVerified &&
      stripeAccountId != null;

  /// Seller has filled in name + address but may not have verified email yet.
  bool get hasAddress => address != null && address!.isComplete;

  /// Seller can actively sell (complete + not suspended).
  bool get canSell => isComplete && !suspended;

  factory SellerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SellerProfile.fromMap(data);
  }

  factory SellerProfile.fromMap(Map<String, dynamic> data) {
    return SellerProfile(
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      country: data['country'] as String?,
      address: data['address'] is Map<String, dynamic>
          ? SellerAddress.fromMap(data['address'] as Map<String, dynamic>)
          : null,
      stripeAccountId: data['stripeAccountId'] as String?,
      stripeOnboarded: data['stripeOnboarded'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      totalSales: data['totalSales'] as int? ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      strikes: data['strikes'] as int? ?? 0,
      suspended: data['suspended'] as bool? ?? false,
      suspendedUntil: _parseTimestamp(data['suspendedUntil']),
      memberSince: _parseTimestamp(data['memberSince']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      isCommercialSeller: data['isCommercialSeller'] as bool? ?? false,
      vatId: data['vatId'] as String?,
      legalEntityName: data['legalEntityName'] as String?,
      commercialDeclaredAt: _parseTimestamp(data['commercialDeclaredAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        'emailVerified': emailVerified,
        if (country != null) 'country': country,
        if (address != null) 'address': address!.toJson(),
        if (stripeAccountId != null) 'stripeAccountId': stripeAccountId,
        'stripeOnboarded': stripeOnboarded,
        'rating': rating,
        'reviewCount': reviewCount,
        'totalSales': totalSales,
        'totalRevenue': totalRevenue,
        'strikes': strikes,
        'suspended': suspended,
        if (suspendedUntil != null)
          'suspendedUntil': suspendedUntil!.toIso8601String(),
        if (memberSince != null)
          'memberSince': memberSince!.toIso8601String(),
        'isCommercialSeller': isCommercialSeller,
        if (vatId != null) 'vatId': vatId,
        if (legalEntityName != null) 'legalEntityName': legalEntityName,
        if (commercialDeclaredAt != null)
          'commercialDeclaredAt': commercialDeclaredAt!.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  SellerProfile copyWith({
    String? displayName,
    String? email,
    bool? emailVerified,
    String? country,
    SellerAddress? address,
    String? stripeAccountId,
    bool? stripeOnboarded,
    double? rating,
    int? reviewCount,
    int? totalSales,
    double? totalRevenue,
    int? strikes,
    bool? suspended,
    DateTime? suspendedUntil,
    DateTime? memberSince,
    bool? isCommercialSeller,
    String? vatId,
    String? legalEntityName,
    DateTime? commercialDeclaredAt,
  }) =>
      SellerProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        emailVerified: emailVerified ?? this.emailVerified,
        country: country ?? this.country,
        address: address ?? this.address,
        stripeAccountId: stripeAccountId ?? this.stripeAccountId,
        stripeOnboarded: stripeOnboarded ?? this.stripeOnboarded,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        totalSales: totalSales ?? this.totalSales,
        totalRevenue: totalRevenue ?? this.totalRevenue,
        strikes: strikes ?? this.strikes,
        suspended: suspended ?? this.suspended,
        suspendedUntil: suspendedUntil ?? this.suspendedUntil,
        memberSince: memberSince ?? this.memberSince,
        isCommercialSeller: isCommercialSeller ?? this.isCommercialSeller,
        vatId: vatId ?? this.vatId,
        legalEntityName: legalEntityName ?? this.legalEntityName,
        commercialDeclaredAt: commercialDeclaredAt ?? this.commercialDeclaredAt,
        updatedAt: DateTime.now(),
      );

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Format-Validation fuer EU-USt-IdNr. Akzeptiert (mit/ohne Spaces):
  /// DE + 9 Ziffern, AT + U + 8 Ziffern, FR + 11 alphanumerisch, etc.
  /// Phase 1: nur Format-Pruefung. VIES-Live-Verifikation Phase 2.
  ///
  /// Returns null wenn valid, sonst eine Fehlermeldung als String.
  static String? validateVatId(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'VAT ID is required for commercial sellers';
    }
    final cleaned = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.length < 8 || cleaned.length > 14) {
      return 'VAT ID must be 8–14 characters';
    }
    if (!RegExp(r'^[A-Z]{2}[A-Z0-9]+$').hasMatch(cleaned)) {
      return 'VAT ID must start with a 2-letter country code (e.g. DE)';
    }
    // Country-specific shortcuts (DE, AT — most common Riftr markets).
    final country = cleaned.substring(0, 2);
    final rest = cleaned.substring(2);
    if (country == 'DE' && !RegExp(r'^[0-9]{9}$').hasMatch(rest)) {
      return 'German VAT ID must be DE followed by 9 digits';
    }
    if (country == 'AT' && !RegExp(r'^U[0-9]{8}$').hasMatch(rest)) {
      return 'Austrian VAT ID must be AT followed by U + 8 digits';
    }
    return null;
  }

  /// Returns the VAT ID in canonical form (uppercase, no spaces) or null.
  static String? canonicalVatId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
  }
}

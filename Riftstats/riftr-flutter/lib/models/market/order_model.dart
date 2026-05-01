import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/shipping_rates.dart';
import 'listing_model.dart';
import 'seller_profile.dart';

enum OrderStatus {
  pendingPayment,
  paid,
  shipped,
  delivered,
  autoCompleted,
  disputed,
  refunded,
  cancelled,
}

extension OrderStatusExt on OrderStatus {
  String get firestoreValue => switch (this) {
        OrderStatus.pendingPayment => 'pending_payment',
        OrderStatus.paid => 'paid',
        OrderStatus.shipped => 'shipped',
        OrderStatus.delivered => 'delivered',
        OrderStatus.autoCompleted => 'auto_completed',
        OrderStatus.disputed => 'disputed',
        OrderStatus.refunded => 'refunded',
        OrderStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        OrderStatus.pendingPayment => 'Pending',
        OrderStatus.paid => 'Paid',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.autoCompleted => 'Completed',
        OrderStatus.disputed => 'Disputed',
        OrderStatus.refunded => 'Refunded',
        OrderStatus.cancelled => 'Cancelled',
      };

  bool get isActive => this == OrderStatus.pendingPayment ||
      this == OrderStatus.paid ||
      this == OrderStatus.shipped;

  bool get isCompleted => this == OrderStatus.delivered ||
      this == OrderStatus.autoCompleted;

  bool get isCancellable => this == OrderStatus.pendingPayment ||
      this == OrderStatus.paid;

  static OrderStatus fromString(String? value) => switch (value) {
        'pending_payment' => OrderStatus.pendingPayment,
        'paid' => OrderStatus.paid,
        'shipped' => OrderStatus.shipped,
        'delivered' => OrderStatus.delivered,
        'auto_completed' => OrderStatus.autoCompleted,
        'disputed' => OrderStatus.disputed,
        'refunded' => OrderStatus.refunded,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.pendingPayment,
      };
}

class OrderItem {
  final String listingId;
  final String cardId;
  final String cardName;
  final String? imageUrl;
  final CardCondition condition;
  final int quantity;
  final double pricePerCard;
  final String? setCode;
  final String? collectorNumber;
  final String? language;
  /// Foil variant flag — important for the seller to know what to ship.
  /// Defaults to false for legacy orders that pre-date this field.
  final bool isFoil;

  const OrderItem({
    required this.listingId,
    required this.cardId,
    required this.cardName,
    this.imageUrl,
    required this.condition,
    required this.quantity,
    required this.pricePerCard,
    this.setCode,
    this.collectorNumber,
    this.language,
    this.isFoil = false,
  });

  double get lineTotal => pricePerCard * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
        listingId: data['listingId'] as String? ?? '',
        cardId: data['cardId'] as String? ?? '',
        cardName: data['cardName'] as String? ?? '',
        imageUrl: data['imageUrl'] as String?,
        condition: CardCondition.values.firstWhere(
          (c) => c.name == data['condition'],
          orElse: () => CardCondition.NM,
        ),
        quantity: data['quantity'] as int? ?? 1,
        pricePerCard: (data['pricePerCard'] as num?)?.toDouble() ?? 0,
        setCode: data['setCode'] as String?,
        collectorNumber: data['collectorNumber'] as String?,
        language: data['language'] as String?,
        isFoil: data['isFoil'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'cardId': cardId,
        'cardName': cardName,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'condition': condition.name,
        'quantity': quantity,
        'pricePerCard': pricePerCard,
        if (setCode != null) 'setCode': setCode,
        if (collectorNumber != null) 'collectorNumber': collectorNumber,
        if (language != null) 'language': language,
        if (isFoil) 'isFoil': true,
      };
}

class MarketOrder {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? sellerStripeAccountId;
  final List<OrderItem> items;
  final double subtotal;
  final double platformFee;
  final double buyerServiceFee;
  final String feePayer; // 'buyer' or 'seller'
  final double shippingCost;
  final double totalPaid;
  final double sellerPayout;
  final SellerAddress? shippingAddress;
  final SellerAddress? sellerAddress;
  final ShippingMethod shippingMethod;
  final String? stripePaymentIntentId;
  final OrderStatus status;
  final String? trackingNumber;
  final String? sellerName;
  final String? buyerName;
  /// Discogs-Modell (2026-05-01): Verkäufer-Status-Snapshot zur Order-Zeit.
  /// Treibt Reklamations-Hinweis-Dialog (Widerruf-Pfad bei gewerblichen
  /// Verkäufern, AGB-Anhang 1) und Buyer-Eskalations-Card.
  final bool sellerIsCommercial;

  /// Seller-Email-Snapshot zur Order-Zeit. Pflichtangabe in der Bestell-
  /// bestätigung für Verbraucher-Käufer bei gewerblichen Verkäufern, damit
  /// Widerrufserklärung an den Verkäufer gerichtet werden kann (§ 312i BGB
  /// + Art. 246a EGBGB, Riftr-AGB-Anhang-1 Abschnitt B).
  final String? sellerEmail;

  /// Firmierung des gewerblichen Verkäufers, snapshot zur Order-Zeit.
  /// DSA Art. 30 / § 5 DDG Pflichtinfo.
  final String? sellerLegalEntityName;

  /// USt-IdNr des gewerblichen Verkäufers, snapshot zur Order-Zeit.
  /// DSA Art. 30 / § 5 DDG Pflichtinfo.
  final String? sellerVatId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? autoReleaseAt;
  final DateTime? cancelledAt;
  final bool cancelRequested;
  final DateTime? cancelRequestedAt;
  final String? cancelReason;
  final String? cancelNote;
  final String? disputeReason;
  final DateTime? disputedAt;
  final String? disputeStatus; // "open", "sellerProposed", "resolved", "cancelled"
  final String? disputeDescription;
  final int? proposedRefundPercent;
  final double? proposedRefundAmount;
  final DateTime? proposedAt;
  final DateTime? resolvedAt;
  final int? buyerRating;
  final String? buyerComment;
  final DateTime? buyerRatingTimestamp;
  final String? preReleaseDate; // ISO date, e.g. "2026-05-08"

  /// Whether shipping is blocked because the set hasn't released yet.
  bool get isPreReleaseBlocked {
    if (preReleaseDate == null) return false;
    final rd = DateTime.tryParse(preReleaseDate!);
    return rd != null && rd.isAfter(DateTime.now());
  }

  const MarketOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.sellerStripeAccountId,
    required this.items,
    required this.subtotal,
    required this.platformFee,
    this.buyerServiceFee = 0,
    this.feePayer = 'seller',
    required this.shippingCost,
    required this.totalPaid,
    required this.sellerPayout,
    this.shippingAddress,
    this.sellerAddress,
    this.shippingMethod = ShippingMethod.letter,
    this.stripePaymentIntentId,
    this.status = OrderStatus.pendingPayment,
    this.trackingNumber,
    this.sellerName,
    this.buyerName,
    this.sellerIsCommercial = false,
    this.sellerEmail,
    this.sellerLegalEntityName,
    this.sellerVatId,
    required this.createdAt,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.autoReleaseAt,
    this.cancelledAt,
    this.cancelRequested = false,
    this.cancelRequestedAt,
    this.cancelReason,
    this.cancelNote,
    this.disputeReason,
    this.disputedAt,
    this.disputeStatus,
    this.disputeDescription,
    this.proposedRefundPercent,
    this.proposedRefundAmount,
    this.proposedAt,
    this.resolvedAt,
    this.buyerRating,
    this.buyerComment,
    this.buyerRatingTimestamp,
    this.preReleaseDate,
  });

  /// First item's card name (convenience for single-item orders).
  String get cardName => items.isNotEmpty ? items.first.cardName : '';
  String? get imageUrl => items.isNotEmpty ? items.first.imageUrl : null;
  CardCondition get condition =>
      items.isNotEmpty ? items.first.condition : CardCondition.NM;
  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  factory MarketOrder.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final itemsList = (d['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MarketOrder(
      id: doc.id,
      buyerId: d['buyerId'] as String? ?? '',
      sellerId: d['sellerId'] as String? ?? '',
      sellerStripeAccountId: d['sellerStripeAccountId'] as String?,
      items: itemsList,
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      platformFee: (d['platformFee'] as num?)?.toDouble() ?? 0,
      buyerServiceFee: (d['buyerServiceFee'] as num?)?.toDouble() ?? 0,
      feePayer: d['feePayer'] as String? ?? 'seller',
      shippingCost: (d['shippingCost'] as num?)?.toDouble() ?? 0,
      totalPaid: (d['totalPaid'] as num?)?.toDouble() ?? 0,
      sellerPayout: (d['sellerPayout'] as num?)?.toDouble() ?? 0,
      shippingAddress: d['shippingAddress'] is Map<String, dynamic>
          ? SellerAddress.fromMap(d['shippingAddress'] as Map<String, dynamic>)
          : null,
      sellerAddress: d['sellerAddress'] is Map<String, dynamic>
          ? SellerAddress.fromMap(d['sellerAddress'] as Map<String, dynamic>)
          : null,
      shippingMethod: ShippingMethod.values.firstWhere(
        (m) => m.name == d['shippingMethod'],
        orElse: () => ShippingMethod.letter,
      ),
      stripePaymentIntentId: d['stripePaymentIntentId'] as String?,
      status: OrderStatusExt.fromString(d['status'] as String?),
      trackingNumber: d['trackingNumber'] as String?,
      sellerName: d['sellerName'] as String?,
      sellerIsCommercial: d['sellerIsCommercial'] as bool? ?? false,
      sellerEmail: d['sellerEmail'] as String?,
      sellerLegalEntityName: d['sellerLegalEntityName'] as String?,
      sellerVatId: d['sellerVatId'] as String?,
      buyerName: d['buyerName'] as String?,
      createdAt: _parseTimestamp(d['createdAt']) ?? DateTime.now(),
      paidAt: _parseTimestamp(d['paidAt']),
      shippedAt: _parseTimestamp(d['shippedAt']),
      deliveredAt: _parseTimestamp(d['deliveredAt']),
      autoReleaseAt: _parseTimestamp(d['autoReleaseAt']),
      cancelledAt: _parseTimestamp(d['cancelledAt']),
      cancelRequested: d['cancelRequested'] as bool? ?? false,
      cancelRequestedAt: _parseTimestamp(d['cancelRequestedAt']),
      cancelReason: d['cancelReason'] as String?,
      cancelNote: d['cancelNote'] as String?,
      disputeReason: d['disputeReason'] as String?,
      disputedAt: _parseTimestamp(d['disputedAt']),
      disputeStatus: d['disputeStatus'] as String?,
      disputeDescription: d['disputeDescription'] as String?,
      proposedRefundPercent: d['proposedRefundPercent'] as int?,
      proposedRefundAmount: (d['proposedRefundAmount'] as num?)?.toDouble(),
      proposedAt: _parseTimestamp(d['proposedAt']),
      resolvedAt: _parseTimestamp(d['resolvedAt']),
      buyerRating: d['buyerRating'] as int?,
      buyerComment: d['buyerComment'] as String?,
      buyerRatingTimestamp: _parseTimestamp(d['buyerRatingTimestamp']),
      preReleaseDate: d['preReleaseDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'buyerId': buyerId,
        'sellerId': sellerId,
        if (sellerStripeAccountId != null)
          'sellerStripeAccountId': sellerStripeAccountId,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'platformFee': platformFee,
        'buyerServiceFee': buyerServiceFee,
        'feePayer': feePayer,
        'shippingCost': shippingCost,
        'totalPaid': totalPaid,
        'sellerPayout': sellerPayout,
        if (shippingAddress != null)
          'shippingAddress': shippingAddress!.toJson(),
        if (sellerAddress != null)
          'sellerAddress': sellerAddress!.toJson(),
        'shippingMethod': shippingMethod.name,
        if (stripePaymentIntentId != null)
          'stripePaymentIntentId': stripePaymentIntentId,
        'status': status.firestoreValue,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        if (sellerName != null) 'sellerName': sellerName,
        if (buyerName != null) 'buyerName': buyerName,
        'sellerIsCommercial': sellerIsCommercial,
        if (sellerEmail != null) 'sellerEmail': sellerEmail,
        if (sellerLegalEntityName != null)
          'sellerLegalEntityName': sellerLegalEntityName,
        if (sellerVatId != null) 'sellerVatId': sellerVatId,
        'createdAt': createdAt.toIso8601String(),
        if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
        if (shippedAt != null) 'shippedAt': shippedAt!.toIso8601String(),
        if (deliveredAt != null)
          'deliveredAt': deliveredAt!.toIso8601String(),
        if (autoReleaseAt != null)
          'autoReleaseAt': autoReleaseAt!.toIso8601String(),
        if (cancelledAt != null)
          'cancelledAt': cancelledAt!.toIso8601String(),
        if (disputeReason != null) 'disputeReason': disputeReason,
        if (disputedAt != null)
          'disputedAt': disputedAt!.toIso8601String(),
        if (disputeStatus != null) 'disputeStatus': disputeStatus,
        if (disputeDescription != null)
          'disputeDescription': disputeDescription,
        if (proposedRefundPercent != null)
          'proposedRefundPercent': proposedRefundPercent,
        if (proposedRefundAmount != null)
          'proposedRefundAmount': proposedRefundAmount,
        if (proposedAt != null) 'proposedAt': proposedAt!.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
        if (buyerRating != null) 'buyerRating': buyerRating,
        if (buyerComment != null) 'buyerComment': buyerComment,
        if (buyerRatingTimestamp != null)
          'buyerRatingTimestamp': buyerRatingTimestamp!.toIso8601String(),
      };

  MarketOrder copyWith({
    OrderStatus? status,
    String? trackingNumber,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? autoReleaseAt,
    DateTime? cancelledAt,
    bool? cancelRequested,
    DateTime? cancelRequestedAt,
    String? cancelReason,
    String? cancelNote,
    String? disputeReason,
    DateTime? disputedAt,
    String? disputeStatus,
    String? disputeDescription,
    int? proposedRefundPercent,
    double? proposedRefundAmount,
    DateTime? proposedAt,
    DateTime? resolvedAt,
    int? buyerRating,
    String? buyerComment,
    DateTime? buyerRatingTimestamp,
  }) =>
      MarketOrder(
        id: id,
        buyerId: buyerId,
        sellerId: sellerId,
        sellerStripeAccountId: sellerStripeAccountId,
        items: items,
        subtotal: subtotal,
        platformFee: platformFee,
        buyerServiceFee: buyerServiceFee,
        feePayer: feePayer,
        shippingCost: shippingCost,
        totalPaid: totalPaid,
        sellerPayout: sellerPayout,
        shippingAddress: shippingAddress,
        sellerAddress: sellerAddress,
        shippingMethod: shippingMethod,
        stripePaymentIntentId: stripePaymentIntentId,
        status: status ?? this.status,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        sellerName: sellerName,
        buyerName: buyerName,
        sellerIsCommercial: sellerIsCommercial,
        sellerEmail: sellerEmail,
        sellerLegalEntityName: sellerLegalEntityName,
        sellerVatId: sellerVatId,
        createdAt: createdAt,
        paidAt: paidAt ?? this.paidAt,
        shippedAt: shippedAt ?? this.shippedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        autoReleaseAt: autoReleaseAt ?? this.autoReleaseAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancelRequested: cancelRequested ?? this.cancelRequested,
        cancelRequestedAt: cancelRequestedAt ?? this.cancelRequestedAt,
        cancelReason: cancelReason ?? this.cancelReason,
        cancelNote: cancelNote ?? this.cancelNote,
        disputeReason: disputeReason ?? this.disputeReason,
        disputedAt: disputedAt ?? this.disputedAt,
        disputeStatus: disputeStatus ?? this.disputeStatus,
        disputeDescription: disputeDescription ?? this.disputeDescription,
        proposedRefundPercent:
            proposedRefundPercent ?? this.proposedRefundPercent,
        proposedRefundAmount:
            proposedRefundAmount ?? this.proposedRefundAmount,
        proposedAt: proposedAt ?? this.proposedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        buyerRating: buyerRating ?? this.buyerRating,
        buyerComment: buyerComment ?? this.buyerComment,
        buyerRatingTimestamp: buyerRatingTimestamp ?? this.buyerRatingTimestamp,
      );

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class CheckoutResult {
  final String clientSecret;
  final String orderId;
  final double total;

  const CheckoutResult({
    required this.clientSecret,
    required this.orderId,
    required this.total,
  });
}

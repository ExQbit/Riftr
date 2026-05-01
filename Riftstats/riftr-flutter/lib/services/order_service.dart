import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../data/shipping_rates.dart';
import '../models/market/listing_model.dart';
import '../models/market/order_model.dart';
import '../models/market/seller_profile.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class OrderService extends ChangeNotifier {
  OrderService._();
  static final OrderService instance = OrderService._();

  StreamSubscription? _purchasesSub;
  StreamSubscription? _salesSub;
  List<MarketOrder> _purchases = [];
  List<MarketOrder> _sales = [];

  List<MarketOrder> get purchases => List.unmodifiable(_purchases);
  List<MarketOrder> get sales => List.unmodifiable(_sales);

  int get activePurchaseCount =>
      _purchases.where((o) => o.status.isActive).length;
  int get activeSaleCount =>
      _sales.where((o) => o.status.isActive).length;

  // ─── Lifecycle ───

  void listen() {
    _purchasesSub?.cancel();
    _salesSub?.cancel();
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    try {
      debugPrint('OrderService: Starting purchases listener for uid=$uid');
      _purchasesSub = FirestoreService.instance
          .globalCollection('orders')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        debugPrint('OrderService: Received ${snap.docs.length} purchases');
        _purchases = snap.docs
            .map((doc) {
              try {
                return MarketOrder.fromFirestore(doc);
              } catch (e) {
                debugPrint('OrderService: Failed to parse purchase ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MarketOrder>()
            .toList();
        notifyListeners();
      }, onError: (e) {
        debugPrint('OrderService: Purchases stream ERROR: $e');
      });
    } catch (e) {
      debugPrint('OrderService: Error starting purchases listener: $e');
    }

    try {
      _salesSub = FirestoreService.instance
          .globalCollection('orders')
          .where('sellerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        debugPrint('OrderService: Received ${snap.docs.length} sales');
        _sales = snap.docs
            .map((doc) {
              try {
                return MarketOrder.fromFirestore(doc);
              } catch (e) {
                debugPrint('OrderService: Failed to parse sale ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MarketOrder>()
            .toList();
        notifyListeners();
      }, onError: (e) {
        debugPrint('OrderService: Sales stream ERROR: $e');
      });
    } catch (e) {
      debugPrint('OrderService: Error starting sales listener: $e');
    }
  }

  void stopListening() {
    _purchasesSub?.cancel();
    _salesSub?.cancel();
    _purchasesSub = null;
    _salesSub = null;
    _purchases = [];
    _sales = [];
  }

  // ─── Buy Flow ───

  /// Create an order and get a Stripe client secret for payment.
  Future<CheckoutResult?> createOrder({
    required MarketListing listing,
    required int quantity,
    required ShippingMethod shippingMethod,
    required SellerAddress shippingAddress,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createPaymentIntent');
      final result = await callable.call<Map<String, dynamic>>({
        'listingId': listing.id,
        'quantity': quantity,
        'shippingMethod': shippingMethod.name,
        'shippingAddress': shippingAddress.toJson(),
      });
      final data = result.data;
      return CheckoutResult(
        clientSecret: data['clientSecret'] as String,
        orderId: data['orderId'] as String,
        total: (data['total'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('OrderService.createOrder error: $e');
      return null;
    }
  }

  // ─── Order Actions ───

  /// Seller marks order as shipped with tracking number.
  Future<bool> markShipped(String orderId, String trackingNumber) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('markShipped');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'trackingNumber': trackingNumber,
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.markShipped error: $e');
      return false;
    }
  }

  /// Update tracking number on an existing order (seller only).
  Future<bool> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('updateTrackingNumber');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'trackingNumber': trackingNumber,
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.updateTrackingNumber error: $e');
      return false;
    }
  }

  /// Confirm payment succeeded (called after PaymentSheet completes).
  Future<bool> confirmPayment(String orderId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('confirmPayment');
      await callable.call<Map<String, dynamic>>({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.confirmPayment error: $e');
      return false;
    }
  }

  /// Buyer confirms delivery.
  Future<bool> confirmDelivery(String orderId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('confirmDelivery');
      await callable.call<Map<String, dynamic>>({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.confirmDelivery error: $e');
      return false;
    }
  }

  /// Create a cart order (multiple listings from same seller).
  Future<CheckoutResult?> createCartOrder({
    required List<Map<String, dynamic>> items,
    required ShippingMethod shippingMethod,
    required SellerAddress shippingAddress,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createPaymentIntent');
      final result = await callable.call<Map<String, dynamic>>({
        'items': items,
        'shippingMethod': shippingMethod.name,
        'shippingAddress': shippingAddress.toJson(),
      });
      final data = result.data;
      return CheckoutResult(
        clientSecret: data['clientSecret'] as String,
        orderId: data['orderId'] as String,
        total: (data['total'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('OrderService.createCartOrder error: $e');
      return null;
    }
  }

  /// Buyer opens a dispute on a shipped order.
  ///
  /// [reasonCodeChoice] — Discogs-Modell-Audit-Feld (2026-05-01).
  /// `'reklamation'` wenn Käufer den Hinweis-Dialog gesehen UND Reklamation
  /// gewählt hat. `'no_choice_required'` (default) wenn der Hinweis-Dialog
  /// nicht angezeigt wurde (Reason ≠ wrong_card/not_arrived ODER Verkäufer
  /// nicht gewerblich). `'widerruf'` darf hier NICHT verwendet werden — das
  /// triggert den separaten Widerrufs-Pfad (Anhang 1 Modal).
  ///
  /// [widerrufHinweisShownAt] / [widerrufHinweisChosenAt] — ISO-Timestamps
  /// für Beweis im Streitfall (UWG/UCPD-Schutz gegen Dark-Pattern-Vorwurf).
  Future<bool> openDispute(
    String orderId,
    String reason, {
    String description = '',
    String reasonCodeChoice = 'no_choice_required',
    DateTime? widerrufHinweisShownAt,
    DateTime? widerrufHinweisChosenAt,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('openDispute');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'reason': reason,
        if (description.isNotEmpty) 'description': description,
        'reasonCodeChoice': reasonCodeChoice,
        if (widerrufHinweisShownAt != null)
          'widerrufHinweisShownAt': widerrufHinweisShownAt.toIso8601String(),
        if (widerrufHinweisChosenAt != null)
          'widerrufHinweisChosenAt': widerrufHinweisChosenAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.openDispute error: $e');
      return false;
    }
  }

  /// Buyer submits a rating for the seller after delivery.
  Future<bool> submitReview(String orderId, int rating, String comment, {List<String> tags = const []}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('submitReview');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        if (tags.isNotEmpty) 'tags': tags,
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.submitReview error: $e');
      return false;
    }
  }

  /// Seller proposes a refund percentage for a disputed order.
  Future<bool> proposeRefund(String orderId, int refundPercent) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('proposeRefund');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'refundPercent': refundPercent,
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.proposeRefund error: $e');
      return false;
    }
  }

  /// Buyer accepts or rejects the seller's refund proposal.
  Future<bool> respondToRefund(String orderId, {required bool accept}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('respondToRefund');
      await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'accept': accept,
      });
      return true;
    } catch (e) {
      debugPrint('OrderService.respondToRefund error: $e');
      return false;
    }
  }

  /// Buyer cancels/withdraws the dispute entirely.
  Future<bool> cancelDispute(String orderId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('cancelDispute');
      await callable.call<Map<String, dynamic>>({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.cancelDispute error: $e');
      return false;
    }
  }

  /// Cancel an order (pre-ship only).
  Future<bool> cancelOrder(String orderId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('cancelOrder');
      await callable.call<Map<String, dynamic>>({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.cancelOrder error: $e');
      return false;
    }
  }

  Future<bool> requestCancel(String orderId, {String? reason, String? note}) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('requestCancelOrder')
          .call({'orderId': orderId, if (reason != null) 'reason': reason, if (note != null) 'note': note});
      return true;
    } catch (e) {
      debugPrint('OrderService.requestCancel error: $e');
      return false;
    }
  }

  Future<bool> acceptCancel(String orderId) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('acceptCancelOrder')
          .call({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.acceptCancel error: $e');
      return false;
    }
  }

  Future<bool> declineCancel(String orderId) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('declineCancelOrder')
          .call({'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('OrderService.declineCancel error: $e');
      return false;
    }
  }
}

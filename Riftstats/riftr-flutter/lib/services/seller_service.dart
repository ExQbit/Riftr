import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/market/seller_profile.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// Manages the seller profile for marketplace onboarding + Stripe Connect.
class SellerService extends ChangeNotifier {
  SellerService._();
  static final SellerService instance = SellerService._();

  SellerProfile? _profile;
  StreamSubscription? _sub;

  SellerProfile? get profile => _profile;

  /// Seller has completed all onboarding (name, address, verified email).
  bool get isReady => _profile?.isComplete ?? false;

  /// Seller has filled in name + address.
  bool get hasAddress => _profile?.hasAddress ?? false;

  /// Email has been verified.
  bool get emailVerified => _profile?.emailVerified ?? false;

  /// Stripe onboarding completed (for future payout).
  bool get stripeOnboarded => _profile?.stripeOnboarded ?? false;

  /// Stripe account exists but onboarding not finished.
  bool get stripeStarted =>
      _profile?.stripeAccountId != null && !stripeOnboarded;

  // ─── Lifecycle ───

  void listen() {
    _sub?.cancel();
    try {
      _sub = FirestoreService.instance
          .userDoc('data', 'sellerProfile')
          .snapshots()
          .listen((snap) {
        _profile = snap.exists ? SellerProfile.fromFirestore(snap) : null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('SellerService.listen error: $e');
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _profile = null;
  }

  // ─── Profile Management ───

  /// Save seller name + address + email + status (Step 0 of onboarding).
  ///
  /// [isCommercialSeller] / [vatId] / [legalEntityName] sind seit
  /// 2026-05-01 vom User waehlbar (Status-Erklaerung). Bei
  /// `isCommercialSeller=true` werden vatId + legalEntityName gespeichert
  /// und [commercialDeclaredAt] auf jetzt gesetzt (Audit-Log fuer
  /// § 308 Nr. 4 BGB — keine stille Re-Klassifizierung).
  Future<bool> saveProfile({
    required String displayName,
    required String email,
    required SellerAddress address,
    bool isCommercialSeller = false,
    String? vatId,
    String? legalEntityName,
  }) async {
    try {
      // commercialDeclaredAt: nur bei initial-set oder wenn der User von
      // privat auf gewerblich wechselt. Bestehende Erklaerung nicht
      // ueberschreiben (sonst wird der Audit-Trail kaputt).
      final wasCommercial = _profile?.isCommercialSeller ?? false;
      final declaredAt = isCommercialSeller && !wasCommercial
          ? DateTime.now()
          : _profile?.commercialDeclaredAt;

      final data = (_profile ?? const SellerProfile()).copyWith(
        displayName: displayName,
        email: email,
        country: address.country,
        address: address,
        memberSince: _profile?.memberSince ?? DateTime.now(),
        isCommercialSeller: isCommercialSeller,
        vatId: isCommercialSeller ? vatId : null,
        legalEntityName: isCommercialSeller ? legalEntityName : null,
        commercialDeclaredAt: declaredAt,
      );
      await FirestoreService.instance
          .userDoc('data', 'sellerProfile')
          .set(data.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('SellerService.saveProfile error: $e');
      return false;
    }
  }

  // ─── Email Verification ───

  /// Send a 6-digit verification code to the seller's email.
  Future<bool> sendVerificationCode(String email) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('sendVerificationCode');
      await callable.call<Map<String, dynamic>>({'email': email});
      return true;
    } catch (e) {
      debugPrint('SellerService.sendVerificationCode error: $e');
      return false;
    }
  }

  /// Verify the 6-digit code. Returns true if verified.
  Future<bool> verifyEmailCode(String code) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('verifyEmailCode');
      await callable.call<Map<String, dynamic>>({'code': code});
      return true;
    } catch (e) {
      debugPrint('SellerService.verifyEmailCode error: $e');
      return false;
    }
  }

  // ─── Stripe Connect ───

  /// Create a Stripe Express account and return the onboarding URL.
  /// If account already exists, returns a fresh onboarding link.
  Future<String?> createStripeAccount() async {
    final uid = AuthService.instance.uid;
    final email = AuthService.instance.currentUser?.email;
    final country = _profile?.address?.country ?? _profile?.country;
    if (uid == null || country == null) return null;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createStripeAccount');
      final result = await callable.call<Map<String, dynamic>>({
        'country': country,
        'email': email,
      });
      final data = result.data;
      return data['url'] as String?;
    } catch (e) {
      debugPrint('SellerService.createStripeAccount error: $e');
      return null;
    }
  }

  /// Get a fresh onboarding link for an existing Stripe account.
  Future<String?> getStripeAccountLink() async {
    final accountId = _profile?.stripeAccountId;
    if (accountId == null) return null;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createStripeAccountLink');
      final result = await callable.call<Map<String, dynamic>>({
        'accountId': accountId,
      });
      final data = result.data;
      return data['url'] as String?;
    } catch (e) {
      debugPrint('SellerService.getStripeAccountLink error: $e');
      return null;
    }
  }
}

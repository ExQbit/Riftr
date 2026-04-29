import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// Profile service — own profile listener + other profile cache
class ProfileService extends ChangeNotifier {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  UserProfile? _ownProfile;
  StreamSubscription? _sub;
  final Map<String, UserProfile> _cache = {};
  final Set<String> _fetched = {};
  bool _hasLoaded = false;

  UserProfile? get ownProfile => _ownProfile;

  /// True after the first Firestore snapshot (even if profile doc doesn't exist).
  bool get hasLoaded => _hasLoaded;

  void listen() {
    _sub?.cancel();
    try {
      _sub = FirestoreService.instance
          .userDoc('data', 'profile')
          .snapshots()
          .listen((snap) {
        _ownProfile = snap.exists ? UserProfile.fromFirestore(snap) : null;
        _hasLoaded = true;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('ProfileService.listen error: $e');
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _ownProfile = null;
    _hasLoaded = false;
    _cache.clear();
    _fetched.clear();
  }

  /// Update own profile (merge)
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await FirestoreService.instance
          .userDoc('data', 'profile')
          .set(profile.toJson(), SetOptions(merge: true));

      // Sync display name to Firebase Auth
      final displayName = profile.displayName;
      if (displayName != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(displayName);
        }
      }

      // Mirror to playerProfiles for search (always update, not just first time).
      // avatarUrl mirrored so player-search results show the user's chosen
      // avatar without requiring a secondary fetch of users/{uid}/data/profile.
      final uid = AuthService.instance.uid;
      if (uid != null && displayName != null && displayName.isNotEmpty) {
        await FirestoreService.instance
            .globalCollection('playerProfiles')
            .doc(uid)
            .set({
          'displayName': displayName,
          'displayNameLower': displayName.toLowerCase(),
          if (profile.city != null) 'city': profile.city,
          if (profile.country != null) 'country': profile.country,
          if (profile.avatarUrl != null) 'avatarUrl': profile.avatarUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('ProfileService.updateProfile error: $e');
    }
  }

  /// Fetch and cache profiles for a list of UIDs.
  /// Liest aus dem `playerProfiles/{uid}` Public-Mirror, NICHT aus
  /// `users/{uid}/data/profile`. Letzteres enthaelt PII (street/zip/email/
  /// realizedGains/etc.) die nach Pre-Launch-Hardening nicht mehr public-
  /// readable sind. Der Mirror enthaelt nur Display-Daten + Public-Stats
  /// (displayName, avatar, country, city, bio, rating, reviewCount,
  /// totalSales, memberSince) — alles was die UI fuer fremde User braucht.
  /// Sync-Trigger laufen automatisch bei sellerProfile-Changes (CF).
  Future<void> fetchProfiles(List<String> uids) async {
    final toFetch = uids.where((uid) => !_fetched.contains(uid)).toList();
    if (toFetch.isEmpty) return;

    for (final uid in toFetch) {
      _fetched.add(uid);
      try {
        final doc = await FirestoreService.instance
            .globalCollection('playerProfiles')
            .doc(uid)
            .get();
        if (doc.exists) {
          _cache[uid] = UserProfile.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('ProfileService.fetchProfile($uid) error: $e');
      }
    }
    notifyListeners();
  }

  /// Get a cached profile (returns null if not yet fetched)
  UserProfile? getCachedProfile(String uid) => _cache[uid];

  /// Display name for a UID — from cache, or fallback
  String displayNameFor(String uid, {String fallback = 'Unknown'}) {
    final own = AuthService.instance.uid;
    if (uid == own) {
      return _ownProfile?.displayName ??
          AuthService.instance.currentUser?.displayName ??
          fallback;
    }
    return _cache[uid]?.displayName ?? fallback;
  }
}

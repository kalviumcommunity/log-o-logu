// lib/features/auth/data/auth_repository.dart
//
// The single source of truth for all Firebase Auth + Firestore interactions.
//
// Responsibilities:
//   • Create / destroy Firebase Auth sessions (sign-up, sign-in, sign-out).
//   • Read / write the `users/{uid}` Firestore profile document.
//   • Expose `idTokenChanges()` as a stream of nullable `UserModel` objects
//     so the service layer can react to every token refresh / expiry event.
//   • Translate raw FirebaseAuthException codes into typed [AuthException]s.
//
// This class has NO knowledge of Flutter (no BuildContext, no widgets).
// It can be replaced/mocked in isolation for unit testing.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:log_o_logu/features/auth/domain/auth_exception.dart';
import 'package:log_o_logu/features/auth/domain/user_model.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ─── Convenience Getters ─────────────────────────────────────────────────

  /// Currently signed-in Firebase user; null if not authenticated.
  User? get currentFirebaseUser => _auth.currentUser;

  /// Firestore reference to the current user's profile document.
  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) =>
      _firestore.collection('users').doc(uid);

  // ─── Auth State Stream ───────────────────────────────────────────────────

  /// Emits a [UserModel] whenever the user signs in or their ID-token is
  /// refreshed, and `null` whenever they sign out or the token is revoked.
  ///
  /// Firebase SDK handles token refresh automatically every ~1 hour.
  /// This stream fires on every refresh so the app always has a valid token.
  Stream<UserModel?> get authStateStream {
    return _auth.idTokenChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        // 1️⃣ Try to fetch fresh profile from Firestore server.
        return await _fetchProfile(firebaseUser.uid);
      } on AuthException {
        // Profile not yet created (e.g. mid-signup race) — return null.
        return null;
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable') {
          // 2️⃣ Firestore is offline — try the local cache first.
          debugPrint('[AuthRepository] Firestore offline, falling back to cache.');
          try {
            return await _fetchProfile(firebaseUser.uid, preferCache: true);
          } catch (_) {
            // 3️⃣ No cache either — build a minimal UserModel from the Auth
            //    token so the user is not kicked back to the login screen.
            debugPrint('[AuthRepository] No cache. Building fallback UserModel from Auth token.');
            return UserModel(
              uid: firebaseUser.uid,
              name: firebaseUser.displayName ?? '',
              email: firebaseUser.email ?? '',
              phone: firebaseUser.phoneNumber ?? '',
              role: UserRole.resident,
            );
          }
        }
        debugPrint('[AuthRepository] authStateStream FirebaseException: $e');
        return null;
      } catch (e) {
        debugPrint('[AuthRepository] authStateStream error: $e');
        return null;
      }
    });
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth user, then writes the Firestore profile.
  ///
  /// Returns the fully hydrated [UserModel] on success.
  /// Throws a typed [AuthException] on failure.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? apartmentId,
  }) async {
    late UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }

    final uid = credential.user!.uid;

    final profile = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      apartmentId: apartmentId,
    );

    try {
      await _writeProfile(profile);
    } catch (_) {
      // Roll back: delete the orphaned Auth account so the user can retry.
      await credential.user?.delete().catchError((_) {});
      throw const ProfileCreationException();
    }

    return profile;
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  /// Signs in an existing user and returns their [UserModel] including role.
  ///
  /// Throws a typed [AuthException] on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    late UserCredential credential;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }

    try {
      return await _fetchProfile(credential.user!.uid);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] signOut error: $e');
      // Swallow — user is effectively unauthenticated even on failure.
    }
  }

  // ─── Token Management ────────────────────────────────────────────────────

  /// Force-refreshes the current user's ID token.
  ///
  /// Call this proactively if you receive a 401 from your backend.
  /// On failure throws [TokenRefreshException].
  Future<String> refreshToken() async {
    final user = _auth.currentUser;
    if (user == null) throw const SessionExpiredException();

    try {
      return await user.getIdToken(true) ?? '';
    } catch (e) {
      debugPrint('[AuthRepository] token refresh error: $e');
      throw const TokenRefreshException();
    }
  }

  // ─── FCM Token Update ────────────────────────────────────────────────────

  /// Persists a new [fcmToken] to the user's Firestore profile.
  Future<void> updateFcmToken(String uid, String fcmToken) async {
    try {
      await _userDocRef(uid).update({'fcmToken': fcmToken});
    } catch (e) {
      debugPrint('[AuthRepository] FCM token update failed: $e');
      // Non-critical — do not rethrow.
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  /// Reads the Firestore profile document for [uid].
  ///
  /// If [preferCache] is true, reads from local Firestore cache rather than
  /// the remote server. Used as a fallback when the device is offline.
  Future<UserModel> _fetchProfile(String uid, {bool preferCache = false}) async {
    final snapshot = await _userDocRef(uid).get(
      preferCache ? const GetOptions(source: Source.cache) : null,
    );
    if (!snapshot.exists || snapshot.data() == null) {
      throw const ProfileNotFoundException();
    }
    return UserModel.fromMap(snapshot.data()!);
  }

  /// Writes (creates or overwrites) the Firestore profile document.
  Future<void> _writeProfile(UserModel user) async {
    await _userDocRef(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Converts a [FirebaseAuthException] into a domain [AuthException].
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    debugPrint('[AuthRepository] FirebaseAuthException: ${e.code} — ${e.message}');
    switch (e.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'user-not-found':
        return const UserNotFoundException();
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'invalid-email':
        return const InvalidEmailException();
      case 'user-disabled':
        return const UnknownAuthException('This account has been disabled.');
      case 'too-many-requests':
        return const UnknownAuthException(
          'Too many attempts. Please wait a moment and try again.',
        );
      default:
        return UnknownAuthException(e.message);
    }
  }
}

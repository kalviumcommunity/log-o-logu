// lib/features/auth/domain/auth_service.dart
//
// The application-level orchestration layer sitting between the repository
// and the UI / routing.
//
// Responsibilities:
//   • Expose a clean ChangeNotifier API for state observation via Provider.
//   • Hold the current [UserModel] in memory and publish changes.
//   • Start / cancel the `idTokenChanges()` subscription (token management).
//   • Route sign-up / sign-in / sign-out calls through [AuthRepository].
//   • Handle persistent session failures — clear user state and signal logout.
//
// The UI layer never imports firebase_auth or cloud_firestore.
// It only depends on AuthService and the domain types.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:log_o_logu/features/auth/data/auth_repository.dart';
import 'package:log_o_logu/features/auth/domain/auth_exception.dart';
import 'package:log_o_logu/features/auth/domain/user_model.dart';

/// Possible states of the auth system during startup.
enum AuthStatus {
  /// Firebase has not yet confirmed whether a session exists.
  initializing,

  /// A valid authenticated user session is active.
  authenticated,

  /// No session exists — user must sign in.
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  AuthService({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _init();
  }

  final AuthRepository _repository;

  // ─── State ────────────────────────────────────────────────────────────────

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.initializing;
  AuthException? _lastError;
  bool _isLoading = false;

  /// The currently authenticated user, or null.
  UserModel? get currentUser => _currentUser;

  /// High-level auth status used by GoRouter for redirection.
  AuthStatus get status => _status;

  /// The last authentication error, cleared on the next auth action.
  AuthException? get lastError => _lastError;

  /// True while a network operation (sign-in, sign-up, etc.) is in progress.
  bool get isLoading => _isLoading;

  /// Convenience helpers.
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing  => _status == AuthStatus.initializing;

  // ─── Token Stream Subscription ────────────────────────────────────────────

  StreamSubscription<UserModel?>? _authSub;

  /// Called once from the constructor — subscribes to Firebase token events.
  void _init() {
    _authSub = _repository.authStateStream.listen(
      _onAuthStateChanged,
      onError: _onAuthStreamError,
    );
  }

  /// Handles every emission from `idTokenChanges()`.
  void _onAuthStateChanged(UserModel? user) {
    if (user == null) {
      _updateState(
        user: null,
        status: AuthStatus.unauthenticated,
      );
    } else {
      _updateState(
        user: user,
        status: AuthStatus.authenticated,
      );
    }
  }

  /// Handles persistent errors on the token stream.
  /// This typically signals a revoked token or network failure.
  void _onAuthStreamError(Object error) {
    debugPrint('[AuthService] auth stream error: $error');
    _updateState(
      user: null,
      status: AuthStatus.unauthenticated,
      error: const TokenRefreshException(),
    );
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Creates a new account and signs in.
  ///
  /// Returns the created [UserModel] on success.
  /// Throws a typed [AuthException] and sets [lastError] on failure.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? apartmentId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _repository.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        apartmentId: apartmentId,
      );
      // The auth stream will emit and call _onAuthStateChanged automatically.
      // We return the UserModel here so the UI can act immediately.
      return user;
    } on AuthException catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in an existing user and returns their [UserModel].
  ///
  /// Throws a typed [AuthException] and sets [lastError] on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      return user;
    } on AuthException catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs the current user out and clears local state.
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _repository.signOut();
      // The auth stream will emit null → _onAuthStateChanged sets unauthenticated.
    } finally {
      _setLoading(false);
    }
  }

  /// Force-refreshes the Firebase ID token.
  ///
  /// Call when a backend call returns HTTP 401.
  Future<void> refreshToken() async {
    try {
      await _repository.refreshToken();
    } on AuthException catch (e) {
      _setError(e);
      // A token-refresh failure means the session is gone — log the user out.
      await signOut();
      rethrow;
    }
  }

  /// Stores a new FCM device token for push notification delivery.
  Future<void> updateFcmToken(String fcmToken) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    await _repository.updateFcmToken(uid, fcmToken);
  }

  // ─── Route Guard Helpers ──────────────────────────────────────────────────

  /// True iff the current user is a resident.
  bool get isResident => _currentUser?.role == UserRole.resident;

  /// True iff the current user is a guard.
  bool get isGuard => _currentUser?.role == UserRole.guard;

  /// True iff the current user is an admin.
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // ─── Private Helpers ─────────────────────────────────────────────────────

  void _updateState({
    required UserModel? user,
    required AuthStatus status,
    AuthException? error,
  }) {
    _currentUser = user;
    _status = status;
    if (error != null) _lastError = error;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(AuthException error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

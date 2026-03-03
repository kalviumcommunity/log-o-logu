// lib/features/auth/domain/auth_exception.dart
//
// Centralised, typed exception hierarchy for all authentication failures.
// Keeps Firebase-specific error codes out of the UI layer.

/// Base class for all authentication-related exceptions.
sealed class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

// ─── Credential Errors ────────────────────────────────────────────────────────

/// Email address is already registered.
final class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('This email address is already registered. Please sign in.');
}

/// Supplied credentials are wrong (wrong password).
final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Incorrect email or password. Please try again.');
}

/// No Firebase user exists for the given email.
final class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super('No account found with this email address.');
}

/// Password does not meet Firebase requirements.
final class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Password is too weak. Use at least 6 characters.');
}

/// The supplied email string is badly formatted.
final class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('Please enter a valid email address.');
}

// ─── Session / Token Errors ───────────────────────────────────────────────────

/// The user's Firebase ID token is expired or invalid; session must end.
final class SessionExpiredException extends AuthException {
  const SessionExpiredException()
      : super('Your session has expired. Please sign in again.');
}

/// Persistent token refresh failure — network issues or revoked credentials.
final class TokenRefreshException extends AuthException {
  const TokenRefreshException()
      : super(
          'Unable to refresh your session. Please check your connection and sign in again.',
        );
}

// ─── Firestore Profile Errors ─────────────────────────────────────────────────

/// Firestore document for this user could not be found after creation.
final class ProfileNotFoundException extends AuthException {
  const ProfileNotFoundException()
      : super('User profile not found. Please contact support.');
}

/// Firestore write for the user profile document failed.
final class ProfileCreationException extends AuthException {
  const ProfileCreationException()
      : super('Failed to create user profile. Please try again.');
}

final class MissingApartmentSelectionException extends AuthException {
  const MissingApartmentSelectionException()
      : super('Please select an apartment to continue.');
}

final class MissingResidentGuardDetailsException extends AuthException {
  const MissingResidentGuardDetailsException()
      : super('Please provide flat number, building name, and phone number.');
}

final class MissingApartmentNameException extends AuthException {
  const MissingApartmentNameException()
      : super('Please enter apartment name to continue.');
}

final class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException()
      : super('Google sign-in was cancelled.');
}

final class GoogleSignInConfigurationException extends AuthException {
  const GoogleSignInConfigurationException()
      : super(
          'Google sign-in is not configured correctly for this app build. Please add your app SHA-1/SHA-256 in Firebase project settings, download updated google-services.json, and rebuild the app.',
        );
}

final class ProfileSetupRequiredException extends AuthException {
  const ProfileSetupRequiredException()
      : super('Complete registration first to set role and apartment.');
}

// ─── General / Unknown ────────────────────────────────────────────────────────

/// Fallback for any Firebase or unexpected runtime error.
final class UnknownAuthException extends AuthException {
  const UnknownAuthException([String? detail])
      : super(detail ?? 'An unexpected error occurred. Please try again.');
}

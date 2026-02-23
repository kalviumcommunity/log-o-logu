// lib/features/auth/domain/user_model.dart
//
// Immutable domain representation of a Log-O-Logu user.
// This is the only type the rest of the app should reference —
// it is completely decoupled from Firebase-specific types.

/// The three roles supported by the system.
enum UserRole { resident, guard, admin }

/// Extension helpers for [UserRole] serialization.
extension UserRoleX on UserRole {
  /// Convert enum → Firestore string value.
  String get value {
    switch (this) {
      case UserRole.resident:
        return 'resident';
      case UserRole.guard:
        return 'guard';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case UserRole.resident:
        return 'Resident';
      case UserRole.guard:
        return 'Guard';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Parse a Firestore string into a [UserRole].
/// Falls back to [UserRole.resident] for unknown values.
UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'guard':
      return UserRole.guard;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.resident;
  }
}

/// Immutable user profile stored in Firestore at `users/{uid}`.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// The apartment this user is associated with.
  /// Null for admins or unassigned users.
  final String? apartmentId;

  /// Firebase Cloud Messaging token — updated on each app launch.
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.apartmentId,
    this.fcmToken,
  });

  // ─── Firestore deserialization ─────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: userRoleFromString(map['role'] as String?),
      apartmentId: map['apartmentId'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  // ─── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'apartmentId': apartmentId,
      'fcmToken': fcmToken,
    };
  }

  // ─── Utility ───────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? apartmentId,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      apartmentId: apartmentId ?? this.apartmentId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, role: ${role.value})';
}

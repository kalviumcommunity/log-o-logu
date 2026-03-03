// lib/features/admin/data/admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PendingApprovalUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? flatNumber;
  final String? buildingName;
  final String role;
  final String? apartmentId;

  const PendingApprovalUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.flatNumber,
    required this.buildingName,
    required this.role,
    required this.apartmentId,
  });

  factory PendingApprovalUser.fromMap(String uid, Map<String, dynamic> map) {
    return PendingApprovalUser(
      uid: uid,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? 'No email',
      phone: map['phone'] as String? ?? '',
      flatNumber: map['flatNumber'] as String?,
      buildingName: map['buildingName'] as String?,
      role: map['role'] as String? ?? 'resident',
      apartmentId: map['apartmentId'] as String?,
    );
  }
}

class AdminApartment {
  final String id;
  final String name;

  const AdminApartment({required this.id, required this.name});

  factory AdminApartment.fromMap(String id, Map<String, dynamic> map) {
    return AdminApartment(
      id: id,
      name: map['name'] as String? ?? '',
    );
  }
}

class AdminMetrics {
  final int totalResidents;
  final int pendingApprovals;
  final int visitorsToday;
  final int currentlyInside;
  final int totalGuards;

  const AdminMetrics({
    required this.totalResidents,
    required this.pendingApprovals,
    required this.visitorsToday,
    required this.currentlyInside,
    required this.totalGuards,
  });

  static const empty = AdminMetrics(
    totalResidents: 0,
    pendingApprovals: 0,
    visitorsToday: 0,
    currentlyInside: 0,
    totalGuards: 0,
  );
}

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of system-wide metrics for the Admin Dashboard.
  Stream<AdminMetrics> metricsStream() {
    // We combine multiple counts into one stream of AdminMetrics.
    // In a production app, these might be served by a scheduled Cloud Function
    // that updates a single `metadata/stats` document to save on read costs.
    // For now, we'll watch the collections directly.

    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((usersSnap) async {
      final residents = usersSnap.docs
          .where((doc) => doc.data()['role'] == 'resident')
          .length;

      final guards =
          usersSnap.docs.where((doc) => doc.data()['role'] == 'guard').length;

      // Pending approvals proxy: users with no apartmentId assigned
      final pending = usersSnap.docs
          .where((doc) =>
              (doc.data()['role'] == 'resident' ||
                  doc.data()['role'] == 'guard') &&
              doc.data()['isApproved'] == false)
          .length;

      // Visitors Today and Currently Inside would come from logs
      // For now we'll fetch them once or return 0 if logs collection doesn't exist
      int visitorsToday = 0;
      int currentlyInside = 0;

      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        final visitorsSnap = await _firestore
            .collection('logs')
            .where('entryTime', isGreaterThanOrEqualTo: startOfDay)
            .get();
        visitorsToday = visitorsSnap.docs.length;

        final insideSnap = await _firestore
            .collection('logs')
            .where('exitTime', isNull: true)
            .where('status', isEqualTo: 'entered')
            .get();
        currentlyInside = insideSnap.docs.length;
      } catch (e) {
        // logs collection might not exist yet
      }

      return AdminMetrics(
        totalResidents: residents,
        pendingApprovals: pending,
        visitorsToday: visitorsToday,
        currentlyInside: currentlyInside,
        totalGuards: guards,
      );
    });
  }

  Stream<List<PendingApprovalUser>> pendingUsersStream() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .where('role', whereIn: ['resident', 'guard'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PendingApprovalUser.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> approveUser(String uid) {
    return _firestore.collection('users').doc(uid).update({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AdminApartment>> apartmentsStream() {
    return _firestore.collection('apartments').orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminApartment.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> createApartment(String name) async {
    final doc = _firestore.collection('apartments').doc();
    await doc.set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}

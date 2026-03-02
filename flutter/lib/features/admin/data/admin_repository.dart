// lib/features/admin/data/admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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
              doc.data()['role'] == 'resident' &&
              doc.data()['apartmentId'] == null)
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
}

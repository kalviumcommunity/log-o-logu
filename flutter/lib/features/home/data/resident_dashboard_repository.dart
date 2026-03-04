import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentVisitorLog {
  final String logId;
  final String guestName;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? buildingName;
  final String? flatNumber;
  final String? inviteId;

  const ResidentVisitorLog({
    required this.logId,
    required this.guestName,
    required this.entryTime,
    required this.exitTime,
    required this.buildingName,
    required this.flatNumber,
    required this.inviteId,
  });

  bool get isInside => exitTime == null;

  factory ResidentVisitorLog.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return ResidentVisitorLog(
      logId: id,
      guestName: (map['guestName'] as String?) ?? 'Visitor',
      entryTime: parseDate(map['entryTime'], DateTime.now()),
      exitTime: parseNullableDate(map['exitTime']),
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
      inviteId: map['inviteId'] as String?,
    );
  }
}

class ResidentDirectoryEntry {
  final String uid;
  final String name;
  final String? buildingName;
  final String? flatNumber;

  const ResidentDirectoryEntry({
    required this.uid,
    required this.name,
    required this.buildingName,
    required this.flatNumber,
  });

  String get unitLabel {
    final building = (buildingName ?? '').trim();
    final flat = (flatNumber ?? '').trim();
    if (building.isEmpty && flat.isEmpty) return 'Unit not available';
    if (building.isEmpty) return flat;
    if (flat.isEmpty) return building;
    return '$building • $flat';
  }

  factory ResidentDirectoryEntry.fromMap(String uid, Map<String, dynamic> map) {
    return ResidentDirectoryEntry(
      uid: uid,
      name: (map['name'] as String?) ?? 'Resident',
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
    );
  }
}

class ResidentDashboardRepository {
  final FirebaseFirestore _firestore;

  ResidentDashboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ResidentVisitorLog>> streamRecentVisitorLogs(
    String residentUid, {
    int limit = 20,
  }) {
    return _firestore
        .collection('logs')
        .where('residentUid', isEqualTo: residentUid)
        .orderBy('entryTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResidentVisitorLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  int visitorsTodayCount(List<ResidentVisitorLog> logs) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return logs
        .where(
          (log) =>
              !log.entryTime.isBefore(start) && log.entryTime.isBefore(end),
        )
        .length;
  }

  int visitorsThisMonthCount(List<ResidentVisitorLog> logs) {
    final now = DateTime.now();
    return logs
        .where(
          (log) =>
              log.entryTime.year == now.year && log.entryTime.month == now.month,
        )
        .length;
  }

  Stream<List<ResidentDirectoryEntry>> streamResidentDirectory(
    String apartmentId,
  ) {
    return _firestore
        .collection('users')
        .where('apartmentId', isEqualTo: apartmentId)
        .where('role', isEqualTo: 'resident')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final residents = snapshot.docs
          .map((doc) => ResidentDirectoryEntry.fromMap(doc.id, doc.data()))
          .toList();
      residents.sort(
        (left, right) => left.name.toLowerCase().compareTo(
              right.name.toLowerCase(),
            ),
      );
      return residents;
    });
  }
}
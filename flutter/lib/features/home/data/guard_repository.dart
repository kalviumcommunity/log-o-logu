import 'package:cloud_firestore/cloud_firestore.dart';

class GuardQueueInvite {
  final String inviteId;
  final String guestName;
  final String? purpose;
  final String? buildingName;
  final String? flatNumber;
  final DateTime validFrom;
  final DateTime validUntil;
  final String status;

  const GuardQueueInvite({
    required this.inviteId,
    required this.guestName,
    required this.purpose,
    required this.buildingName,
    required this.flatNumber,
    required this.validFrom,
    required this.validUntil,
    required this.status,
  });

  bool get isReadyNow {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  factory GuardQueueInvite.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return GuardQueueInvite(
      inviteId: id,
      guestName: (map['guestName'] as String?) ?? 'Visitor',
      purpose: map['purpose'] as String?,
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
      validFrom: parseDate(map['validFrom']),
      validUntil: parseDate(map['validUntil']),
      status: (map['status'] as String?) ?? 'pending',
    );
  }
}

class GuardEntryLog {
  final String logId;
  final String guestName;
  final String? buildingName;
  final String? flatNumber;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? inviteId;

  const GuardEntryLog({
    required this.logId,
    required this.guestName,
    required this.buildingName,
    required this.flatNumber,
    required this.entryTime,
    required this.exitTime,
    required this.inviteId,
  });

  bool get isInside => exitTime == null;

  factory GuardEntryLog.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return GuardEntryLog(
      logId: id,
      guestName: (map['guestName'] as String?) ?? 'Visitor',
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
      entryTime: parseNullableDate(map['entryTime']) ?? DateTime.now(),
      exitTime: parseNullableDate(map['exitTime']),
      inviteId: map['inviteId'] as String?,
    );
  }
}

class GuardResident {
  final String uid;
  final String name;
  final String phone;
  final String? buildingName;
  final String? flatNumber;

  const GuardResident({
    required this.uid,
    required this.name,
    required this.phone,
    required this.buildingName,
    required this.flatNumber,
  });

  String get unitLabel {
    final building = (buildingName ?? '').trim();
    final flat = (flatNumber ?? '').trim();
    if (building.isEmpty && flat.isEmpty) return 'Unit not set';
    if (building.isEmpty) return flat;
    if (flat.isEmpty) return building;
    return '$building • $flat';
  }

  factory GuardResident.fromMap(String uid, Map<String, dynamic> map) {
    return GuardResident(
      uid: uid,
      name: (map['name'] as String?) ?? 'Resident',
      phone: (map['phone'] as String?) ?? '',
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
    );
  }
}

class GuardRepository {
  final FirebaseFirestore _firestore;

  GuardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<GuardQueueInvite>> streamValidationQueue(String apartmentId) {
    return _firestore
        .collection('invites')
        .where('apartmentId', isEqualTo: apartmentId)
        .where('status', whereIn: const ['active', 'pending'])
        .snapshots()
        .map((snapshot) {
      final invites = snapshot.docs
          .map((doc) => GuardQueueInvite.fromMap(doc.id, doc.data()))
          .toList();
      invites.sort((a, b) => a.validUntil.compareTo(b.validUntil));
      return invites;
    });
  }

  Stream<List<GuardEntryLog>> streamRecentLogs(
    String apartmentId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('logs')
        .where('apartmentId', isEqualTo: apartmentId)
        .orderBy('entryTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GuardEntryLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<GuardEntryLog>> streamCurrentlyInside(String apartmentId) {
    return _firestore
        .collection('logs')
        .where('apartmentId', isEqualTo: apartmentId)
        .where('exitTime', isNull: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GuardEntryLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<GuardResident>> streamResidentDirectory(String apartmentId) {
    return _firestore
        .collection('users')
        .where('apartmentId', isEqualTo: apartmentId)
        .where('role', isEqualTo: 'resident')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final residents = snapshot.docs
          .map((doc) => GuardResident.fromMap(doc.id, doc.data()))
          .toList();
      residents.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return residents;
    });
  }

  // ── Gate Operations (LLD §3.5) ─────────────────────────────────────────────

  /// Atomically validates an invite via a Firestore transaction:
  /// 1. Reads the invite and checks status + time window.
  /// 2. Sets invite status to 'used'.
  /// 3. Creates a log document with entryTime.
  /// Returns the created [GuardEntryLog] on success, or throws on failure.
  Future<GuardEntryLog> validateAndLogEntry({
    required String inviteId,
    required String guardUid,
    required String apartmentId,
  }) async {
    return _firestore.runTransaction<GuardEntryLog>((transaction) async {
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      final inviteSnap = await transaction.get(inviteRef);

      if (!inviteSnap.exists) {
        throw Exception('Invite not found');
      }

      final data = inviteSnap.data()!;
      final status = data['status'] as String? ?? '';
      final validUntil =
          (data['validUntil'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final validFrom =
          (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime(2100);
      final now = DateTime.now();

      if (status != 'active' && status != 'pending') {
        throw Exception('Invite is no longer valid (status: $status)');
      }
      if (now.isBefore(validFrom)) {
        throw Exception('Invite is not yet active');
      }
      if (now.isAfter(validUntil)) {
        throw Exception('Invite has expired');
      }

      // Mark invite as used
      transaction.update(inviteRef, {'status': 'used'});

      // Create log entry
      final logRef = _firestore.collection('logs').doc();
      final logData = {
        'apartmentId': apartmentId,
        'inviteId': inviteId,
        'residentUid': data['residentUid'] as String? ?? '',
        'scannedByGuardUid': guardUid,
        'guestName': data['guestName'] as String? ?? 'Visitor',
        'entryTime': FieldValue.serverTimestamp(),
        'exitTime': null,
        'buildingName': data['buildingName'] as String?,
        'flatNumber': data['flatNumber'] as String?,
      };
      transaction.set(logRef, logData);

      return GuardEntryLog(
        logId: logRef.id,
        guestName: data['guestName'] as String? ?? 'Visitor',
        buildingName: data['buildingName'] as String?,
        flatNumber: data['flatNumber'] as String?,
        entryTime: now,
        exitTime: null,
        inviteId: inviteId,
      );
    });
  }

  /// Creates a manual service entry log (no invite — delivery / service partner).
  Future<GuardEntryLog> createManualEntry({
    required String apartmentId,
    required String guardUid,
    required String residentUid,
    required String guestName,
    String? buildingName,
    String? flatNumber,
  }) async {
    final logRef = _firestore.collection('logs').doc();
    final now = DateTime.now();
    final logData = {
      'apartmentId': apartmentId,
      'inviteId': null,
      'residentUid': residentUid,
      'scannedByGuardUid': guardUid,
      'guestName': guestName,
      'entryTime': Timestamp.fromDate(now),
      'exitTime': null,
      'buildingName': buildingName,
      'flatNumber': flatNumber,
    };

    await logRef.set(logData);

    return GuardEntryLog(
      logId: logRef.id,
      guestName: guestName,
      buildingName: buildingName,
      flatNumber: flatNumber,
      entryTime: now,
      exitTime: null,
      inviteId: null,
    );
  }

  /// Records the exit time for a visitor log entry.
  Future<void> recordExit(String logId) async {
    await _firestore.collection('logs').doc(logId).update({
      'exitTime': FieldValue.serverTimestamp(),
    });
  }
}
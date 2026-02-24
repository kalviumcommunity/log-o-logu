// lib/features/invite/domain/invite_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { pending, used, expired, cancelled }

extension InviteStatusX on InviteStatus {
  String get value {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.used:
        return 'used';
      case InviteStatus.expired:
        return 'expired';
      case InviteStatus.cancelled:
        return 'cancelled';
    }
  }
}

InviteStatus inviteStatusFromString(String? value) {
  switch (value) {
    case 'used':
      return InviteStatus.used;
    case 'expired':
      return InviteStatus.expired;
    case 'cancelled':
      return InviteStatus.cancelled;
    default:
      return InviteStatus.pending;
  }
}

class InviteModel {
  final String inviteId;
  final String residentUid;
  final String guestName;
  final String guestPhone;
  final DateTime validFrom;
  final DateTime validUntil;
  final InviteStatus status;
  final String type; // e.g., 'one-time'

  const InviteModel({
    required this.inviteId,
    required this.residentUid,
    required this.guestName,
    required this.guestPhone,
    required this.validFrom,
    required this.validUntil,
    this.status = InviteStatus.pending,
    this.type = 'one-time',
  });

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      inviteId: map['inviteId'] as String? ?? '',
      residentUid: map['residentUid'] as String? ?? '',
      guestName: map['guestName'] as String? ?? '',
      guestPhone: map['guestPhone'] as String? ?? '',
      validFrom: (map['validFrom'] as Timestamp).toDate(),
      validUntil: (map['validUntil'] as Timestamp).toDate(),
      status: inviteStatusFromString(map['status'] as String?),
      type: map['type'] as String? ?? 'one-time',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'residentUid': residentUid,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'status': status.value,
      'type': type,
    };
  }

  InviteModel copyWith({
    String? inviteId,
    String? residentUid,
    String? guestName,
    String? guestPhone,
    DateTime? validFrom,
    DateTime? validUntil,
    InviteStatus? status,
    String? type,
  }) {
    return InviteModel(
      inviteId: inviteId ?? this.inviteId,
      residentUid: residentUid ?? this.residentUid,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
  bool get isValid {
    final now = DateTime.now();
    return status == InviteStatus.pending &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil);
  }

  bool get isExpired {
    return status == InviteStatus.expired || DateTime.now().isAfter(validUntil);
  }
}

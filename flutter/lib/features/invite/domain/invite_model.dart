// lib/features/invite/domain/invite_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { active, pending, used, expired, cancelled }

extension InviteStatusX on InviteStatus {
  String get value {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.active:
        return 'active';
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
    case 'active':
      return InviteStatus.active;
    case 'pending':
      return InviteStatus.pending;
    case 'used':
      return InviteStatus.used;
    case 'expired':
      return InviteStatus.expired;
    case 'cancelled':
      return InviteStatus.cancelled;
    default:
      return InviteStatus.active;
  }
}

class InviteModel {
  final String inviteId;
  final String apartmentId;
  final String residentUid;
  final String guestName;
  final String guestPhone;
  final String purpose;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? buildingName;
  final String? flatNumber;
  final InviteStatus status;
  final String type; // e.g., 'one-time'
  final bool notifyOnArrival;

  const InviteModel({
    required this.inviteId,
    required this.apartmentId,
    required this.residentUid,
    required this.guestName,
    required this.guestPhone,
    this.purpose = 'guest',
    required this.validFrom,
    required this.validUntil,
    this.buildingName,
    this.flatNumber,
    this.status = InviteStatus.active,
    this.type = 'one-time',
    this.notifyOnArrival = true,
  });

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      inviteId: map['inviteId'] as String? ?? '',
      apartmentId: map['apartmentId'] as String? ?? '',
      residentUid: map['residentUid'] as String? ?? '',
      guestName: map['guestName'] as String? ?? '',
      guestPhone: map['guestPhone'] as String? ?? '',
      purpose: map['purpose'] as String? ?? 'guest',
      validFrom: (map['validFrom'] as Timestamp).toDate(),
      validUntil: (map['validUntil'] as Timestamp).toDate(),
      buildingName: map['buildingName'] as String?,
      flatNumber: map['flatNumber'] as String?,
      status: inviteStatusFromString(map['status'] as String?),
      type: map['type'] as String? ?? 'one-time',
      notifyOnArrival: map['notifyOnArrival'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'apartmentId': apartmentId,
      'residentUid': residentUid,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'purpose': purpose,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'buildingName': buildingName,
      'flatNumber': flatNumber,
      'status': status.value,
      'type': type,
      'notifyOnArrival': notifyOnArrival,
    };
  }

  InviteModel copyWith({
    String? inviteId,
    String? apartmentId,
    String? residentUid,
    String? guestName,
    String? guestPhone,
    String? purpose,
    DateTime? validFrom,
    DateTime? validUntil,
    String? buildingName,
    String? flatNumber,
    InviteStatus? status,
    String? type,
    bool? notifyOnArrival,
  }) {
    return InviteModel(
      inviteId: inviteId ?? this.inviteId,
      apartmentId: apartmentId ?? this.apartmentId,
      residentUid: residentUid ?? this.residentUid,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      purpose: purpose ?? this.purpose,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      buildingName: buildingName ?? this.buildingName,
      flatNumber: flatNumber ?? this.flatNumber,
      status: status ?? this.status,
      type: type ?? this.type,
      notifyOnArrival: notifyOnArrival ?? this.notifyOnArrival,
    );
  }
  bool get isValid {
    final now = DateTime.now();
    return (status == InviteStatus.pending || status == InviteStatus.active) &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil);
  }

  bool get isExpired {
    return status == InviteStatus.expired || DateTime.now().isAfter(validUntil);
  }
}

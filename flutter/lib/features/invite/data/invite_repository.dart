// lib/features/invite/data/invite_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';

class InviteRepository {
  final FirebaseFirestore _firestore;

  InviteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invitesCollection =>
      _firestore.collection('invites');

  Future<void> createInvite(InviteModel invite) async {
    await _invitesCollection.doc(invite.inviteId).set(invite.toMap());
  }

  Future<InviteModel?> getInvite(String inviteId) async {
    final doc = await _invitesCollection.doc(inviteId).get();
    if (doc.exists && doc.data() != null) {
      return InviteModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<List<InviteModel>> streamResidentInvites(String residentUid) {
    return _invitesCollection
        .where('residentUid', isEqualTo: residentUid)
        .orderBy('validUntil', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<InviteModel>> streamPendingInvites() {
    return _invitesCollection
        .where('status', whereIn: [
          InviteStatus.active.value,
          InviteStatus.pending.value,
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .toList());
  }

  /// Cancels an invite by setting its status to 'cancelled'.
  /// Only cancels if the current status is 'active' or 'pending'.
  Future<void> cancelInvite(String inviteId) async {
    final doc = await _invitesCollection.doc(inviteId).get();
    if (!doc.exists) throw Exception('Invite not found');

    final currentStatus = doc.data()?['status'] as String?;
    if (currentStatus != 'active' && currentStatus != 'pending') {
      throw Exception('Invite cannot be cancelled (status: $currentStatus)');
    }

    await _invitesCollection.doc(inviteId).update({
      'status': InviteStatus.cancelled.value,
    });
  }
}

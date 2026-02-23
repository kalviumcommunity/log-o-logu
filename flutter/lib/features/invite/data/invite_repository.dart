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
        .orderBy('validFrom', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .toList());
  }
}

// lib/features/invite/domain/invite_service.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:log_o_logu/features/invite/data/invite_repository.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';

class InviteService extends ChangeNotifier {
  final InviteRepository _repository;
  final _uuid = const Uuid();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  InviteService({InviteRepository? repository})
      : _repository = repository ?? InviteRepository();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Creates a new guest invite and returns the generated inviteId.
  Future<String?> createGuestInvite({
    required String residentUid,
    required String guestName,
    required String guestPhone,
    DateTime? validFrom,
    DateTime? validUntil,
    String type = 'one-time',
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final inviteId = _uuid.v4();
      final now = DateTime.now();
      
      final invite = InviteModel(
        inviteId: inviteId,
        residentUid: residentUid,
        guestName: guestName,
        guestPhone: guestPhone,
        validFrom: validFrom ?? now,
        validUntil: validUntil ?? now.add(const Duration(hours: 24)),
        status: InviteStatus.pending,
        type: type,
      );

      await _repository.createInvite(invite);
      return inviteId;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Streams invites for a specific resident.
  Stream<List<InviteModel>> streamResidentInvites(String residentUid) {
    return _repository.streamResidentInvites(residentUid);
  }

  void clearError() {
    _setError(null);
  }
}

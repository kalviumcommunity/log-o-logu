// lib/features/admin/domain/admin_service.dart

import 'package:flutter/foundation.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';

class AdminService with ChangeNotifier {
  final AdminRepository _repository;
  AdminMetrics _metrics = AdminMetrics.empty;
  bool _isLoading = false;
  bool _isApproving = false;
  bool _isCreatingApartment = false;

  AdminService({required AdminRepository repository})
      : _repository = repository;

  AdminMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  bool get isApproving => _isApproving;
  bool get isCreatingApartment => _isCreatingApartment;

  /// Starts listening to metrics stream.
  void initMetrics() {
    _isLoading = true;
    notifyListeners();

    _repository.metricsStream().listen((metrics) {
      _metrics = metrics;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('AdminService metrics error: $e');
    });
  }

  Stream<List<PendingApprovalUser>> pendingUsersStream() {
    return _repository.pendingUsersStream();
  }

  Stream<List<AdminApartment>> apartmentsStream() {
    return _repository.apartmentsStream();
  }

  Future<void> approveUser(String uid) async {
    _isApproving = true;
    notifyListeners();
    try {
      await _repository.approveUser(uid);
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  Future<void> createApartment(String name) async {
    _isCreatingApartment = true;
    notifyListeners();
    try {
      await _repository.createApartment(name.trim());
    } finally {
      _isCreatingApartment = false;
      notifyListeners();
    }
  }
}

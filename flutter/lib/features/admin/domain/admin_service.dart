// lib/features/admin/domain/admin_service.dart

import 'package:flutter/foundation.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';

class AdminService with ChangeNotifier {
  final AdminRepository _repository;
  AdminMetrics _metrics = AdminMetrics.empty;
  bool _isLoading = false;

  AdminService({required AdminRepository repository})
      : _repository = repository;

  AdminMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;

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
}

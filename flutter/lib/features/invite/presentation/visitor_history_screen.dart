// lib/features/invite/presentation/visitor_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/home/data/resident_dashboard_repository.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  static final ResidentDashboardRepository _residentRepo =
      ResidentDashboardRepository();

  Stream<List<ResidentVisitorLog>>? _logsStream;
  String? _cachedUid;
  List<ResidentVisitorLog> _lastKnownLogs = const [];
  bool _initialLoaded = false;

  @override
  Widget build(BuildContext context) {
    final residentUid = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.uid,
    );

    if (residentUid == null || residentUid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Resident profile not available.',
            style: TextStyle(color: AppTheme.greyText),
          ),
        ),
      );
    }

    if (_cachedUid != residentUid) {
      _cachedUid = residentUid;
      _initialLoaded = false;
      _lastKnownLogs = const [];
      _logsStream = _residentRepo.streamRecentVisitorLogs(residentUid, limit: 200);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visitor History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ResidentVisitorLog>>(
              stream: _logsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _lastKnownLogs = snapshot.data!;
                  _initialLoaded = true;
                }

                if (snapshot.hasError && !_initialLoaded) {
                  debugPrint(
                      '[VisitorHistory] logs stream error: ${snapshot.error}');
                  _initialLoaded = true;
                }

                if (!_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = _lastKnownLogs;

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No visitor history found.',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _HistoryListItem(log: logs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // History
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.greyText,
        onTap: (index) {
          if (index == 0) context.go('/resident');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Pre-invite'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final ResidentVisitorLog log;

  const _HistoryListItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
           Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.guestName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Entry: ${DateFormat('MMM d, hh:mm a').format(log.entryTime)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
                if (log.exitTime != null)
                  Text(
                    'Exit: ${DateFormat('MMM d, hh:mm a').format(log.exitTime!)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (log.isInside ? Colors.green : Colors.grey)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.isInside ? 'ENTERED' : 'COMPLETED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: log.isInside ? Colors.green : AppTheme.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

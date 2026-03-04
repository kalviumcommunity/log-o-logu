import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/home/data/guard_repository.dart';

class GuardLogsTab extends StatefulWidget {
  const GuardLogsTab({super.key});

  @override
  State<GuardLogsTab> createState() => _GuardLogsTabState();
}

class _GuardLogsTabState extends State<GuardLogsTab> {
  static final GuardRepository _guardRepository = GuardRepository();

  Stream<List<GuardEntryLog>>? _logsStream;
  String? _cachedApartmentId;
  List<GuardEntryLog> _lastKnownLogs = const [];
  bool _initialLoaded = false;

  @override
  Widget build(BuildContext context) {
    final apartmentId = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.apartmentId,
    );

    if (apartmentId == null || apartmentId.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Apartment is not configured for this guard profile.',
            style: TextStyle(color: AppTheme.greyText),
          ),
        ),
      );
    }

    if (_cachedApartmentId != apartmentId) {
      _cachedApartmentId = apartmentId;
      _initialLoaded = false;
      _lastKnownLogs = const [];
      _logsStream = _guardRepository.streamRecentLogs(apartmentId);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entry Logs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a visitor to log their exit',
              style: TextStyle(color: AppTheme.greyText),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<GuardEntryLog>>(
                stream: _logsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _lastKnownLogs = snapshot.data!;
                    _initialLoaded = true;
                  }
                  if (snapshot.hasError && !_initialLoaded) {
                    debugPrint('[GuardLogs] stream error: ${snapshot.error}');
                    _initialLoaded = true;
                  }

                  if (!_initialLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = _lastKnownLogs;

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 72,
                            color: AppTheme.greyText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No logs yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = logs[index];
                      return _LogTile(
                        entry: entry,
                        onRecordExit: entry.isInside
                            ? () => _confirmExit(context, entry)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, GuardEntryLog entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Exit'),
        content: Text(
            'Mark ${entry.guestName} as exited?\n${entry.buildingName ?? ''} ${entry.flatNumber ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Exit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _guardRepository.recordExit(entry.logId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.guestName} exit recorded')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _LogTile extends StatelessWidget {
  final GuardEntryLog entry;
  final VoidCallback? onRecordExit;

  const _LogTile({required this.entry, this.onRecordExit});

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${entry.buildingName ?? 'Building'} • ${entry.flatNumber ?? 'Flat'}';

    return Card(
      child: ListTile(
        onTap: onRecordExit,
        leading: CircleAvatar(
          backgroundColor: entry.isInside
              ? Colors.green.withValues(alpha: 0.14)
              : AppTheme.greyText.withValues(alpha: 0.14),
          child: Icon(
            entry.isInside ? Icons.login_rounded : Icons.logout_rounded,
            color: entry.isInside ? Colors.green : AppTheme.greyText,
          ),
        ),
        title: Text(
          entry.guestName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$subtitle\nIn: ${_formatDateTime(entry.entryTime)}${entry.exitTime != null ? '\nOut: ${_formatDateTime(entry.exitTime!)}' : ''}',
        ),
        isThreeLine: true,
        trailing: entry.isInside
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'INSIDE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.exit_to_app,
                      size: 18, color: Colors.orange.shade700),
                ],
              )
            : const Text(
                'EXITED',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.greyText,
                ),
              ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridian = value.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $meridian';
  }
}

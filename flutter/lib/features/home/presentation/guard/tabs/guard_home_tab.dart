import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/home/data/guard_repository.dart';
import 'package:log_o_logu/features/home/presentation/guard/scan_qr_screen.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

class GuardHomeTab extends StatefulWidget {
  const GuardHomeTab({super.key});

  @override
  State<GuardHomeTab> createState() => _GuardHomeTabState();
}

class _GuardHomeTabState extends State<GuardHomeTab> {
  static final GuardRepository _guardRepository = GuardRepository();

  Stream<List<GuardQueueInvite>>? _queueStream;
  Stream<List<GuardEntryLog>>? _insideStream;
  String? _cachedApartmentId;

  List<GuardQueueInvite> _lastKnownQueue = const [];
  List<GuardEntryLog> _lastKnownInside = const [];
  bool _initialQueueLoaded = false;
  bool _initialInsideLoaded = false;

  void _ensureStreams(String apartmentId) {
    if (_cachedApartmentId != apartmentId) {
      _cachedApartmentId = apartmentId;
      _initialQueueLoaded = false;
      _initialInsideLoaded = false;
      _lastKnownQueue = const [];
      _lastKnownInside = const [];
      _queueStream = _guardRepository.streamValidationQueue(apartmentId);
      _insideStream = _guardRepository.streamCurrentlyInside(apartmentId);
    }
  }

  // ── Invite validation with Firestore transaction + log creation ──

  Future<void> _validateAndLog(BuildContext context, String rawPayload) async {
    final inviteId = _extractInviteId(rawPayload);
    if (inviteId.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    final apartmentId = user?.apartmentId;
    final guardUid = user?.uid;

    if (apartmentId == null || guardUid == null) return;

    // Show a loading dialog while the transaction runs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final log = await _guardRepository.validateAndLogEntry(
        inviteId: inviteId,
        guardUid: guardUid,
        apartmentId: apartmentId,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      await _showResultDialog(
        context,
        success: true,
        title: 'Access Granted',
        message: '${log.guestName} has been logged in.\n'
            '${log.buildingName ?? ''} ${log.flatNumber ?? ''}',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      await _showResultDialog(
        context,
        success: false,
        title: 'Access Denied',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _showResultDialog(
    BuildContext context, {
    required bool success,
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? Colors.green : AppTheme.errorRed,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInviteValidationDialog(BuildContext context) async {
    final controller = TextEditingController();

    final inviteId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validate Invite ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Invite ID',
            hintText: 'Paste or type invite ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Validate'),
          ),
        ],
      ),
    );

    if (!context.mounted || inviteId == null || inviteId.isEmpty) return;
    await _validateAndLog(context, inviteId);
  }

  Future<void> _openQrScanner(BuildContext context) async {
    final scannedPayload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );

    if (!context.mounted || scannedPayload == null || scannedPayload.isEmpty) {
      return;
    }
    await _validateAndLog(context, scannedPayload);
  }

  // ── Manual service entry (LLD §3.4 — unplanned visitor) ──

  Future<void> _openManualEntryDialog(BuildContext context) async {
    final user = context.read<AuthService>().currentUser;
    final apartmentId = user?.apartmentId;
    final guardUid = user?.uid;

    if (apartmentId == null || guardUid == null) return;

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Fetch resident list for dropdown
    final residents =
        await _guardRepository.streamResidentDirectory(apartmentId).first;

    GuardResident? selectedResident;

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Manual Service Entry'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Log an unplanned visitor (delivery, service partner)',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.greyText),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Visitor / Company Name',
                        hintText: 'e.g. Swiggy, Amazon',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GuardResident>(
                      decoration: const InputDecoration(
                        labelText: 'Resident (destination)',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      items: residents
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                    '${r.name} • ${r.unitLabel}',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedResident = v),
                      validator: (v) =>
                          v == null ? 'Select a resident' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: const Text('Log Entry'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true ||
        !context.mounted ||
        selectedResident == null) {
      return;
    }

    try {
      final log = await _guardRepository.createManualEntry(
        apartmentId: apartmentId,
        guardUid: guardUid,
        residentUid: selectedResident!.uid,
        guestName: nameController.text.trim(),
        buildingName: selectedResident!.buildingName,
        flatNumber: selectedResident!.flatNumber,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${log.guestName} logged in → ${selectedResident!.unitLabel}'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _extractInviteId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    final queryId = uri.queryParameters['inviteId'];
    if (queryId != null && queryId.trim().isNotEmpty) return queryId.trim();
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final last = segments.last.trim();
      if (last.isNotEmpty) return last;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthService, 
        ({String? uid, String? apartmentId, String? name})>(
      (auth) => (
        uid: auth.currentUser?.uid,
        apartmentId: auth.currentUser?.apartmentId,
        name: auth.currentUser?.name,
      ),
    );
    final apartmentId = user.apartmentId;

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

    _ensureStreams(apartmentId);

    return StreamBuilder<List<GuardQueueInvite>>(
      stream: _queueStream,
      builder: (context, queueSnapshot) {
        if (queueSnapshot.hasData) {
          _lastKnownQueue = queueSnapshot.data!;
          _initialQueueLoaded = true;
        }
        if (queueSnapshot.hasError && !_initialQueueLoaded) {
          debugPrint('[GuardHome] queue error: ${queueSnapshot.error}');
          _initialQueueLoaded = true;
        }

        final queue = _lastKnownQueue;
        final now = DateTime.now();

        final readyNow = queue
            .where((i) =>
                now.isAfter(i.validFrom) && now.isBefore(i.validUntil))
            .toList()
          ..sort((a, b) => a.validUntil.compareTo(b.validUntil));

        final upcoming = queue
            .where((i) => now.isBefore(i.validFrom))
            .toList()
          ..sort((a, b) => a.validFrom.compareTo(b.validFrom));

        return StreamBuilder<List<GuardEntryLog>>(
          stream: _insideStream,
          builder: (context, insideSnapshot) {
            if (insideSnapshot.hasData) {
              _lastKnownInside = insideSnapshot.data!;
              _initialInsideLoaded = true;
            }
            if (insideSnapshot.hasError && !_initialInsideLoaded) {
              debugPrint('[GuardHome] inside error: ${insideSnapshot.error}');
              _initialInsideLoaded = true;
            }

            if (!_initialQueueLoaded || !_initialInsideLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final insideCount = _lastKnownInside.length;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Welcome, ${user.name?.split(' ').first ?? 'Guard'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$apartmentId • Gate Operations',
                    style: const TextStyle(color: AppTheme.greyText),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'READY NOW',
                          value: '${readyNow.length}',
                          color: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'UPCOMING',
                          value: '${upcoming.length}',
                          color: const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'INSIDE',
                          value: '$insideCount',
                          color: const Color(0xFFFFF3E0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Actions ──
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _openQrScanner(context),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan QR'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _openInviteValidationDialog(context),
                                  icon: const Icon(Icons.badge_outlined),
                                  label: const Text('Enter ID'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openManualEntryDialog(context),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Manual Service Entry'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(
                                    color: Colors.orange.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Pending Validation Queue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (readyNow.isEmpty && upcoming.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No pending invites right now.',
                          style: TextStyle(color: AppTheme.greyText),
                        ),
                      ),
                    )
                  else
                    ...[...readyNow, ...upcoming.take(5)].map(
                      (invite) => _QueueTile(invite: invite),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Metric card ────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Queue tile ─────────────────────────────────────────────────────────────────

class _QueueTile extends StatelessWidget {
  final GuardQueueInvite invite;

  const _QueueTile({required this.invite});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isReady =
      now.isAfter(invite.validFrom) && now.isBefore(invite.validUntil);
    final subtitle = isReady
        ? 'Valid until ${_formatTime(invite.validUntil)}'
        : 'Valid from ${_formatTime(invite.validFrom)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReady
              ? Colors.green.withValues(alpha: 0.15)
              : AppTheme.primaryBlue.withValues(alpha: 0.12),
          child: Icon(
            isReady ? Icons.verified_user_outlined : Icons.schedule,
            color: isReady ? Colors.green : AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          invite.guestName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: invite.flatNumber != null || invite.buildingName != null,
        subtitleTextStyle: const TextStyle(color: AppTheme.greyText),
        dense: false,
        trailing: Text(
          isReady ? 'READY' : 'UPCOMING',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isReady ? Colors.green : AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridian = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridian';
  }
}

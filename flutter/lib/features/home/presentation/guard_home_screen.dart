import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/features/invite/domain/invite_service.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

class GuardHomeScreen extends StatelessWidget {
  const GuardHomeScreen({super.key});

  Future<void> _openInviteValidationDialog(
    BuildContext context,
    InviteService inviteService,
  ) async {
    final controller = TextEditingController();

    final inviteId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Check'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || inviteId == null || inviteId.isEmpty) {
      return;
    }

    final invite = await inviteService.getInviteById(inviteId);

    if (!context.mounted) return;

    final now = DateTime.now();
    final isValidNow = invite != null &&
        invite.status == InviteStatus.pending &&
        now.isAfter(invite.validFrom) &&
        now.isBefore(invite.validUntil);

    final title = isValidNow ? 'Access Allowed' : 'Access Denied';
    final icon = isValidNow ? Icons.verified_user : Icons.block;
    final iconColor = isValidNow ? Colors.green : AppTheme.errorRed;
    final details = invite == null
        ? 'Invite not found.'
        : '${invite.guestName} • ${invite.guestPhone}\nStatus: ${invite.status.value.toUpperCase()}';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(details),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final inviteService = context.watch<InviteService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<InviteModel>>(
        stream: inviteService.streamPendingInvites(),
        builder: (context, snapshot) {
          final invites = snapshot.data ?? const <InviteModel>[];
          final now = DateTime.now();

          final readyNow = invites
              .where((invite) => now.isAfter(invite.validFrom) && now.isBefore(invite.validUntil))
              .toList()
            ..sort((a, b) => a.validUntil.compareTo(b.validUntil));

          final upcoming = invites
              .where((invite) => now.isBefore(invite.validFrom))
              .toList()
            ..sort((a, b) => a.validFrom.compareTo(b.validFrom));

          final expired = invites.where((invite) => now.isAfter(invite.validUntil)).length;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome, ${user?.name.split(' ').first ?? 'Guard'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.apartmentId ?? 'Apartment'} • Gate Operations',
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
                        label: 'EXPIRED',
                        value: '$expired',
                        color: const Color(0xFFFFEBEE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openInviteValidationDialog(context, inviteService),
                                icon: const Icon(Icons.badge_outlined),
                                label: const Text('Validate Invite ID'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('QR scanner will be enabled in the next iteration.')),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan QR'),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}

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

class _QueueTile extends StatelessWidget {
  final InviteModel invite;

  const _QueueTile({required this.invite});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isReady = now.isAfter(invite.validFrom) && now.isBefore(invite.validUntil);
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

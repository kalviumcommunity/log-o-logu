import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/home/data/resident_dashboard_repository.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/features/invite/domain/invite_service.dart';
import 'package:log_o_logu/features/invite/presentation/invite_qr_screen.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the user's UID actually changes, not on every
    // AuthService notification (isLoading, error clears, metadata changes).
    final uid = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.uid,
    );

    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Resident profile not available.',
            style: TextStyle(color: AppTheme.greyText),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ResidentOverviewTab(
            onOpenHistory: () => setState(() => _currentIndex = 2),
          ),
          const _ResidentDirectoryTab(),
          const _ResidentHistoryTab(),
          const _ResidentProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/create-invite'),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon:
                Icon(Icons.group_rounded, color: AppTheme.primaryBlue),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon:
                Icon(Icons.history_rounded, color: AppTheme.primaryBlue),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ResidentOverviewTab extends StatefulWidget {
  final VoidCallback onOpenHistory;

  const _ResidentOverviewTab({required this.onOpenHistory});

  @override
  State<_ResidentOverviewTab> createState() => _ResidentOverviewTabState();
}

class _ResidentOverviewTabState extends State<_ResidentOverviewTab> {
  static final ResidentDashboardRepository _residentRepo =
      ResidentDashboardRepository();

  Stream<List<ResidentVisitorLog>>? _logsStream;
  Stream<List<InviteModel>>? _invitesStream;
  String? _cachedUid;

  // Cache last known good data so stream errors don't blank the UI.
  List<ResidentVisitorLog> _lastKnownLogs = const [];
  List<InviteModel> _lastKnownInvites = const [];
  bool _initialLogsLoaded = false;
  bool _initialInvitesLoaded = false;

  void _ensureStreams(String uid, InviteService inviteService) {
    if (_cachedUid != uid) {
      _cachedUid = uid;
      _initialLogsLoaded = false;
      _initialInvitesLoaded = false;
      _lastKnownLogs = const [];
      _lastKnownInvites = const [];
      _logsStream = _residentRepo.streamRecentVisitorLogs(uid, limit: 150);
      _invitesStream = inviteService.streamResidentInvites(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final inviteService = context.read<InviteService>();

    if (user == null || user.uid.isEmpty) {
      return const Center(
        child: Text(
          'Resident profile not available.',
          style: TextStyle(color: AppTheme.greyText),
        ),
      );
    }

    _ensureStreams(user.uid, inviteService);

    return SafeArea(
      child: StreamBuilder<List<ResidentVisitorLog>>(
        stream: _logsStream,
        builder: (context, logsSnapshot) {
          // Update cache when real data arrives
          if (logsSnapshot.hasData) {
            _lastKnownLogs = logsSnapshot.data!;
            _initialLogsLoaded = true;
          }

          // Also mark as loaded on error so the spinner stops
          if (logsSnapshot.hasError && !_initialLogsLoaded) {
            debugPrint('[ResidentOverview] logs stream error: ${logsSnapshot.error}');
            _initialLogsLoaded = true;
          }

          // Show loader only before ANY data has ever arrived
          if (!_initialLogsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // Always use cached data — survives stream errors
          final logs = _lastKnownLogs;
          final visitorsToday = _residentRepo.visitorsTodayCount(logs);
          final visitorsThisMonth = _residentRepo.visitorsThisMonthCount(logs);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.name.split(' ').first}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        Text(
                          '${user.buildingName ?? 'Building'} • ${user.flatNumber ?? 'Flat'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'ACTIVE TODAY',
                      value: visitorsToday.toString().padLeft(2, '0'),
                      color: const Color(0xFFEFF6FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      label: 'TOTAL MONTHLY',
                      value: visitorsThisMonth.toString().padLeft(2, '0'),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Guest Invites',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenHistory,
                    child: const Text('View History'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<InviteModel>>(
                stream: _invitesStream,
                builder: (context, snapshot) {
                  // Update cache when real data arrives
                  if (snapshot.hasData) {
                    _lastKnownInvites = snapshot.data!;
                    _initialInvitesLoaded = true;
                  }

                  // Also mark as loaded on error so the spinner stops
                  if (snapshot.hasError && !_initialInvitesLoaded) {
                    debugPrint('[ResidentOverview] invites stream error: ${snapshot.error}');
                    _initialInvitesLoaded = true;
                  }

                  if (!_initialInvitesLoaded) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Always use cached data — survives stream errors
                  final invites = _lastKnownInvites
                      .where((invite) =>
                          invite.status == InviteStatus.active ||
                          invite.status == InviteStatus.pending)
                      .toList();

                  if (invites.isEmpty) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Text(
                          'No active invites',
                          style: TextStyle(color: AppTheme.greyText),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: invites.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return _InviteCard(invite: invites[index]);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Visitors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: widget.onOpenHistory,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_initialLogsLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No visitors recorded yet.',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  ),
                )
              else
                ...logs.take(5).map(
                  (log) {
                    final status = log.isInside ? 'ENTERED' : 'COMPLETED';
                    final statusColor =
                        log.isInside ? Colors.green : AppTheme.greyText;
                    final details = log.isInside
                        ? 'Entry: ${DateFormat('MMM d, hh:mm a').format(log.entryTime)}'
                        : 'Exit: ${DateFormat('MMM d, hh:mm a').format(log.exitTime!)}';

                    return _VisitorListItem(
                      name: log.guestName,
                      details: details,
                      status: status,
                      statusColor: statusColor,
                    );
                  },
                ),
              const SizedBox(height: 90),
            ],
          );
        },
      ),
    );
  }
}

class _ResidentDirectoryTab extends StatefulWidget {
  const _ResidentDirectoryTab();

  @override
  State<_ResidentDirectoryTab> createState() => _ResidentDirectoryTabState();
}

class _ResidentDirectoryTabState extends State<_ResidentDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  static final ResidentDashboardRepository _residentRepo =
      ResidentDashboardRepository();

  String _query = '';
  Stream<List<ResidentDirectoryEntry>>? _directoryStream;
  String? _cachedApartmentId;
  List<ResidentDirectoryEntry> _lastKnownEntries = const [];
  bool _initialLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apartmentId = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.apartmentId,
    );

    if (apartmentId == null || apartmentId.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Apartment is not configured.',
            style: TextStyle(color: AppTheme.greyText),
          ),
        ),
      );
    }

    if (_cachedApartmentId != apartmentId) {
      _cachedApartmentId = apartmentId;
      _initialLoaded = false;
      _lastKnownEntries = const [];
      _directoryStream = _residentRepo.streamResidentDirectory(apartmentId);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Resident Directory',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or unit',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ResidentDirectoryEntry>>(
              stream: _directoryStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _lastKnownEntries = snapshot.data!;
                  _initialLoaded = true;
                }

                if (snapshot.hasError && !_initialLoaded) {
                  debugPrint(
                      '[ResidentDirectory] stream error: ${snapshot.error}');
                  _initialLoaded = true;
                }

                if (!_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = _lastKnownEntries;
                final lower = _query.toLowerCase();
                final filtered = lower.isEmpty
                    ? entries
                    : entries
                        .where(
                          (entry) =>
                              entry.name.toLowerCase().contains(lower) ||
                              entry.unitLabel.toLowerCase().contains(lower),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No residents found.',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final initial = entry.name.isEmpty
                        ? 'R'
                        : entry.name[0].toUpperCase();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          entry.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(entry.unitLabel),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentHistoryTab extends StatefulWidget {
  const _ResidentHistoryTab();

  @override
  State<_ResidentHistoryTab> createState() => _ResidentHistoryTabState();
}

class _ResidentHistoryTabState extends State<_ResidentHistoryTab> {
  static final ResidentDashboardRepository _residentRepo =
      ResidentDashboardRepository();

  Stream<List<ResidentVisitorLog>>? _logsStream;
  String? _cachedUid;
  List<ResidentVisitorLog> _lastKnownLogs = const [];
  bool _initialLoaded = false;

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.uid,
    );

    if (uid == null || uid.isEmpty) {
      return const Center(
        child: Text(
          'Resident profile not available.',
          style: TextStyle(color: AppTheme.greyText),
        ),
      );
    }

    if (_cachedUid != uid) {
      _cachedUid = uid;
      _initialLoaded = false;
      _lastKnownLogs = const [];
      _logsStream = _residentRepo.streamRecentVisitorLogs(uid, limit: 200);
    }

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Visitor History',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ResidentVisitorLog>>(
              stream: _logsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _lastKnownLogs = snapshot.data!;
                  _initialLoaded = true;
                }

                if (snapshot.hasError && !_initialLoaded) {
                  debugPrint('[ResidentHistory] logs stream error: ${snapshot.error}');
                  _initialLoaded = true;
                }

                final logs = _lastKnownLogs;

                if (!_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No visitor history found.',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final status = log.isInside ? 'ENTERED' : 'COMPLETED';
                    final statusColor =
                        log.isInside ? Colors.green : AppTheme.greyText;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.14),
                          child: Icon(
                            log.isInside ? Icons.login_rounded : Icons.logout,
                            color: statusColor,
                          ),
                        ),
                        title: Text(
                          log.guestName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Entry: ${DateFormat('MMM d, hh:mm a').format(log.entryTime)}${log.exitTime != null ? '\nExit: ${DateFormat('MMM d, hh:mm a').format(log.exitTime!)}' : ''}',
                        ),
                        isThreeLine: log.exitTime != null,
                        trailing: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentProfileTab extends StatelessWidget {
  const _ResidentProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  child: Text(
                    (user?.name.isNotEmpty == true)
                        ? user!.name[0].toUpperCase()
                        : 'R',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Resident',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.buildingName ?? 'Building'} • ${user?.flatNumber ?? 'Flat'}',
                  style: const TextStyle(color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '—',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user?.phone ?? '—',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.apartment_outlined,
            label: 'Apartment',
            value: user?.apartmentId ?? '—',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.greyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final InviteModel invite;

  const _InviteCard({required this.invite});

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invite'),
        content: Text('Cancel the invite for ${invite.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success =
          await context.read<InviteService>().cancelInvite(invite.inviteId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Invite cancelled'
                : 'Failed to cancel invite'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.qr_code, size: 24, color: AppTheme.primaryBlue),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VALID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _confirmCancel(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.close, size: 18, color: AppTheme.greyText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            invite.guestName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.primaryBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Exp: ${DateFormat('E, h:mm a').format(invite.validUntil)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InviteQRScreen(invite: invite),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 14),
                  SizedBox(width: 4),
                  Text('View QR', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorListItem extends StatelessWidget {
  final String name;
  final String details;
  final String status;
  final Color statusColor;

  const _VisitorListItem({
    required this.name,
    required this.details,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(
              status == 'ENTERED' ? Icons.login_rounded : Icons.logout_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

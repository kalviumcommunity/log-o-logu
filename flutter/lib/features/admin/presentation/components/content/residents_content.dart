import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:log_o_logu/core/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';
import 'package:log_o_logu/features/admin/domain/admin_service.dart';

class ResidentsContent extends StatelessWidget {
  const ResidentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return StreamBuilder<List<PendingApprovalUser>>(
      stream: adminService.pendingUsersStream(),
      builder: (context, snapshot) {
        final pendingUsers = snapshot.data ?? const <PendingApprovalUser>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Approvals',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.adminApprovals),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open full approval page'),
              ),
              const SizedBox(height: 8),
              Text(
                'Approve resident and guard accounts to unlock dashboard access.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: pendingUsers.isEmpty
                    ? Center(
                        child: Text(
                          'No pending approvals.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.separated(
                        itemCount: pendingUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = pendingUsers[index];
                          final roleLabel =
                              '${user.role[0].toUpperCase()}${user.role.substring(1)}';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(user.name.isEmpty
                                    ? '?'
                                    : user.name[0].toUpperCase()),
                              ),
                              title: Text(user.name),
                              subtitle: Text(
                                '${user.email}\nPhone: ${user.phone.isEmpty ? 'N/A' : user.phone}\nRole: $roleLabel • Apt: ${user.apartmentId ?? 'N/A'} • Flat: ${user.flatNumber ?? 'N/A'} • Building: ${user.buildingName ?? 'N/A'}',
                              ),
                              isThreeLine: true,
                              trailing: FilledButton(
                                onPressed: adminService.isApproving
                                    ? null
                                    : () async {
                                        await context
                                            .read<AdminService>()
                                            .approveUser(user.uid);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('${user.name} approved'),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Approve'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

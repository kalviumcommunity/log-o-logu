import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';
import 'package:log_o_logu/features/admin/domain/admin_service.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Approvals'),
      ),
      body: StreamBuilder<List<PendingApprovalUser>>(
        stream: adminService.pendingUsersStream(),
        builder: (context, snapshot) {
          final pendingUsers = snapshot.data ?? const <PendingApprovalUser>[];

          if (pendingUsers.isEmpty) {
            return Center(
              child: Text(
                'No pending approvals.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              final roleLabel =
                  '${user.role[0].toUpperCase()}${user.role.substring(1)}';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
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
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user.name} approved')),
                            );
                          },
                    child: const Text('Approve'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

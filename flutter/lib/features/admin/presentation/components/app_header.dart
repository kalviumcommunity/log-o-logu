import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';

class AdminAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AuthService>().currentUser;

    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.domain, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Admin Portal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Greenwood Estate',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black54),
          tooltip: 'Logout',
          onPressed: () async {
            await context.read<AuthService>().signOut();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

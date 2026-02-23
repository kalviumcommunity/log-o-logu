// lib/features/invite/presentation/visitor_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

class VisitorHistoryScreen extends StatelessWidget {
  const VisitorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final inviteService = context.watch<InviteService>();

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
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                _FilterChip(label: 'All Status', isSelected: true),
                const SizedBox(width: 8),
                _FilterChip(label: 'Completed', isSelected: false),
                const SizedBox(width: 8),
                _FilterChip(label: 'Today', isSelected: false),
                const SizedBox(width: 8),
                _FilterChip(label: 'This Week', isSelected: false),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // History List
          Expanded(
            child: StreamBuilder<List<InviteModel>>(
              stream: inviteService.streamResidentInvites(user?.uid ?? ''),
              builder: (context, snapshot) {
                final invites = snapshot.data ?? [];
                
                if (invites.isEmpty) {
                  return const Center(
                    child: Text('No visitor history found.', style: TextStyle(color: AppTheme.greyText)),
                  );
                }

                // In a real app, we would group these by date.
                // For now, we'll just show them in a list with a mockup "TODAY" header.
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const _SectionHeader(title: 'TODAY'),
                    ...invites.map((invite) => _HistoryListItem(invite: invite)),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'YESTERDAY'),
                    const _HistoryListItemMock(
                      name: 'Robert Wilson',
                      entry: '10:15 AM',
                      exit: '04:45 PM',
                    ),
                    const SizedBox(height: 80), // Padding for nav bar
                  ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.primaryBlack,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.greyText,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final InviteModel invite;

  const _HistoryListItem({required this.invite});

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
                  invite.guestName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Entry: ${DateFormat('hh:mm a').format(invite.validFrom)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'COMPLETED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryListItemMock extends StatelessWidget {
  final String name;
  final String entry;
  final String exit;

  const _HistoryListItemMock({required this.name, required this.entry, required this.exit});

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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Entry: Today, $entry',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
                Text(
                  'Exit: Today, $exit',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'COMPLETED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

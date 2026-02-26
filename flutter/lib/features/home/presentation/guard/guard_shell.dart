import 'package:flutter/material.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:log_o_logu/features/home/presentation/guard/tabs/guard_home_tab.dart';
import 'package:log_o_logu/features/home/presentation/guard/tabs/guard_logs_tab.dart';
import 'package:log_o_logu/features/home/presentation/guard/tabs/guard_directory_tab.dart';
import 'package:log_o_logu/features/home/presentation/guard/tabs/guard_profile_tab.dart';

/// Shell widget that wraps all guard tabs and renders the bottom navigation bar.
class GuardShell extends StatefulWidget {
  const GuardShell({super.key});

  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    GuardHomeTab(),
    GuardLogsTab(),
    GuardDirectoryTab(),
    GuardProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(index: _currentIndex),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon:
                Icon(Icons.people_rounded, color: AppTheme.primaryBlue),
            label: 'Directory',
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

/// Dynamically updates the AppBar title based on the selected tab.
class _AppBarTitle extends StatelessWidget {
  final int index;

  const _AppBarTitle({required this.index});

  static const _titles = [
    'Guard Dashboard',
    'Entry Logs',
    'Resident Directory',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Text(_titles[index]);
  }
}

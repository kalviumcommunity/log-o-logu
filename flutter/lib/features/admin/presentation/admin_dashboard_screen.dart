import 'package:flutter/material.dart';
import 'components/components.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppHeader(),
      body: _buildContent(),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  /// Builds the main content based on selected index
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return HomeContent(
          onFeatureTap: (featureName) {
            // Handle feature taps if needed
          },
        );
      case 1:
        return const ResidentsContent();
      case 2:
        return const VisitorsContent();
      case 3:
        return const SettingsContent();
      default:
        return HomeContent(
          onFeatureTap: (featureName) {
            // Handle feature taps if needed
          },
        );
    }
  }
}

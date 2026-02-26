import 'package:flutter/material.dart';
import '../cards/overview_card.dart';
import '../cards/wide_card.dart';
import '../cards/management_menu_item.dart';

class HomeContent extends StatelessWidget {
  final ValueChanged<String> onFeatureTap;

  const HomeContent({
    super.key,
    required this.onFeatureTap,
  });

  void _showFeatureSnackbar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName tapped - Feature active'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Overview Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  OverviewCard(
                    icon: Icons.people_outline,
                    iconColor: Colors.blue,
                    title: 'Total Residents',
                    value: '452',
                    onTap: () {
                      _showFeatureSnackbar(context, 'Total Residents');
                      onFeatureTap('Total Residents');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.orange,
                    title: 'Pending Approvals',
                    value: '12',
                    onTap: () {
                      _showFeatureSnackbar(context, 'Pending Approvals');
                      onFeatureTap('Pending Approvals');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.directions_walk_outlined,
                    iconColor: Colors.teal,
                    title: 'Visitors Today',
                    value: '84',
                    onTap: () {
                      _showFeatureSnackbar(context, 'Visitors Today');
                      onFeatureTap('Visitors Today');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.green,
                    title: 'Currently Inside',
                    value: '18',
                    onTap: () {
                      _showFeatureSnackbar(context, 'Currently Inside');
                      onFeatureTap('Currently Inside');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Security Guards Card
              WideCard(
                icon: Icons.security_outlined,
                title: 'Security Guards',
                subtitle: 'Active on duty',
                value: '6',
                color: Colors.grey,
                onTap: () {
                  _showFeatureSnackbar(context, 'Security Guards');
                  onFeatureTap('Security Guards');
                },
              ),

              const SizedBox(height: 32),

              // Management Section
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Management Menu Items
              ManagementMenuItem(
                icon: Icons.person_outline,
                title: 'Resident Management',
                onTap: () {
                  _showFeatureSnackbar(context, 'Resident Management');
                  onFeatureTap('Resident Management');
                },
              ),
              ManagementMenuItem(
                icon: Icons.assignment_outlined,
                title: 'Visitor Logs',
                onTap: () {
                  _showFeatureSnackbar(context, 'Visitor Logs');
                  onFeatureTap('Visitor Logs');
                },
              ),
              ManagementMenuItem(
                icon: Icons.done_outline,
                title: 'Pending Approvals',
                showBadge: true,
                badgeLabel: 'New',
                badgeCount: '12',
                onTap: () {
                  _showFeatureSnackbar(context, 'Pending Approvals');
                  onFeatureTap('Pending Approvals');
                },
              ),
              ManagementMenuItem(
                icon: Icons.security_outlined,
                title: 'Security Management',
                onTap: () {
                  _showFeatureSnackbar(context, 'Security Management');
                  onFeatureTap('Security Management');
                },
              ),
              ManagementMenuItem(
                icon: Icons.description_outlined,
                title: 'Reports',
                onTap: () {
                  _showFeatureSnackbar(context, 'Reports');
                  onFeatureTap('Reports');
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

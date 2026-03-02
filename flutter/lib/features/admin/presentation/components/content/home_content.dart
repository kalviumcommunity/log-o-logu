import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/admin/domain/admin_service.dart';
import '../cards/overview_card.dart';
import '../cards/wide_card.dart';
import '../cards/management_menu_item.dart';

class HomeContent extends StatefulWidget {
  final ValueChanged<String> onFeatureTap;

  const HomeContent({
    super.key,
    required this.onFeatureTap,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Initialize metrics stream on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().initMetrics();
    });
  }

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
    final adminService = context.watch<AdminService>();
    final metrics = adminService.metrics;
    final isLoading = adminService.isLoading;

    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
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
                    value: metrics.totalResidents.toString(),
                    onTap: () {
                      _showFeatureSnackbar(context, 'Total Residents');
                      widget.onFeatureTap('Total Residents');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.orange,
                    title: 'Pending Approvals',
                    value: metrics.pendingApprovals.toString(),
                    onTap: () {
                      _showFeatureSnackbar(context, 'Pending Approvals');
                      widget.onFeatureTap('Pending Approvals');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.directions_walk_outlined,
                    iconColor: Colors.teal,
                    title: 'Visitors Today',
                    value: metrics.visitorsToday.toString(),
                    onTap: () {
                      _showFeatureSnackbar(context, 'Visitors Today');
                      widget.onFeatureTap('Visitors Today');
                    },
                  ),
                  OverviewCard(
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.green,
                    title: 'Currently Inside',
                    value: metrics.currentlyInside.toString(),
                    onTap: () {
                      _showFeatureSnackbar(context, 'Currently Inside');
                      widget.onFeatureTap('Currently Inside');
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
                value: metrics.totalGuards.toString(),
                color: Colors.grey,
                onTap: () {
                  _showFeatureSnackbar(context, 'Security Guards');
                  widget.onFeatureTap('Security Guards');
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
                  widget.onFeatureTap('Resident Management');
                },
              ),
              ManagementMenuItem(
                icon: Icons.assignment_outlined,
                title: 'Visitor Logs',
                onTap: () {
                  _showFeatureSnackbar(context, 'Visitor Logs');
                  widget.onFeatureTap('Visitor Logs');
                },
              ),
              ManagementMenuItem(
                icon: Icons.done_outline,
                title: 'Pending Approvals',
                showBadge: metrics.pendingApprovals > 0,
                badgeLabel: 'New',
                badgeCount: metrics.pendingApprovals.toString(),
                onTap: () {
                  _showFeatureSnackbar(context, 'Pending Approvals');
                  widget.onFeatureTap('Pending Approvals');
                },
              ),
              ManagementMenuItem(
                icon: Icons.security_outlined,
                title: 'Security Management',
                onTap: () {
                  _showFeatureSnackbar(context, 'Security Management');
                  widget.onFeatureTap('Security Management');
                },
              ),
              ManagementMenuItem(
                icon: Icons.description_outlined,
                title: 'Reports',
                onTap: () {
                  _showFeatureSnackbar(context, 'Reports');
                  widget.onFeatureTap('Reports');
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

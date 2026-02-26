import 'package:flutter/material.dart';

class VisitorsContent extends StatelessWidget {
  const VisitorsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_walk_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Visitor Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Feature coming soon',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

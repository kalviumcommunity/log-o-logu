import 'package:flutter/material.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

/// Directory tab — shows a searchable directory of residents.
class GuardDirectoryTab extends StatefulWidget {
  const GuardDirectoryTab({super.key});

  @override
  State<GuardDirectoryTab> createState() => _GuardDirectoryTabState();
}

class _GuardDirectoryTabState extends State<GuardDirectoryTab> {
  final _searchController = TextEditingController();
  String _query = '';

  // Placeholder directory entries
  final List<_DirectoryEntry> _entries = const [
    _DirectoryEntry(
        name: 'Aditya Sharma', flat: 'A-101', phone: '+91 98765 43210'),
    _DirectoryEntry(
        name: 'Priya Mehta', flat: 'A-102', phone: '+91 91234 56789'),
    _DirectoryEntry(
        name: 'Rohan Gupta', flat: 'B-201', phone: '+91 87654 32109'),
    _DirectoryEntry(
        name: 'Sneha Patel', flat: 'B-202', phone: '+91 76543 21098'),
    _DirectoryEntry(
        name: 'Vikram Joshi', flat: 'C-301', phone: '+91 65432 10987'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DirectoryEntry> get _filtered {
    if (_query.isEmpty) return _entries;
    final lower = _query.toLowerCase();
    return _entries
        .where((e) =>
            e.name.toLowerCase().contains(lower) ||
            e.flat.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resident Directory',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse residents by flat or name',
                  style: TextStyle(color: AppTheme.greyText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or flat…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No residents found',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.12),
                            child: Text(
                              entry.name[0],
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
                          subtitle: Text(entry.flat),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone_outlined,
                                color: AppTheme.primaryBlue),
                            tooltip: 'Call ${entry.name}',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling ${entry.phone}…'),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryEntry {
  final String name;
  final String flat;
  final String phone;

  const _DirectoryEntry({
    required this.name,
    required this.flat,
    required this.phone,
  });
}

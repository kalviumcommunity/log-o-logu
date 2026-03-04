import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/home/data/guard_repository.dart';

/// Directory tab — shows a searchable directory of residents.
class GuardDirectoryTab extends StatefulWidget {
  const GuardDirectoryTab({super.key});

  @override
  State<GuardDirectoryTab> createState() => _GuardDirectoryTabState();
}

class _GuardDirectoryTabState extends State<GuardDirectoryTab> {
  final _searchController = TextEditingController();
  final GuardRepository _guardRepository = GuardRepository();
  String _query = '';

  Stream<List<GuardResident>>? _directoryStream;
  String? _cachedApartmentId;
  List<GuardResident> _lastKnownResidents = const [];
  bool _initialLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apartmentId = context.select<AuthService, String?>(
      (auth) => auth.currentUser?.apartmentId,
    );

    if (apartmentId == null || apartmentId.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Apartment is not configured for this guard profile.',
            style: TextStyle(color: AppTheme.greyText),
          ),
        ),
      );
    }

    if (_cachedApartmentId != apartmentId) {
      _cachedApartmentId = apartmentId;
      _initialLoaded = false;
      _lastKnownResidents = const [];
      _directoryStream = _guardRepository.streamResidentDirectory(apartmentId);
    }

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
            child: StreamBuilder<List<GuardResident>>(
              stream: _directoryStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _lastKnownResidents = snapshot.data!;
                  _initialLoaded = true;
                }
                if (snapshot.hasError && !_initialLoaded) {
                  debugPrint('[GuardDirectory] stream error: ${snapshot.error}');
                  _initialLoaded = true;
                }

                if (!_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final residents = _lastKnownResidents;
                final lowerQuery = _query.toLowerCase();
                final filtered = lowerQuery.isEmpty
                    ? residents
                    : residents
                        .where(
                          (resident) =>
                              resident.name.toLowerCase().contains(lowerQuery) ||
                              resident.unitLabel
                                  .toLowerCase()
                                  .contains(lowerQuery),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No residents found',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final resident = filtered[index];
                    final firstChar = resident.name.isEmpty
                        ? 'R'
                        : resident.name[0].toUpperCase();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Text(
                            firstChar,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          resident.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(resident.unitLabel),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone_outlined,
                              color: AppTheme.primaryBlue),
                          tooltip: 'Call ${resident.name}',
                          onPressed: () {
                            final phone = resident.phone.trim();
                            final content = phone.isEmpty
                                ? 'Phone not available for ${resident.name}'
                                : 'Phone: $phone';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(content)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';
import 'package:log_o_logu/features/admin/domain/admin_service.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  final _apartmentNameController = TextEditingController();

  @override
  void dispose() {
    _apartmentNameController.dispose();
    super.dispose();
  }

  Future<void> _createApartment(BuildContext context) async {
    final name = _apartmentNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter apartment name.')),
      );
      return;
    }

    await context.read<AdminService>().createApartment(name);
    if (!context.mounted) return;
    _apartmentNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apartment created successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apartment Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create apartments that residents and guards can select during registration.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _apartmentNameController,
            decoration: const InputDecoration(
              labelText: 'Apartment Name',
              hintText: 'e.g. Greenwood Estate',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: adminService.isCreatingApartment
                ? null
                : () => _createApartment(context),
            child: adminService.isCreatingApartment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Apartment'),
          ),
          const SizedBox(height: 20),
          Text(
            'Available Apartments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<AdminApartment>>(
              stream: adminService.apartmentsStream(),
              builder: (context, snapshot) {
                final apartments = snapshot.data ?? const <AdminApartment>[];
                if (apartments.isEmpty) {
                  return Center(
                    child: Text(
                      'No apartments added yet.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: apartments.length,
                  itemBuilder: (context, index) {
                    final apartment = apartments[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.apartment_outlined),
                        title: Text(apartment.name),
                        subtitle: Text('ID: ${apartment.id}'),
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

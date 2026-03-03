import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/apartment_model.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/auth/domain/user_model.dart';

class OAuthDetailsScreen extends StatefulWidget {
  const OAuthDetailsScreen({super.key});

  @override
  State<OAuthDetailsScreen> createState() => _OAuthDetailsScreenState();
}

class _OAuthDetailsScreenState extends State<OAuthDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _adminApartmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();

  UserRole _selectedRole = UserRole.resident;
  String? _selectedApartmentId;
  late Future<List<ApartmentModel>> _apartmentsFuture;

  @override
  void initState() {
    super.initState();
    _apartmentsFuture = context.read<AuthService>().getAvailableApartments();

    final user = context.read<AuthService>().currentUser;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _flatController.text = user?.flatNumber ?? '';
    _buildingController.text = user?.buildingName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adminApartmentController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthService>().completeOAuthOnboarding(
            role: _selectedRole,
            name: _nameController.text.trim(),
            apartmentId:
                _selectedRole == UserRole.admin ? null : _selectedApartmentId,
            apartmentName: _selectedRole == UserRole.admin
                ? _adminApartmentController.text.trim()
                : null,
            phone: _selectedRole == UserRole.admin
                ? null
                : _phoneController.text.trim(),
            flatNumber: _selectedRole != UserRole.resident
                ? null
                : _flatController.text.trim(),
            buildingName: _selectedRole != UserRole.resident
                ? null
                : _buildingController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile setup complete.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthService>().isLoading;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete Your Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'One last step after Google sign-in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us your role and profile details to continue.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (_selectedRole == UserRole.admin) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_selectedRole == UserRole.resident) ...[
                  TextFormField(
                    controller: _flatController,
                    decoration: const InputDecoration(
                      labelText: 'Flat Number',
                      hintText: 'e.g. A-1203',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter flat number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _buildingController,
                    decoration: const InputDecoration(
                      labelText: 'Building Name',
                      hintText: 'e.g. Tower B',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter building name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                if (_selectedRole == UserRole.admin) ...[
                  TextFormField(
                    controller: _adminApartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Apartment Name',
                      hintText: 'Enter apartment/complex name',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole == UserRole.admin &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter apartment name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  FutureBuilder<List<ApartmentModel>>(
                    future: _apartmentsFuture,
                    builder: (context, snapshot) {
                      final apartments =
                          snapshot.data ?? const <ApartmentModel>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Apartment',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedApartmentId,
                              hint: const Text('Choose apartment'),
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: apartments
                                  .map(
                                    (apartment) => DropdownMenuItem(
                                      value: apartment.id,
                                      child: Text(apartment.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedApartmentId = value);
                              },
                            ),
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Role',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<UserRole>(
                        value: _selectedRole,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items:
                            [UserRole.resident, UserRole.guard, UserRole.admin]
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.label),
                                    ))
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                              _selectedApartmentId = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isLoading ? 'Saving...' : 'Continue'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

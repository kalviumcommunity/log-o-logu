import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthService>().currentUser;
    if (_phoneController.text.isEmpty) {
      _phoneController.text = user?.phone ?? '';
    }
    if (_flatController.text.isEmpty) {
      _flatController.text = user?.flatNumber ?? '';
    }
    if (_buildingController.text.isEmpty) {
      _buildingController.text = user?.buildingName ?? '';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _flatController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthService>().completeResidentGuardProfile(
            phone: _phoneController.text,
            flatNumber: _flatController.text,
            buildingName: _buildingController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
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
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almost there!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please add your phone, flat number, and building name to continue.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _flatController,
                  decoration: const InputDecoration(
                    labelText: 'Flat Number',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter flat number'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _buildingController,
                  decoration: const InputDecoration(
                    labelText: 'Building Name',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter building name'
                      : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

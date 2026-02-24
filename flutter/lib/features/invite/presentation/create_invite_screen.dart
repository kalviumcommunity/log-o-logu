// lib/features/invite/presentation/create_invite_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/features/invite/presentation/invite_qr_screen.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CreateInviteScreen extends StatefulWidget {
  const CreateInviteScreen({super.key});

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(const Duration(hours: 24));
  bool _notifyOnArrival = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isFrom) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validTo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isFrom ? _validFrom : _validTo),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
          if (isFrom) {
            _validFrom = newDateTime;
          } else {
            _validTo = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final inviteService = context.read<InviteService>();
    final residentUid = authService.currentUser?.uid;

    if (residentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final inviteId = await inviteService.createGuestInvite(
        residentUid: residentUid,
        guestName: _nameController.text.trim(),
        guestPhone: _phoneController.text.trim(),
        validFrom: _validFrom,
        validUntil: _validTo,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Operation timed out. Please check your internet connection.';
      });

      if (inviteId != null && mounted) {
        final invite = InviteModel(
          inviteId: inviteId,
          residentUid: residentUid,
          guestName: _nameController.text.trim(),
          guestPhone: _phoneController.text.trim(),
          validFrom: _validFrom,
          validUntil: _validTo,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InviteQRScreen(invite: invite),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(inviteService.error ?? 'Failed to create invite')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<InviteService>().isLoading;
    final format = DateFormat('MM/dd/yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Guest Invite',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite a Guest',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in the details below to generate a secure access QR code for your visitor.',
                  style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                ),
                const SizedBox(height: 32),
                
                _InputLabel(label: 'VISITOR NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Johnathan Smith',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Please enter guest name' : null,
                ),
                const SizedBox(height: 20),

                _InputLabel(label: 'VALID FROM'),
                const SizedBox(height: 8),
                _DateField(
                  value: format.format(_validFrom),
                  onTap: () => _selectDateTime(context, true),
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 20),

                _InputLabel(label: 'VALID TO'),
                const SizedBox(height: 8),
                _DateField(
                  value: format.format(_validTo),
                  onTap: () => _selectDateTime(context, false),
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notify me on arrival',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Switch.adaptive(
                      value: _notifyOnArrival,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setState(() => _notifyOnArrival = val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _InputLabel(label: 'SECURITY NOTE'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter any security instructions...',
                    prefixIcon: Icon(Icons.security_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 48),
                
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _createInvite,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Generate QR Code'),
                        SizedBox(width: 8),
                        Icon(Icons.qr_code, size: 20),
                      ],
                    ),
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

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const _DateField({required this.value, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.greyText),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyNoteController = TextEditingController();
  String? _bloodType;

  // Password fields
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _deletingAccount = false;

  String? _profileSuccess;
  String? _profileError;
  String? _passwordSuccess;
  String? _passwordError;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyNoteController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    final data = await ApiService.fetchMe();
    if (mounted && data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _allergiesController.text = data['allergies'] ?? '';
      _medicationsController.text = data['medications'] ?? '';
      _emergencyNoteController.text = data['emergency_note'] ?? '';
      final bt = data['blood_type']?.toString();
      setState(() {
        _bloodType = (_bloodTypes.contains(bt)) ? bt : null;
        _loadingProfile = false;
      });
    } else {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _savingProfile = true; _profileError = null; _profileSuccess = null; });
    final result = await ApiService.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodType: _bloodType,
      allergies: _allergiesController.text.trim(),
      medications: _medicationsController.text.trim(),
      emergencyNote: _emergencyNoteController.text.trim(),
    );
    setState(() => _savingProfile = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _profileSuccess = 'Profile updated successfully.');
    } else {
      setState(() => _profileError = result['message'] ?? 'Failed to update profile.');
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'Please fill in all password fields.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _passwordError = 'New passwords do not match.');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters.');
      return;
    }

    setState(() { _savingPassword = true; _passwordError = null; _passwordSuccess = null; });
    final result = await ApiService.updatePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    setState(() => _savingPassword = false);
    if (!mounted) return;
    if (result['success'] == true) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _passwordSuccess = 'Password updated successfully.');
    } else {
      setState(() => _passwordError = result['message'] ?? 'Failed to update password.');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deletingAccount = true);
    final result = await ApiService.deleteAccount();
    setState(() => _deletingAccount = false);
    if (!mounted) return;
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed to delete account.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9B7FE4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Profile Information',
                    subtitle: "Update your account's profile information and email address.",
                    child: Column(
                      children: [
                        _buildField(_nameController, 'Name', false),
                        const SizedBox(height: 12),
                        _buildField(_emailController, 'Email', false,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _buildField(_phoneController, 'Phone', false,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildBloodTypeDropdown(),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'This information can be important in emergency medical situations.',
                            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                          ),
                        ),
                        _buildField(_allergiesController, 'Allergies', false, maxLines: 3),
                        const SizedBox(height: 12),
                        _buildField(_medicationsController, 'Medications', false, maxLines: 3),
                        const SizedBox(height: 12),
                        _buildField(_emergencyNoteController, 'Emergency note', false, maxLines: 3),
                        if (_profileError != null) ...[
                          const SizedBox(height: 12),
                          _buildAlert(_profileError!, isError: true),
                        ],
                        if (_profileSuccess != null) ...[
                          const SizedBox(height: 12),
                          _buildAlert(_profileSuccess!, isError: false),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildButton('SAVE', _savingProfile, _saveProfile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Update Password',
                    subtitle: 'Ensure your account is using a long, random password to stay secure.',
                    child: Column(
                      children: [
                        _buildField(_currentPasswordController, 'Current Password', true),
                        const SizedBox(height: 12),
                        _buildField(_newPasswordController, 'New Password', true),
                        const SizedBox(height: 12),
                        _buildField(_confirmPasswordController, 'Confirm Password', true),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 12),
                          _buildAlert(_passwordError!, isError: true),
                        ],
                        if (_passwordSuccess != null) ...[
                          const SizedBox(height: 12),
                          _buildAlert(_passwordSuccess!, isError: false),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildButton('SAVE', _savingPassword, _savePassword),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Delete Account',
                    subtitle: 'Once your account is deleted, all of its resources and data will be permanently deleted. Before deleting your account, please download any data or information that you wish to retain.',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _deletingAccount ? null : _deleteAccount,
                        child: _deletingAccount
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('DELETE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, bool obscure, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF9B7FE4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blood type', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _bloodType,
              hint: Text('Select', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
              dropdownColor: const Color(0xFF1E1E2E),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.white38),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (v) => setState(() => _bloodType = v),
              items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, bool loading, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D2D44),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: loading ? null : onTap,
      child: loading
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildAlert(String msg, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isError ? Colors.red : Colors.green).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg,
              style: TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent, fontSize: 13))),
        ],
      ),
    );
  }
}

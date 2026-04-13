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

  // Will / Oporuka fields
  final _willTextController = TextEditingController();
  final _willExtra1Controller = TextEditingController();
  final _willExtra2Controller = TextEditingController();
  int _willDays = 7;

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _savingWill = false;
  bool _deletingAccount = false;

  String? _profileSuccess;
  String? _profileError;
  String? _passwordSuccess;
  String? _passwordError;
  String? _willSuccess;
  String? _willError;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadWill();
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
    _willTextController.dispose();
    _willExtra1Controller.dispose();
    _willExtra2Controller.dispose();
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

  Future<void> _loadWill() async {
    final data = await ApiService.fetchSettings();
    if (mounted && data != null) {
      setState(() {
        _willTextController.text = data['will_text'] ?? '';
        _willDays = (data['will_days'] as num?)?.toInt() ?? 7;
        _willExtra1Controller.text = data['will_extra_email_1'] ?? '';
        _willExtra2Controller.text = data['will_extra_email_2'] ?? '';
      });
    }
  }

  Future<void> _saveWill() async {
    setState(() { _savingWill = true; _willError = null; _willSuccess = null; });
    final result = await ApiService.saveWill(
      willText: _willTextController.text.trim(),
      willDays: _willDays,
      extraEmail1: _willExtra1Controller.text.trim().isEmpty ? null : _willExtra1Controller.text.trim(),
      extraEmail2: _willExtra2Controller.text.trim().isEmpty ? null : _willExtra2Controller.text.trim(),
    );
    setState(() => _savingWill = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _willSuccess = 'Will saved.');
    } else {
      setState(() => _willError = result['message'] ?? 'Failed to save.');
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
                  _buildWillSection(),
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

  Widget _buildEmailField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        prefixIcon: Icon(Icons.mail_outline, size: 18, color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9B7FE4)),
        ),
      ),
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

  Widget _buildWillSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF9B7FE4).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B7FE4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.article_outlined, color: Color(0xFF9B7FE4), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Will',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A message that will be sent to your guardians if you fail to check in.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const SizedBox(height: 18),

          // Will text field — s lijevim borderom
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.6), width: 3),
              ),
            ),
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Will text',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _willTextController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Passwords, instructions, a message to your loved ones...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF9B7FE4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Leave empty if you do not want to send a will.',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),

          const SizedBox(height: 18),
          Text(
            'Send after',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 8),
          _buildWillDaysPicker(),

          const SizedBox(height: 20),
          // Extra email recipients
          Row(
            children: [
              const Icon(Icons.alternate_email, size: 15, color: Color(0xFF9B7FE4)),
              const SizedBox(width: 8),
              Text(
                'Also send will to:',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Optional. Up to 2 additional recipients (family, lawyer, etc.)',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
          ),
          const SizedBox(height: 10),
          _buildEmailField(_willExtra1Controller, 'Additional email 1'),
          const SizedBox(height: 8),
          _buildEmailField(_willExtra2Controller, 'Additional email 2'),

          if (_willError != null) ...[
            const SizedBox(height: 12),
            _buildAlert(_willError!, isError: true),
          ],
          if (_willSuccess != null) ...[
            const SizedBox(height: 12),
            _buildAlert(_willSuccess!, isError: false),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildButton('SAVE', _savingWill, _saveWill),
          ),
        ],
      ),
    );
  }

  Widget _buildWillDaysPicker() {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = _willDays == day;
        final isFree = day == 7;
        return GestureDetector(
          onTap: () => setState(() => _willDays = day),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF9B7FE4).withOpacity(0.25)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9B7FE4)
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day}d',
                  style: TextStyle(
                    color: selected ? const Color(0xFF9B7FE4) : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isFree)
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: const Color(0xFFFFC857).withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    'free',
                    style: TextStyle(
                      color: const Color(0xFF5BFF6A).withOpacity(0.7),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
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

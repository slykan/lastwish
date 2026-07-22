import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hub/hub_screen.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyNoteController = TextEditingController();

  final _willTextController = TextEditingController();
  int _willDays = 7;

  String? _bloodType;
  bool _showOptional = false;
  bool _loading = false;
  String? _error;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyNoteController.dispose();
    _willTextController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await ApiService.register(
      name, email, password,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      bloodType: _bloodType,
      allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
      medications: _medicationsController.text.trim().isEmpty ? null : _medicationsController.text.trim(),
      emergencyNote: _emergencyNoteController.text.trim().isEmpty ? null : _emergencyNoteController.text.trim(),
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result != null && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);

      // Save will if user filled it in during registration
      final willText = _willTextController.text.trim();
      if (willText.isNotEmpty) {
        await ApiService.saveWill(willText: willText, willDays: _willDays);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      setState(() => _error = result?['message'] ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.webp', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildField(_nameController, 'Full Name', false),
                      const SizedBox(height: 12),
                      _buildField(_emailController, 'Email', false,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildField(_passwordController, 'Password', true),
                      const SizedBox(height: 12),
                      _buildField(_confirmController, 'Confirm Password', true),

                      const SizedBox(height: 16),

                      // Optional fields toggle
                      GestureDetector(
                        onTap: () => setState(() => _showOptional = !_showOptional),
                        child: Row(
                          children: [
                            Icon(
                              _showOptional ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white38, size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Additional info (optional)',
                              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      if (_showOptional) ...[
                        const SizedBox(height: 12),
                        _buildField(_phoneController, 'Phone', false,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),

                        // Blood type dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _bloodType,
                              hint: Text('Blood Type',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                              dropdownColor: const Color(0xFF1E1E2E),
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.white38),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (v) => setState(() => _bloodType = v),
                              items: _bloodTypes.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              )).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildField(_allergiesController, 'Allergies', false, maxLines: 2),
                        const SizedBox(height: 12),
                        _buildField(_medicationsController, 'Medications', false, maxLines: 2),
                        const SizedBox(height: 12),
                        _buildField(_emergencyNoteController, 'Emergency Note', false, maxLines: 3),
                        const SizedBox(height: 16),

                        // ── WILL ──
                        Row(
                          children: [
                            const Icon(Icons.article_outlined, size: 14, color: Color(0xFF9B7FE4)),
                            const SizedBox(width: 6),
                            Text(
                              'WILL',
                              style: TextStyle(
                                color: const Color(0xFF9B7FE4).withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Optional. A message for your guardians if you don\'t check in.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        _buildField(_willTextController, 'Will text', false, maxLines: 4),
                        const SizedBox(height: 10),
                        Text(
                          'Send after (days):',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        _buildWillDaysPicker(),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Register'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Log in',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWillDaysPicker() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = _willDays == day;
        final isFree = day == 7;
        return GestureDetector(
          onTap: () => setState(() => _willDays = day),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF9B7FE4).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9B7FE4)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day}d',
                  style: TextStyle(
                    color: selected ? const Color(0xFF9B7FE4) : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isFree ? 'free' : 'PRO',
                  style: TextStyle(
                    color: isFree
                        ? const Color(0xFF5BFF6A).withOpacity(0.7)
                        : const Color(0xFFFFC857).withOpacity(0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

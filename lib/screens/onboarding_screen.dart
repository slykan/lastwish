import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'hub/hub_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;               // 0 = role pick, 1 = invite, 2 = done
  String? _role;               // 'guardian' or 'protected'
  bool _sending = false;
  bool _sent = false;
  String? _error;
  final _emailCtrl = TextEditingController();
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<void> _nextStep(int next) async {
    await _anim.reverse();
    setState(() => _step = next);
    _anim.forward();
  }

  void _selectRole(String role) async {
    _role = role;
    await _nextStep(1);
  }

  Future<void> _sendInvite() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    setState(() { _sending = true; _error = null; });

    // Guardian invites a protected person; Protected invites a guardian
    final inviteRole = _role == 'guardian' ? 'protected' : 'guardian';
    final result = await ApiService.sendInvite(email, inviteRole);

    setState(() => _sending = false);
    if (result['success'] == true) {
      setState(() => _sent = true);
      await Future.delayed(const Duration(milliseconds: 600));
      _nextStep(2);
    } else {
      setState(() => _error = result['message']?.toString() ?? 'Failed to send invitation.');
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HubScreen()),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.webp', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildRolePicker();
      case 1:
        return _buildInviteStep();
      case 2:
        return _buildDoneStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── STEP 0: role picker ───────────────────────────────────────────────────

  Widget _buildRolePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Logo / brand
          const Text(
            'LastWish',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome! Let\'s get you set up.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Who are you?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick your role — you can always change this later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 36),

          // Guardian card
          _RoleCard(
            icon: Icons.shield_outlined,
            title: 'I\'m a Guardian',
            subtitle: 'I want to watch over someone.\nI\'ll be notified if they miss a check-in.',
            color: const Color(0xFF4C9DFF),
            onTap: () => _selectRole('guardian'),
          ),
          const SizedBox(height: 16),

          // Protected card
          _RoleCard(
            icon: Icons.favorite_border_rounded,
            title: 'I\'m Protected',
            subtitle: 'I want someone to watch over me.\nIf I miss a check-in, they\'ll be alerted.',
            color: const Color(0xFF9D4CFF),
            onTap: () => _selectRole('protected'),
          ),

          const Spacer(),

          // Skip small link
          TextButton(
            onPressed: _finish,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: invite ────────────────────────────────────────────────────────

  Widget _buildInviteStep() {
    final isGuardian = _role == 'guardian';
    final icon = isGuardian ? Icons.favorite_border_rounded : Icons.shield_outlined;
    final accentColor = isGuardian ? const Color(0xFF4C9DFF) : const Color(0xFF9D4CFF);
    final title = isGuardian
        ? 'Add someone to protect'
        : 'Add your Guardian';
    final desc = isGuardian
        ? 'Enter the email of the person you\'d like to watch over.\nThey\'ll receive an invitation.'
        : 'Enter the email of the person who will look after you.\nThey\'ll receive an invitation.';
    final hint = isGuardian ? 'Protected person\'s email' : 'Guardian\'s email';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
          GestureDetector(
            onTap: () => _nextStep(0),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withOpacity(0.5), size: 20),
          ),
          const SizedBox(height: 28),

          // Step indicator
          _StepDots(current: 1),
          const SizedBox(height: 28),

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withOpacity(0.35)),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),

          // Email field
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: Colors.white.withOpacity(0.4), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                  ),
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ],

          const SizedBox(height: 20),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _sendInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Invitation',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),

          const Spacer(),

          // Skip
          Center(
            child: TextButton(
              onPressed: _finish,
              child: Text(
                'Skip, I\'ll do this later',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: done ──────────────────────────────────────────────────────────

  Widget _buildDoneStep() {
    final isGuardian = _role == 'guardian';
    final accentColor = isGuardian ? const Color(0xFF4C9DFF) : const Color(0xFF9D4CFF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          _StepDots(current: 2),
          const SizedBox(height: 40),

          // Big check
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF2ECC71).withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF2ECC71), size: 44),
          ),
          const SizedBox(height: 28),

          const Text(
            'You\'re all set!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Invitation sent successfully.\nYou\'ve done everything on your side — now wait for the other person to accept.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // What happens next hint
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: accentColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGuardian
                          ? '• The person you invited will receive an email.\n• Once they accept, you\'ll start receiving alerts if they miss a check-in.\n• You can track their status from the main screen.'
                          : '• Your guardian will receive an email.\n• Once they accept, they\'ll be notified if you miss a check-in.\n• Make sure to set your check-in interval in Settings.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Go to App',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.7), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current; // 1 or 2
  const _StepDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = (i + 1) <= current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/google_auth_service.dart';
import '../services/apple_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hub/hub_screen.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    final result = await GoogleAuthService.signIn();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result != null && result['token'] != null) {
      await _handleLoginSuccess(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign in failed. Please try again.")),
      );
    }
  }

  Future<void> _loginWithApple() async {
    setState(() => _appleLoading = true);
    final result = await AppleAuthService.signIn();
    if (!mounted) return;
    setState(() => _appleLoading = false);

    if (result != null && result['token'] != null) {
      await _handleLoginSuccess(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Apple sign in failed. Please try again.")),
      );
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", result['token']);

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
    } catch (e) { print("FCM token error: $e"); }

    final userId = result['user']?['id']?.toString() ?? result['id']?.toString();
    if (userId != null) {
      await RevenueCatService.identify(userId);
      final isPro = await RevenueCatService.isPro();
      await ApiService.syncProStatus(isPro: isPro);
    }

    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => onboardingDone ? const HubScreen() : const OnboardingScreen(),
    ));
  }

  void login() async {
  setState(() => loading = true);

  final result = await ApiService.login(
    emailController.text.trim(),
    passwordController.text.trim(),
  );

  setState(() => loading = false);

  if (result != null && result['token'] != null) {
    await _handleLoginSuccess(result);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login failed")),
    );
  }
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          // CENTER CONTENT
          Center(
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
                      "Login",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

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
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    ]),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_googleLoading || loading) ? null : _loginWithGoogle,
                        icon: _googleLoading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Image.network(
                                'https://www.google.com/favicon.ico',
                                width: 18, height: 18,
                                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: Colors.white),
                              ),
                        label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_appleLoading || loading) ? null : _loginWithApple,
                          icon: _appleLoading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.apple, size: 20, color: Colors.white),
                          label: const Text('Continue with Apple', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(
                        "Don't have an account? Register",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
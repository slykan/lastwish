import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'hub/hub_screen.dart';
import 'location_disclosure_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    Widget destination = const LoginScreen();
    bool disclosureShown = false;

    try {
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      final token = prefs.getString("token");
      disclosureShown = prefs.getBool('bg_location_disclosure_shown') ?? false;

      if (token != null) destination = const HubScreen();
    } catch (e) {
      debugPrint('SplashScreen checkLogin ERROR: $e');
    }

    if (!mounted) return;

    if (!disclosureShown) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDisclosureScreen(nextScreen: destination),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 120,
        ),
      ),
    );
  }
}
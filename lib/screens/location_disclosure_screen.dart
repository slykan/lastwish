import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationDisclosureScreen extends StatelessWidget {
  final Widget nextScreen;

  const LocationDisclosureScreen({super.key, required this.nextScreen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.webp', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B7FE4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF9B7FE4).withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.location_searching,
                          color: Color(0xFF9B7FE4), size: 32),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Location Data Notice',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'LastWish collects your location data in the background.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                          height: 1.55),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7FE4).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF9B7FE4).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What this means:',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text(
                          '• The app can access your GPS location even when LastWish is closed or not in use\n'
                          '• Your guardians can request your real-time location at any time\n'
                          '• If you miss a check-in, your guardians can see your last known location',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                              height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF2ECC71).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.privacy_tip_outlined,
                            color:
                                const Color(0xFF2ECC71).withOpacity(0.7),
                            size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your location is only shared with guardians you approve. '
                            'It is never sold, never used for advertising, and never shared with third parties.',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12.5,
                                height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                            'bg_location_disclosure_shown', true);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => nextScreen),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B7FE4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('I understand, continue',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

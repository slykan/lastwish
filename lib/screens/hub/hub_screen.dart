import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'widgets/status_hero.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  Timer? _ticker;

  int totalSeconds = 5 * 60 * 60;
  int remainingSeconds = 4 * 60 * 60 + 32;

  bool isAlert = false;
  bool flash = false;
  String userName = 'Protected user';

  @override
  void initState() {
    super.initState();
    _startTicker();

    // Ako kasnije spajaš API:
    // _loadData();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        }

        isAlert = remainingSeconds <= 15 * 60;
        flash = isAlert ? !flash : false;
      });
    });
  }

  Future<void> _loadData() async {
    // Ovdje spoji svoj API kad budeš spreman.
    // Primjer:
    //
    // final user = await ApiService.getUser();
    // final status = await ApiService.getStatus();
    //
    // setState(() {
    //   userName = user['name'] ?? 'Protected user';
    //   totalSeconds = status['total_seconds'] ?? 86400;
    //   remainingSeconds = status['remaining_seconds'] ?? 0;
    //   isAlert = status['is_alert'] ?? false;
    // });
  }

  double get progress {
    if (totalSeconds <= 0) return 0;
    final value = remainingSeconds / totalSeconds;
    return value.clamp(0.0, 1.0);
  }

  String get statusText {
    if (remainingSeconds <= 0) return 'Alert';
    if (isAlert) return 'Warning';
    return 'Safe';
  }

  String formatTime(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final secs = s % 60;
    return '${hours}h ${minutes}m ${secs}s';
  }

  void onCheckInPressed() {
    setState(() {
      remainingSeconds = totalSeconds;
      isAlert = false;
      flash = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in successful'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SpaceBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Hi, $userName',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: isAlert
                                ? const Color(0xFFFF8A80)
                                : Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                StatusHero(
                  progress: progress,
                  statusText: statusText,
                  countdownText: formatTime(remainingSeconds),
                  onCheckInPressed: onCheckInPressed,
                  isAlert: isAlert,
                  flash: flash,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Text(
                    isAlert
                        ? 'Time is running out'
                        : 'Everything looks good',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpacePainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Color(0xFF2D2F68),
              Color(0xFF12051F),
              Color(0xFF020304),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  final List<_Star> stars = List.generate(55, (index) {
    final rnd = math.Random(index * 17 + 9);
    return _Star(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: rnd.nextDouble() * 2.2 + 0.6,
      opacity: rnd.nextDouble() * 0.35 + 0.10,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double x;
  final double y;
  final double r;
  final double opacity;

  _Star({
    required this.x,
    required this.y,
    required this.r,
    required this.opacity,
  });
}
import 'dart:math';
import 'package:flutter/material.dart';

class NoGuardianHero extends StatefulWidget {
  final VoidCallback onAdd;

  const NoGuardianHero({
    super.key,
    required this.onAdd,
  });

  @override
  State<NoGuardianHero> createState() => _NoGuardianHeroState();
}

class _NoGuardianHeroState extends State<NoGuardianHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    /// 🔄 rotacija ringa
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    /// 💡 glow pulsiranje
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotateController, _pulseController]),
      builder: (_, __) {
        final glow = 0.04 + (_pulseController.value * 0.04);

        return Stack(
          alignment: Alignment.center,
          children: [
            /// 🌫️ glow
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(glow),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            /// 🔄 rotating dashed ring
            Transform.rotate(
              angle: _rotateController.value * 2 * pi,
              child: SizedBox(
                width: 210,
                height: 210,
                child: CustomPaint(
                  painter: _DashedRingPainter(),
                ),
              ),
            ),

            /// 🔥 content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'NO GUARDIAN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are not protected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: widget.onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      'Add guardian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width / 2 - 12;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashWidth = 6;
    const dashSpace = 6;

    double startAngle = 0;

    while (startAngle < 2 * pi) {
      final sweepAngle = dashWidth / radius;

      canvas.drawArc(
        rect.deflate(12),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
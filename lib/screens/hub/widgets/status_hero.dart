import 'dart:math' as math;
import 'package:flutter/material.dart';

class StatusHero extends StatelessWidget {
  final double progress;
  final String statusText;
  final String countdownText;
  final VoidCallback onCheckInPressed;
  final bool isAlert;
  final bool flash;

  const StatusHero({
    super.key,
    required this.progress,
    required this.statusText,
    required this.countdownText,
    required this.onCheckInPressed,
    this.isAlert = false,
    this.flash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 340,
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(340, 340),
              painter: RingPainter(progress: progress),
            ),
            _CenterContent(
              statusText: statusText,
              countdownText: countdownText,
              onCheckInPressed: onCheckInPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterContent extends StatelessWidget {
  final String statusText;
  final String countdownText;
  final VoidCallback onCheckInPressed;

  const _CenterContent({
    required this.statusText,
    required this.countdownText,
    required this.onCheckInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STATUS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            countdownText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCheckInPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'Check in now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class RingPainter extends CustomPainter {
  final double progress;

  RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 40;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const full = math.pi * 2;

    /// GAP
  const gap = 0.14;
const fix = 0.02; // 🔥 mali hack koji rješava sve
final start = -math.pi / 2 + gap / 2 - fix;
    final available = full - gap;

    final sweep = available * progress;

    /// ======================
    /// BASE TRACK
    /// ======================
    final base = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(rect, start, available, false, base);

    if (sweep <= 0) return;

    /// ======================
    /// FULL GRADIENT
    /// ======================
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: full,
      transform: GradientRotation(-math.pi / 2),
      colors: const [
        Color(0xFF5BFF6A),
        Color(0xFFFFC857),
        Color(0xFFFF5E5E),
      ],
      stops: const [
        0.0,
        0.7,
        1.0,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round; // 🔥 bitno

    canvas.drawArc(rect, start, sweep, false, paint);

    /// ======================
    /// ROUND CAP (ručno)
    /// ======================
    final endAngle = start + sweep;

    final endPoint = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final capColor = _getColor(progress);

    final capPaint = Paint()
      ..color = capColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, 7, capPaint);
/// ======================
/// CENTER WHITE LINE (FINAL)
/// ======================
final midRect = Rect.fromCircle(
  center: center,
  radius: radius,
);

final highlight = Paint() 
  ..color = Colors.white.withOpacity(0.55) // 🔥 jače da se vidi
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3 // 🔥 duplo tanje (bilo 6)
  ..strokeCap = StrokeCap.round
  ..blendMode = BlendMode.plus; // 🔥 KLJUČ (digne svjetlinu)

canvas.drawArc(midRect, start, sweep, false, highlight);
    /// ======================
/// COLOR MATCHING GLOW
/// ======================
final glowGradient = SweepGradient(
  startAngle: 0,
  endAngle: full,
  transform: GradientRotation(-math.pi / 2),
  colors: const [
    Color(0xFF5BFF6A),
    Color(0xFFFFC857),
    Color(0xFFFF5E5E),
  ],
  stops: const [
    0.0,
    0.7,
    1.0,
  ],
);

final glowPaint = Paint()
  ..shader = glowGradient.createShader(rect)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 22
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

canvas.drawArc(rect, start, sweep, false, glowPaint);
    final glow = Paint()
      ..color = capColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    
  }

  /// boja za cap (da prati kraj)
  Color _getColor(double t) {
    if (t < 0.7) {
      return Color.lerp(
        const Color(0xFF5BFF6A),
        const Color(0xFFFFC857),
        t / 0.7,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFFC857),
        const Color(0xFFFF5E5E),
        (t - 0.7) / 0.3,
      )!;
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
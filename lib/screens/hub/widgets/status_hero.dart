import 'dart:math' as math;
import 'package:flutter/material.dart';

class StatusHero extends StatefulWidget {
  final double progress;
  final String statusText;
  final String countdownText;
  final VoidCallback onCheckInPressed;
  final bool isAlert;
  final bool isGrace;
  final bool flash;
  final bool isCheckingIn;

  const StatusHero({
    super.key,
    required this.progress,
    required this.statusText,
    required this.countdownText,
    required this.onCheckInPressed,
    this.isAlert = false,
    this.isGrace = false,
    this.flash = false,
    this.isCheckingIn = false,
  });

  @override
  State<StatusHero> createState() => _StatusHeroState();
}

class _StatusHeroState extends State<StatusHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant StatusHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGrace != widget.isGrace ||
        oldWidget.isAlert != widget.isAlert) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    if (widget.isGrace || widget.isAlert) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) {
          final scale =
              (widget.isGrace || widget.isAlert) ? _pulseAnim.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 340,
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(340, 340),
                    painter: RingPainter(
                      progress: widget.progress,
                      isAlert: widget.isAlert,
                      isGrace: widget.isGrace,
                      pulseValue: _pulseAnim.value,
                    ),
                  ),
                  _CenterContent(
                    statusText: widget.statusText,
                    countdownText: widget.countdownText,
                    onCheckInPressed: widget.onCheckInPressed,
                    isCheckingIn: widget.isCheckingIn,
                    isAlert: widget.isAlert,
                    isGrace: widget.isGrace,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress; // 1.0 = pun, 0.0 = prazan
  final bool isAlert;
  final bool isGrace;
  final double pulseValue;

  RingPainter({
    required this.progress,
    this.isAlert = false,
    this.isGrace = false,
    this.pulseValue = 1.0,
  });

  // t = pozicija na PUNOM luku (0.0=početak punog luka, 1.0=kraj punog luka)
  // Boja na poziciji t:
  // t=0 → zelena (gdje bi bio početak punog luka)
  // t=1 → crvena (kraj punog luka, fiksno lijevo od gapa)
  Color _colorAt(double t) {
    if (isAlert) {
      return Color.lerp(const Color(0xFFFF2200), const Color(0xFFFF8800),
          (math.sin(t * math.pi)).abs())!;
    }
    if (isGrace) {
      return Color.lerp(const Color(0xFFFFC857), const Color(0xFFFF5E5E), t)!;
    }
    if (t < 0.55) {
      return Color.lerp(
          const Color(0xFF5BFF6A), const Color(0xFFFFC857), t / 0.55)!;
    }
    return Color.lerp(
        const Color(0xFFFFC857), const Color(0xFFFF5E5E), (t - 0.55) / 0.45)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 40;

    const full = math.pi * 2;
    const gap = 0.18;

    final arcEnd = math.pi / 2 - gap / 2;
    final available = full - gap;

    // ── ALERT: poseban prikaz – puni krug crveno-narančasti ──────
    if (isAlert) {
      _drawAlertRing(canvas, center, radius, full);
      return;
    }

    final sweep = available * progress.clamp(0.0, 1.0);
    final arcStart = arcEnd - sweep;

    // ── Sivi track ───────────────────────────────────────────────
    final trackStart = arcEnd - available;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      trackStart, available, false,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    if (sweep <= 0) return;

    // ── GLOW ─────────────────────────────────────────────────────
    final glowRect = Rect.fromCircle(center: center, radius: radius);
    final glowTStart = 1.0 - progress;
    final glowColor = _colorAt(glowTStart.clamp(0.0, 1.0));

    canvas.drawArc(
      glowRect, arcStart, sweep, false,
      Paint()
        ..color = isGrace ? const Color(0xFFFFAA44) : glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // ── Segmenti ─────────────────────────────────────────────────
    const segments = 120;
    final segAngle = sweep / segments;
    final tStart = 1.0 - progress;

    for (int i = 0; i < segments; i++) {
      final tGlobal = tStart + (i / (segments - 1)) * progress;
      final segStart = arcStart + i * segAngle;
      final color = _colorAt(tGlobal.clamp(0.0, 1.0));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart, segAngle + 0.01, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── 3D highlight (tanka bijela linija kroz sredinu) ──────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      arcStart, sweep, false,
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus,
    );

    // ── Caps ─────────────────────────────────────────────────────
    _drawCap(canvas, center, radius, arcStart, _colorAt(tStart));
    _drawCap(canvas, center, radius, arcEnd, _colorAt(1.0));
  }

  void _drawAlertRing(Canvas canvas, Offset center, double radius, double full) {
    // Puni krug glow (narančasti)
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFFFF4400).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Puni krug gradijent crvena → narančasta
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFF2200),
          Color(0xFFFF6600),
          Color(0xFFFF9900),
          Color(0xFFFF6600),
          Color(0xFFFF2200),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, sweepPaint);

    // Drugi vanjski glow sloj
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFFFF6600).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 3D highlight – tanka bijela linija
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..blendMode = BlendMode.plus,
    );
  }

  void _drawCap(Canvas canvas, Offset center, double radius, double angle, Color color) {
    final point = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(point, 10,
        Paint()
          ..color = color.withOpacity(0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(point, 7, Paint()..color = color);
    canvas.drawCircle(point, 7,
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress ||
      old.isAlert != isAlert ||
      old.isGrace != isGrace ||
      old.pulseValue != pulseValue;
}

class _CenterContent extends StatelessWidget {
  final String statusText;
  final String countdownText;
  final VoidCallback onCheckInPressed;
  final bool isCheckingIn;
  final bool isAlert;
  final bool isGrace;

  const _CenterContent({
    required this.statusText,
    required this.countdownText,
    required this.onCheckInPressed,
    required this.isCheckingIn,
    required this.isAlert,
    required this.isGrace,
  });

  Color get _statusColor {
    if (isAlert) return const Color(0xFFFF5E5E);
    if (isGrace) return const Color(0xFFFFC857);
    return const Color(0xFF5BFF6A);
  }

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
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: _statusColor,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countdownText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: isCheckingIn ? null : onCheckInPressed,
            child: AnimatedOpacity(
              opacity: isCheckingIn ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(
                    color: (isAlert
                            ? const Color(0xFFFF5E5E)
                            : isGrace
                                ? const Color(0xFFFFC857)
                                : Colors.white)
                        .withOpacity(0.25),
                  ),
                ),
                child: isCheckingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Check in now',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
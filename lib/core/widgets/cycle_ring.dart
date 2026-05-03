import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';

/// Ring progress melingkar yang menunjukkan posisi hari ke-N pada siklus.
///
/// Mengikuti gaya Apple Activity ring — gradient halus, ujung membulat.
class CycleRing extends StatelessWidget {
  const CycleRing({
    super.key,
    required this.progress,
    required this.cycleDay,
    required this.cycleLength,
    required this.phaseColor,
    this.size = 220,
    this.strokeWidth = 18,
    this.label,
  });

  /// Nilai 0..1 untuk persentase posisi pada siklus.
  final double progress;
  final int cycleDay;
  final int cycleLength;
  final Color phaseColor;
  final double size;
  final double strokeWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                color: phaseColor,
                trackColor: AppColors.fillSubtle,
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hari $cycleDay',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.labelSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label ?? '$cycleDay / $cycleLength',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.labelPrimary,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: [color.withValues(alpha: 0.7), color],
    ).createShader(rect);

    final fg = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

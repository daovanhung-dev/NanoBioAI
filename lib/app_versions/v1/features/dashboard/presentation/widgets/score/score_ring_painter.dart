import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScoreRingPainter extends CustomPainter {
  final double progress;
  final double pulseValue;

  const ScoreRingPainter({required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF22D3EE), Color(0xFF4ADE80)],
        stops: [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progress * math.pi * 2,
      false,
      progressPaint,
    );

    if (progress > 0.02) {
      final angle = startAngle + progress * math.pi * 2;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glowPaint = Paint()
        ..color = const Color(
          0xFF60A5FA,
        ).withValues(alpha: 0.4 + pulseValue * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, 6, glowPaint);
      canvas.drawCircle(dotCenter, 4, Paint()..color = const Color(0xFF93C5FD));
    }
  }

  @override
  bool shouldRepaint(covariant ScoreRingPainter old) {
    return old.progress != progress || old.pulseValue != pulseValue;
  }
}

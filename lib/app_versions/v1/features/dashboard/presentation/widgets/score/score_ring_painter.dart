import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/app_semantic_colors.dart';

class ScoreRingPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final AppSemanticColors colors;

  const ScoreRingPainter({
    required this.progress,
    required this.pulseValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = colors.onBrand.withValues(alpha: 0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [colors.secondary, colors.secondary, colors.primaryLight],
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
        ..color = colors.primaryLight.withValues(alpha: 0.4 + pulseValue * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, 6, glowPaint);
      canvas.drawCircle(dotCenter, 4, Paint()..color = colors.outline);
    }
  }

  @override
  bool shouldRepaint(covariant ScoreRingPainter old) {
    return old.progress != progress ||
        old.pulseValue != pulseValue ||
        old.colors != colors;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/nabi_expression.dart';

/// Nhân vật Nabi dạng vector Canvas, nền trong suốt.
///
/// Canvas giúp biểu cảm thực sự thay đổi theo state, không phụ thuộc bộ ảnh
/// bitmap, chạy tốt ở mọi density và sẵn sàng thay bằng Rive/sprite sau này.
class NabiCharacter extends StatefulWidget {
  const NabiCharacter({
    required this.emotion,
    super.key,
    this.size = 92,
    this.minimized = false,
    this.primaryColor,
    this.secondaryColor,
  });

  final NabiEmotion emotion;
  final double size;
  final bool minimized;
  final Color? primaryColor;
  final Color? secondaryColor;

  @override
  State<NabiCharacter> createState() => _NabiCharacterState();
}

class _NabiCharacterState extends State<NabiCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = widget.primaryColor ?? scheme.primary;
    final secondary = widget.secondaryColor ?? scheme.secondary;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _motionController,
          _blinkController,
        ]),
        builder: (context, _) {
          final blink = _blinkAmount(_blinkController.value);
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _NabiCharacterPainter(
              emotion: widget.emotion,
              motion: _motionController.value,
              blink: blink,
              minimized: widget.minimized,
              primaryColor: primary,
              secondaryColor: secondary,
              surfaceColor: scheme.surface,
              outlineColor: scheme.onSurface.withOpacity(0.78),
            ),
          );
        },
      ),
    );
  }

  double _blinkAmount(double value) {
    // Mắt chỉ khép rất ngắn ở giữa chu kỳ để không gây cảm giác chớp liên tục.
    const start = 0.46;
    const end = 0.54;
    if (value < start || value > end) return 0;
    final distance = (value - 0.5).abs() / 0.04;
    return (1 - distance).clamp(0.0, 1.0).toDouble();
  }
}

class _NabiCharacterPainter extends CustomPainter {
  const _NabiCharacterPainter({
    required this.emotion,
    required this.motion,
    required this.blink,
    required this.minimized,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.outlineColor,
  });

  final NabiEmotion emotion;
  final double motion;
  final double blink;
  final bool minimized;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 100;
    final bob =
        math.sin(motion * math.pi * 2) *
        (emotion == NabiEmotion.celebrating ? 2.4 : 1.3) *
        unit;
    final sway =
        math.sin(motion * math.pi * 2) *
        (emotion == NabiEmotion.thinking ? 1.2 : 0.55) *
        unit;

    canvas.save();
    canvas.translate(0, bob);

    // Bóng nhẹ để nhân vật nổi trên mọi nền và mọi màn hình.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(50 * unit, 91 * unit),
        width: 50 * unit,
        height: 9 * unit,
      ),
      Paint()..color = Colors.black.withOpacity(0.13),
    );

    _drawBody(canvas, unit, sway);
    _drawHead(canvas, unit, sway);
    _drawFace(canvas, unit, sway);
    _drawContextAccent(canvas, unit, sway);
    canvas.restore();
  }

  void _drawBody(Canvas canvas, double u, double sway) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(25 * u + sway * 0.3, 63 * u, 50 * u, 28 * u),
      Radius.circular(17 * u),
    );
    canvas.drawRRect(body, Paint()..color = primaryColor.withOpacity(0.94));

    // Áo khoác sáng gợi chất "đồng hành sức khỏe" nhưng vẫn tối giản.
    final coat = Path()
      ..moveTo(33 * u + sway * 0.3, 68 * u)
      ..quadraticBezierTo(50 * u, 77 * u, 67 * u + sway * 0.3, 68 * u)
      ..lineTo(70 * u + sway * 0.3, 91 * u)
      ..lineTo(30 * u + sway * 0.3, 91 * u)
      ..close();
    canvas.drawPath(coat, Paint()..color = surfaceColor.withOpacity(0.94));

    final seamPaint = Paint()
      ..color = primaryColor.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(50 * u, 76 * u), Offset(50 * u, 90 * u), seamPaint);

    // Huy hiệu trái tim nhỏ.
    _drawHeart(canvas, Offset(50 * u, 81.5 * u), 3.2 * u, secondaryColor);
  }

  void _drawHead(Canvas canvas, double u, double sway) {
    final headCenter = Offset(50 * u + sway, 39 * u);
    final skin = Color.lerp(surfaceColor, const Color(0xFFFFD7C6), 0.78)!;

    // Tóc phía sau.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx, 34 * u),
        width: 64 * u,
        height: 61 * u,
      ),
      Paint()..color = primaryColor.withOpacity(0.95),
    );

    // Tai + khuôn mặt.
    canvas.drawCircle(
      Offset(21 * u + sway, 40 * u),
      6.5 * u,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(79 * u + sway, 40 * u),
      6.5 * u,
      Paint()..color = skin,
    );
    canvas.drawOval(
      Rect.fromCenter(center: headCenter, width: 55 * u, height: 58 * u),
      Paint()..color = skin,
    );

    // Mái tóc.
    final fringe = Path()
      ..moveTo(24 * u + sway, 33 * u)
      ..quadraticBezierTo(30 * u + sway, 6 * u, 52 * u + sway, 10 * u)
      ..quadraticBezierTo(74 * u + sway, 10 * u, 77 * u + sway, 32 * u)
      ..quadraticBezierTo(66 * u + sway, 26 * u, 57 * u + sway, 31 * u)
      ..quadraticBezierTo(48 * u + sway, 22 * u, 40 * u + sway, 35 * u)
      ..quadraticBezierTo(32 * u + sway, 28 * u, 24 * u + sway, 33 * u)
      ..close();
    canvas.drawPath(fringe, Paint()..color = primaryColor);

    // Kẹp tóc nhận diện Nabi.
    canvas.drawCircle(
      Offset(71 * u + sway, 24 * u),
      5.2 * u,
      Paint()..color = secondaryColor,
    );
    canvas.drawCircle(
      Offset(69.2 * u + sway, 22.3 * u),
      1.4 * u,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
  }

  void _drawFace(Canvas canvas, double u, double sway) {
    final left = Offset(40 * u + sway, 39 * u);
    final right = Offset(60 * u + sway, 39 * u);
    final browPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..strokeCap = StrokeCap.round;

    _drawEyebrows(canvas, u, sway, browPaint);
    _drawEyes(canvas, u, left, right, browPaint);
    _drawMouth(canvas, u, sway);

    if (emotion == NabiEmotion.happy ||
        emotion == NabiEmotion.celebrating ||
        emotion == NabiEmotion.encouraging) {
      final blush = Paint()..color = secondaryColor.withOpacity(0.20);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(31 * u + sway, 50 * u),
          width: 10 * u,
          height: 4.7 * u,
        ),
        blush,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(69 * u + sway, 50 * u),
          width: 10 * u,
          height: 4.7 * u,
        ),
        blush,
      );
    }
  }

  void _drawEyebrows(Canvas canvas, double u, double sway, Paint paint) {
    final leftStart = Offset(34 * u + sway, 31.3 * u);
    final rightStart = Offset(56 * u + sway, 31.3 * u);

    switch (emotion) {
      case NabiEmotion.concerned:
        canvas.drawLine(leftStart, Offset(45 * u + sway, 29 * u), paint);
        canvas.drawLine(
          Offset(56 * u + sway, 29 * u),
          Offset(67 * u + sway, 31.3 * u),
          paint,
        );
        break;
      case NabiEmotion.thinking:
        canvas.drawLine(leftStart, Offset(44 * u + sway, 30 * u), paint);
        canvas.drawLine(
          Offset(56 * u + sway, 28.5 * u),
          Offset(67 * u + sway, 31.3 * u),
          paint,
        );
        break;
      case NabiEmotion.sleepy:
        canvas.drawLine(leftStart, Offset(45 * u + sway, 31.3 * u), paint);
        canvas.drawLine(rightStart, Offset(67 * u + sway, 31.3 * u), paint);
        break;
      default:
        canvas.drawLine(leftStart, Offset(45 * u + sway, 30.2 * u), paint);
        canvas.drawLine(rightStart, Offset(67 * u + sway, 30.2 * u), paint);
        break;
    }
  }

  void _drawEyes(
    Canvas canvas,
    double u,
    Offset left,
    Offset right,
    Paint linePaint,
  ) {
    if (emotion == NabiEmotion.celebrating) {
      _drawStar(canvas, left, 4.8 * u, secondaryColor);
      _drawStar(canvas, right, 4.8 * u, secondaryColor);
      return;
    }

    if (emotion == NabiEmotion.happy || emotion == NabiEmotion.encouraging) {
      final rectLeft = Rect.fromCenter(
        center: left,
        width: 11 * u,
        height: 8 * u,
      );
      final rectRight = Rect.fromCenter(
        center: right,
        width: 11 * u,
        height: 8 * u,
      );
      canvas.drawArc(rectLeft, 0, math.pi, false, linePaint);
      canvas.drawArc(rectRight, 0, math.pi, false, linePaint);
      return;
    }

    if (emotion == NabiEmotion.sleepy) {
      canvas.drawLine(
        left - Offset(4.5 * u, 0),
        left + Offset(4.5 * u, 0),
        linePaint,
      );
      canvas.drawLine(
        right - Offset(4.5 * u, 0),
        right + Offset(4.5 * u, 0),
        linePaint,
      );
      return;
    }

    final eyeScale = (1 - blink).clamp(0.12, 1.0).toDouble();
    final openHeight =
        (emotion == NabiEmotion.listening ? 10.5 : 8.2) * u * eyeScale;
    final eyePaint = Paint()..color = outlineColor;
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.92);

    final leftRect = Rect.fromCenter(
      center: left,
      width: 8.8 * u,
      height: openHeight,
    );
    final rightRect = Rect.fromCenter(
      center: right,
      width: 8.8 * u,
      height: openHeight,
    );
    canvas.drawOval(leftRect, eyePaint);
    canvas.drawOval(rightRect, eyePaint);

    final lookOffset = switch (emotion) {
      NabiEmotion.thinking => Offset(1.3 * u, -1.2 * u),
      NabiEmotion.concerned => Offset(0, 1.0 * u),
      NabiEmotion.listening => Offset(0, 0.6 * u),
      _ => Offset.zero,
    };
    canvas.drawCircle(
      left + lookOffset - Offset(1.15 * u, 1.1 * u),
      1.25 * u,
      highlightPaint,
    );
    canvas.drawCircle(
      right + lookOffset - Offset(1.15 * u, 1.1 * u),
      1.25 * u,
      highlightPaint,
    );
  }

  void _drawMouth(Canvas canvas, double u, double sway) {
    final mouthPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * u
      ..strokeCap = StrokeCap.round;
    final center = Offset(50 * u + sway, 54 * u);

    switch (emotion) {
      case NabiEmotion.listening:
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 8.5 * u, height: 7.8 * u),
          Paint()..color = outlineColor,
        );
        break;
      case NabiEmotion.thinking:
        canvas.drawArc(
          Rect.fromCenter(center: center, width: 11 * u, height: 6 * u),
          0,
          math.pi,
          false,
          mouthPaint,
        );
        break;
      case NabiEmotion.concerned:
        canvas.drawArc(
          Rect.fromCenter(
            center: center + Offset(0, 3.2 * u),
            width: 14 * u,
            height: 8 * u,
          ),
          math.pi,
          math.pi,
          false,
          mouthPaint,
        );
        break;
      case NabiEmotion.sleepy:
        canvas.drawLine(
          center - Offset(5.5 * u, 0),
          center + Offset(5.5 * u, 0),
          mouthPaint,
        );
        break;
      case NabiEmotion.celebrating:
        canvas.drawArc(
          Rect.fromCenter(center: center, width: 17 * u, height: 12 * u),
          0,
          math.pi,
          false,
          mouthPaint,
        );
        break;
      default:
        final path = Path()
          ..moveTo(43 * u + sway, 53 * u)
          ..quadraticBezierTo(50 * u + sway, 60 * u, 57 * u + sway, 53 * u);
        canvas.drawPath(path, mouthPaint);
        break;
    }
  }

  void _drawContextAccent(Canvas canvas, double u, double sway) {
    switch (emotion) {
      case NabiEmotion.thinking:
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset((73 + i * 5) * u + sway, (15 - i * 2) * u),
            (1.8 + i * 0.2) * u,
            Paint()..color = secondaryColor.withOpacity(0.74),
          );
        }
        break;
      case NabiEmotion.celebrating:
        _drawSparkle(
          canvas,
          Offset(16 * u + sway, 18 * u),
          4.2 * u,
          secondaryColor,
        );
        _drawSparkle(
          canvas,
          Offset(84 * u + sway, 44 * u),
          3.2 * u,
          primaryColor,
        );
        break;
      case NabiEmotion.happy:
      case NabiEmotion.encouraging:
        _drawHeart(
          canvas,
          Offset(83 * u + sway, 24 * u),
          4.3 * u,
          secondaryColor.withOpacity(0.92),
        );
        break;
      case NabiEmotion.concerned:
        canvas.drawCircle(
          Offset(82 * u + sway, 26 * u),
          4 * u,
          Paint()..color = primaryColor.withOpacity(0.16),
        );
        final alertPaint = Paint()
          ..color = primaryColor.withOpacity(0.7)
          ..strokeWidth = 1.1 * u;
        canvas.drawLine(
          Offset(82 * u + sway, 24 * u),
          Offset(82 * u + sway, 27 * u),
          alertPaint,
        );
        canvas.drawCircle(
          Offset(82 * u + sway, 29 * u),
          0.7 * u,
          Paint()..color = primaryColor.withOpacity(0.7),
        );
        break;
      case NabiEmotion.sleepy:
        _drawZ(
          canvas,
          Offset(76 * u + sway, 19 * u),
          5 * u,
          outlineColor.withOpacity(0.66),
        );
        break;
      default:
        break;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..cubicTo(
        center.dx - radius * 1.8,
        center.dy - radius * 0.15,
        center.dx - radius,
        center.dy - radius * 1.65,
        center.dx,
        center.dy - radius * 0.45,
      )
      ..cubicTo(
        center.dx + radius,
        center.dy - radius * 1.65,
        center.dx + radius * 1.8,
        center.dy - radius * 0.15,
        center.dx,
        center.dy + radius,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.44;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      paint,
    );
    canvas.drawLine(
      center - Offset(0, radius),
      center + Offset(0, radius),
      paint,
    );
  }

  void _drawZ(Canvas canvas, Offset origin, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + size, origin.dy)
      ..lineTo(origin.dx + 1.2 * size, origin.dy + size)
      ..lineTo(origin.dx + 2.2 * size, origin.dy + size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NabiCharacterPainter oldDelegate) {
    return oldDelegate.emotion != emotion ||
        oldDelegate.motion != motion ||
        oldDelegate.blink != blink ||
        oldDelegate.minimized != minimized ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}

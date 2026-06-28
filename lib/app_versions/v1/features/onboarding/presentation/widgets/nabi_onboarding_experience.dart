import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Visual language dedicated to NaBi onboarding.
///
/// Blue remains the product anchor; cyan, violet and warm amber are only used
/// as supporting accents to add energy without reducing readability.
class NabiPalette {
  const NabiPalette._();

  static const Color deepBlue = Color(0xFF103B8C);
  static const Color royalBlue = Color(0xFF246BFD);
  static const Color skyBlue = Color(0xFF66C8FF);
  static const Color cyan = Color(0xFF39D6C5);
  static const Color violet = Color(0xFF8E7CFF);
  static const Color amber = Color(0xFFFFB14A);
  static const Color rose = Color(0xFFFF7A9E);

  static const Color canvas = Color(0xFFF3F8FF);
  static const Color canvasDeep = Color(0xFFE7F1FF);
  static const Color ink = Color(0xFF102044);
  static const Color mutedInk = Color(0xFF5B6C8D);
  static const Color line = Color(0xFFD9E7FF);

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, royalBlue, skyBlue],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepBlue, royalBlue, cyan],
  );

  static const LinearGradient selection = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [royalBlue, Color(0xFF3A8DFF), cyan],
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFEFFFFFF), Color(0xFFF6FAFF)],
  );

  static const LinearGradient softBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF)],
  );
}

/// A lightweight animated ambient canvas used behind all onboarding screens.
/// It does not require image assets and remains usable on small devices.
class NabiAmbientBackground extends StatefulWidget {
  final Widget child;

  const NabiAmbientBackground({super.key, required this.child});

  @override
  State<NabiAmbientBackground> createState() => _NabiAmbientBackgroundState();
}

class _NabiAmbientBackgroundState extends State<NabiAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F7FF), NabiPalette.canvas, Color(0xFFF9FBFF)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _NabiAmbientPainter(_controller.value),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _NabiAmbientPainter extends CustomPainter {
  final double progress;

  const _NabiAmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    void drawGlow({
      required Offset center,
      required double radius,
      required Color color,
      double opacity = 0.16,
    }) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    final wave = math.sin(progress * math.pi * 2);
    final drift = math.cos(progress * math.pi * 2);

    drawGlow(
      center: Offset(size.width * 0.02, size.height * (0.06 + wave * 0.022)),
      radius: size.width * 0.54,
      color: NabiPalette.skyBlue,
      opacity: 0.18,
    );
    drawGlow(
      center: Offset(size.width * 0.98, size.height * (0.20 + drift * 0.03)),
      radius: size.width * 0.42,
      color: NabiPalette.violet,
      opacity: 0.10,
    );
    drawGlow(
      center: Offset(size.width * (0.68 + wave * 0.03), size.height * 0.90),
      radius: size.width * 0.50,
      color: NabiPalette.cyan,
      opacity: 0.10,
    );

    final sparklePaint = Paint()
      ..color = NabiPalette.skyBlue.withValues(alpha: 0.36);
    final sparkles = <Offset>[
      Offset(size.width * 0.13, size.height * 0.17),
      Offset(size.width * 0.89, size.height * 0.32),
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.19, size.height * 0.80),
    ];
    for (var index = 0; index < sparkles.length; index++) {
      final point = sparkles[index];
      final pulse = 1 + math.sin(progress * math.pi * 2 + index) * 0.22;
      canvas.drawCircle(point, 2.2 * pulse, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NabiAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Glass-like container that keeps cards readable over the ambient canvas.
class NabiGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final bool elevated;

  const NabiGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.gradient,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? NabiPalette.card,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: NabiPalette.deepBlue.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: child,
        ),
      ),
    );
  }
}

class NabiMoodPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const NabiMoodPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? NabiPalette.royalBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: NabiPalette.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class NabiCompanionAvatar extends StatefulWidget {
  final double size;
  final bool showStatus;

  const NabiCompanionAvatar({
    super.key,
    this.size = 116,
    this.showStatus = true,
  });

  @override
  State<NabiCompanionAvatar> createState() => _NabiCompanionAvatarState();
}

class _NabiCompanionAvatarState extends State<NabiCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = math.sin(_controller.value * math.pi * 2);
        final lift = wave * widget.size * 0.028;
        final haloScale = 1 + (wave + 1) * 0.018;
        return Transform.translate(
          offset: Offset(0, lift),
          child: SizedBox(
            width: widget.size * 1.36,
            height: widget.size * 1.36,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: haloScale,
                  child: Container(
                    width: widget.size * 1.24,
                    height: widget.size * 1.24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NabiPalette.skyBlue.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  padding: EdgeInsets.all(widget.size * 0.06),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NabiPalette.hero,
                    boxShadow: [
                      BoxShadow(
                        color: NabiPalette.royalBlue.withValues(alpha: 0.32),
                        blurRadius: 26,
                        offset: const Offset(0, 11),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _NabiFacePainter(
                        blink: _blinkValue(_controller.value),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.06,
                  right: widget.size * 0.04,
                  child: Transform.rotate(
                    angle: wave * 0.18,
                    child: Container(
                      width: widget.size * 0.26,
                      height: widget.size * 0.26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [NabiPalette.amber, Color(0xFFFFD479)],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: widget.size * 0.15,
                      ),
                    ),
                  ),
                ),
                if (widget.showStatus)
                  Positioned(
                    bottom: widget.size * 0.01,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.size * 0.11,
                        vertical: widget.size * 0.045,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        boxShadow: [
                          BoxShadow(
                            color: NabiPalette.deepBlue.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: widget.size * 0.07,
                            height: widget.size * 0.07,
                            decoration: const BoxDecoration(
                              color: NabiPalette.cyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: widget.size * 0.045),
                          Text(
                            'NaBi đang lắng nghe',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: NabiPalette.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: widget.size * 0.092,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _blinkValue(double value) {
    final phase = (value * 3.1) % 1;
    if (phase > 0.83 && phase < 0.94) {
      return 0.12;
    }
    return 1;
  }
}

class _NabiFacePainter extends CustomPainter {
  final double blink;

  const _NabiFacePainter({required this.blink});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final white = Paint()..color = Colors.white;
    final blue = Paint()..color = NabiPalette.deepBlue;
    final blush = Paint()..color = NabiPalette.rose.withValues(alpha: 0.54);

    final eyeY = size.height * 0.43;
    final eyeX = size.width * 0.31;
    final eyeWidth = size.width * 0.075;
    final eyeHeight = size.height * 0.098 * blink;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(eyeX, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      white,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width - eyeX, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      white,
    );

    if (blink > 0.2) {
      canvas.drawCircle(Offset(eyeX, eyeY), size.width * 0.022, blue);
      canvas.drawCircle(
        Offset(size.width - eyeX, eyeY),
        size.width * 0.022,
        blue,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.61),
        width: size.width * 0.13,
        height: size.height * 0.055,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.61),
        width: size.width * 0.13,
        height: size.height * 0.055,
      ),
      blush,
    );

    final mouth = Path()
      ..moveTo(size.width * 0.39, size.height * 0.61)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.71,
        size.width * 0.61,
        size.height * 0.61,
      );
    canvas.drawPath(
      mouth,
      Paint()
        ..color = Colors.white
        ..strokeWidth = size.width * 0.035
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _NabiFacePainter oldDelegate) =>
      oldDelegate.blink != blink;
}

class NabiAssistantMessage extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;

  const NabiAssistantMessage({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.waving_hand_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return NabiGlassPanel(
      elevated: false,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: NabiPalette.softBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NabiPalette.royalBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NabiPalette.royalBlue, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      height: 1.34,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NabiPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;

  const NabiPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: NabiPalette.button,
            borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
            boxShadow: [
              BoxShadow(
                color: NabiPalette.royalBlue.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
              splashColor: Colors.white.withValues(alpha: 0.20),
              highlightColor: Colors.white.withValues(alpha: 0.10),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.buttonSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(icon, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NabiSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const NabiSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.buttonLarge),
            border: Border.all(color: NabiPalette.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: NabiPalette.royalBlue, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: NabiPalette.deepBlue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

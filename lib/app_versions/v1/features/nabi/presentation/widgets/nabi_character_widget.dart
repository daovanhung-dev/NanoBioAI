import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';

import '../../domain/nabi_asset_resolver.dart';
import '../../domain/nabi_visual_state.dart';
import '../../providers/nabi_provider.dart';

// ─── Animation profile ────────────────────────────────────────────────────────

/// Loại hoạt ảnh chính gắn với mỗi nhóm state.
enum _NabiAnimProfile {
  idle,         // float + sway nhẹ
  happy,        // bounce + sparkle
  thinking,     // pulse + wobble nhẹ
  wave,         // swing xoay
  celebrate,    // burst scale + particles
  sad,          // droop chậm
  chat,         // nhịp đập typing
  onboarding,   // slide-up + shine
  loading,      // spin nhẹ
}

_NabiAnimProfile _profileFor(NabiVisualState s) {
  return switch (s) {
    NabiVisualState.idleHappy ||
    NabiVisualState.idleNeutral ||
    NabiVisualState.listen ||
    NabiVisualState.speak ||
    NabiVisualState.pointGuide => _NabiAnimProfile.idle,

    NabiVisualState.taskComplete ||
    NabiVisualState.proudOfYou ||
    NabiVisualState.thankYou ||
    NabiVisualState.syncSuccess ||
    NabiVisualState.accountConnected ||
    NabiVisualState.personalBest ||
    NabiVisualState.planReady ||
    NabiVisualState.freshRestart ||
    NabiVisualState.welcomeBack => _NabiAnimProfile.happy,

    NabiVisualState.think ||
    NabiVisualState.analyze ||
    NabiVisualState.chatReasoning => _NabiAnimProfile.thinking,

    NabiVisualState.wave ||
    NabiVisualState.newUser ||
    NabiVisualState.chatGreet => _NabiAnimProfile.wave,

    NabiVisualState.dayComplete ||
    NabiVisualState.streak7Days ||
    NabiVisualState.streakStart ||
    NabiVisualState.milestoneBadge ||
    NabiVisualState.premiumUnlocked ||
    NabiVisualState.referralSuccess ||
    NabiVisualState.commissionSuccess => _NabiAnimProfile.celebrate,

    NabiVisualState.offline ||
    NabiVisualState.syncRetry ||
    NabiVisualState.missedTaskRemind ||
    NabiVisualState.lowProgressEncourage ||
    NabiVisualState.taskSkipGentle ||
    NabiVisualState.accessLocked => _NabiAnimProfile.sad,

    NabiVisualState.chatTyping ||
    NabiVisualState.chatListen ||
    NabiVisualState.chatAnswerReady ||
    NabiVisualState.chatClarify ||
    NabiVisualState.chatMealTip ||
    NabiVisualState.chatExerciseTip ||
    NabiVisualState.chatRestTip ||
    NabiVisualState.chatWaterTip => _NabiAnimProfile.chat,

    NabiVisualState.onboardingIntro ||
    NabiVisualState.onboardingBasicInfo ||
    NabiVisualState.onboardingBodyProfile ||
    NabiVisualState.onboardingGoal ||
    NabiVisualState.onboardingHealthCheck ||
    NabiVisualState.onboardingLifestyle ||
    NabiVisualState.onboardingReview => _NabiAnimProfile.onboarding,

    NabiVisualState.loading ||
    NabiVisualState.syncing ||
    NabiVisualState.aiGeneratingPlan => _NabiAnimProfile.loading,

    _ => _NabiAnimProfile.idle,
  };
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class NabiCharacterWidget extends ConsumerStatefulWidget {
  final double size;
  final NabiVisualState? forceState;
  final bool showAura;
  final bool showParticles;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const NabiCharacterWidget({
    super.key,
    this.size = 80,
    this.forceState,
    this.showAura = true,
    this.showParticles = true,
    this.onTap,
    this.semanticLabel,
  });

  @override
  ConsumerState<NabiCharacterWidget> createState() =>
      _NabiCharacterWidgetState();
}

class _NabiCharacterWidgetState extends ConsumerState<NabiCharacterWidget>
    with TickerProviderStateMixin {

  // ── Shared: float / sway ──────────────────────────────────────────────────
  late final AnimationController _floatCtrl;
  late final AnimationController _swayCtrl;

  // ── Crossfade ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Aura pulse ────────────────────────────────────────────────────────────
  late final AnimationController _auraCtrl;

  // ── Bounce (happy / complete) ─────────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  // ── Wobble (thinking) ─────────────────────────────────────────────────────
  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  // ── Swing (wave / greet) ──────────────────────────────────────────────────
  late final AnimationController _swingCtrl;
  late final Animation<double> _swingAnim;

  // ── Droop (sad / offline) ─────────────────────────────────────────────────
  late final AnimationController _droopCtrl;
  late final Animation<double> _droopAnim;

  // ── Celebrate burst ───────────────────────────────────────────────────────
  late final AnimationController _celebCtrl;
  late final Animation<double> _celebAnim;

  // ── Chat pulse ────────────────────────────────────────────────────────────
  late final AnimationController _chatCtrl;
  late final Animation<double> _chatAnim;

  // ── Shine sweep (onboarding) ──────────────────────────────────────────────
  late final AnimationController _shineCtrl;

  // ── Spin (loading) ────────────────────────────────────────────────────────
  late final AnimationController _spinCtrl;

  // ── State tracking ────────────────────────────────────────────────────────
  NabiVisualState _currentState = NabiVisualState.idleHappy;
  NabiVisualState? _previousState;
  _NabiAnimProfile _currentProfile = _NabiAnimProfile.idle;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startProfile(_NabiAnimProfile.idle);
  }

  void _initControllers() {
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1;
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 0.88), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.00), weight: 20),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _wobbleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0), weight: 25),
    ]).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut));

    _swingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _swingAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.28), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: -0.18), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.12), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.06), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0), weight: 15),
    ]).animate(CurvedAnimation(parent: _swingCtrl, curve: Curves.easeOut));

    _droopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _droopAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _droopCtrl, curve: Curves.easeOut),
    );

    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebAnim = CurvedAnimation(parent: _celebCtrl, curve: Curves.easeOut);

    _chatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _chatAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _chatCtrl, curve: Curves.easeInOut),
    );

    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  void _startProfile(_NabiAnimProfile profile) {
    _stopAll();
    _currentProfile = profile;

    switch (profile) {
      case _NabiAnimProfile.idle:
        _floatCtrl.repeat(reverse: true);
        _swayCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);

      case _NabiAnimProfile.happy:
        _floatCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);
        _bounceCtrl.forward(from: 0).then((_) {
          if (mounted && _currentProfile == _NabiAnimProfile.happy) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && _currentProfile == _NabiAnimProfile.happy) {
                _bounceCtrl.forward(from: 0);
              }
            });
          }
        });

      case _NabiAnimProfile.thinking:
        _floatCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);
        _wobbleCtrl.repeat();

      case _NabiAnimProfile.wave:
        _floatCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);
        _swingCtrl.forward(from: 0).then((_) {
          if (mounted && _currentProfile == _NabiAnimProfile.wave) {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted && _currentProfile == _NabiAnimProfile.wave) {
                _swingCtrl.forward(from: 0);
              }
            });
          }
        });

      case _NabiAnimProfile.celebrate:
        _celebCtrl.forward(from: 0).then((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted && _currentProfile == _NabiAnimProfile.celebrate) {
                _celebCtrl.forward(from: 0);
              }
            });
          }
        });
        _auraCtrl.repeat(reverse: true);
        _bounceCtrl.forward(from: 0);

      case _NabiAnimProfile.sad:
        _auraCtrl.repeat(reverse: true);
        _droopCtrl.forward(from: 0);

      case _NabiAnimProfile.chat:
        _floatCtrl.repeat(reverse: true);
        _chatCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);

      case _NabiAnimProfile.onboarding:
        _floatCtrl.repeat(reverse: true);
        _auraCtrl.repeat(reverse: true);
        _shineCtrl.repeat();

      case _NabiAnimProfile.loading:
        _spinCtrl.repeat();
        _auraCtrl.repeat(reverse: true);
    }
  }

  void _stopAll() {
    _floatCtrl.stop();
    _swayCtrl.stop();
    _wobbleCtrl.stop();
    _swingCtrl.stop();
    _droopCtrl.stop();
    _celebCtrl.stop();
    _chatCtrl.stop();
    _shineCtrl.stop();
    _spinCtrl.stop();
    _auraCtrl.stop();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _swayCtrl.dispose();
    _fadeCtrl.dispose();
    _auraCtrl.dispose();
    _bounceCtrl.dispose();
    _wobbleCtrl.dispose();
    _swingCtrl.dispose();
    _droopCtrl.dispose();
    _celebCtrl.dispose();
    _chatCtrl.dispose();
    _shineCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  void _onStateChanged(NabiVisualState newState) {
    if (_currentState == newState) return;
    _previousState = _currentState;
    _currentState = newState;

    final newProfile = _profileFor(newState);
    if (newProfile != _currentProfile) _startProfile(newProfile);

    _fadeCtrl.forward(from: 0);
    if (newProfile == _NabiAnimProfile.happy ||
        newProfile == _NabiAnimProfile.celebrate) {
      _bounceCtrl.forward(from: 0);
    }
  }

  void _handleTapDown(TapDownDetails _) =>
      setState(() => _isPressed = true);

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final NabiVisualState resolvedState =
        widget.forceState ?? ref.watch(NabiVisualStateProvider);

    if (_currentState == NabiVisualState.idleHappy &&
        resolvedState != NabiVisualState.idleHappy) {
      _currentState = resolvedState;
      final p = _profileFor(resolvedState);
      if (p != _currentProfile) _startProfile(p);
    }

    if (_currentState != resolvedState) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onStateChanged(resolvedState),
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? 'Nabi – tro ly suc khoe AI',
      button: widget.onTap != null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatCtrl, _swayCtrl, _fadeCtrl, _auraCtrl,
          _bounceCtrl, _wobbleCtrl, _swingCtrl,
          _droopCtrl, _celebCtrl, _chatCtrl,
          _shineCtrl, _spinCtrl,
        ]),
        builder: (context, _) {
          final state = _currentState;
          final profile = _currentProfile;

          // ── Computed transforms ──────────────────────────────────────────
          final floatY = lerpDouble(0, -5, _floatCtrl.value)!;
          final swayX = lerpDouble(-2, 2, _swayCtrl.value)!;

          final bounceScale = _bounceCtrl.isAnimating ? _bounceAnim.value : 1.0;
          final chatScale = profile == _NabiAnimProfile.chat
              ? _chatAnim.value : 1.0;
          final pressScale = _isPressed ? 0.90 : 1.0;
          final droopY = profile == _NabiAnimProfile.sad
              ? lerpDouble(0, 6, _droopAnim.value)! : 0.0;
          final celebScale = profile == _NabiAnimProfile.celebrate
              ? lerpDouble(1.0, 1.18, _celebAnim.value)! : 1.0;

          // Wobble = rotation trad. ──────────────────────────────────────────
          final wobbleAngle = profile == _NabiAnimProfile.thinking
              ? _wobbleAnim.value : 0.0;
          // Swing = rotation wave ────────────────────────────────────────────
          final swingAngle = profile == _NabiAnimProfile.wave
              ? _swingAnim.value : 0.0;
          // Loading spin ─────────────────────────────────────────────────────
          final spinAngle = profile == _NabiAnimProfile.loading
              ? _spinCtrl.value * math.pi * 2 * 0.08 : 0.0;

          final totalScale = bounceScale * chatScale * pressScale * celebScale;
          final totalAngle = wobbleAngle + swingAngle + spinAngle;
          final totalY = floatY + droopY;

          return Transform.translate(
            offset: Offset(swayX * 0.5, totalY),
            child: Transform.rotate(
              angle: totalAngle,
              child: Transform.scale(
                scale: totalScale,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: widget.onTap != null ? _handleTapDown : null,
                  onTapUp: widget.onTap != null ? _handleTapUp : null,
                  onTapCancel: widget.onTap != null ? _handleTapCancel : null,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Aura
                        if (widget.showAura)
                          _NabiAura(
                            size: widget.size,
                            state: state,
                            pulseValue: _auraCtrl.value,
                            profile: profile,
                          ),

                        // 2. Celebrate particles
                        if (widget.showParticles &&
                            profile == _NabiAnimProfile.celebrate)
                          _NabiParticles(
                            size: widget.size,
                            progress: _celebAnim.value,
                          ),

                        // 3. Ảnh chính + crossfade
                        _NabiImage(
                          size: widget.size,
                          currentState: state,
                          previousState: _previousState,
                          fadeValue: _fadeAnim.value,
                        ),

                        // 4. Shine sweep (onboarding)
                        if (profile == _NabiAnimProfile.onboarding)
                          _NabiShine(
                            size: widget.size,
                            progress: _shineCtrl.value,
                          ),

                        // 5. Loading ring
                        if (profile == _NabiAnimProfile.loading)
                          _NabiLoadingRing(
                            size: widget.size,
                            progress: _spinCtrl.value,
                          ),

                        // 6. Thinking dots
                        if (profile == _NabiAnimProfile.thinking ||
                            profile == _NabiAnimProfile.loading)
                          Positioned(
                            bottom: widget.size * 0.04,
                            child: _NabiThinkingDots(
                              dotSize: widget.size * 0.07,
                              color: profile == _NabiAnimProfile.loading
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                          ),

                        // 7. Chat wave indicator
                        if (profile == _NabiAnimProfile.chat &&
                            state == NabiVisualState.chatTyping)
                          Positioned(
                            bottom: widget.size * 0.04,
                            child: _NabiChatWave(size: widget.size),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Vòng hào quang – màu + kích thước thay đổi theo profile.
class _NabiAura extends StatelessWidget {
  final double size;
  final NabiVisualState state;
  final double pulseValue;
  final _NabiAnimProfile profile;

  const _NabiAura({
    required this.size,
    required this.state,
    required this.pulseValue,
    required this.profile,
  });

  Color _color() => switch (profile) {
    _NabiAnimProfile.celebrate => AppColors.warning,
    _NabiAnimProfile.happy     => AppColors.success,
    _NabiAnimProfile.sad       => AppColors.textHint,
    _NabiAnimProfile.thinking ||
    _NabiAnimProfile.loading   => AppColors.secondary,
    _NabiAnimProfile.chat      => AppColors.tertiary,
    _NabiAnimProfile.wave      => AppColors.primaryLight,
    _NabiAnimProfile.onboarding => AppColors.primary,
    _NabiAnimProfile.idle      => AppColors.primary,
  };

  double _intensity() => switch (profile) {
    _NabiAnimProfile.celebrate => 0.38,
    _NabiAnimProfile.happy     => 0.28,
    _NabiAnimProfile.sad       => 0.08,
    _NabiAnimProfile.chat      => 0.20,
    _                          => 0.18,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final intensity = _intensity();
    final extra = profile == _NabiAnimProfile.celebrate
        ? lerpDouble(12, 28, pulseValue)!
        : lerpDouble(6, 16, pulseValue)!;
    final auraSize = size + extra;

    return Container(
      width: auraSize,
      height: auraSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: lerpDouble(intensity * 0.6, intensity, pulseValue)!),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Crossfade ảnh Nabi.
class _NabiImage extends StatelessWidget {
  final double size;
  final NabiVisualState currentState;
  final NabiVisualState? previousState;
  final double fadeValue;

  const _NabiImage({
    required this.size,
    required this.currentState,
    this.previousState,
    required this.fadeValue,
  });

  @override
  Widget build(BuildContext context) {
    final curr = NabiAssetResolver.pathFor(currentState);
    final prev = previousState != null
        ? NabiAssetResolver.pathFor(previousState!)
        : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (prev != null && fadeValue < 1)
            Opacity(
              opacity: (1 - fadeValue).clamp(0.0, 1.0),
              child: _img(prev),
            ),
          Opacity(
            opacity: fadeValue.clamp(0.0, 1.0),
            child: _img(curr),
          ),
        ],
      ),
    );
  }

  Widget _img(String path) => Image.asset(
    path,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, __, ___) => _NabiFallbackIcon(size: size),
  );
}

/// Fallback khi PNG chưa load được.
class _NabiFallbackIcon extends StatelessWidget {
  final double size;
  const _NabiFallbackIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        ),
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: size * 0.48),
    );
  }
}

/// Particles nổ ra khi celebrate.
class _NabiParticles extends StatelessWidget {
  final double size;
  final double progress; // 0→1

  const _NabiParticles({required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.4,
      height: size * 2.4,
      child: CustomPaint(
        painter: _ParticlesPainter(progress: progress, size: size),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final double size;

  static const _count = 10;
  static final _rng = math.Random(42);
  static final _angles = List.generate(
    _count, (i) => i * (math.pi * 2 / _count) + _rng.nextDouble() * 0.4,
  );
  static final _speeds = List.generate(
    _count, (_) => 0.55 + _rng.nextDouble() * 0.45,
  );
  static final _colors = [
    AppColors.warning, AppColors.success, AppColors.primary,
    AppColors.secondary, AppColors.tertiary,
    AppColors.primaryLight, AppColors.secondaryLight,
    AppColors.warning, AppColors.success, AppColors.primary,
  ];

  _ParticlesPainter({required this.progress, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = canvasSize.center(Offset.zero);
    final maxDist = size * 1.1;
    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < _count; i++) {
      final dist = maxDist * progress * _speeds[i];
      final x = center.dx + math.cos(_angles[i]) * dist;
      final y = center.dy + math.sin(_angles[i]) * dist;
      final radius = lerpDouble(5, 2.5, progress)! * _speeds[i];

      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.progress != progress;
}

/// Shine sweep dọc – onboarding effect.
class _NabiShine extends StatelessWidget {
  final double size;
  final double progress; // 0→1 repeat

  const _NabiShine({required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CustomPaint(
          painter: _ShinePainter(progress: progress),
        ),
      ),
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double progress;
  _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = lerpDouble(-size.width * 0.4, size.width * 1.4, progress)!;
    final rect = Rect.fromLTWH(x - 20, 0, 40, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.progress != progress;
}

/// Vòng loading xoay.
class _NabiLoadingRing extends StatelessWidget {
  final double size;
  final double progress; // 0→1 repeat

  const _NabiLoadingRing({required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 12,
      height: size + 12,
      child: CustomPaint(
        painter: _LoadingRingPainter(progress: progress),
      ),
    );
  }
}

class _LoadingRingPainter extends CustomPainter {
  final double progress;
  _LoadingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final angle = progress * math.pi * 2;

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(angle),
        colors: [
          AppColors.secondary.withValues(alpha: 0),
          AppColors.secondary,
          AppColors.secondary.withValues(alpha: 0.2),
        ],
        stops: const [0, 0.6, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle, math.pi * 1.4, false, arcPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingRingPainter old) => old.progress != progress;
}

/// Ba dấu chấm nhảy stagger – thinking / loading.
class _NabiThinkingDots extends StatefulWidget {
  final double dotSize;
  final Color color;

  const _NabiThinkingDots({
    required this.dotSize,
    this.color = AppColors.primary,
  });

  @override
  State<_NabiThinkingDots> createState() => _NabiThinkingDotsState();
}

class _NabiThinkingDotsState extends State<_NabiThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(3, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    ));
    _anims = _ctls
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.32),
            child: Transform.translate(
              offset: Offset(0, -widget.dotSize * 0.9 * _anims[i].value),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha: lerpDouble(0.45, 0.85, _anims[i].value)!,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Sóng chat – typing indicator dạng equalizer.
class _NabiChatWave extends StatefulWidget {
  final double size;
  const _NabiChatWave({required this.size});

  @override
  State<_NabiChatWave> createState() => _NabiChatWaveState();
}

class _NabiChatWaveState extends State<_NabiChatWave>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctls;
  static const _barCount = 4;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(_barCount, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + i * 80),
    ));
    for (int i = 0; i < _barCount; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barW = widget.size * 0.06;
    final maxH = widget.size * 0.22;
    final minH = widget.size * 0.06;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (i) {
        return AnimatedBuilder(
          animation: _ctls[i],
          builder: (_, __) {
            final h = lerpDouble(minH, maxH, _ctls[i].value)!;
            return Container(
              width: barW,
              height: h,
              margin: EdgeInsets.symmetric(horizontal: barW * 0.4),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(barW),
              ),
            );
          },
        );
      }),
    );
  }
}

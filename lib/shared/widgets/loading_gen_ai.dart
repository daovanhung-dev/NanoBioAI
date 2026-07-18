import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nano_app/core/constants/app/app_duration.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';
import 'package:nano_app/core/constants/app/app_spacing.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_gradients.dart';
import 'package:nano_app/core/theme/app_shadows.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

class AIGeneratingPage extends StatefulWidget {
  const AIGeneratingPage({super.key});

  @override
  State<AIGeneratingPage> createState() => _AIGeneratingPageState();
}

class _AIGeneratingPageState extends State<AIGeneratingPage>
    with TickerProviderStateMixin {
  // ─── Breathing animation (orb scale) ─────────────────────────
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheScale;

  // ─── Ripple animation (expanding ring) ───────────────────────
  late final AnimationController _rippleCtrl;
  late final Animation<double> _rippleScale;
  late final Animation<double> _rippleOpacity;

  // ─── Second ripple (offset in time) ──────────────────────────
  late final AnimationController _ripple2Ctrl;
  late final Animation<double> _ripple2Scale;
  late final Animation<double> _ripple2Opacity;

  // ─── Dot phase & rotating messages ───────────────────────────
  int _dotPhase = 0;
  int _messageIndex = 0;
  Timer? _dotTimer;
  Timer? _messageTimer;

  final List<_ThoughtEntry> _thoughts = const [
    _ThoughtEntry(
      icon: Icons.favorite_rounded,
      text: 'Tôi đang lắng nghe thật kỹ điều bạn cần...',
    ),
    _ThoughtEntry(
      icon: Icons.spa_rounded,
      text: 'Tôi đang gom những chi tiết quan trọng để chăm chút cho bạn...',
    ),
    _ThoughtEntry(
      icon: Icons.auto_awesome_rounded,
      text: 'Tôi đang sắp xếp câu trả lời sao cho dễ hiểu và nhẹ nhàng nhất...',
    ),
    _ThoughtEntry(
      icon: Icons.fact_check_rounded,
      text: 'Tôi kiểm tra thêm một lượt để bạn có thể yên tâm hơn...',
    ),
    _ThoughtEntry(
      icon: Icons.volunteer_activism_rounded,
      text: 'Sắp xong rồi, cảm ơn bạn đã chờ tôi thêm một chút nhé.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _rippleScale = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));

    _rippleOpacity = Tween<double>(
      begin: 0.45,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));

    _ripple2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _ripple2Ctrl.repeat();
    });

    _ripple2Scale = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _ripple2Ctrl, curve: Curves.easeOut));

    _ripple2Opacity = Tween<double>(
      begin: 0.30,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ripple2Ctrl, curve: Curves.easeOut));

    _dotTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _dotPhase = (_dotPhase + 1) % 4);
    });

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _thoughts.length);
      }
    });
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _rippleCtrl.dispose();
    _ripple2Ctrl.dispose();
    _dotTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildSoftBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topSpace = (constraints.maxHeight * 0.08)
                    .clamp(28.0, 72.0)
                    .toDouble();
                final bottomSpace = (constraints.maxHeight * 0.06)
                    .clamp(24.0, 56.0)
                    .toDouble();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: topSpace),

                          _buildIdentityLabel(),

                          const SizedBox(height: AppSpacing.md),

                          _buildHeadline(),

                          const SizedBox(height: AppSpacing.xl),

                          Semantics(
                            label: 'Nabi đang chuẩn bị câu trả lời cho bạn',
                            liveRegion: true,
                            child: _buildOrb(),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          _buildThinkingPill(),

                          const SizedBox(height: AppSpacing.lg),

                          _buildRotatingThought(),

                          SizedBox(height: bottomSpace),

                          _buildFooter(),

                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -64,
            child: _buildSoftCircle(
              size: 190,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -72,
            child: _buildSoftCircle(
              size: 180,
              color: AppColors.secondary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 220,
            left: 36,
            child: _buildSoftCircle(
              size: 74,
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 54, spreadRadius: 18)],
      ),
    );
  }

  Widget _buildIdentityLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Nabi • Đang ở bên bạn',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        Text(
          'Đợi Nabi một chút nhé',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tôi đang chăm chút câu trả lời để mọi thứ đến với bạn thật rõ ràng và dễ chịu.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrb() {
    const orbSize = 88.0;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ripple2Ctrl,
            builder: (_, __) => Transform.scale(
              scale: _ripple2Scale.value,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(
                    alpha: _ripple2Opacity.value * 0.6,
                  ),
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, __) => Transform.scale(
              scale: _rippleScale.value,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: _rippleOpacity.value * 0.7,
                  ),
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) => Transform.scale(
              scale: _breatheScale.value,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) {
              final t = (_breatheScale.value - 0.93) / 0.14;
              final coreScale = 0.96 + t * 0.08;

              return Transform.scale(
                scale: coreScale,
                child: Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.ai,
                    boxShadow: AppShadows.primary,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nabi đang nghĩ',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildDots(),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == (_dotPhase % 3);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(left: 4),
          width: isActive ? 9 : 6,
          height: isActive ? 9 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.textDisabled,
          ),
        );
      }),
    );
  }

  Widget _buildRotatingThought() {
    final thought = _thoughts[_messageIndex];

    return AnimatedSwitcher(
      duration: AppDuration.animation,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: Padding(
        key: ValueKey(_messageIndex),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              thought.icon,
              size: 16,
              color: AppColors.primary.withValues(alpha: 0.78),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                thought.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Giữ màn hình mở thêm chút. Nabi sẽ trả lời khi sẵn sàng.',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        height: 1.45,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ThoughtEntry {
  const _ThoughtEntry({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

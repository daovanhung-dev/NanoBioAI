import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nano_app/core/constants/app/app_duration.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';
import 'package:nano_app/core/constants/app/app_spacing.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_gradients.dart';
import 'package:nano_app/core/theme/app_shadows.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

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

  // Các tin nhắn tuần tự – viết theo giọng "tôi" để cảm giác trợ lý thật sự
  final List<_ThoughtEntry> _thoughts = const [
    _ThoughtEntry(
      icon: Icons.search_rounded,
      text: 'Tôi đang đọc kỹ yêu cầu của bạn...',
    ),
    _ThoughtEntry(
      icon: Icons.hub_rounded,
      text: 'Đang kết nối các thông tin liên quan...',
    ),
    _ThoughtEntry(
      icon: Icons.edit_note_rounded,
      text: 'Đang lên kế hoạch câu trả lời phù hợp...',
    ),
    _ThoughtEntry(
      icon: Icons.fact_check_rounded,
      text: 'Đang kiểm tra lại một lần cuối...',
    ),
    _ThoughtEntry(
      icon: Icons.volunteer_activism_rounded,
      text: 'Gần xong rồi! Cảm ơn bạn đã kiên nhẫn.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // ── Breathing (2.4 s, reverse) ───────────────────────────────
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    // ── Ripple 1 ─────────────────────────────────────────────────
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

    // ── Ripple 2 (offset 1.1 s) ──────────────────────────────────
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

    // ── Dots (sequential, 420 ms) ─────────────────────────────────
    _dotTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _dotPhase = (_dotPhase + 1) % 4);
    });

    // ── Rotating thoughts (2.8 s) ─────────────────────────────────
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

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── 1. Identity label ─────────────────────────────
              _buildIdentityLabel(),

              const SizedBox(height: AppSpacing.sm),

              // ── 2. Headline ───────────────────────────────────
              Text(
                'Đang xử lý cho bạn',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── 3. Breathing orb ──────────────────────────────
              _buildOrb(),

              const SizedBox(height: AppSpacing.xl),

              // ── 4. Thinking pill ──────────────────────────────
              _buildThinkingPill(),

              const SizedBox(height: AppSpacing.lg),

              // ── 5. Rotating thought ───────────────────────────
              _buildRotatingThought(),

              const Spacer(flex: 4),

              // ── 6. Footer ─────────────────────────────────────
              _buildFooter(),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════════════════

  Widget _buildIdentityLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
            'Trợ lý AI • Đang trực tuyến',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Orb (breathing + dual ripple) ────────────────────────────────

  Widget _buildOrb() {
    const orbSize = 88.0;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple 2
          AnimatedBuilder(
            animation: _ripple2Ctrl,
            builder: (_, __) => Transform.scale(
              scale: _ripple2Scale.value,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(
                    _ripple2Opacity.value * 0.6,
                  ),
                ),
              ),
            ),
          ),

          // Ripple 1
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, __) => Transform.scale(
              scale: _rippleScale.value,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(
                    _rippleOpacity.value * 0.7,
                  ),
                ),
              ),
            ),
          ),

          // Soft glow halo (breathing)
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
                      color: AppColors.primary.withOpacity(0.22),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.14),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Core orb (breathing, slightly less scale range)
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) {
              // Dampen the breathing for the core so it's subtle
              final t = (_breatheScale.value - 0.93) / 0.14; // 0..1
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

  // ── Thinking pill with sequential dots ───────────────────────────

  Widget _buildThinkingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Đang suy nghĩ', style: AppTextStyles.labelLarge),
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

  // ── Rotating thought with icon ────────────────────────────────────

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
            Icon(thought.icon, size: 15, color: AppColors.textHint),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                thought.text,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Text(
      'Phản hồi thường mất 5–15 phút. Vui lòng không đóng ứng dụng trong khi chờ.',
      style: AppTextStyles.caption,
      textAlign: TextAlign.center,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DATA MODEL
// ════════════════════════════════════════════════════════════════

class _ThoughtEntry {
  const _ThoughtEntry({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

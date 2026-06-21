import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';

import 'package:nano_app/core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingProvider.notifier);
    final aiDevCheckEnabled = ref.watch(onboardingAiDevCheckEnabledProvider);
    final aiDevCheck = aiDevCheckEnabled
        ? ref.watch(onboardingAiDevCheckProvider)
        : null;
    final width = MediaQuery.sizeOf(context).width;
    final showDecoration = width >= 420;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SoftBackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),
        if (showDecoration) ...[
          Positioned(
            top: -110,
            right: -86,
            child: _FloatingCircle(
              controller: _floatingController,
              size: 240,
              color: AppColors.primary.withValues(alpha: 0.055),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -110,
            child: _FloatingCircle(
              controller: _floatingController,
              size: 300,
              color: AppColors.success.withValues(alpha: 0.05),
            ),
          ),
        ],
        OnboardingStepShell(
          stepIndex: 0,
          showBack: false,
          isScrollable: false,
          title: '',
          subtitle: '',
          nextLabel: 'Để Nami hiểu mình hơn',
          onNext: controller.nextStep,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isWide = maxWidth >= 760;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: _adaptive(maxWidth, 8, 14, 18),
                  bottom: AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _NamiHeroHeader(),
                    if (aiDevCheckEnabled && aiDevCheck != null) ...[
                      SizedBox(height: _adaptive(maxWidth, 14, 18, 20)),
                      _AiDevCheckBanner(state: aiDevCheck),
                    ],
                    SizedBox(height: _adaptive(maxWidth, 18, 24, 28)),
                    const _HumanMessageCard(),
                    SizedBox(height: _adaptive(maxWidth, 22, 28, 32)),
                    const _TitleSection(
                      eyebrow: 'Nami sẽ đồng hành như thế nào?',
                      title:
                          'Mỗi ngày một chút, mình cùng chăm cơ thể bạn nhẹ nhàng hơn.',
                      subtitle:
                          'Không ép bạn phải hoàn hảo. Nami chỉ giúp bạn nhìn thấy cơ thể mình đang cần gì và nhắc bạn chăm bản thân đúng lúc.',
                    ),
                    SizedBox(height: _adaptive(maxWidth, 16, 20, 24)),
                    _CareFeatureGrid(isWide: isWide),
                    SizedBox(height: _adaptive(maxWidth, 22, 28, 32)),
                    const _CarePromiseCard(),
                    SizedBox(height: _adaptive(maxWidth, 22, 28, 32)),
                    const _GentleStartCard(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _adaptive(double width, double mobile, double tablet, double desktop) {
    if (width >= 900) return desktop;
    if (width >= 600) return tablet;
    return mobile;
  }
}

class _AiDevCheckBanner extends StatelessWidget {
  final AsyncValue<AIConnectionCheckResult?> state;

  const _AiDevCheckBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (result) {
        if (result == null) {
          return const SizedBox.shrink();
        }

        return _AiDevCheckBannerFrame(
          success: result.success,
          message: result.message,
          modelName: result.modelName,
        );
      },
      loading: () => const _AiDevCheckBannerFrame(
        isLoading: true,
        message: 'Đang kiểm tra kết nối AI...',
      ),
      error: (error, stackTrace) => const _AiDevCheckBannerFrame(
        success: false,
        message: 'Không thể kiểm tra kết nối AI.',
      ),
    );
  }
}

class _AiDevCheckBannerFrame extends StatelessWidget {
  final bool success;
  final bool isLoading;
  final String message;
  final String? modelName;

  const _AiDevCheckBannerFrame({
    this.success = false,
    this.isLoading = false,
    required this.message,
    this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLoading
        ? AppColors.primary
        : success
        ? AppColors.success
        : AppColors.error;
    final backgroundColor = isLoading
        ? AppColors.primarySoft
        : success
        ? AppColors.successSoft
        : AppColors.errorSoft;
    final icon = success
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;

    return Container(
      key: const Key('onboarding_ai_dev_check_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: isLoading
                ? CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  )
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (modelName != null && modelName!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Model: ${modelName!.trim()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color.withValues(alpha: 0.82),
                      height: 1.3,
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

class _NamiHeroHeader extends StatelessWidget {
  const _NamiHeroHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final padding = compact ? AppSpacing.lg : AppSpacing.xl;
        final avatarSize = compact ? 66.0 : 82.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: AppShadows.primary,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -40,
                right: -42,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -55,
                left: -45,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NamiAvatar(size: avatarSize),
                      const Spacer(),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _StatusPill(
                            icon: Icons.favorite_rounded,
                            label: compact ? 'Nami' : 'Nami · Trợ lý sức khỏe',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                  Text(
                    'Chào bạn,\nmình là Nami.',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      fontSize: compact ? 30 : 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Từ hôm nay, mình sẽ ở đây để lắng nghe cơ thể bạn, nhắc bạn chăm mình đúng lúc và giúp mọi thay đổi trở nên nhẹ nhàng hơn.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                      height: 1.7,
                      fontSize: compact ? 15.5 : 17,
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                  const _WarmNoteStrip(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NamiAvatar extends StatelessWidget {
  final double size;

  const _NamiAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        child: Icon(
          Icons.volunteer_activism_rounded,
          color: Colors.white,
          size: size * 0.46,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmNoteStrip extends StatelessWidget {
  const _WarmNoteStrip();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final items = const [
          _WarmNote(icon: Icons.spa_rounded, label: 'Nhẹ nhàng'),
          _WarmNote(icon: Icons.lock_rounded, label: 'Riêng tư'),
          _WarmNote(
            icon: Icons.favorite_border_rounded,
            label: 'Không phán xét',
          ),
        ];

        if (compact) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: item,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item == items.last ? 0 : AppSpacing.sm,
                    ),
                    child: item,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _WarmNote extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WarmNote({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HumanMessageCard extends StatelessWidget {
  const _HumanMessageCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          decoration:
              AppDecoration.card(
                radius: AppRadius.xxl,
                shadows: AppShadows.soft,
              ).copyWith(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
          child: compact
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MessageIcon(),
                    SizedBox(height: AppSpacing.md),
                    _MessageContent(),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MessageIcon(),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(child: _MessageContent()),
                  ],
                ),
        );
      },
    );
  }
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.primary,
      ),
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trước khi bắt đầu, Nami muốn nói với bạn một điều nhỏ.',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bạn không cần thay đổi thật nhanh. Chỉ cần thành thật với cơ thể mình hôm nay. Nami sẽ dựa vào những điều bạn chia sẻ để gợi ý từng bước vừa sức hơn.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _TitleSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _TitleSection({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDecoration.outlined(
            color: AppColors.primarySoft,
            borderColor: AppColors.primary.withValues(alpha: 0.16),
            radius: AppRadius.circular,
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: AppTextStyles.overline.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _CareFeatureGrid extends StatelessWidget {
  final bool isWide;

  const _CareFeatureGrid({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _CareFeatureData(
        icon: Icons.monitor_heart_rounded,
        title: 'Lắng nghe cơ thể bạn',
        description:
            'Nami giúp bạn ghi lại giấc ngủ, cân nặng, bữa ăn và những tín hiệu nhỏ mà đôi khi bạn bỏ qua.',
        gradient: AppGradients.primary,
      ),
      _CareFeatureData(
        icon: Icons.restaurant_menu_rounded,
        title: 'Gợi ý bữa ăn vừa sức',
        description:
            'Không phải thực đơn khô khan. Nami ưu tiên món dễ ăn, gần gũi và phù hợp với thói quen của bạn.',
        gradient: AppGradients.health,
      ),
      _CareFeatureData(
        icon: Icons.notifications_active_rounded,
        title: 'Nhắc bạn đúng lúc',
        description:
            'Khi bạn bận, Nami sẽ nhẹ nhàng nhắc uống nước, nghỉ mắt, vận động và ngủ đúng giờ hơn.',
        gradient: AppGradients.ai,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = isWide ? AppSpacing.lg : AppSpacing.md;
        final columns = width >= 920
            ? 3
            : width >= 620
            ? 2
            : 1;
        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _CareFeatureCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CareFeatureData {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  const _CareFeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _CareFeatureCard extends StatelessWidget {
  final _CareFeatureData item;

  const _CareFeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration:
          AppDecoration.card(
            radius: AppRadius.xl,
            shadows: AppShadows.sm,
          ).copyWith(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.primary,
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.title,
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.62,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePromiseCard extends StatelessWidget {
  const _CarePromiseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration:
          AppDecoration.gradient(
            colors: [AppColors.primarySoft, Colors.white],
            radius: AppRadius.xxl,
            shadows: AppShadows.soft,
          ).copyWith(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lời hứa nhỏ của Nami',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mình sẽ không làm bạn thấy bị chấm điểm hay bị ép buộc. Mọi gợi ý đều bắt đầu từ nhịp sống thật của bạn, rồi tốt lên từng chút một.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PromiseIcon(),
                const SizedBox(height: AppSpacing.md),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PromiseIcon(),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _PromiseIcon extends StatelessWidget {
  const _PromiseIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: AppGradients.health,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.success,
      ),
      child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 30),
    );
  }
}

class _GentleStartCard extends StatelessWidget {
  const _GentleStartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.futuristic,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -44,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mình bắt đầu bằng vài câu hỏi thật nhẹ nhé?',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nami sẽ hỏi từng bước ngắn thôi: bạn là ai, cơ thể bạn đang thế nào và bạn muốn được chăm sóc ra sao. Bạn có thể chọn gần đúng, không cần áp lực.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  height: 1.75,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _FloatingCircle({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(controller.value * math.pi * 2) * 14,
            math.cos(controller.value * math.pi * 2) * 14,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SoftBackgroundPainter extends CustomPainter {
  final double animation;

  const _SoftBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withValues(alpha: 0.15),
          AppColors.secondarySoft.withValues(alpha: 0.12),
          Colors.white,
        ],
        stops: const [0, 0.38, 0.72, 1],
        transform: GradientRotation(animation * math.pi * 0.8),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final softPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.035);

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      120 + math.sin(animation * math.pi * 2) * 10,
      softPaint,
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.success.withValues(alpha: 0.030);

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.70),
      160 + math.cos(animation * math.pi * 2) * 12,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.018)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 58) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }

    for (double i = 0; i < size.height; i += 58) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class FeaturesHubPage extends StatelessWidget {
  const FeaturesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureAction(
        title: 'Lịch trình cá nhân',
        subtitle: 'Nabi giúp bạn nhìn lại nhịp sống trong tuần.',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        onTap: () => context.push(V1RoutePaths.lifestyleSchedule),
      ),
      _FeatureAction(
        title: 'Nhiệm vụ hôm nay',
        subtitle: 'Từng việc nhỏ, Nabi sẽ cùng bạn hoàn thành nhẹ nhàng.',
        icon: Icons.favorite_rounded,
        color: AppColors.success,
        onTap: () => context.push(V1RoutePaths.healthTracking),
      ),
      _FeatureAction(
        title: 'Thực đơn theo tuần',
        subtitle: 'Những bữa ăn được chuẩn bị để bạn dễ chăm mình hơn.',
        icon: Icons.restaurant_rounded,
        color: AppColors.secondary,
        onTap: () => context.push(V1RoutePaths.mealPlan),
      ),
      _FeatureAction(
        title: 'Dinh dưỡng',
        subtitle: 'Theo dõi năng lượng và thói quen ăn uống của bạn.',
        icon: Icons.pie_chart_rounded,
        color: AppColors.warning,
        onTap: () => context.push(V1RoutePaths.nutrition),
      ),
      _FeatureAction(
        title: 'Chi so co the',
        subtitle: 'Tinh nhanh BMI, BMR/RMR, TDEE va goi y nuoc, ngu, van dong.',
        icon: Icons.monitor_weight_rounded,
        color: AppColors.info,
        onTap: () => context.push(V1RoutePaths.bodyMetrics),
      ),
      _FeatureAction(
        title: 'Giấc ngủ',
        subtitle: 'Ghi nhận giấc ngủ để cơ thể được nghỉ ngơi tốt hơn.',
        icon: Icons.bedtime_rounded,
        color: AppColors.primary,
        onTap: () => context.push(V1RoutePaths.sleepTracking),
      ),
      _FeatureAction(
        title: 'Cảm xúc & stress',
        subtitle: 'Một nơi nhỏ để bạn lắng nghe cảm xúc của mình.',
        icon: Icons.psychology_rounded,
        color: AppColors.info,
        onTap: () => context.push(V1RoutePaths.stressTracking),
      ),
      _FeatureAction(
        title: 'Cộng đồng chăm sóc',
        subtitle: 'Kết nối với những người cũng đang quan tâm sức khỏe.',
        icon: Icons.groups_rounded,
        color: AppColors.error,
        onTap: () => context.push(V1RoutePaths.community),
      ),
      _FeatureAction(
        title: 'Trò chuyện với Nabi',
        subtitle: 'Hỏi Nabi bất cứ điều gì bạn đang băn khoăn hôm nay.',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.secondary,
        onTap: () => context.push(V1RoutePaths.aiChat),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    128,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _HeaderSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const _NamiCareCard(),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bạn muốn chăm sóc điều gì?',
                              style: AppTextStyles.heading2.copyWith(
                                fontWeight: AppTypography.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(
                                AppRadius.circular,
                              ),
                            ),
                            child: Text(
                              '${features.length} góc nhỏ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Chọn một mục, Nabi sẽ đưa bạn đến đúng nơi cần thiết.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width >= 900
                              ? 4
                              : width >= 620
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: features.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisExtent: 178,
                                ),
                            itemBuilder: (context, index) {
                              return _FeatureTile(action: features[index]);
                            },
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppGradients.ai.colors),
            shape: BoxShape.circle,
            boxShadow: AppShadows.sm,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Góc chăm sóc',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nabi đã sắp sẵn những công cụ nhỏ cho bạn.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NamiCareCard extends StatelessWidget {
  const _NamiCareCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: .12),
            AppColors.secondary.withValues(alpha: .08),
            AppColors.card.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: .12)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Text(
              'Nabigợi ý',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hôm nay mình chăm bản thân từ điều nhỏ nhất nhé.',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bạn không cần làm mọi thứ cùng lúc. Chỉ cần chọn một mục phù hợp với mình lúc này, Nabi sẽ đồng hành từng bước.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _FeatureAction action;

  const _FeatureTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: action.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(action.icon, color: action.color, size: 23),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: AppColors.textMuted.withValues(alpha: .7),
                      size: 18,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  action.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppColors.background)),
        Positioned(
          top: -90,
          right: -80,
          child: _GlowOrb(size: 220, color: AppColors.primary, opacity: .10),
        ),
        Positioned(
          top: 220,
          left: -120,
          child: _GlowOrb(size: 240, color: AppColors.secondary, opacity: .08),
        ),
        Positioned(
          bottom: -120,
          right: -100,
          child: _GlowOrb(size: 260, color: AppColors.primary, opacity: .07),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * .35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _FeatureAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

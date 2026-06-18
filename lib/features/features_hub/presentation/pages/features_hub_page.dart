import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/constants/routes/route_names.dart';
import 'package:nano_app/core/theme/theme.dart';

class FeaturesHubPage extends StatelessWidget {
  const FeaturesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureAction(
        title: 'Lịch trình cá nhân',
        subtitle: 'Lịch trình cá nhân theo tuần',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        onTap: () => context.push(RoutePaths.lifestyleSchedule),
      ),
      _FeatureAction(
        title: 'Nhiệm vụ hôm nay',
        subtitle: 'Theo dõi các việc nhỏ trong ngày',
        icon: Icons.favorite_rounded,
        color: const Color(0xFF22C55E),
        onTap: () => context.push(RoutePaths.healthTracking),
      ),
      _FeatureAction(
        title: 'Thực đơn theo tuần',
        subtitle: 'Các bữa ăn AI đã chuẩn bị',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF06B6D4),
        onTap: () => context.push(RoutePaths.mealPlan),
      ),
      _FeatureAction(
        title: 'Dinh dưỡng',
        subtitle: 'Tổng hợp meal_plans và nutrition_logs',
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => context.push(RoutePaths.nutrition),
      ),
      _FeatureAction(
        title: 'Theo dõi giấc ngủ',
        subtitle: 'Ghi nhận chất lượng ngủ',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => context.push(RoutePaths.sleepTracking),
      ),
      _FeatureAction(
        title: 'Theo dõi stress',
        subtitle: 'Ghi lại cảm xúc và mức căng thẳng',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.push(RoutePaths.stressTracking),
      ),
      _FeatureAction(
        title: 'Cộng đồng chăm sóc',
        subtitle: 'Kết nối nhóm hỗ trợ sức khỏe',
        icon: Icons.groups_rounded,
        color: const Color(0xFFEF4444),
        onTap: () => context.push(RoutePaths.community),
      ),
      _FeatureAction(
        title: 'AI Coach',
        subtitle: 'Huấn luyện thói quen cá nhân',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => context.push(RoutePaths.aiChat),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  Text(
                    'Tính năng',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Các công cụ sức khỏe cá nhân trong BioAI',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: features.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: .96,
                        ),
                    itemBuilder: (context, index) {
                      return _FeatureTile(action: features[index]);
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
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

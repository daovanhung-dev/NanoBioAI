import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/health_module_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

class FeaturesHubPage extends StatelessWidget {
  const FeaturesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentFeatures = _currentFeatures(context);
    final totalFeatureCount =
        currentFeatures.length + advancedHealthFeatureCatalog.length;

    return MedicalPageScaffold(
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
                  MedicalPageHero(
                    eyebrow: 'TRUNG TÂM CHĂM SÓC',
                    title: 'Chăm sức khỏe theo cách dễ hiểu',
                    subtitle:
                        'Mỗi công cụ được sắp theo mục tiêu rõ ràng để bạn theo dõi, hiểu và cải thiện sức khỏe từng bước.',
                    icon: Icons.health_and_safety_rounded,
                    actions: [
                      MedicalStatusPill(
                        label: '$totalFeatureCount công cụ',
                        icon: Icons.widgets_outlined,
                        foregroundColor: AppColors.textInverse,
                        backgroundColor: Colors.white.withValues(alpha: .14),
                        borderColor: Colors.white.withValues(alpha: .22),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const MedicalSectionHeader(
                    key: Key('current-features-section'),
                    title: 'Công cụ chăm sóc hiện tại',
                    subtitle:
                        'Chọn một mục, Nabi sẽ đưa bạn đến đúng nơi cần thiết.',
                    icon: Icons.dashboard_customize_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureGrid(
                    itemCount: currentFeatures.length,
                    itemBuilder: (context, index) =>
                        _FeatureTile(action: currentFeatures[index]),
                    mainAxisExtent: 178,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const MedicalSectionHeader(
                    key: Key('advanced-health-features-section'),
                    title: 'Theo dõi chuyên sâu đang phát triển',
                    subtitle:
                        'Mười công cụ mới đang được hoàn thiện để bạn theo dõi sức khỏe chủ động hơn.',
                    icon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureGrid(
                    itemCount: advancedHealthFeatureCatalog.length,
                    itemBuilder: (context, index) {
                      final item = advancedHealthFeatureCatalog[index];
                      return _AdvancedHealthFeatureTile(
                        item: item,
                        onTap: () => context.push(
                          HealthModuleRoutePaths.detail(item.moduleId),
                        ),
                      );
                    },
                    mainAxisExtent: 252,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FeatureAction> _currentFeatures(BuildContext context) {
    return [
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
        title: 'Chỉ số cơ thể',
        subtitle: 'Tính nhanh BMI, BMR/RMR, TDEE và gợi ý nước, ngủ, vận động.',
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
  }
}

class _FeatureGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisExtent;

  const _FeatureGrid({
    required this.itemCount,
    required this.itemBuilder,
    required this.mainAxisExtent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 620
            ? 3
            : width >= 440
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: itemBuilder,
        );
      },
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
                    _FeatureIcon(icon: action.icon, color: action.color),
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

class _AdvancedHealthFeatureTile extends StatelessWidget {
  final HealthFeatureCatalogItem item;
  final VoidCallback onTap;

  const _AdvancedHealthFeatureTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFree = item.minimumAccess == HealthFeatureMinimumAccess.free;

    return Material(
      key: Key('advanced-health-feature-${item.moduleId}'),
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: item.color.withValues(alpha: .22)),
            boxShadow: AppShadows.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _FeatureIcon(icon: item.icon, color: item.color),
                    const Spacer(),
                    _FeatureBadge(
                      key: Key('access-badge-${item.moduleId}'),
                      label: isFree ? 'Miễn phí' : 'Plus',
                      foregroundColor: isFree
                          ? AppColors.success
                          : AppColors.tertiary,
                      backgroundColor: isFree
                          ? AppColors.successSoft
                          : AppColors.tertiarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.title,
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
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                const _FeatureBadge(
                  label: 'Đang phát triển',
                  icon: Icons.schedule_rounded,
                  foregroundColor: AppColors.info,
                  backgroundColor: AppColors.infoSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FeatureIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _FeatureBadge({
    super.key,
    required this.label,
    this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: foregroundColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
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

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
    final plannedFeatures = _plannedFeatures(context);

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  const _CareJourneyHero(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  const MedicalSectionHeader(
                    title: 'Chăm sóc hôm nay',
                    subtitle: 'Chọn một mục để bắt đầu.',
                    icon: Icons.favorite_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ResponsiveFeatureList(
                    itemCount: currentFeatures.length,
                    itemBuilder: (context, index) =>
                        _FeatureTile(action: currentFeatures[index]),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  const MedicalSectionHeader(
                    title: 'Sắp ra mắt',
                    subtitle: 'Các mục này đang được hoàn thiện.',
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ResponsiveFeatureList(
                    itemCount: plannedFeatures.length,
                    itemBuilder: (context, index) => _FeatureTile(
                      action: plannedFeatures[index],
                      statusLabel: 'Sắp ra mắt',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  const MedicalSectionHeader(
                    key: Key('advanced-health-features-section'),
                    title: 'Theo dõi chuyên sâu',
                    subtitle: 'Các công cụ mới đang được phát triển.',
                    icon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ResponsiveFeatureList(
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
        title: 'Nabi Care',
        subtitle: 'Mở các công cụ chăm sóc đã sẵn sàng.',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.namiCare),
      ),
      _FeatureAction(
        title: 'Lịch trình cá nhân',
        subtitle: 'Xem nhịp sống trong tuần.',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelBlue,
        onTap: () => context.push(V1RoutePaths.lifestyleSchedule),
      ),
      _FeatureAction(
        title: 'Nhiệm vụ hôm nay',
        subtitle: 'Hoàn thành từng việc nhỏ.',
        icon: Icons.favorite_rounded,
        color: AppColors.error,
        backgroundColor: AppColors.pastelRose,
        onTap: () => context.push(V1RoutePaths.todayTasks),
      ),
      _FeatureAction(
        title: 'Thực đơn theo tuần',
        subtitle: 'Xem bữa ăn Nabi đã chuẩn bị.',
        icon: Icons.restaurant_rounded,
        color: AppColors.secondary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.mealPlan),
      ),
      _FeatureAction(
        title: 'Dinh dưỡng',
        subtitle: 'Theo dõi năng lượng và thói quen ăn uống.',
        icon: Icons.pie_chart_rounded,
        color: AppColors.warning,
        backgroundColor: AppColors.pastelAmber,
        onTap: () => context.push(V1RoutePaths.nutrition),
      ),
      _FeatureAction(
        title: 'Chỉ số cơ thể',
        subtitle: 'Xem các chỉ số cơ bản, dễ hiểu.',
        icon: Icons.monitor_weight_rounded,
        color: AppColors.info,
        backgroundColor: AppColors.pastelSky,
        onTap: () => context.push(V1RoutePaths.bodyMetrics),
      ),
      _FeatureAction(
        title: 'Trò chuyện với Nabi',
        subtitle: 'Hỏi điều bạn đang băn khoăn.',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.tertiary,
        backgroundColor: AppColors.pastelLavender,
        onTap: () => context.push(V1RoutePaths.aiChat),
      ),
    ];
  }

  List<_FeatureAction> _plannedFeatures(BuildContext context) {
    return [
      _FeatureAction(
        title: 'Giấc ngủ',
        subtitle: 'Ghi nhận nhịp nghỉ ngơi mỗi ngày.',
        icon: Icons.bedtime_rounded,
        color: AppColors.tertiary,
        backgroundColor: AppColors.pastelLavender,
        onTap: () => context.push(V1RoutePaths.sleepTracking),
      ),
      _FeatureAction(
        title: 'Cảm xúc & stress',
        subtitle: 'Một nơi riêng tư để lắng nghe cảm xúc.',
        icon: Icons.psychology_rounded,
        color: AppColors.secondary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.stressTracking),
      ),
      _FeatureAction(
        title: 'Cộng đồng chăm sóc',
        subtitle: 'Kết nối trong một không gian tích cực.',
        icon: Icons.groups_rounded,
        color: AppColors.error,
        backgroundColor: AppColors.pastelRose,
        onTap: () => context.push(V1RoutePaths.community),
      ),
    ];
  }
}

class _CareJourneyHero extends StatelessWidget {
  const _CareJourneyHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Trung tâm chăm sóc. Bảng Theo dõi Hành Trình Sống Khỏe.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRUNG TÂM CHĂM SÓC',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.textInverse.withValues(alpha: .88),
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: .24),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.textInverse,
                    size: 27,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Bảng Theo dõi Hành Trình Sống Khỏe',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: AppTypography.bold,
                      height: 1.24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFeatureList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _ResponsiveFeatureList({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < itemCount; index++) ...[
                itemBuilder(context, index),
                if (index != itemCount - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        final crossAxisCount = constraints.maxWidth >= 1080 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 250,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _FeatureAction action;
  final String? statusLabel;

  const _FeatureTile({required this.action, this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: statusLabel == null
          ? '${action.title}. ${action.subtitle}'
          : '${action.title}. $statusLabel. ${action.subtitle}',
      child: Material(
        color: action.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: action.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: action.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: action.color.withValues(alpha: .18)),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          action.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _FeatureBadge(
                          label: statusLabel!,
                          icon: Icons.schedule_rounded,
                          foregroundColor: action.color,
                          backgroundColor: AppColors.surface.withValues(
                            alpha: .68,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    action.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Row(
                    children: [
                      _FeatureIcon(icon: action.icon, color: action.color),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: action.color,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    final backgroundColor = _pastelFor(item.color);

    return Semantics(
      button: true,
      label: '${item.title}. Đang phát triển. ${item.description}',
      child: Material(
        key: Key('advanced-health-feature-${item.moduleId}'),
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: item.color.withValues(alpha: .18)),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FeatureBadge(
                        key: Key('access-badge-${item.moduleId}'),
                        label: isFree ? 'Miễn phí' : 'Plus',
                        foregroundColor: isFree
                            ? AppColors.success
                            : AppColors.tertiary,
                        backgroundColor: AppColors.surface.withValues(
                          alpha: .72,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Row(
                    children: [
                      _FeatureIcon(icon: item.icon, color: item.color),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _FeatureBadge(
                            label: 'Đang phát triển',
                            icon: Icons.schedule_rounded,
                            foregroundColor: AppColors.info,
                            backgroundColor: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _pastelFor(Color color) {
    if (color == AppColors.secondary || color == AppColors.success) {
      return AppColors.pastelMint;
    }
    if (color == AppColors.warning) return AppColors.pastelAmber;
    if (color == AppColors.error || color == AppColors.danger) {
      return AppColors.pastelRose;
    }
    if (color == AppColors.tertiary) return AppColors.pastelLavender;
    return AppColors.pastelSky;
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FeatureIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Icon(icon, color: color, size: 26),
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
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
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
  final Color backgroundColor;
  final VoidCallback onTap;

  const _FeatureAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });
}

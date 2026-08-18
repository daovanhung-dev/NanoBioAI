import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/health_module_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

class FeaturesHubPage extends StatefulWidget {
  const FeaturesHubPage({super.key});

  @override
  State<FeaturesHubPage> createState() => _FeaturesHubPageState();
}

class _FeaturesHubPageState extends State<FeaturesHubPage> {
  bool _plannedExpanded = false;
  bool _advancedExpanded = false;

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
                AppSpacing.md,
                AppSpacing.md,
                128,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _CareJourneyHero(),
                  const SizedBox(height: AppSpacing.lg),
                  const _CompactSectionHeader(
                    title: 'Chăm sóc hôm nay',
                    subtitle: 'Chạm để mở nhanh công cụ bạn cần.',
                    icon: Icons.favorite_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ResponsiveCompactFeatureGrid(actions: currentFeatures),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _CollapsibleFeatureSection(
                    key: const Key('planned-features-section'),
                    toggleKey: const Key('planned-features-toggle'),
                    title: 'Sắp ra mắt',
                    subtitle: 'Các công cụ đang được hoàn thiện.',
                    icon: Icons.schedule_rounded,
                    count: plannedFeatures.length,
                    expanded: _plannedExpanded,
                    onToggle: () => setState(
                      () => _plannedExpanded = !_plannedExpanded,
                    ),
                    child: _ResponsiveCompactFeatureGrid(
                      actions: plannedFeatures,
                      gridKey: const Key('planned-features-grid'),
                      tileKeyPrefix: 'planned-feature',
                      statusLabel: 'Sắp ra mắt',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CollapsibleFeatureSection(
                    key: const Key('advanced-health-features-section'),
                    toggleKey: const Key('advanced-health-features-toggle'),
                    title: 'Theo dõi chuyên sâu',
                    subtitle: 'Các công cụ nâng cao đang được phát triển.',
                    icon: Icons.health_and_safety_outlined,
                    count: advancedHealthFeatureCatalog.length,
                    expanded: _advancedExpanded,
                    onToggle: () => setState(
                      () => _advancedExpanded = !_advancedExpanded,
                    ),
                    child: _ResponsiveAdvancedFeatureGrid(
                      items: advancedHealthFeatureCatalog,
                      onTap: (item) => context.push(
                        HealthModuleRoutePaths.detail(item.moduleId),
                      ),
                    ),
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
        id: 'nabi-care',
        title: 'Nabi Care',
        subtitle: 'Mở các công cụ chăm sóc đã sẵn sàng.',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.namiCare),
      ),
      _FeatureAction(
        id: 'lifestyle-schedule',
        title: 'Lịch trình cá nhân',
        subtitle: 'Xem nhịp sống trong tuần.',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelBlue,
        onTap: () => context.push(V1RoutePaths.lifestyleSchedule),
      ),
      _FeatureAction(
        id: 'today-tasks',
        title: 'Nhiệm vụ hôm nay',
        subtitle: 'Hoàn thành từng việc nhỏ.',
        icon: Icons.favorite_rounded,
        color: AppColors.error,
        backgroundColor: AppColors.pastelRose,
        onTap: () => context.push(V1RoutePaths.todayTasks),
      ),
      _FeatureAction(
        id: 'meal-plan',
        title: 'Thực đơn theo tuần',
        subtitle: 'Xem bữa ăn Nabi đã chuẩn bị.',
        icon: Icons.restaurant_rounded,
        color: AppColors.secondary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.mealPlan),
      ),
      _FeatureAction(
        id: 'nutrition',
        title: 'Dinh dưỡng',
        subtitle: 'Theo dõi năng lượng và thói quen ăn uống.',
        icon: Icons.pie_chart_rounded,
        color: AppColors.warning,
        backgroundColor: AppColors.pastelAmber,
        onTap: () => context.push(V1RoutePaths.nutrition),
      ),
      _FeatureAction(
        id: 'body-metrics',
        title: 'Chỉ số cơ thể',
        subtitle: 'Xem các chỉ số sức khỏe của bạn.',
        icon: Icons.monitor_weight_rounded,
        color: AppColors.info,
        backgroundColor: AppColors.pastelSky,
        onTap: () => context.push(V1RoutePaths.bodyMetrics),
      ),
      _FeatureAction(
        id: 'health-tracking',
        title: 'Theo dõi sức khỏe',
        subtitle: 'Ghi nhận tình trạng sức khỏe hằng ngày.',
        icon: Icons.monitor_heart_rounded,
        color: AppColors.success,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.healthTracking),
      ),
      _FeatureAction(
        id: 'water-tracking',
        title: 'Uống nước',
        subtitle: 'Theo dõi lượng nước trong ngày.',
        icon: Icons.water_drop_rounded,
        color: AppColors.info,
        backgroundColor: AppColors.pastelSky,
        onTap: () => context.push(V1RoutePaths.waterTracking),
      ),
      _FeatureAction(
        id: 'personal-goals',
        title: 'Mục tiêu cá nhân',
        subtitle: 'Xem mục tiêu nhỏ phù hợp với bạn.',
        icon: Icons.flag_rounded,
        color: AppColors.success,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.personalGoals),
      ),
      _FeatureAction(
        id: 'weekly-summary',
        title: 'Tổng kết tuần',
        subtitle: 'Nhìn lại các ghi nhận trong tuần.',
        icon: Icons.insights_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelBlue,
        onTap: () => context.push(V1RoutePaths.weeklySummary),
      ),
      _FeatureAction(
        id: 'quick-care',
        title: 'Chăm mình 5 phút',
        subtitle: 'Bắt đầu một bài tự chăm sóc ngắn.',
        icon: Icons.spa_rounded,
        color: AppColors.secondary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.quickCare),
      ),
      _FeatureAction(
        id: 'gentle-care',
        title: 'Chế độ dịu nhẹ',
        subtitle: 'Giảm nhịp và chọn gợi ý nhẹ nhàng.',
        icon: Icons.nights_stay_rounded,
        color: AppColors.warning,
        backgroundColor: AppColors.pastelAmber,
        onTap: () => context.push(V1RoutePaths.gentleCare),
      ),
      _FeatureAction(
        id: 'daily-routine',
        title: 'Thói quen hằng ngày',
        subtitle: 'Điều chỉnh nhịp sinh hoạt phù hợp.',
        icon: Icons.calendar_view_day_rounded,
        color: AppColors.primary,
        backgroundColor: AppColors.pastelBlue,
        onTap: () => context.push(V1RoutePaths.dailyRoutinePreferences),
      ),
      _FeatureAction(
        id: 'ai-chat',
        title: 'Trò chuyện với Nabi',
        subtitle: 'Hỏi điều bạn đang băn khoăn.',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.tertiary,
        backgroundColor: AppColors.pastelLavender,
        onTap: () => context.push(V1RoutePaths.aiChat),
      ),
      _FeatureAction(
        id: 'ai-voice',
        title: 'Trò chuyện giọng nói',
        subtitle: 'Trao đổi với Nabi bằng giọng nói.',
        icon: Icons.mic_rounded,
        color: AppColors.tertiary,
        backgroundColor: AppColors.pastelLavender,
        onTap: () => context.push(V1RoutePaths.aiVoice),
      ),
    ];
  }

  List<_FeatureAction> _plannedFeatures(BuildContext context) {
    return [
      _FeatureAction(
        id: 'sleep-tracking',
        title: 'Giấc ngủ',
        subtitle: 'Ghi nhận nhịp nghỉ ngơi mỗi ngày.',
        icon: Icons.bedtime_rounded,
        color: AppColors.tertiary,
        backgroundColor: AppColors.pastelLavender,
        onTap: () => context.push(V1RoutePaths.sleepTracking),
      ),
      _FeatureAction(
        id: 'stress-tracking',
        title: 'Cảm xúc & stress',
        subtitle: 'Một nơi riêng tư để lắng nghe cảm xúc.',
        icon: Icons.psychology_rounded,
        color: AppColors.secondary,
        backgroundColor: AppColors.pastelMint,
        onTap: () => context.push(V1RoutePaths.stressTracking),
      ),
      _FeatureAction(
        id: 'community',
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
        padding: const EdgeInsets.all(AppSpacing.md),
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Bảng Theo dõi Hành Trình Sống Khỏe',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: AppTypography.bold,
                      height: 1.2,
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

class _CompactSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _CompactSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pastelBlue,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: .14),
            ),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveCompactFeatureGrid extends StatelessWidget {
  final List<_FeatureAction> actions;
  final Key gridKey;
  final String tileKeyPrefix;
  final String? statusLabel;

  const _ResponsiveCompactFeatureGrid({
    required this.actions,
    this.gridKey = const Key('active-features-grid'),
    this.tileKeyPrefix = 'feature-tile',
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final textScale = MediaQuery.textScalerOf(context).scale(1);

        late final int crossAxisCount;
        late final double mainAxisExtent;
        if (isCompact) {
          crossAxisCount = 3;
          if (textScale > 1.7) {
            mainAxisExtent = 132;
          } else if (textScale > 1.3) {
            mainAxisExtent = 118;
          } else {
            mainAxisExtent = 104;
          }
        } else if (constraints.maxWidth < 1080) {
          crossAxisCount = 4;
          mainAxisExtent = textScale > 1.5 ? 132 : 116;
        } else {
          crossAxisCount = 6;
          mainAxisExtent = textScale > 1.5 ? 132 : 116;
        }

        final spacing = isCompact ? AppSpacing.sm : AppSpacing.md;

        return GridView.builder(
          key: gridKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => _CompactFeatureTile(
            action: actions[index],
            keyPrefix: tileKeyPrefix,
            statusLabel: statusLabel,
          ),
        );
      },
    );
  }
}

class _CompactFeatureTile extends StatelessWidget {
  final _FeatureAction action;
  final String keyPrefix;
  final String? statusLabel;

  const _CompactFeatureTile({
    required this.action,
    required this.keyPrefix,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: statusLabel == null
          ? '${action.title}. ${action.subtitle}'
          : '${action.title}. $statusLabel. ${action.subtitle}',
      child: Material(
        key: Key('$keyPrefix-${action.id}'),
        color: action.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: action.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: action.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: action.color.withValues(alpha: .16)),
              boxShadow: AppShadows.xs,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: action.color.withValues(alpha: .12),
                          ),
                        ),
                        child: Icon(action.icon, color: action.color, size: 19),
                      ),
                      if (statusLabel != null)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.circular,
                              ),
                              border: Border.all(
                                color: action.color.withValues(alpha: .16),
                              ),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: action.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Center(
                      child: Text(
                        action.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
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

class _CollapsibleFeatureSection extends StatelessWidget {
  final Key toggleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleFeatureSection({
    super.key,
    required this.toggleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion ? Duration.zero : AppDuration.fast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label:
              '$title. ${expanded ? 'Đang mở' : 'Đang thu gọn'}. $count mục. $subtitle',
          child: Material(
            key: toggleKey,
            color: semanticColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: onToggle,
              child: Ink(
                decoration: BoxDecoration(
                  color: semanticColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: semanticColors.borderLight),
                  boxShadow: AppShadows.xs,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.cardPaddingCompact,
                    vertical: AppSpacing.compactItemSpacing,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.pastelBlue,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CountBadge(count: count),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        duration: duration,
                        turns: expanded ? .5 : 0,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: expanded
              ? Padding(
                  key: const ValueKey('expanded'),
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: child,
                )
              : const SizedBox.shrink(key: ValueKey('collapsed')),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.pastelSky,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        maxLines: 1,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

class _ResponsiveAdvancedFeatureGrid extends StatelessWidget {
  final List<HealthFeatureCatalogItem> items;
  final ValueChanged<HealthFeatureCatalogItem> onTap;

  const _ResponsiveAdvancedFeatureGrid({
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isCompact = constraints.maxWidth < 720;

        late final int crossAxisCount;
        late final double mainAxisExtent;
        if (isCompact) {
          crossAxisCount = 2;
          if (textScale > 1.7) {
            mainAxisExtent = 174;
          } else if (textScale > 1.3) {
            mainAxisExtent = 158;
          } else {
            mainAxisExtent = 138;
          }
        } else if (constraints.maxWidth < 1080) {
          crossAxisCount = 3;
          mainAxisExtent = textScale > 1.5 ? 164 : 144;
        } else {
          crossAxisCount = 5;
          mainAxisExtent = textScale > 1.5 ? 164 : 144;
        }

        final spacing = isCompact ? AppSpacing.sm : AppSpacing.md;

        return GridView.builder(
          key: const Key('advanced-features-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _CompactAdvancedHealthFeatureTile(
              item: item,
              onTap: () => onTap(item),
            );
          },
        );
      },
    );
  }
}

class _CompactAdvancedHealthFeatureTile extends StatelessWidget {
  final HealthFeatureCatalogItem item;
  final VoidCallback onTap;

  const _CompactAdvancedHealthFeatureTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = item.minimumAccess == HealthFeatureMinimumAccess.free;
    final backgroundColor = _pastelFor(item.color);

    return Semantics(
      button: true,
      label:
          '${item.title}. ${isFree ? 'Miễn phí' : 'Plus'}. Đang phát triển. ${item.description}',
      child: Material(
        key: Key('advanced-health-feature-${item.moduleId}'),
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: item.color.withValues(alpha: .16)),
              boxShadow: AppShadows.xs,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingCompact),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .80),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: item.color.withValues(alpha: .12),
                          ),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const Spacer(),
                      _MiniFeatureBadge(
                        key: Key('access-badge-${item.moduleId}'),
                        label: isFree ? 'Miễn phí' : 'Plus',
                        foregroundColor: isFree
                            ? AppColors.success
                            : AppColors.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const _DevelopmentStatusLabel(),
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

class _MiniFeatureBadge extends StatelessWidget {
  final String label;
  final Color foregroundColor;

  const _MiniFeatureBadge({
    super.key,
    required this.label,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: foregroundColor,
          fontWeight: AppTypography.semiBold,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _DevelopmentStatusLabel extends StatelessWidget {
  const _DevelopmentStatusLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 11,
          color: AppColors.info,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            'Đang phát triển',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.info,
              fontWeight: AppTypography.semiBold,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _FeatureAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });
}

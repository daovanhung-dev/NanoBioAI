import 'dart:math' as math;

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
                  const _SectionHeader(
                    title: 'Chăm sóc hôm nay',
                    subtitle: 'Chạm để mở nhanh công cụ bạn cần.',
                    icon: Icons.favorite_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdaptiveFeatureGrid(
                    actions: currentFeatures,
                    gridKey: const Key('active-features-grid'),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _CollapsibleSection(
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
                    child: _AdaptiveFeatureGrid(
                      actions: plannedFeatures,
                      gridKey: const Key('planned-features-grid'),
                      tileKeyPrefix: 'planned-feature',
                      statusLabel: 'Sắp ra mắt',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CollapsibleSection(
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
                    child: _AdaptiveAdvancedGrid(
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

  List<_FeatureAction> _currentFeatures(BuildContext context) => [
    _FeatureAction('nabi-care', 'Nabi Care', Icons.health_and_safety_rounded,
        AppColors.primary, AppColors.pastelMint,
        () => context.push(V1RoutePaths.namiCare)),
    _FeatureAction('lifestyle-schedule', 'Lịch trình cá nhân',
        Icons.event_note_rounded, AppColors.primary, AppColors.pastelBlue,
        () => context.push(V1RoutePaths.lifestyleSchedule)),
    _FeatureAction('today-tasks', 'Nhiệm vụ hôm nay', Icons.favorite_rounded,
        AppColors.error, AppColors.pastelRose,
        () => context.push(V1RoutePaths.todayTasks)),
    _FeatureAction('meal-plan', 'Thực đơn theo tuần', Icons.restaurant_rounded,
        AppColors.secondary, AppColors.pastelMint,
        () => context.push(V1RoutePaths.mealPlan)),
    _FeatureAction('nutrition', 'Dinh dưỡng', Icons.pie_chart_rounded,
        AppColors.warning, AppColors.pastelAmber,
        () => context.push(V1RoutePaths.nutrition)),
    _FeatureAction('body-metrics', 'Chỉ số cơ thể', Icons.monitor_weight_rounded,
        AppColors.info, AppColors.pastelSky,
        () => context.push(V1RoutePaths.bodyMetrics)),
    _FeatureAction('health-tracking', 'Theo dõi sức khỏe',
        Icons.monitor_heart_rounded, AppColors.success, AppColors.pastelMint,
        () => context.push(V1RoutePaths.healthTracking)),
    _FeatureAction('water-tracking', 'Uống nước', Icons.water_drop_rounded,
        AppColors.info, AppColors.pastelSky,
        () => context.push(V1RoutePaths.waterTracking)),
    _FeatureAction('personal-goals', 'Mục tiêu cá nhân', Icons.flag_rounded,
        AppColors.success, AppColors.pastelMint,
        () => context.push(V1RoutePaths.personalGoals)),
    _FeatureAction('weekly-summary', 'Tổng kết tuần', Icons.insights_rounded,
        AppColors.primary, AppColors.pastelBlue,
        () => context.push(V1RoutePaths.weeklySummary)),
    _FeatureAction('quick-care', 'Chăm mình 5 phút', Icons.spa_rounded,
        AppColors.secondary, AppColors.pastelMint,
        () => context.push(V1RoutePaths.quickCare)),
    _FeatureAction('gentle-care', 'Chế độ dịu nhẹ', Icons.nights_stay_rounded,
        AppColors.warning, AppColors.pastelAmber,
        () => context.push(V1RoutePaths.gentleCare)),
    _FeatureAction('daily-routine', 'Thói quen hằng ngày',
        Icons.calendar_view_day_rounded, AppColors.primary, AppColors.pastelBlue,
        () => context.push(V1RoutePaths.dailyRoutinePreferences)),
    _FeatureAction('ai-chat', 'Trò chuyện với Nabi', Icons.auto_awesome_rounded,
        AppColors.tertiary, AppColors.pastelLavender,
        () => context.push(V1RoutePaths.aiChat)),
    _FeatureAction('ai-voice', 'Trò chuyện giọng nói', Icons.mic_rounded,
        AppColors.tertiary, AppColors.pastelLavender,
        () => context.push(V1RoutePaths.aiVoice)),
  ];

  List<_FeatureAction> _plannedFeatures(BuildContext context) => [
    _FeatureAction('sleep-tracking', 'Giấc ngủ', Icons.bedtime_rounded,
        AppColors.tertiary, AppColors.pastelLavender,
        () => context.push(V1RoutePaths.sleepTracking)),
    _FeatureAction('stress-tracking', 'Cảm xúc & stress',
        Icons.psychology_rounded, AppColors.secondary, AppColors.pastelMint,
        () => context.push(V1RoutePaths.stressTracking)),
    _FeatureAction('community', 'Cộng đồng chăm sóc', Icons.groups_rounded,
        AppColors.error, AppColors.pastelRose,
        () => context.push(V1RoutePaths.community)),
  ];
}

class _CareJourneyHero extends StatelessWidget {
  const _CareJourneyHero();
  @override
  Widget build(BuildContext context) => Semantics(
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
      child: Text(
        'Bảng Theo dõi Hành Trình Sống Khỏe',
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.textInverse,
          fontWeight: AppTypography.bold,
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: context.semanticColors.primary),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.heading4),
      Text(subtitle, style: AppTextStyles.labelMedium.copyWith(color: context.semanticColors.textSecondary)),
    ])),
  ]);
}

class _AdaptiveFeatureGrid extends StatelessWidget {
  const _AdaptiveFeatureGrid({required this.actions, required this.gridKey,
    this.tileKeyPrefix = 'feature-tile', this.statusLabel});
  final List<_FeatureAction> actions;
  final Key gridKey;
  final String tileKeyPrefix;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final minTileWidth = scale >= 1.5 ? 132.0 : 108.0;
    final spacing = AppSpacing.sm;
    final columns = math.max(
      1,
      math.min(6, ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor()),
    );
    final extent = scale >= 1.7 ? 148.0 : scale >= 1.3 ? 128.0 : 108.0;
    return GridView.builder(
      key: gridKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        mainAxisExtent: extent,
      ),
      itemBuilder: (context, index) => _FeatureTile(
        action: actions[index],
        key: Key('$tileKeyPrefix-${actions[index].id}'),
        statusLabel: statusLabel,
      ),
    );
  });
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({super.key, required this.action, this.statusLabel});
  final _FeatureAction action;
  final String? statusLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: statusLabel == null ? action.title : '${action.title}. $statusLabel',
    child: Material(
      color: action.backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(action.icon, color: action.color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: Text(action.title, maxLines: 3,
              overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(fontWeight: AppTypography.bold))),
            if (statusLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(statusLabel!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(color: action.color)),
            ],
          ]),
        ),
      ),
    ),
  );
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({super.key, required this.toggleKey, required this.title,
    required this.subtitle, required this.icon, required this.count,
    required this.expanded, required this.onToggle, required this.child});
  final Key toggleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final duration = (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
        ? Duration.zero : AppDuration.fast;
    return Column(children: [
      Material(
        key: toggleKey,
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingCompact),
            child: Row(children: [
              Icon(icon, color: context.semanticColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(color: context.semanticColors.textSecondary)),
              ])),
              Text('$count'),
              AnimatedRotation(
                duration: duration,
                turns: expanded ? .5 : 0,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ]),
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: duration,
        child: expanded
            ? Padding(key: const ValueKey('expanded'), padding: const EdgeInsets.only(top: AppSpacing.sm), child: child)
            : const SizedBox.shrink(key: ValueKey('collapsed')),
      ),
    ]);
  }
}

class _AdaptiveAdvancedGrid extends StatelessWidget {
  const _AdaptiveAdvancedGrid({required this.items, required this.onTap});
  final List<HealthFeatureCatalogItem> items;
  final ValueChanged<HealthFeatureCatalogItem> onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final minWidth = scale >= 1.5 ? 180.0 : 150.0;
    final columns = math.max(1, math.min(5, (constraints.maxWidth / minWidth).floor()));
    final height = scale >= 1.5 ? 180.0 : 150.0;
    return GridView.builder(
      key: const Key('advanced-features-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: height,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          key: Key('advanced-health-feature-${item.moduleId}'),
          color: context.semanticColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => onTap(item),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.icon, color: item.color),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: AppTypography.bold))),
                const Text('Đang phát triển'),
              ]),
            ),
          ),
        );
      },
    );
  });
}

class _FeatureAction {
  const _FeatureAction(this.id, this.title, this.icon, this.color,
      this.backgroundColor, this.onTap);
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _scoreController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _entryController.forward();
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardDynamicProvider);
    await ref.read(dashboardProvider.future);
    await ref.read(dashboardDynamicProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final dynamicAsync = ref.watch(dashboardDynamicProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardAsync.when(
        loading: () => const _DashboardLoadingView(),
        error: (error, _) => _DashboardErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (dashboard) {
          final dynamicData =
              dynamicAsync.value ?? DashboardDynamicEntity.empty();
          return FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _DashboardContent(
                  dashboard: dashboard,
                  dynamicData: dynamicData,
                  isDynamicLoading: dynamicAsync.isLoading,
                  dynamicError: dynamicAsync.hasError
                      ? dynamicAsync.error.toString()
                      : null,
                  pulseAnimation: _pulseController,
                  scoreAnimation: _scoreController,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final dynamic dashboard;
  final DashboardDynamicEntity dynamicData;
  final bool isDynamicLoading;
  final String? dynamicError;
  final Animation<double> pulseAnimation;
  final Animation<double> scoreAnimation;

  const _DashboardContent({
    required this.dashboard,
    required this.dynamicData,
    required this.isDynamicLoading,
    required this.dynamicError,
    required this.pulseAnimation,
    required this.scoreAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final name = _safeText(dashboard.fullName, fallback: 'bạn');
    final bmi = _asDouble(dashboard.bmi);
    final weightKg = _asDouble(dashboard.weightKg);
    final heightCm = _asDouble(dashboard.heightCm);
    final goals = _asStringList(dashboard.goals);
    final conditions = _asStringList(dashboard.conditions);
    final habits = _asStringList(dashboard.habits);
    final sleepQuality = _safeText(
      dashboard.sleepQuality,
      fallback: 'Chưa ghi nhận',
    );
    final activityLevel = _safeText(
      dashboard.activityLevel,
      fallback: 'Chưa ghi nhận',
    );
    final waterPerDay = _safeText(
      dashboard.waterPerDay,
      fallback: 'Chưa ghi nhận',
    );
    final concern = _safeText(dashboard.concernText, fallback: '');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _HeroPanel(
            name: name,
            bmi: bmi,
            unreadNotifications: dynamicData.unreadNotificationCount,
            pulseAnimation: pulseAnimation,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.lg),
              if (isDynamicLoading) const _SyncBanner(),
              if (dynamicError != null) ...[
                _InlineErrorBanner(message: dynamicError!),
                const SizedBox(height: AppSpacing.md),
              ],
              _HealthScorePanel(
                metrics: dynamicData.metrics,
                bmi: bmi,
                sleepQuality: sleepQuality,
                activityLevel: activityLevel,
                scoreAnimation: scoreAnimation,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TodayMetricsGrid(
                weightKg: weightKg,
                heightCm: heightCm,
                metrics: dynamicData.metrics,
              ),
              const SizedBox(height: AppSpacing.lg),
              _InsightSection(
                insights: dynamicData.insights,
                recommendations: dynamicData.recommendations,
                concern: concern,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimelineSection(items: dynamicData.timeline),
              const SizedBox(height: AppSpacing.lg),
              _GoalProgressSection(
                progressItems: dynamicData.goalProgress,
                fallbackGoals: goals,
              ),
              const SizedBox(height: AppSpacing.lg),
              _LifestyleSection(
                sleepQuality: sleepQuality,
                activityLevel: activityLevel,
                waterPerDay: waterPerDay,
                conditions: conditions,
                habits: habits,
              ),
              const SizedBox(height: AppSpacing.lg),
              _GoalChipsSection(goals: goals),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String name;
  final double bmi;
  final int unreadNotifications;
  final Animation<double> pulseAnimation;

  const _HeroPanel({
    required this.name,
    required this.bmi,
    required this.unreadNotifications,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final shortName = name.trim().isEmpty ? 'bạn' : name.trim().split(' ').last;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        56,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + pulseAnimation.value * 0.04,
                    child: child,
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.26)),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const Spacer(),
              _HeroPill(
                icon: Icons.notifications_rounded,
                label: unreadNotifications == 0
                    ? 'Không có nhắc mới'
                    : '$unreadNotifications nhắc mới',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chào $shortName,',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nami đã lấy dữ liệu mới nhất từ hệ thống để cùng bạn nhìn lại hôm nay.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _HeroPill(
            icon: Icons.monitor_heart_rounded,
            label: bmi > 0
                ? 'BMI ${bmi.toStringAsFixed(1)}'
                : 'BMI chưa có dữ liệu',
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthScorePanel extends StatelessWidget {
  final DashboardDailyMetrics metrics;
  final double bmi;
  final String sleepQuality;
  final String activityLevel;
  final Animation<double> scoreAnimation;

  const _HealthScorePanel({
    required this.metrics,
    required this.bmi,
    required this.sleepQuality,
    required this.activityLevel,
    required this.scoreAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final score = metrics.dailyScore;
    return _DashboardCard(
      child: Row(
        children: [
          AnimatedBuilder(
            animation: scoreAnimation,
            builder: (context, _) {
              return _ScoreRing(
                progress: (score / 100) * scoreAnimation.value,
                label: score == 0 ? '--' : score.toString(),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score == 0 ? 'Chưa đủ dữ liệu chấm điểm' : _scoreTitle(score),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  score == 0
                      ? 'Khi bạn ghi log sức khỏe, hoàn thành nhiệm vụ hoặc bữa ăn, điểm hôm nay sẽ tự cập nhật.'
                      : 'Điểm này được tính từ log sức khỏe, nhiệm vụ hằng ngày, bữa ăn và dữ liệu nước/ngủ trong hệ thống.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      label: bmi > 0
                          ? 'BMI ${bmi.toStringAsFixed(1)}'
                          : 'BMI --',
                    ),
                    _MiniBadge(label: sleepQuality),
                    _MiniBadge(label: activityLevel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreTitle(int score) {
    if (score >= 85) return 'Hôm nay của bạn rất ổn';
    if (score >= 65) return 'Bạn đang đi đúng hướng';
    if (score >= 40) return 'Mình cùng cải thiện nhẹ nhé';
    return 'Nami sẽ theo sát bạn hơn hôm nay';
  }
}

class _ScoreRing extends StatelessWidget {
  final double progress;
  final String label;

  const _ScoreRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 94,
            height: 94,
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              strokeWidth: 9,
              backgroundColor: AppColors.primary.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text('điểm', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayMetricsGrid extends StatelessWidget {
  final double weightKg;
  final double heightCm;
  final DashboardDailyMetrics metrics;

  const _TodayMetricsGrid({
    required this.weightKg,
    required this.heightCm,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        icon: Icons.monitor_weight_rounded,
        title: 'Cân nặng',
        value: weightKg > 0 ? '${weightKg.toStringAsFixed(1)} kg' : 'Chưa có',
      ),
      _MetricData(
        icon: Icons.height_rounded,
        title: 'Chiều cao',
        value: heightCm > 0 ? '${heightCm.toStringAsFixed(0)} cm' : 'Chưa có',
      ),
      _MetricData(
        icon: Icons.local_fire_department_rounded,
        title: 'Calories',
        value: metrics.caloriesLogged > 0
            ? '${metrics.caloriesLogged} kcal'
            : metrics.caloriesPlanned > 0
            ? '${metrics.caloriesPlanned} kcal dự kiến'
            : 'Chưa có',
      ),
      _MetricData(
        icon: Icons.water_drop_rounded,
        title: 'Nước',
        value: metrics.waterMl > 0 ? '${metrics.waterMl} ml' : 'Chưa có',
      ),
      _MetricData(
        icon: Icons.task_alt_rounded,
        title: 'Nhiệm vụ',
        value: metrics.totalTasks > 0
            ? '${metrics.completedTasks}/${metrics.totalTasks}'
            : 'Chưa có',
      ),
      _MetricData(
        icon: Icons.directions_walk_rounded,
        title: 'Bước chân',
        value: metrics.stepsCount > 0 ? '${metrics.stepsCount}' : 'Chưa có',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Dữ liệu hôm nay',
          subtitle: 'Tất cả chỉ số bên dưới được đọc từ hệ thống',
          icon: Icons.query_stats_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            final spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _MetricTile(data: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MetricData {
  final IconData icon;
  final String title;
  final String value;

  const _MetricData({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(data.title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final List<DashboardInsightItem> insights;
  final List<DashboardRecommendationItem> recommendations;
  final String concern;

  const _InsightSection({
    required this.insights,
    required this.recommendations,
    required this.concern,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Nami nhận thấy',
          subtitle: 'Gợi ý của AI và đề xuất được lấy từ AI trong hệ thống',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (concern.isNotEmpty) ...[
          _DashboardCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Điều bạn đang quan tâm: $concern',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (insights.isEmpty && recommendations.isEmpty)
          const _EmptyDataCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Chưa có insight AI trong hệ thống',
            message:
                'Khi bảng ai_insights hoặc ai_recommendations có dữ liệu, phần này sẽ tự hiển thị.',
          )
        else ...[
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InsightCard(item: item),
            ),
          ),
          ...recommendations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationCard(item: item),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final DashboardInsightItem item;

  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _riskIcon(item.riskLevel),
                color: _riskColor(item.riskLevel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final DashboardRecommendationItem item;

  const _RecommendationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isRead
                    ? Icons.lightbulb_outline_rounded
                    : Icons.lightbulb_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (item.actionText.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.actionText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<DashboardTimelineItem> items;

  const _TimelineSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Hôm nay của chúng ta',
          subtitle: 'Bữa ăn, nhiệm vụ và thông báo được gom từ hệ thống',
          icon: Icons.timeline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const _EmptyDataCard(
            icon: Icons.timeline_outlined,
            title: 'Chưa có timeline hôm nay',
            message:
                'Khi meal_plans, daily_health_tasks hoặc notifications có dữ liệu hôm nay, timeline sẽ tự cập nhật.',
          )
        else
          _DashboardCard(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _TimelineRow(item: items[i]),
                  if (i != items.length - 1) const Divider(height: 24),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DashboardTimelineItem item;

  const _TimelineRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            item.timeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _categoryColor(item.category).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _categoryIcon(item.category),
            color: _categoryColor(item.category),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (item.subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        Icon(
          item.isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: item.isCompleted ? AppColors.primary : Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}

class _GoalProgressSection extends StatelessWidget {
  final List<DashboardGoalProgressItem> progressItems;
  final List<String> fallbackGoals;

  const _GoalProgressSection({
    required this.progressItems,
    required this.fallbackGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Tiến độ mục tiêu',
          subtitle: 'Nâng cao sức khỏe mỗi ngày cùng Nami nha',
          icon: Icons.flag_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (progressItems.isEmpty)
          _EmptyDataCard(
            icon: Icons.flag_outlined,
            title: fallbackGoals.isEmpty
                ? 'Chưa có mục tiêu sức khỏe'
                : 'Chưa có tiến độ nhiệm vụ hôm nay',
            message: fallbackGoals.isEmpty
                ? 'Hãy hoàn thành onboarding để lưu mục tiêu vào hệ thống.'
                : 'Mục tiêu đã có, nhưng hôm nay chưa có tiến độ.',
          )
        else
          _DashboardCard(
            child: Column(
              children: [
                for (var i = 0; i < progressItems.length; i++) ...[
                  _GoalProgressRow(item: progressItems[i]),
                  if (i != progressItems.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  final DashboardGoalProgressItem item;

  const _GoalProgressRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${(item.progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.progress.clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: AppColors.primary.withOpacity(0.10),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _LifestyleSection extends StatelessWidget {
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;
  final List<String> conditions;
  final List<String> habits;

  const _LifestyleSection({
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.conditions,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Nhịp sống của bạn',
          subtitle:
              'Dữ liệu được Nami tổng hợp từ các log sức khỏe, nhiệm vụ và bữa ăn trong hệ thống nè, bạn cố lên',
          icon: Icons.spa_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _DashboardCard(
          child: Column(
            children: [
              _LifestyleRow(
                icon: Icons.bedtime_rounded,
                label: 'Giấc ngủ',
                value: sleepQuality,
              ),
              const Divider(height: 24),
              _LifestyleRow(
                icon: Icons.directions_run_rounded,
                label: 'Vận động',
                value: activityLevel,
              ),
              const Divider(height: 24),
              _LifestyleRow(
                icon: Icons.water_drop_rounded,
                label: 'Nước mỗi ngày',
                value: waterPerDay,
              ),
              if (conditions.isNotEmpty || habits.isNotEmpty) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...conditions.map(
                        (item) => _InfoChip(
                          label: item,
                          icon: Icons.health_and_safety_rounded,
                        ),
                      ),
                      ...habits.map(
                        (item) => _InfoChip(
                          label: item,
                          icon: Icons.restaurant_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LifestyleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LifestyleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _GoalChipsSection extends StatelessWidget {
  final List<String> goals;

  const _GoalChipsSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Điều chúng ta đang hướng tới',
          subtitle: 'Danh sách mục tiêu lấy từ health_goals',
          icon: Icons.track_changes_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (goals.isEmpty)
          const _EmptyDataCard(
            icon: Icons.track_changes_outlined,
            title: 'Chưa có mục tiêu',
            message:
                'Sau onboarding, mục tiêu sẽ được lưu và tự hiển thị ở đây.',
          )
        else
          _DashboardCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals
                  .map(
                    (goal) => _InfoChip(label: goal, icon: Icons.flag_rounded),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyDataCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _DashboardCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đang đồng bộ dữ liệu động từ hệ thống...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không đọc được một phần dữ liệu động: $message',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa thể mở trang chủ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'water':
      return Icons.water_drop_rounded;
    case 'body':
    case 'exercise':
      return Icons.directions_run_rounded;
    case 'mind':
    case 'stress':
      return Icons.self_improvement_rounded;
    case 'brain':
      return Icons.psychology_rounded;
    case 'meal':
      return Icons.restaurant_rounded;
    default:
      return Icons.favorite_rounded;
  }
}

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'water':
      return AppColors.secondary;
    case 'body':
    case 'exercise':
      return Colors.green;
    case 'mind':
    case 'stress':
      return Colors.purple;
    case 'brain':
      return Colors.orange;
    case 'meal':
      return AppColors.primary;
    default:
      return AppColors.primary;
  }
}

IconData _riskIcon(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return Icons.warning_rounded;
    case 'medium':
    case 'warning':
      return Icons.info_rounded;
    default:
      return Icons.check_circle_rounded;
  }
}

Color _riskColor(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'high':
    case 'danger':
      return Colors.redAccent;
    case 'medium':
    case 'warning':
      return Colors.orange;
    default:
      return AppColors.primary;
  }
}

String _safeText(Object? value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<String> _asStringList(Object? value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = value.toString().trim();
  if (text.isEmpty) return const [];
  return [text];
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/features/dashboard/domain/services/dashboard_companion_service.dart';
import 'package:nano_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/services/ai/ai_exceptions.dart';
import 'package:nano_app/shared/widgets/ai_chat_fab.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final bool showStandaloneChatButton;

  const DashboardPage({super.key, this.showStandaloneChatButton = true});

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

  Future<void> _generateAdditionalPlan() async {
    try {
      await ref
          .read(dashboardControllerProvider.notifier)
          .generateAdditionalPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nami đã thêm kế hoạch 7 ngày tiếp theo rồi nhé.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AIOverloadedException
          ? AIOverloadedException.userMessage
          : 'Nami chưa thể tạo thêm kế hoạch lúc này. Mình thử lại sau một chút nhé.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _completeTimelineItem(DashboardTimelineItem item) async {
    await _runDashboardAction(
      action: () => ref
          .read(dashboardControllerProvider.notifier)
          .completeTimelineItem(item),
      successMessage: 'Nami đã ghi nhận việc nhỏ này rồi nhé.',
      errorMessage:
          'Nami chưa thể cập nhật việc này lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _saveDailyCheckIn(String mood) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).saveDailyCheckIn(mood),
      successMessage: 'Nami đã ghi nhận cảm nhận hôm nay của bạn.',
      errorMessage:
          'Nami chưa thể ghi nhận cảm nhận lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _addWater(int amountMl) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).addWater(amountMl),
      successMessage: 'Nami đã thêm lượng nước cho hôm nay.',
      errorMessage:
          'Nami chưa thể cập nhật nước lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _setWater(int waterMl) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).setWater(waterMl),
      successMessage: 'Nami đã lưu lượng nước hôm nay.',
      errorMessage:
          'Nami chưa thể cập nhật nước lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _saveWeight(double weightKg) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).saveWeight(weightKg),
      successMessage: 'Nami đã lưu cân nặng hôm nay.',
      errorMessage:
          'Nami chưa thể cập nhật cân nặng lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _runDashboardAction({
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final dynamicAsync = ref.watch(dashboardDynamicProvider);
    final generationState = ref.watch(dashboardControllerProvider);

    final body = dashboardAsync.when(
      loading: () => const _DashboardLoadingView(),
      error: (error, _) => _DashboardErrorView(
        message:
            'Nami chưa thể mở trang chủ lúc này. Mình thử lại sau một chút nhé.',
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
                    ? 'Nami chưa thể cập nhật một vài tín hiệu mới nhất. Bạn có thể kéo xuống để thử lại nhé.'
                    : null,
                isGeneratingPlan: generationState.isLoading,
                onGeneratePlan: _generateAdditionalPlan,
                onCompleteTimelineItem: _completeTimelineItem,
                onDailyCheckIn: _saveDailyCheckIn,
                onAddWater: _addWater,
                onSetWater: _setWater,
                onSaveWeight: _saveWeight,
                pulseAnimation: _pulseController,
                scoreAnimation: _scoreController,
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (widget.showStandaloneChatButton)
            const DraggableAIChatButton(bottomReserve: 24),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final dynamic dashboard;
  final DashboardDynamicEntity dynamicData;
  final bool isDynamicLoading;
  final String? dynamicError;
  final bool isGeneratingPlan;
  final Future<void> Function() onGeneratePlan;
  final TimelineActionCallback onCompleteTimelineItem;
  final Future<void> Function(String mood) onDailyCheckIn;
  final Future<void> Function(int amountMl) onAddWater;
  final Future<void> Function(int waterMl) onSetWater;
  final Future<void> Function(double weightKg) onSaveWeight;
  final Animation<double> pulseAnimation;
  final Animation<double> scoreAnimation;

  const _DashboardContent({
    required this.dashboard,
    required this.dynamicData,
    required this.isDynamicLoading,
    required this.dynamicError,
    required this.isGeneratingPlan,
    required this.onGeneratePlan,
    required this.onCompleteTimelineItem,
    required this.onDailyCheckIn,
    required this.onAddWater,
    required this.onSetWater,
    required this.onSaveWeight,
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
    final displayWeightKg = dynamicData.todayWeightKg ?? weightKg;
    final dailySummary = DashboardCompanionService.buildDailySummary(
      metrics: dynamicData.metrics,
      sleepQuality: sleepQuality,
      activityLevel: activityLevel,
    );
    final isSlowDay = DashboardCompanionService.isSlowDayMood(
      dynamicData.todayMood,
    );
    final nextAction = DashboardCompanionService.selectNextAction(
      timeline: dynamicData.timeline,
      mood: dynamicData.todayMood,
    );

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
            isGeneratingPlan: isGeneratingPlan,
            onGeneratePlan: onGeneratePlan,
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
              if (dynamicData.planStatus.hasPlan &&
                  dynamicData.planStatus.remainingDays == 1) ...[
                _PlanRenewalBanner(
                  isLoading: isGeneratingPlan,
                  onGeneratePlan: onGeneratePlan,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              DashboardDailySummaryCard(summary: dailySummary),
              const SizedBox(height: AppSpacing.md),
              DashboardDailyCheckInCard(
                selectedMood: dynamicData.todayMood,
                onSelectMood: onDailyCheckIn,
              ),
              if (isSlowDay) ...[
                const SizedBox(height: AppSpacing.md),
                const DashboardSlowDayBanner(),
              ],
              const SizedBox(height: AppSpacing.md),
              DashboardNextActionSection(
                item: nextAction,
                isSlowDay: isSlowDay,
                onComplete: onCompleteTimelineItem,
                onLater: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mình để việc này lại một chút, Nami vẫn nhắc nhẹ thôi nhé.',
                        ),
                      ),
                    );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _HealthScorePanel(
                metrics: dynamicData.metrics,
                bmi: bmi,
                sleepQuality: sleepQuality,
                activityLevel: activityLevel,
                scoreAnimation: scoreAnimation,
                onTap: () => _showScoreBreakdown(
                  context,
                  metrics: dynamicData.metrics,
                  sleepQuality: sleepQuality,
                  activityLevel: activityLevel,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TodayMetricsGrid(
                weightKg: displayWeightKg,
                heightCm: heightCm,
                metrics: dynamicData.metrics,
                onWaterTap: () => _showWaterSheet(context),
                onWeightTap: () =>
                    _showWeightSheet(context, currentWeightKg: displayWeightKg),
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPlanStatusCard(planStatus: dynamicData.planStatus),
              const SizedBox(height: AppSpacing.lg),
              DashboardSelfCareStreakCard(streak: dynamicData.selfCareStreak),
              const SizedBox(height: AppSpacing.lg),
              _InsightSection(
                insights: dynamicData.insights,
                recommendations: dynamicData.recommendations,
                concern: concern,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimelineSection(
                items: dynamicData.timeline,
                onCompleteTimelineItem: onCompleteTimelineItem,
              ),
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

  void _showScoreBreakdown(
    BuildContext context, {
    required DashboardDailyMetrics metrics,
    required String sleepQuality,
    required String activityLevel,
  }) {
    final items = DashboardCompanionService.buildScoreBreakdown(
      metrics: metrics,
      sleepQuality: sleepQuality,
      activityLevel: activityLevel,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (_) => DashboardHealthScoreBreakdownSheet(items: items),
    );
  }

  void _showWaterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DashboardWaterUpdateSheet(
        currentWaterMl: dynamicData.metrics.waterMl,
        onAddWater: onAddWater,
        onSetWater: onSetWater,
      ),
    );
  }

  void _showWeightSheet(
    BuildContext context, {
    required double currentWeightKg,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DashboardWeightUpdateSheet(
        currentWeightKg: currentWeightKg > 0 ? currentWeightKg : null,
        onSaveWeight: onSaveWeight,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String name;
  final double bmi;
  final int unreadNotifications;
  final bool isGeneratingPlan;
  final Future<void> Function() onGeneratePlan;
  final Animation<double> pulseAnimation;

  const _HeroPanel({
    required this.name,
    required this.bmi,
    required this.unreadNotifications,
    required this.isGeneratingPlan,
    required this.onGeneratePlan,
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
          const SizedBox(height: AppSpacing.md),
          _GeneratePlanCta(
            isLoading: isGeneratingPlan,
            onPressed: onGeneratePlan,
          ),
        ],
      ),
    );
  }
}

class _GeneratePlanCta extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onPressed;

  const _GeneratePlanCta({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? 'Nami đang tạo dữ liệu 7 ngày...'
                          : 'Tạo dữ liệu 7 ngày',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Thêm 7 ngày thực đơn, vận động và lịch trình nhẹ nhàng cho bạn.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary.withValues(alpha: isLoading ? 0.4 : 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRenewalBanner extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onGeneratePlan;

  const _PlanRenewalBanner({
    required this.isLoading,
    required this.onGeneratePlan,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hôm nay là ngày cuối trong lịch trình',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bạn có thể tạo dữ liệu 7 ngày mới để Nami tiếp tục đồng hành.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onGeneratePlan,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isLoading ? 'Nami đang tạo...' : 'Tạo dữ liệu 7 ngày',
              ),
            ),
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
  final VoidCallback onTap;

  const _HealthScorePanel({
    required this.metrics,
    required this.bmi,
    required this.sleepQuality,
    required this.activityLevel,
    required this.scoreAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = metrics.dailyScore;
    return GestureDetector(
      onTap: onTap,
      child: _DashboardCard(
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
                    score == 0
                        ? 'Chưa đủ dữ liệu chấm điểm'
                        : _scoreTitle(score),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    score == 0
                        ? 'Khi bạn ghi nhận sức khỏe, hoàn thành việc nhỏ hoặc dùng bữa, điểm hôm nay sẽ tự cập nhật.'
                        : 'Điểm này được Nami tổng hợp từ sức khỏe, nhiệm vụ hằng ngày, bữa ăn, nước uống và giấc ngủ.',
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
                      const _MiniBadge(label: 'Chạm để xem thêm'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final VoidCallback onWaterTap;
  final VoidCallback onWeightTap;

  const _TodayMetricsGrid({
    required this.weightKg,
    required this.heightCm,
    required this.metrics,
    required this.onWaterTap,
    required this.onWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        icon: Icons.monitor_weight_rounded,
        title: 'Cân nặng',
        value: weightKg > 0 ? '${weightKg.toStringAsFixed(1)} kg' : 'Chưa có',
        onTap: onWeightTap,
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
        onTap: onWaterTap,
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
          subtitle: 'Nami gom lại những tín hiệu chính của hôm nay',
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
  final VoidCallback? onTap;

  const _MetricData({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final content = _DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.primary, size: 22),
              const Spacer(),
              if (data.onTap != null)
                Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary.withValues(alpha: 0.65),
                  size: 16,
                ),
            ],
          ),
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

    final onTap = data.onTap;
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
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
          subtitle: 'Những điều Nami muốn bạn để ý một chút hôm nay',
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
            title: 'Nami chưa có nhận xét mới',
            message:
                'Khi có thêm tín hiệu từ ngày của bạn, Nami sẽ đặt những điều đáng chú ý ở đây.',
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
  final TimelineActionCallback onCompleteTimelineItem;

  const _TimelineSection({
    required this.items,
    required this.onCompleteTimelineItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Hôm nay của chúng ta',
          subtitle: 'Bữa ăn, việc nhỏ và lời nhắc được Nami gom lại cho bạn',
          icon: Icons.timeline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const _EmptyDataCard(
            icon: Icons.timeline_outlined,
            title: 'Chưa có timeline hôm nay',
            message:
                'Khi hôm nay có bữa ăn, việc nhỏ hoặc lời nhắc mới, Nami sẽ sắp chúng thành một nhịp dễ theo dõi.',
          )
        else
          _DashboardCard(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _TimelineRow(
                    item: items[i],
                    onComplete: onCompleteTimelineItem,
                  ),
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
  final TimelineActionCallback onComplete;

  const _TimelineRow({required this.item, required this.onComplete});

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
        if (item.isCompleted)
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 20,
          )
        else if (item.canComplete)
          IconButton(
            tooltip: 'Đã làm',
            visualDensity: VisualDensity.compact,
            onPressed: () => onComplete(item),
            icon: const Icon(Icons.check_circle_outline_rounded),
            color: AppColors.primary,
          )
        else
          const Icon(
            Icons.radio_button_unchecked_rounded,
            color: Colors.grey,
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
              'Nami tổng hợp các ghi nhận sức khỏe, việc nhỏ và bữa ăn để hiểu nhịp sống của bạn hơn.',
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
          subtitle: 'Những mục tiêu Nami sẽ cùng bạn chăm từng chút một',
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
                'Nami đang cập nhật những tín hiệu mới nhất...',
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
              message,
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

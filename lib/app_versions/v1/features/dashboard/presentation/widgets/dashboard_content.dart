import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/services/dashboard_companion_service.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart';
import 'package:nano_app/core/membership/membership_display_info.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/cloud_sync/cloud_sync.dart';

class DashboardContent extends StatelessWidget {
  final DashboardEntity dashboard;
  final MembershipDisplayInfo membershipInfo;
  final DashboardDynamicEntity dynamicData;
  final bool isDynamicLoading;
  final String? dynamicError;
  final bool isGeneratingPlan;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onGeneratePlan;
  final TimelineActionCallback onCompleteTimelineItem;
  final Future<void> Function(String mood) onDailyCheckIn;
  final Future<void> Function(int amountMl) onAddWater;
  final Future<void> Function(int waterMl) onSetWater;
  final Future<void> Function(double weightKg) onSaveWeight;
  final VoidCallback onViewSchedule;
  final UserDataSyncState userDataSyncState;

  const DashboardContent({
    required this.dashboard,
    required this.membershipInfo,
    required this.dynamicData,
    required this.isDynamicLoading,
    required this.dynamicError,
    required this.isGeneratingPlan,
    required this.onRefresh,
    required this.onGeneratePlan,
    required this.onCompleteTimelineItem,
    required this.onDailyCheckIn,
    required this.onAddWater,
    required this.onSetWater,
    required this.onSaveWeight,
    required this.onViewSchedule,
    required this.userDataSyncState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = dashboard.fullName.trim().isEmpty
        ? 'bạn'
        : dashboard.fullName.trim();
    final sleepQuality = dashboard.sleepQuality.trim().isEmpty
        ? 'Giấc ngủ chưa ghi nhận'
        : dashboard.sleepQuality.trim();
    final activityLevel = dashboard.activityLevel.trim().isEmpty
        ? 'Vận động chưa ghi nhận'
        : dashboard.activityLevel.trim();
    final waterPerDay = dashboard.waterPerDay.trim().isEmpty
        ? 'Nước chưa ghi nhận'
        : dashboard.waterPerDay.trim();
    final displayWeightKg =
        dynamicData.todayWeightKg ?? dashboard.weightKg;
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              fullName: fullName,
              membershipInfo: membershipInfo,
              unreadNotifications: dynamicData.unreadNotificationCount,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sectionSpacing,
                AppSpacing.pagePadding,
                96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (userDataSyncState.status ==
                              UserDataSyncStatus.pendingUpload ||
                          userDataSyncState.status ==
                              UserDataSyncStatus.error) ...[
                        DashboardUserDataSyncBanner(
                          state: userDataSyncState,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (isDynamicLoading) ...[
                        const DashboardSyncBanner(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (dynamicError != null) ...[
                        DashboardInlineErrorBanner(message: dynamicError!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      DashboardSnapshotCard(
                        metrics: dynamicData.metrics,
                        nextAction: nextAction,
                        dailySummary: dailySummary,
                        isSlowDay: isSlowDay,
                        onScoreTap: () => _showScoreBreakdown(
                          context,
                          metrics: dynamicData.metrics,
                          sleepQuality: sleepQuality,
                          activityLevel: activityLevel,
                        ),
                        onComplete: onCompleteTimelineItem,
                        onLater: () => _showLaterMessage(context),
                      ),
                      if (isSlowDay) ...[
                        const SizedBox(height: AppSpacing.md),
                        const DashboardSlowDayBanner(),
                      ],
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardQuickActions(
                        selectedMood: dynamicData.todayMood,
                        waterMl: dynamicData.metrics.waterMl,
                        weightKg: displayWeightKg,
                        onMoodTap: () => _showMoodSheet(context),
                        onWaterTap: () => _showWaterSheet(context),
                        onWeightTap: () => _showWeightSheet(
                          context,
                          currentWeightKg: displayWeightKg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardTodayMetrics(metrics: dynamicData.metrics),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardTimelinePreview(
                        items: dynamicData.timeline,
                        onComplete: onCompleteTimelineItem,
                        onViewAll: onViewSchedule,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardProgressCard(
                        planStatus: dynamicData.planStatus,
                        streak: dynamicData.selfCareStreak,
                        isGeneratingPlan: isGeneratingPlan,
                        onGeneratePlan: onGeneratePlan,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardPrimaryInsight(
                        insights: dynamicData.insights,
                        recommendations: dynamicData.recommendations,
                        concern: dashboard.concernText,
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      DashboardHealthDetails(
                        bmi: dashboard.bmi,
                        heightCm: dashboard.heightCm,
                        sleepQuality: sleepQuality,
                        activityLevel: activityLevel,
                        waterPerDay: waterPerDay,
                        goalProgress: dynamicData.goalProgress,
                        fallbackGoals: dashboard.goals,
                        conditions: dashboard.conditions,
                        habits: dashboard.habits,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

  void _showMoodSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DashboardMoodCheckInSheet(
        selectedMood: dynamicData.todayMood,
        onSelectMood: onDailyCheckIn,
      ),
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

  void _showLaterMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Mình để việc này lại một chút, Nabi vẫn nhắc nhẹ thôi nhé.',
          ),
        ),
      );
  }
}

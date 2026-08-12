import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/dashboard_content.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_horizon.dart';
import 'package:nano_app/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/app_versions/v1/shared/widgets/ai_chat_fab.dart';
import 'package:nano_app/core/membership/membership_display_info.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/nabi.dart';
import 'package:nano_app/services/supabase/cloud_sync/cloud_sync.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final bool showStandaloneChatButton;

  const DashboardPage({super.key, this.showStandaloneChatButton = true});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  Timer? _scheduleStatusTimer;
  final Set<String> _busyTimelineItems = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleStatusTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.invalidate(dashboardDynamicProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardDynamicProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleStatusTimer?.cancel();
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
      final result = await ref
          .read(dashboardControllerProvider.notifier)
          .generateAdditionalPlan();
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.milestone);
      final message = switch (result.generationSource) {
        PlanGenerationSource.ai =>
          'Nabi đã thêm kế hoạch 7 ngày tiếp theo rồi nhé.',
        PlanGenerationSource.localFallback || PlanGenerationSource.unknown =>
          'Nabi đã thêm lịch gợi ý cơ bản 7 ngày. Khi dịch vụ sẵn sàng, bạn có thể tạo lại để nhận gợi ý cá nhân hơn nhé.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      if (error is DailyRoutinePreferencesRequiredException) {
        final saved = await context.push<bool>(
          V1RoutePaths.dailyRoutinePreferences,
        );
        if (saved != true || !mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Tạo lịch 7 ngày mới?'),
            content: const Text(
              'Nabi đã lưu nhịp sinh hoạt. Chỉ khi bạn xác nhận, Nabi mới dùng một lượt để tạo lịch mới.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Tạo lịch'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await _generateAdditionalPlan();
        }
        return;
      }
      if (error is PersonalScheduleQuotaExceededException) {
        AppFeedbackService.instance.emit(AppFeedbackType.error);
        await showMembershipUpgradePrompt(
          context,
          title: 'Đã dùng hết lượt tạo lịch',
          message:
              '${PersonalScheduleQuotaExceededException.userMessage} Nâng cấp Plus để tiếp tục tạo lịch theo nhu cầu của bạn nhé.',
          planCode: MembershipUpgradePlan.plus,
        );
        return;
      }
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      final message = switch (error) {
        DashboardGenerationAuthRequiredException() =>
          DashboardGenerationAuthRequiredException.userMessage,
        GuestInitialPlanAlreadyUsedException() =>
          GuestInitialPlanAlreadyUsedException.userMessage,
        PersonalScheduleQuotaUnavailableException() =>
          PersonalScheduleQuotaUnavailableException.userMessage,
        PersonalScheduleStillActiveException() =>
          'Lịch trình hiện tại vẫn còn ${error.remainingDays} ngày. Bạn có thể tạo lịch mới khi còn 1 ngày nhé.',
        ScheduleHorizonDataException() =>
          ScheduleHorizonDataException.userMessage,
        AIOverloadedException() => AIOverloadedException.userMessage,
        _ =>
          'Nabi chưa thể tạo thêm kế hoạch lúc này. Mình thử lại sau một chút nhé.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _completeTimelineItem(DashboardTimelineItem item) async {
    if (!_busyTimelineItems.add(item.id)) return;
    try {
      final sourceId = item.sourceId?.trim();
      if (sourceId == null || sourceId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nabi chưa tìm thấy nhiệm vụ trong lịch chăm sóc.'),
          ),
        );
        return;
      }
      await context.push(
        Uri(
          path: V1RoutePaths.lifestyleSchedule,
          queryParameters: {'item': sourceId},
        ).toString(),
      );
      if (mounted) {
        ref.invalidate(dashboardDynamicProvider);
      }
    } finally {
      _busyTimelineItems.remove(item.id);
    }
  }

  Future<void> _saveDailyCheckIn(String mood) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).saveDailyCheckIn(mood),
      successMessage: 'Nabi đã ghi nhận cảm nhận hôm nay của bạn.',
      errorMessage:
          'Nabi chưa thể ghi nhận cảm nhận lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _addWater(int amountMl) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).addWater(amountMl),
      successMessage: 'Nabi đã thêm lượng nước cho hôm nay.',
      errorMessage:
          'Nabi chưa thể cập nhật nước lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _setWater(int waterMl) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).setWater(waterMl),
      successMessage: 'Nabi đã lưu lượng nước hôm nay.',
      errorMessage:
          'Nabi chưa thể cập nhật nước lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<void> _saveWeight(double weightKg) async {
    await _runDashboardAction(
      action: () =>
          ref.read(dashboardControllerProvider.notifier).saveWeight(weightKg),
      successMessage: 'Nabi đã lưu cân nặng hôm nay.',
      errorMessage:
          'Nabi chưa thể cập nhật cân nặng lúc này. Mình thử lại sau một chút nhé.',
    );
  }

  Future<bool> _runDashboardAction({
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      await action();
      if (!mounted) return false;
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
      return true;
    } catch (_) {
      if (!mounted) return false;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final dynamicAsync = ref.watch(dashboardDynamicProvider);
    final generationState = ref.watch(dashboardControllerProvider);
    final userDataSyncState = ref.watch(userDataSyncControllerProvider);

    final body = dashboardAsync.when(
      loading: () => const KeyedSubtree(
        key: ValueKey('dashboard-loading'),
        child: DashboardLoadingView(),
      ),
      error: (error, _) => KeyedSubtree(
        key: const ValueKey('dashboard-error'),
        child: DashboardErrorView(
          message:
              'Nabi chưa thể mở trang chủ lúc này. Mình thử lại sau một chút nhé.',
          onRetry: () {
            ref.invalidate(dashboardProvider);
            ref.invalidate(dashboardDynamicProvider);
          },
        ),
      ),
      data: (dashboard) {
        final dynamicData =
            dynamicAsync.value ?? DashboardDynamicEntity.empty();
        final membershipInfo = membershipDisplayInfoForTier(
          dashboard.subscriptionTier,
        );
        return KeyedSubtree(
          key: const ValueKey('dashboard-ready'),
          child: DashboardContent(
            dashboard: dashboard,
            membershipInfo: membershipInfo,
            dynamicData: dynamicData,
            isDynamicLoading: dynamicAsync.isLoading,
            dynamicError: dynamicAsync.hasError
                ? 'Nabi chưa thể cập nhật một vài tín hiệu mới nhất. Bạn có thể kéo xuống để thử lại nhé.'
                : null,
            isGeneratingPlan: generationState.isLoading,
            onRefresh: _refresh,
            onGeneratePlan: _generateAdditionalPlan,
            onCompleteTimelineItem: _completeTimelineItem,
            onDailyCheckIn: _saveDailyCheckIn,
            onAddWater: _addWater,
            onSetWater: _setWater,
            onSaveWeight: _saveWeight,
            onViewSchedule: () => context.push(V1RoutePaths.lifestyleSchedule),
            userDataSyncState: userDataSyncState,
          ),
        );
      },
    );

    return MedicalPageScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AppStateSwitcher(
              alignment: Alignment.topCenter,
              child: body,
            ),
          ),
          if (widget.showStandaloneChatButton)
            NabiFeatureFlags.spriteMascotEnabled
                ? const NabiFloatingOverlay(bottomReserve: 24)
                : const DraggableAIChatButton(bottomReserve: 24),
        ],
      ),
    );
  }
}

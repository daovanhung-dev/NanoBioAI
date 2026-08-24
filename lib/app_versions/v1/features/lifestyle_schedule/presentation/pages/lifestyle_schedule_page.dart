import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_horizon.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_state.dart';
import '../widgets/daily_health_hub_panel.dart';
import '../widgets/schedule_date_selector.dart';
import '../widgets/schedule_day_header.dart';
import '../widgets/schedule_feedback_banner.dart';
import '../widgets/schedule_page_states.dart';
import '../widgets/schedule_progress_summary.dart';
import '../widgets/schedule_regeneration_card.dart';
import '../widgets/schedule_timeline.dart';
import 'schedule_proof_gallery_page.dart';

class LifestyleSchedulePage extends ConsumerStatefulWidget {
  final String? initialItemId;

  const LifestyleSchedulePage({super.key, this.initialItemId});

  @override
  ConsumerState<LifestyleSchedulePage> createState() =>
      _LifestyleSchedulePageState();
}

class _LifestyleSchedulePageState extends ConsumerState<LifestyleSchedulePage>
    with WidgetsBindingObserver {
  Timer? _boundaryTimer;
  DateTime? _scheduledBoundary;
  final GlobalKey _focusedItemKey = GlobalKey();
  bool _didRevealFocusedItem = false;
  bool _isGeneratingPlan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusInitialItemIfNeeded();
      unawaited(
        ref
            .read(lifestyleScheduleControllerProvider.notifier)
            .reconcilePendingRewards(),
      );
      unawaited(
        ref.read(dailyHealthHubControllerProvider).reconcilePendingRewards(),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boundaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (mounted) setState(() {});
    final controller = ref.read(lifestyleScheduleControllerProvider.notifier);

    if (controller.hasActiveCompletionFlow) return;

    ref.invalidate(scheduleHorizonProvider);
    unawaited(() async {
      await controller.refresh();
      await controller.reconcilePendingRewards();
      await ref.read(dailyHealthHubControllerProvider).reconcilePendingRewards();
    }());
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);

    ref.listen(lifestyleScheduleControllerProvider, (previous, next) {
      final previousError = previous?.value?.lastErrorMessage;
      final nextError = next.value?.lastErrorMessage;
      if (nextError != null && nextError != previousError) {
        AppFeedbackService.instance.emit(AppFeedbackType.error);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: isDark
          ? AppColorTokens.darkBackground
          : AppColorTokens.background,
      appBar: AppBar(
        title: const Text('Ngày của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tùy chỉnh nhịp sinh hoạt',
            onPressed: () => context.push(V1RoutePaths.dailyRoutinePreferences),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: scheduleAsync.when(
          loading: () => const SchedulePageFrame(
            key: ValueKey('schedule-loading'),
            child: ScheduleLoadingState(),
          ),
          error: (_, __) => SchedulePageFrame(
            key: const ValueKey('schedule-error'),
            child: ScheduleErrorState(onRetry: _refreshSchedule),
          ),
          data: (state) {
            _queueBoundaryRefresh(state.summary.items);
            _queueFocusedItemReveal(state);
            return SchedulePageFrame(
              key: const ValueKey('schedule-ready'),
              child: RefreshIndicator(
                onRefresh: _refreshSchedule,
                child: _ScheduleReadyContent(
                  state: state,
                  focusedItemKey: _focusedItemKey,
                  isGeneratingPlan: _isGeneratingPlan,
                  onGeneratePlan: _generateAdditionalPlan,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshSchedule() async {
    ref.invalidate(scheduleHorizonProvider);
    await ref.read(lifestyleScheduleControllerProvider.notifier).refresh();
  }

  Future<void> _generateAdditionalPlan() async {
    if (_isGeneratingPlan) return;
    final horizon = ref.read(scheduleHorizonProvider).value;
    if (horizon == null || horizon.remainingDays >= 2) return;

    setState(() => _isGeneratingPlan = true);
    try {
      final result = await ref
          .read(dashboardControllerProvider.notifier)
          .generateAdditionalPlan();
      if (!mounted) return;

      ref.invalidate(scheduleHorizonProvider);
      AppFeedbackService.instance.emit(AppFeedbackType.milestone);
      final message = switch (result.generationSource) {
        PlanGenerationSource.ai =>
          'Nabi đã thêm lịch 7 ngày tiếp theo rồi nhé.',
        PlanGenerationSource.localFallback || PlanGenerationSource.unknown =>
          'Nabi đã thêm lịch gợi ý cơ bản 7 ngày. Khi dịch vụ sẵn sàng, bạn có thể tạo lại để nhận gợi ý cá nhân hơn nhé.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      if (error is DailyRoutinePreferencesRequiredException) {
        setState(() => _isGeneratingPlan = false);
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
          'Lịch trình hiện tại vẫn còn ${error.remainingDays} ngày. Bạn có thể tạo lịch mới khi lịch còn dưới 2 ngày nhé.',
        ScheduleHorizonDataException() =>
          ScheduleHorizonDataException.userMessage,
        AIOverloadedException() => AIOverloadedException.userMessage,
        _ =>
          'Nabi chưa thể tạo thêm lịch lúc này. Mình thử lại sau một chút nhé.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted && _isGeneratingPlan) {
        setState(() => _isGeneratingPlan = false);
      }
    }
  }

  void _focusInitialItemIfNeeded() {
    final initialItemId = widget.initialItemId?.trim();
    if (initialItemId == null || initialItemId.isEmpty) return;
    unawaited(() async {
      await ref.read(lifestyleScheduleControllerProvider.future);
      if (!mounted) return;
      ref
          .read(lifestyleScheduleControllerProvider.notifier)
          .focusItem(initialItemId);
    }());
  }

  void _queueBoundaryRefresh(List<LifestyleScheduleItemEntity> items) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = ref.read(lifestyleScheduleClockProvider)();
      final boundaries = <DateTime>[];
      for (final item in items) {
        final start = item.scheduledAt;
        final deadline = item.completionDeadline;
        if (start != null && start.isAfter(now)) boundaries.add(start);
        if (deadline != null && deadline.isAfter(now)) {
          boundaries.add(deadline);
        }
      }
      boundaries.sort();
      final next = boundaries.firstOrNull;
      if (next == _scheduledBoundary && _boundaryTimer?.isActive == true) {
        return;
      }
      _boundaryTimer?.cancel();
      _scheduledBoundary = next;
      if (next == null) return;
      _boundaryTimer = Timer(
        next.difference(now) + const Duration(milliseconds: 50),
        () {
          if (!mounted) return;
          _scheduledBoundary = null;
          setState(() {});
        },
      );
    });
  }

  void _queueFocusedItemReveal(LifestyleScheduleState state) {
    if (_didRevealFocusedItem || state.focusedItemId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _focusedItemKey.currentContext;
      if (targetContext == null) return;
      _didRevealFocusedItem = true;
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: AppMotionScope.duration(
            context,
            AppDuration.emphasized,
          ),
          curve: AppAnimations.emphasizedCurve,
          alignment: .18,
        ),
      );
    });
  }
}

class _ScheduleReadyContent extends ConsumerWidget {
  const _ScheduleReadyContent({
    required this.state,
    required this.focusedItemKey,
    required this.isGeneratingPlan,
    required this.onGeneratePlan,
  });

  final LifestyleScheduleState state;
  final GlobalKey focusedItemKey;
  final bool isGeneratingPlan;
  final Future<void> Function() onGeneratePlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lifestyleScheduleControllerProvider.notifier);
    final horizonAsync = ref.watch(scheduleHorizonProvider);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacingTokens.pagePadding,
            AppSpacingTokens.itemSpacingLarge,
            AppSpacingTokens.pagePadding,
            96,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final expanded = constraints.maxWidth >= 760;
                    final timeline = ScheduleTimeline(
                      items: state.selectedItems,
                      focusedItemId: state.focusedItemId,
                      focusedItemKey: focusedItemKey,
                    );
                    final overview = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScheduleDayHeader(state: state),
                        const SizedBox(
                          height: AppSpacingTokens.itemSpacingLarge,
                        ),
                        ScheduleProgressSummary(state: state),
                        if (state.lastEncouragement != null) ...[
                          const SizedBox(
                            height: AppSpacingTokens.itemSpacingLarge,
                          ),
                          ScheduleEncouragementBanner(
                            message: state.lastEncouragement!,
                          ),
                        ],
                        if (state.lastErrorMessage != null) ...[
                          const SizedBox(
                            height: AppSpacingTokens.itemSpacingLarge,
                          ),
                          ScheduleActionErrorBanner(
                            message: state.lastErrorMessage!,
                          ),
                        ],
                      ],
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScheduleDateSelector(
                          dates: state.availableDates,
                          selectedDate: state.selectedDate,
                          today: ref.watch(lifestyleScheduleClockProvider)(),
                          onSelected: (date) {
                            AppFeedbackService.instance.emit(
                              AppFeedbackType.selection,
                            );
                            unawaited(controller.selectDate(date));
                          },
                        ),
                        const SizedBox(height: AppSpacingTokens.sectionSpacing),
                        DailyHealthHubPanel(state: state),
                        const SizedBox(height: AppSpacingTokens.sectionSpacing),
                        ScheduleRegenerationCard(
                          remainingDays: horizonAsync.value?.remainingDays,
                          isLoading: horizonAsync.isLoading,
                          hasError: horizonAsync.hasError,
                          isGenerating: isGeneratingPlan,
                          onGenerate: () => unawaited(onGeneratePlan()),
                        ),
                        const SizedBox(height: AppSpacingTokens.sectionSpacing),
                        if (expanded)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: overview),
                              const SizedBox(
                                width: AppSpacingTokens.sectionSpacing,
                              ),
                              Expanded(child: timeline),
                            ],
                          )
                        else ...[
                          overview,
                          const SizedBox(
                            height: AppSpacingTokens.sectionSpacing,
                          ),
                          timeline,
                        ],
                        if (state.completionProofs.isNotEmpty) ...[
                          const SizedBox(
                            height: AppSpacingTokens.sectionSpacing,
                          ),
                          ScheduleProofPreviewSection(
                            proofs: state.completionProofs,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

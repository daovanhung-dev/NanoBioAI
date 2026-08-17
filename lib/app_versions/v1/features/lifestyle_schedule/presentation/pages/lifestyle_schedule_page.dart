import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_state.dart';
import '../widgets/daily_health_hub_panel.dart';
import '../widgets/schedule_date_selector.dart';
import '../widgets/schedule_day_header.dart';
import '../widgets/schedule_feedback_banner.dart';
import '../widgets/schedule_page_states.dart';
import '../widgets/schedule_progress_summary.dart';
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
            child: ScheduleErrorState(
              onRetry: () => ref
                  .read(lifestyleScheduleControllerProvider.notifier)
                  .refresh(),
            ),
          ),
          data: (state) {
            _queueBoundaryRefresh(state.summary.items);
            _queueFocusedItemReveal(state);
            return SchedulePageFrame(
              key: const ValueKey('schedule-ready'),
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(lifestyleScheduleControllerProvider.notifier)
                    .refresh(),
                child: _ScheduleReadyContent(
                  state: state,
                  focusedItemKey: _focusedItemKey,
                ),
              ),
            );
          },
        ),
      ),
    );
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
  });

  final LifestyleScheduleState state;
  final GlobalKey focusedItemKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lifestyleScheduleControllerProvider.notifier);

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

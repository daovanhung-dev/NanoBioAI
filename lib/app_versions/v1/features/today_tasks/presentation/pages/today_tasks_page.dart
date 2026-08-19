import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/today_tasks/domain/services/today_task_selector.dart';
import 'package:nano_app/app_versions/v1/features/today_tasks/presentation/widgets/today_tasks_states.dart';
import 'package:nano_app/core/theme/theme.dart';

class TodayTasksPage extends ConsumerStatefulWidget {
  const TodayTasksPage({super.key});

  @override
  ConsumerState<TodayTasksPage> createState() => _TodayTasksPageState();
}

class _TodayTasksPageState extends ConsumerState<TodayTasksPage>
    with WidgetsBindingObserver {
  static const _selector = TodayTaskSelector();

  Timer? _boundaryTimer;
  DateTime? _scheduledBoundary;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = ref.read(lifestyleScheduleClockProvider)();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boundaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the clock provider in the dependency graph so test/runtime overrides
    // are observed, while actual time progression is driven by boundary timers.
    ref.watch(lifestyleScheduleClockProvider);
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);

    return MedicalPageScaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ hôm nay'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: scheduleAsync.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: scheduleAsync.when(
          loading: () =>
              const TodayTasksPageFrame(child: TodayTasksLoadingState()),
          error: (_, __) => TodayTasksPageFrame(
            child: TodayTasksErrorState(onRetry: _refresh),
          ),
          data: (state) {
            final tasks = _selector.select(
              items: state.summary.items,
              today: _now,
            );
            _scheduleBoundaryRefresh(tasks);
            return TodayTasksReadyState(
              tasks: tasks,
              now: _now,
              onRefresh: _refresh,
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    _updateNow();
    await ref.read(lifestyleScheduleControllerProvider.notifier).refresh();
  }

  void _updateNow() {
    if (!mounted) return;
    final next = ref.read(lifestyleScheduleClockProvider)();
    setState(() => _now = next);
  }

  void _scheduleBoundaryRefresh(List<LifestyleScheduleItemEntity> tasks) {
    final nextBoundary = _nextBoundary(tasks, _now);
    if (_scheduledBoundary == nextBoundary && _boundaryTimer?.isActive == true) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scheduledBoundary == nextBoundary &&
          _boundaryTimer?.isActive == true) {
        return;
      }
      _boundaryTimer?.cancel();
      _scheduledBoundary = nextBoundary;
      if (nextBoundary == null) return;

      final current = ref.read(lifestyleScheduleClockProvider)();
      var delay = nextBoundary.difference(current);
      if (delay.isNegative) delay = Duration.zero;
      // A tiny grace avoids sampling the same side of the boundary because of
      // timer scheduling precision on some devices.
      delay += const Duration(milliseconds: 40);
      _boundaryTimer = Timer(delay, () {
        if (!mounted) return;
        _scheduledBoundary = null;
        _updateNow();
      });
    });
  }

  DateTime? _nextBoundary(
    List<LifestyleScheduleItemEntity> tasks,
    DateTime now,
  ) {
    final candidates = <DateTime>[
      DateTime(now.year, now.month, now.day + 1),
    ];
    for (final task in tasks) {
      final start = task.scheduledAt;
      final deadline = task.completionDeadline;
      if (start != null && start.isAfter(now)) candidates.add(start);
      if (deadline != null && deadline.isAfter(now)) candidates.add(deadline);
    }
    candidates.sort();
    return candidates.isEmpty ? null : candidates.first;
  }
}

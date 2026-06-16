import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

import '../../domain/entities/daily_health_summary_entity.dart';
import '../../domain/entities/daily_health_task_entity.dart';
import '../../domain/repositories/daily_health_tracking_repository.dart';
import '../../providers/daily_health_tracking_provider.dart';
import 'daily_health_tracking_state.dart';

class DailyHealthTrackingController
    extends AsyncNotifier<DailyHealthTrackingState> {
  static const _tag = 'DAILY_TRACKING_CTRL';

  late final DailyHealthTrackingRepository _repository;

  @override
  Future<DailyHealthTrackingState> build() async {
    _repository = ref.read(dailyHealthTrackingRepositoryProvider);
    AppLogger.provider(_tag, 'Build daily health tracking controller');
    final summary = await _repository.getTodaySummary();
    return DailyHealthTrackingState(summary: summary);
  }

  Future<void> refresh() async {
    AppLogger.action(_tag, 'Refresh Today Tracking');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final summary = await _repository.refreshToday();
      return DailyHealthTrackingState(summary: summary);
    });
  }

  Future<void> toggleTask(DailyHealthTaskEntity task) async {
    AppLogger.action(_tag, 'Toggle task ${task.taskCode}');
    await _updateTask(() => _repository.toggleTask(task));
  }

  Future<void> addWater(DailyHealthTaskEntity task) async {
    AppLogger.action(_tag, 'Add water for ${task.taskCode}');
    await _updateTask(() => _repository.addProgress(task: task, amount: 250));
  }

  Future<void> addSteps(DailyHealthTaskEntity task) async {
    AppLogger.action(_tag, 'Add steps for ${task.taskCode}');
    await _updateTask(() => _repository.addProgress(task: task, amount: 500));
  }

  void dismissEncouragement() {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(current.copyWith(clearEncouragement: true));
  }

  Future<void> _updateTask(
    Future<DailyHealthTaskEntity> Function() action,
  ) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final updatedTask = await action();
      final tasks = current.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();
      final summary = DailyHealthSummaryEntity(
        userId: current.summary.userId,
        fullName: current.summary.fullName,
        taskDate: current.summary.taskDate,
        tasks: tasks,
      );
      HapticFeedback.lightImpact();
      AppLogger.summary(_tag, 'TASK_UPDATED', {
        'taskCode': updatedTask.taskCode,
        'completed': updatedTask.isCompleted,
        'score': summary.score,
      });
      return DailyHealthTrackingState(
        summary: summary,
        lastEncouragement: updatedTask.isCompleted
            ? updatedTask.encouragement
            : null,
      );
    });
  }
}

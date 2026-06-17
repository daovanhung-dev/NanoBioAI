import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../../domain/repositories/lifestyle_schedule_repository.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import 'lifestyle_schedule_state.dart';

class LifestyleScheduleController
    extends AsyncNotifier<LifestyleScheduleState> {
  late final LifestyleScheduleRepository _repository;

  @override
  Future<LifestyleScheduleState> build() async {
    _repository = ref.read(lifestyleScheduleRepositoryProvider);
    final summary = await _repository.getWeekSchedule();
    final selectedDate = _defaultSelectedDate(summary.availableDates);
    return LifestyleScheduleState(summary: summary, selectedDate: selectedDate);
  }

  Future<void> refresh() async {
    final current = state.whenOrNull(data: (value) => value);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final summary = await _repository.getWeekSchedule(
        anchorDate: current?.selectedDate,
      );
      final selectedDate = current?.selectedDate;
      return LifestyleScheduleState(
        summary: summary,
        selectedDate:
            selectedDate ?? _defaultSelectedDate(summary.availableDates),
      );
    });
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedDate: DateUtils.dateOnly(date)));
  }

  Future<void> toggleItem(LifestyleScheduleItemEntity item) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateItemCompletion(
        item: item,
        isCompleted: !item.isCompleted,
      );
      final items = current.summary.items
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList();
      HapticFeedback.lightImpact();
      return current.copyWith(
        summary: LifestyleScheduleSummaryEntity(
          userId: current.summary.userId,
          fullName: current.summary.fullName,
          items: items,
        ),
        lastEncouragement: updated.isCompleted ? updated.encouragement : null,
      );
    });
  }

  void dismissEncouragement() {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(current.copyWith(clearEncouragement: true));
  }

  DateTime _defaultSelectedDate(List<DateTime> availableDates) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (availableDates.any((date) => DateUtils.isSameDay(date, today))) {
      return today;
    }
    if (availableDates.isNotEmpty) return availableDates.first;
    return today;
  }
}

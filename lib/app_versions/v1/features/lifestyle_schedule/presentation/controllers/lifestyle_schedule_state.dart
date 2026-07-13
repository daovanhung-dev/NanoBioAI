import 'package:flutter/material.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/services/daily_schedule_score_service.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';

class LifestyleScheduleState {
  final LifestyleScheduleSummaryEntity summary;
  final DateTime selectedDate;
  final String? lastEncouragement;
  final String? lastErrorMessage;
  final String? focusedItemId;
  final List<ScheduleCompletionProofEntity> completionProofs;

  const LifestyleScheduleState({
    required this.summary,
    required this.selectedDate,
    this.lastEncouragement,
    this.lastErrorMessage,
    this.focusedItemId,
    this.completionProofs = const [],
  });

  List<DateTime> get availableDates => summary.availableDates;

  List<LifestyleScheduleItemEntity> get selectedItems {
    return summary.itemsForDate(selectedDate);
  }

  int get totalItems => selectedItems.length;

  int get completedItems =>
      selectedItems.where((item) => item.isCompleted).length;

  int get score {
    if (selectedItems.isEmpty) return 0;
    return DailyScheduleScoreService.calculate(
      items: selectedItems,
      scheduleDate: _dateKey(selectedDate),
      now: LifestyleScheduleWindowPolicy.vietnamNow(),
    ).score;
  }

  bool get isSelectedToday => DateUtils.isSameDay(
    selectedDate,
    DateUtils.dateOnly(LifestyleScheduleWindowPolicy.vietnamNow()),
  );

  LifestyleScheduleState copyWith({
    LifestyleScheduleSummaryEntity? summary,
    DateTime? selectedDate,
    String? lastEncouragement,
    String? lastErrorMessage,
    String? focusedItemId,
    List<ScheduleCompletionProofEntity>? completionProofs,
    bool clearEncouragement = false,
    bool clearError = false,
    bool clearFocus = false,
  }) {
    return LifestyleScheduleState(
      summary: summary ?? this.summary,
      selectedDate: selectedDate ?? this.selectedDate,
      lastEncouragement: clearEncouragement
          ? null
          : lastEncouragement ?? this.lastEncouragement,
      lastErrorMessage: clearError
          ? null
          : lastErrorMessage ?? this.lastErrorMessage,
      focusedItemId: clearFocus ? null : focusedItemId ?? this.focusedItemId,
      completionProofs: completionProofs ?? this.completionProofs,
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

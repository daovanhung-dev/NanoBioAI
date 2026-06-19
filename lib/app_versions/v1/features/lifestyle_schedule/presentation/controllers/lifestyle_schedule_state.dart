import 'package:flutter/material.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';

class LifestyleScheduleState {
  final LifestyleScheduleSummaryEntity summary;
  final DateTime selectedDate;
  final String? lastEncouragement;

  const LifestyleScheduleState({
    required this.summary,
    required this.selectedDate,
    this.lastEncouragement,
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
    return ((completedItems / selectedItems.length) * 100).round();
  }

  bool get isSelectedToday =>
      DateUtils.isSameDay(selectedDate, DateUtils.dateOnly(DateTime.now()));

  LifestyleScheduleState copyWith({
    LifestyleScheduleSummaryEntity? summary,
    DateTime? selectedDate,
    String? lastEncouragement,
    bool clearEncouragement = false,
  }) {
    return LifestyleScheduleState(
      summary: summary ?? this.summary,
      selectedDate: selectedDate ?? this.selectedDate,
      lastEncouragement: clearEncouragement
          ? null
          : lastEncouragement ?? this.lastEncouragement,
    );
  }
}

import '../entities/lifestyle_schedule_item_entity.dart';

class DailyScheduleScoreService {
  static const formulaVersion = 'daily_schedule_equal_v1_2026_07';
  static const wellnessProgramCode = 'wellness_schedule_v1';
  static const wellnessSourceType = 'lifestyle_schedule_item';

  const DailyScheduleScoreService._();

  static DailyScheduleScoreResult calculate({
    required List<LifestyleScheduleItemEntity> items,
    required String scheduleDate,
    required DateTime now,
  }) {
    final dueItems = items
        .where(
          (item) => _isDue(item: item, scheduleDate: scheduleDate, now: now),
        )
        .toList(growable: false);
    final completed = dueItems.where((item) => item.isCompleted).length;
    final score = dueItems.isEmpty
        ? 0
        : ((completed / dueItems.length) * 100).round().clamp(0, 100).toInt();

    return DailyScheduleScoreResult(
      score: score,
      completedDueItems: completed,
      dueItems: dueItems.length,
    );
  }

  static bool _isDue({
    required LifestyleScheduleItemEntity item,
    required String scheduleDate,
    required DateTime now,
  }) {
    final itemDate = DateTime.tryParse(item.scheduleDate);
    final fallbackDate = DateTime.tryParse(scheduleDate);
    final date = itemDate ?? fallbackDate;
    if (date == null) return false;

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(today)) return true;
    if (day.isAfter(today)) return false;

    final scheduled = item.scheduledAt;
    if (scheduled == null) return true;
    return !now.isBefore(scheduled);
  }
}

class DailyScheduleScoreResult {
  final int score;
  final int completedDueItems;
  final int dueItems;

  const DailyScheduleScoreResult({
    required this.score,
    required this.completedDueItems,
    required this.dueItems,
  });
}

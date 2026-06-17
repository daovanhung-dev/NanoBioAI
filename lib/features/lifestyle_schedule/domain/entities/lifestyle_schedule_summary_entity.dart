import 'lifestyle_schedule_item_entity.dart';

class LifestyleScheduleSummaryEntity {
  final String userId;
  final String fullName;
  final List<LifestyleScheduleItemEntity> items;

  const LifestyleScheduleSummaryEntity({
    required this.userId,
    required this.fullName,
    required this.items,
  });

  List<DateTime> get availableDates {
    final dates = <DateTime>{};
    for (final item in items) {
      final parsed = DateTime.tryParse(item.scheduleDate);
      if (parsed != null) dates.add(_dateOnly(parsed));
    }
    return dates.toList()..sort((a, b) => a.compareTo(b));
  }

  int get totalItems => items.length;

  int get completedItems => items.where((item) => item.isCompleted).length;

  int get score {
    if (items.isEmpty) return 0;
    return ((completedItems / items.length) * 100).round();
  }

  List<LifestyleScheduleItemEntity> itemsForDate(DateTime date) {
    return items.where((item) {
      final parsed = DateTime.tryParse(item.scheduleDate);
      return parsed != null && _isSameDay(parsed, date);
    }).toList()..sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.startTime.compareTo(b.startTime);
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';

/// Chọn projection nhiệm vụ của đúng ngày hiện tại từ lịch chăm sóc hiện hữu.
///
/// Service này không đọc database và không thay đổi danh sách đầu vào. Business
/// time được caller truyền vào từ [lifestyleScheduleClockProvider].
class TodayTaskSelector {
  const TodayTaskSelector();

  List<LifestyleScheduleItemEntity> select({
    required List<LifestyleScheduleItemEntity> items,
    required DateTime today,
  }) {
    final dateKey = _dateKey(today);
    final selected = items
        .where((item) => item.scheduleDate.trim() == dateKey)
        .toList(growable: false);

    selected.sort((a, b) {
      final timeCompare = a.startTime.compareTo(b.startTime);
      if (timeCompare != 0) return timeCompare;
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.id.compareTo(b.id);
    });
    return selected;
  }

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

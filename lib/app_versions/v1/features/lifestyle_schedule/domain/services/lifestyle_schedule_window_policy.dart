enum CompletionWindowStatus { waiting, open, locked, completed }

/// Quy tắc thời gian duy nhất cho các mốc trong lịch chăm sóc.
///
/// NanoBio lưu ngày/giờ lịch dưới dạng giờ tường tại Việt Nam. Việt Nam không
/// dùng DST, vì vậy đồng hồ mặc định được chuyển từ UTC sang UTC+7 trước khi
/// so sánh với dữ liệu lịch.
class LifestyleScheduleWindowPolicy {
  static const completionWindow = Duration(minutes: 30);
  static const _vietnamOffset = Duration(hours: 7);

  const LifestyleScheduleWindowPolicy._();

  static DateTime vietnamNow() {
    final shifted = DateTime.now().toUtc().add(_vietnamOffset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  /// Chuyển một instant UTC sang giờ tường Việt Nam. Giá trị local/không có
  /// timezone được xem là giờ Việt Nam để hỗ trợ dữ liệu và test hiện hữu.
  static DateTime toVietnamWallClock(DateTime value) {
    if (!value.isUtc) return value;
    final shifted = value.add(_vietnamOffset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  static DateTime? parseScheduledAt({
    required String scheduleDate,
    required String startTime,
  }) {
    final dateMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(scheduleDate.trim());
    final timeMatch = RegExp(
      r'^(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?$',
    ).firstMatch(startTime.trim());
    if (dateMatch == null || timeMatch == null) return null;

    final year = int.tryParse(dateMatch.group(1)!);
    final month = int.tryParse(dateMatch.group(2)!);
    final day = int.tryParse(dateMatch.group(3)!);
    final hour = int.tryParse(timeMatch.group(1)!);
    final minute = int.tryParse(timeMatch.group(2)!);
    final second = int.tryParse(timeMatch.group(3) ?? '0');
    final fraction = (timeMatch.group(4) ?? '').padRight(6, '0');
    final microseconds = int.tryParse(fraction.isEmpty ? '0' : fraction);
    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null ||
        second == null ||
        microseconds == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }

    final parsed = DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      microseconds ~/ Duration.microsecondsPerMillisecond,
      microseconds % Duration.microsecondsPerMillisecond,
    );
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static DateTime? completionDeadline({
    required String scheduleDate,
    required String startTime,
  }) {
    return parseScheduledAt(
      scheduleDate: scheduleDate,
      startTime: startTime,
    )?.add(completionWindow);
  }

  static CompletionWindowStatus statusAt({
    required String scheduleDate,
    required String startTime,
    required bool isCompleted,
    required DateTime now,
  }) {
    if (isCompleted) return CompletionWindowStatus.completed;
    final scheduled = parseScheduledAt(
      scheduleDate: scheduleDate,
      startTime: startTime,
    );
    if (scheduled == null) return CompletionWindowStatus.locked;

    final vietnamNow = toVietnamWallClock(now);
    if (vietnamNow.isBefore(scheduled)) {
      return CompletionWindowStatus.waiting;
    }
    if (vietnamNow.isAfter(scheduled.add(completionWindow))) {
      return CompletionWindowStatus.locked;
    }
    return CompletionWindowStatus.open;
  }

  static bool isWithinWindow({
    required String scheduleDate,
    required String startTime,
    required DateTime now,
  }) {
    final scheduled = parseScheduledAt(
      scheduleDate: scheduleDate,
      startTime: startTime,
    );
    if (scheduled == null) return false;
    final vietnamNow = toVietnamWallClock(now);
    final deadline = scheduled.add(completionWindow);
    return !vietnamNow.isBefore(scheduled) && !vietnamNow.isAfter(deadline);
  }
}

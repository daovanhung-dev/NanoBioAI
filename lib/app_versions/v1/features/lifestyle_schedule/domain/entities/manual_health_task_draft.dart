import 'schedule_health_action_type.dart';

class ManualHealthTaskRepeat {
  static const once = 'once';
  static const daily = 'daily';
  static const weekdays = 'weekdays';
  static const weekends = 'weekends';

  static const values = <String>[once, daily, weekdays, weekends];
}

class ManualHealthTaskMetadata {
  static const prefix = 'manual_health';

  final String seriesId;
  final ScheduleHealthActionType actionType;
  final bool reminderEnabled;
  final String repeat;

  const ManualHealthTaskMetadata({
    required this.seriesId,
    required this.actionType,
    required this.reminderEnabled,
    this.repeat = ManualHealthTaskRepeat.once,
  });

  String encode() =>
      '$prefix|$seriesId|${actionType.stableCode}|${reminderEnabled ? '1' : '0'}|$repeat';

  static ManualHealthTaskMetadata? tryParse(String? sourceId) {
    final parts = sourceId?.trim().split('|') ?? const <String>[];
    if ((parts.length != 4 && parts.length != 5) || parts.first != prefix) {
      return null;
    }
    final action = ScheduleHealthActionTypeX.fromStableCode(parts[2]);
    if (action == null || parts[1].trim().isEmpty) return null;
    final repeat = parts.length == 5 && ManualHealthTaskRepeat.values.contains(parts[4])
        ? parts[4]
        : ManualHealthTaskRepeat.once;
    return ManualHealthTaskMetadata(
      seriesId: parts[1].trim(),
      actionType: action,
      reminderEnabled: parts[3] == '1',
      repeat: repeat,
    );
  }
}

class ManualHealthTaskDraft {
  final DateTime firstDate;
  final String startTime;
  final String title;
  final String description;
  final String category;
  final ScheduleHealthActionType actionType;
  final String repeat;
  final bool reminderEnabled;

  const ManualHealthTaskDraft({
    required this.firstDate,
    required this.startTime,
    required this.title,
    this.description = '',
    required this.category,
    required this.actionType,
    this.repeat = ManualHealthTaskRepeat.once,
    this.reminderEnabled = true,
  });

  List<String> validate() {
    final errors = <String>[];
    if (title.trim().length < 2) {
      errors.add('Tên nhiệm vụ cần ít nhất 2 ký tự.');
    }
    if (title.trim().length > 120) {
      errors.add('Tên nhiệm vụ tối đa 120 ký tự.');
    }
    if (description.trim().length > 500) {
      errors.add('Mô tả nhiệm vụ tối đa 500 ký tự.');
    }
    if (!_isValidTime(startTime)) {
      errors.add('Giờ thực hiện chưa hợp lệ.');
    }
    if (category.trim().isEmpty) {
      errors.add('Bạn cần chọn một nhóm chăm sóc.');
    }
    if (!ManualHealthTaskRepeat.values.contains(repeat)) {
      errors.add('Kiểu lặp lại chưa hợp lệ.');
    }
    if (actionType == ScheduleHealthActionType.photoProof) {
      errors.add('Nhiệm vụ tự tạo không dùng ảnh minh chứng bắt buộc.');
    }
    return errors;
  }

  List<DateTime> occurrenceDates({int horizonDays = 7}) {
    final first = DateTime(firstDate.year, firstDate.month, firstDate.day);
    if (repeat == ManualHealthTaskRepeat.once) return [first];

    final result = <DateTime>[];
    for (var offset = 0; offset < horizonDays; offset++) {
      final date = first.add(Duration(days: offset));
      final isWeekend = date.weekday >= DateTime.saturday;
      final include = switch (repeat) {
        ManualHealthTaskRepeat.daily => true,
        ManualHealthTaskRepeat.weekdays => !isWeekend,
        ManualHealthTaskRepeat.weekends => isWeekend,
        _ => offset == 0,
      };
      if (include) result.add(date);
    }
    return result;
  }

  static bool _isValidTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return false;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    return hour != null && minute != null && hour <= 23 && minute <= 59;
  }
}

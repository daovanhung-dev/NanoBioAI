class RoutineTimeRange {
  final String start;
  final String end;

  const RoutineTimeRange({required this.start, required this.end});

  Map<String, Object?> toJson() => {'start': start, 'end': end};

  factory RoutineTimeRange.fromJson(Map<String, Object?> json) {
    return RoutineTimeRange(
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
    );
  }

  RoutineTimeRange copyWith({String? start, String? end}) {
    return RoutineTimeRange(start: start ?? this.start, end: end ?? this.end);
  }
}

class RoutineDayTemplate {
  final String wakeTime;
  final String sleepTime;
  final List<String> mealTimes;
  final bool napEnabled;
  final RoutineTimeRange? napRange;
  final List<RoutineTimeRange> workoutRanges;
  final RoutineTimeRange? busyRange;

  const RoutineDayTemplate({
    required this.wakeTime,
    required this.sleepTime,
    required this.mealTimes,
    required this.napEnabled,
    required this.napRange,
    required this.workoutRanges,
    required this.busyRange,
  });

  Map<String, Object?> toJson() => {
    'wake_time': wakeTime,
    'sleep_time': sleepTime,
    'meal_times': mealTimes,
    'nap_enabled': napEnabled,
    'nap_range': napRange?.toJson(),
    'workout_ranges': workoutRanges.map((item) => item.toJson()).toList(),
    'busy_range': busyRange?.toJson(),
  };

  factory RoutineDayTemplate.fromJson(Map<String, Object?> json) {
    return RoutineDayTemplate(
      wakeTime: json['wake_time']?.toString() ?? '',
      sleepTime: json['sleep_time']?.toString() ?? '',
      mealTimes: _stringList(json['meal_times']),
      napEnabled: json['nap_enabled'] == true,
      napRange: _rangeOrNull(json['nap_range']),
      workoutRanges: _rangeList(json['workout_ranges']),
      busyRange: _rangeOrNull(json['busy_range']),
    );
  }

  RoutineDayTemplate copyWith({
    String? wakeTime,
    String? sleepTime,
    List<String>? mealTimes,
    bool? napEnabled,
    RoutineTimeRange? napRange,
    bool clearNapRange = false,
    List<RoutineTimeRange>? workoutRanges,
    RoutineTimeRange? busyRange,
    bool clearBusyRange = false,
  }) {
    return RoutineDayTemplate(
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      mealTimes: mealTimes ?? this.mealTimes,
      napEnabled: napEnabled ?? this.napEnabled,
      napRange: clearNapRange ? null : napRange ?? this.napRange,
      workoutRanges: workoutRanges ?? this.workoutRanges,
      busyRange: clearBusyRange ? null : busyRange ?? this.busyRange,
    );
  }
}

class DailyRoutinePreferences {
  static const questionCode = 'daily_routine_v1';
  static const schemaVersion = 1;

  final int version;
  final RoutineDayTemplate weekday;
  final RoutineDayTemplate weekend;

  static const defaultValue = DailyRoutinePreferences(
    weekday: RoutineDayTemplate(
      wakeTime: '06:30',
      sleepTime: '22:30',
      mealTimes: ['07:00', '09:30', '12:00', '15:30', '18:30'],
      napEnabled: true,
      napRange: RoutineTimeRange(start: '12:45', end: '13:15'),
      workoutRanges: [
        RoutineTimeRange(start: '07:45', end: '08:15'),
        RoutineTimeRange(start: '17:30', end: '18:00'),
      ],
      busyRange: RoutineTimeRange(start: '08:30', end: '11:30'),
    ),
    weekend: RoutineDayTemplate(
      wakeTime: '07:30',
      sleepTime: '23:00',
      mealTimes: ['08:00', '10:30', '12:30', '16:00', '19:00'],
      napEnabled: true,
      napRange: RoutineTimeRange(start: '13:15', end: '13:45'),
      workoutRanges: [
        RoutineTimeRange(start: '09:00', end: '09:30'),
        RoutineTimeRange(start: '17:30', end: '18:00'),
      ],
      busyRange: null,
    ),
  );

  const DailyRoutinePreferences({
    this.version = schemaVersion,
    required this.weekday,
    required this.weekend,
  });

  factory DailyRoutinePreferences.defaults() {
    return defaultValue;
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'weekday': weekday.toJson(),
    'weekend': weekend.toJson(),
  };

  factory DailyRoutinePreferences.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version != schemaVersion) {
      throw const FormatException('Unsupported daily routine version');
    }
    final weekday = json['weekday'];
    final weekend = json['weekend'];
    if (weekday is! Map || weekend is! Map) {
      throw const FormatException('Missing daily routine templates');
    }
    return DailyRoutinePreferences(
      version: schemaVersion,
      weekday: RoutineDayTemplate.fromJson(Map<String, Object?>.from(weekday)),
      weekend: RoutineDayTemplate.fromJson(Map<String, Object?>.from(weekend)),
    );
  }

  RoutineDayTemplate templateFor(DateTime date) {
    return date.weekday >= DateTime.saturday ? weekend : weekday;
  }

  DailyRoutinePreferences copyWith({
    RoutineDayTemplate? weekday,
    RoutineDayTemplate? weekend,
  }) {
    return DailyRoutinePreferences(
      version: version,
      weekday: weekday ?? this.weekday,
      weekend: weekend ?? this.weekend,
    );
  }

  List<String> validate() {
    return [
      ..._validateTemplate(weekday, 'Ngày thường'),
      ..._validateTemplate(weekend, 'Cuối tuần'),
    ];
  }
}

List<String> _validateTemplate(RoutineDayTemplate template, String label) {
  final errors = <String>[];
  final wake = _minuteOfDay(template.wakeTime);
  final sleep = _minuteOfDay(template.sleepTime);
  if (wake == null || sleep == null) {
    return ['$label: giờ thức dậy hoặc giờ ngủ chưa hợp lệ.'];
  }
  final awakeEnd = sleep <= wake ? sleep + 1440 : sleep;

  int? awakeMinute(String value) {
    final minute = _minuteOfDay(value);
    if (minute == null) return null;
    return minute < wake ? minute + 1440 : minute;
  }

  if (template.mealTimes.length != 5) {
    errors.add('$label: cần đủ 5 giờ ăn.');
  } else {
    var previous = -1;
    for (final time in template.mealTimes) {
      final minute = awakeMinute(time);
      if (minute == null || minute < wake || minute > awakeEnd) {
        errors.add('$label: giờ ăn phải nằm trong thời gian thức.');
        break;
      }
      if (minute <= previous) {
        errors.add('$label: 5 bữa cần theo đúng thứ tự trong ngày.');
        break;
      }
      previous = minute;
    }
  }

  final workouts = template.workoutRanges;
  if (workouts.length != 2) {
    errors.add('$label: cần đủ 2 khung tập luyện.');
    return errors;
  }

  List<int>? normalizedRange(RoutineTimeRange? range) {
    if (range == null) return null;
    final start = awakeMinute(range.start);
    final endRaw = _minuteOfDay(range.end);
    if (start == null || endRaw == null) return null;
    var end = endRaw < wake ? endRaw + 1440 : endRaw;
    if (end <= start) end += 1440;
    if (start < wake || end > awakeEnd || end <= start) return null;
    return [start, end];
  }

  final workoutValues = workouts.map(normalizedRange).toList();
  if (workoutValues.any((value) => value == null)) {
    errors.add('$label: khung tập phải nằm trọn trong thời gian thức.');
    return errors;
  }
  if (_overlaps(workoutValues[0]!, workoutValues[1]!)) {
    errors.add('$label: hai khung tập không được chồng nhau.');
  }

  final nap = template.napEnabled ? normalizedRange(template.napRange) : null;
  if (template.napEnabled && nap == null) {
    errors.add('$label: khung ngủ trưa chưa hợp lệ.');
  }
  final busy = template.busyRange == null
      ? null
      : normalizedRange(template.busyRange);
  if (template.busyRange != null && busy == null) {
    errors.add('$label: khoảng bận chưa hợp lệ.');
  }
  for (final workout in workoutValues.whereType<List<int>>()) {
    if (nap != null && _overlaps(workout, nap)) {
      errors.add('$label: khung tập không được chồng giấc trưa.');
    }
    if (busy != null && _overlaps(workout, busy)) {
      errors.add('$label: khung tập không được chồng khoảng bận.');
    }
  }
  return errors.toSet().toList();
}

bool _overlaps(List<int> left, List<int> right) {
  return left[0] < right[1] && right[0] < left[1];
}

int? _minuteOfDay(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

RoutineTimeRange? _rangeOrNull(Object? value) {
  if (value is! Map) return null;
  return RoutineTimeRange.fromJson(Map<String, Object?>.from(value));
}

List<RoutineTimeRange> _rangeList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => RoutineTimeRange.fromJson(Map<String, Object?>.from(item)))
      .toList(growable: false);
}

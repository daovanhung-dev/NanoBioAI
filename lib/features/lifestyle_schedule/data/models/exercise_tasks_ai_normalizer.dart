import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';

import 'exercise_task_model.dart';

class ExerciseTasksAiNormalizer {
  static const exercisesPerDay = 2;

  const ExerciseTasksAiNormalizer();

  List<ExerciseTaskModel> normalize({
    required List<dynamic> items,
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
    final expectedCount = days * exercisesPerDay;
    if (items.length != expectedCount) {
      throw FormatException(
        'Exercise AI response must contain exactly $expectedCount tasks',
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Exercise AI task must be an object');
      }

      final map = Map<String, dynamic>.from(item);
      final date = _dateKeyFromText(_readString(map['schedule_date']));
      if (date == null) {
        throw const FormatException('Invalid exercise schedule_date');
      }
      grouped.putIfAbsent(date, () => <Map<String, dynamic>>[]).add(map);
    }

    final result = <ExerciseTaskModel>[];
    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final dayItems = grouped[date];
      if (dayItems == null || dayItems.length != exercisesPerDay) {
        throw FormatException('Expected $exercisesPerDay exercises for $date');
      }

      dayItems.sort((a, b) {
        return _readTime(a['start_time']).compareTo(_readTime(b['start_time']));
      });

      for (var index = 0; index < dayItems.length; index++) {
        final map = dayItems[index];
        final startTime = _readTime(map['start_time']);
        final endTime = _readTime(map['end_time']);
        if (endTime.compareTo(startTime) < 0) {
          throw FormatException(
            'Exercise end_time before start_time for $date',
          );
        }

        result.add(
          ExerciseTaskModel(
            id: 'exercise_${profile.userId}_${date}_${index + 1}',
            userId: profile.userId,
            scheduleDate: date,
            startTime: startTime,
            endTime: endTime,
            title: _readString(map['title'], fallback: 'Van dong co the'),
            description: _readString(map['description']),
            targetValue: _readPositiveDouble(map['target_value']),
            unit: _readString(map['unit'], fallback: 'lan'),
            encouragement: _readString(map['encouragement']),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
      }
    }

    return result;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _readTime(Object? value) {
    final text = _readString(value);
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      throw FormatException('Invalid exercise time: $text');
    }
    final hour = int.parse(text.substring(0, 2));
    final minute = int.parse(text.substring(3, 5));
    if (hour > 23 || minute > 59) {
      throw FormatException('Invalid exercise time: $text');
    }
    return text;
  }

  static double _readPositiveDouble(Object? value) {
    final parsed = switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim()) ?? 1,
      _ => 1.0,
    };
    return parsed > 0 ? parsed : 1;
  }

  static String? _dateKeyFromText(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    return _dateKey(parsed);
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

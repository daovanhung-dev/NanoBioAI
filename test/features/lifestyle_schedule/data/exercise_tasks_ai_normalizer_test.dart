import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';

void main() {
  const profile = DailyHealthProfileEntity(
    userId: 'u1',
    fullName: 'Test User',
    goals: ['sleep_better'],
    conditions: [],
    habits: [],
    sleepQuality: 'Good',
    activityLevel: 'Light',
    waterPerDay: '1.5-2L',
  );

  test('normalizes seven days into two exercise tasks per day', () {
    final startDate = DateTime(2026, 6, 17);

    final exercises = const ExerciseTasksAiNormalizer().normalize(
      items: _items(startDate),
      profile: profile,
      startDate: startDate,
      createdAt: '2026-06-16T08:00:00',
    );

    expect(exercises, hasLength(14));
    expect(exercises.first.id, 'exercise_u1_2026-06-17_1');
    expect(exercises.first.scheduleDate, '2026-06-17');
    expect(exercises.first.startTime, '08:00');
    expect(exercises.first.endTime, '08:25');
  });

  test('throws when a day does not have exactly two exercises', () {
    final startDate = DateTime(2026, 6, 17);
    final items = _items(startDate)
      ..removeWhere(
        (item) =>
            item['schedule_date'] == '2026-06-17' &&
            item['start_time'] == '17:30',
      );

    expect(
      () => const ExerciseTasksAiNormalizer().normalize(
        items: items,
        profile: profile,
        startDate: startDate,
        createdAt: '2026-06-16T08:00:00',
      ),
      throwsFormatException,
    );
  });
}

List<Map<String, Object>> _items(DateTime startDate) {
  return [
    for (var day = 0; day < 7; day++) ...[
      {
        'schedule_date': _dateKey(startDate.add(Duration(days: day))),
        'start_time': '08:00',
        'end_time': '08:25',
        'title': 'Walk',
        'description': 'Walk around the house',
        'target_value': 1,
        'unit': 'lan',
        'encouragement': 'Good',
      },
      {
        'schedule_date': _dateKey(startDate.add(Duration(days: day))),
        'start_time': '17:30',
        'end_time': '18:00',
        'title': 'Mobility',
        'description': 'Gentle mobility',
        'target_value': 1,
        'unit': 'lan',
        'encouragement': 'Nice',
      },
    ],
  ];
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

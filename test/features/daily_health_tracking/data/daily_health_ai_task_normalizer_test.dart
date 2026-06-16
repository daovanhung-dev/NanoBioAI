import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_ai_task_normalizer.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';

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

  test('normalizes seven days into stable AI tasks', () {
    final startDate = DateTime(2026, 6, 17);
    final items = _items(startDate);

    final tasks = const DailyHealthAiTaskNormalizer().normalize(
      items: items,
      profile: profile,
      startDate: startDate,
      createdAt: '2026-06-16T08:00:00',
    );

    expect(tasks, hasLength(28));
    expect(tasks.first.id, 'daily_u1_2026-06-17_ai_water');
    expect(tasks.first.taskCode, 'ai_water');
    expect(tasks.first.source, 'ai');
    expect(tasks.first.currentValue, 0);
    expect(tasks.first.isCompleted, isFalse);
    expect(
      tasks
          .where((task) => task.taskDate == '2026-06-17')
          .map((task) => task.category)
          .toSet(),
      {'water', 'body', 'mind', 'brain'},
    );
  });

  test('throws when a day is missing a required category', () {
    final startDate = DateTime(2026, 6, 17);
    final items = _items(startDate)
      ..removeWhere(
        (item) =>
            item['task_date'] == '2026-06-17' && item['category'] == 'brain',
      );

    expect(
      () => const DailyHealthAiTaskNormalizer().normalize(
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
  const categories = DailyHealthAiTaskNormalizer.categories;
  return [
    for (var day = 0; day < 7; day++)
      for (final category in categories)
        {
          'task_date': _dateKey(startDate.add(Duration(days: day))),
          'task_code': 'suggested_$category',
          'category': category,
          'title': '$category task',
          'description': '$category description',
          'target_value': category == 'water' ? 2000 : 1,
          'unit': category == 'water' ? 'ml' : 'lan',
          'encouragement': 'Good',
        },
  ];
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

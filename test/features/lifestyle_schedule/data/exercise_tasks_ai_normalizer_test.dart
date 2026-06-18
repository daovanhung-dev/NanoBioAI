import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';

void main() {
  const catalog = AiCatalogBundle(
    meals: AiCatalogSeedData.meals,
    exercises: AiCatalogSeedData.exercises,
    scheduleTasks: AiCatalogSeedData.scheduleTasks,
  );
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
      items: _items(),
      catalog: catalog,
      profile: profile,
      startDate: startDate,
      createdAt: '2026-06-16T08:00:00',
    );

    expect(exercises, hasLength(14));
    expect(exercises.first.id, 'exercise_u1_2026-06-17_1');
    expect(exercises.first.scheduleDate, '2026-06-17');
    expect(exercises.first.startTime, '08:00');
    expect(exercises.first.endTime, '08:25');
    expect(exercises.first.title, 'Đi bộ thư giãn');
    expect(exercises.first.unit, 'lần');
    expect(exercises.first.encouragement, contains('Bạn'));
  });

  test('throws when a day does not have exactly two exercises', () {
    final startDate = DateTime(2026, 6, 17);
    final items = _items()
      ..removeWhere((item) => item['day'] == 1 && item['priority'] == 2);

    expect(
      () => const ExerciseTasksAiNormalizer().normalize(
        items: items,
        catalog: catalog,
        profile: profile,
        startDate: startDate,
        createdAt: '2026-06-16T08:00:00',
      ),
      throwsFormatException,
    );
  });

  test('throws when AI returns display text fields or unknown codes', () {
    final withTitle = _items();
    withTitle.first['title'] = 'Walk';

    expect(
      () => const ExerciseTasksAiNormalizer().validateCodeItems(
        items: withTitle.take(4).toList(),
        catalog: catalog,
        startDay: 1,
        days: 2,
        usedCodeCounts: const {},
      ),
      throwsFormatException,
    );

    final withUnknownCode = _items();
    withUnknownCode.first['exercise_code'] = 'unknown_exercise';

    expect(
      () => const ExerciseTasksAiNormalizer().validateCodeItems(
        items: withUnknownCode.take(4).toList(),
        catalog: catalog,
        startDay: 1,
        days: 2,
        usedCodeCounts: const {},
      ),
      throwsFormatException,
    );
  });

  test('fallback creates a complete valid exercise chunk', () {
    final fallback = const ExerciseTasksAiNormalizer().fallbackCodeItems(
      catalog: catalog,
      startDay: 5,
      days: 3,
      usedCodeCounts: const {'ex_walk_relaxed': 1},
    );

    final valid = const ExerciseTasksAiNormalizer().validateCodeItems(
      items: fallback,
      catalog: catalog,
      startDay: 5,
      days: 3,
      usedCodeCounts: const {},
    );

    expect(valid, hasLength(6));
    expect(valid.map((item) => item['day']).toSet(), {5, 6, 7});
  });
}

List<Map<String, Object?>> _items() {
  return [
    for (var day = 1; day <= 7; day++) ...[
      {
        'day': day,
        'exercise_code': AiCatalogSeedData.exercises[(day - 1) * 2].code,
        'start_time': '08:00',
        'end_time': '08:25',
        'intensity': 'light',
        'target_value': 1,
        'priority': 1,
      },
      {
        'day': day,
        'exercise_code': AiCatalogSeedData.exercises[((day - 1) * 2) + 1].code,
        'start_time': '17:30',
        'end_time': '18:00',
        'intensity': 'moderate',
        'target_value': 1,
        'priority': 2,
      },
    ],
  ];
}

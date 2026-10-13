import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';

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
      ..removeWhere(
        (item) =>
            item['day'] == 1 &&
            item['exercise_code'] == AiCatalogSeedData.exercises[1].code,
      );

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

  test('rejects an inactive context-only exercise code', () {
    final inactiveCatalog = AiCatalogBundle(
      meals: catalog.meals,
      exercises: [
        ExerciseCatalogItemModel(
          code: 'ex_draft_context_only',
          category: 'cardio',
          title: 'Bài đang chờ rà soát',
          description: '',
          unit: 'minutes',
          encouragement: '',
          minTarget: 1,
          maxTarget: 10,
          defaultTarget: 5,
          intensityLevel: 'light',
          isActive: false,
          createdAt: '2026-06-16T08:00:00',
          updatedAt: '2026-06-16T08:00:00',
        ),
      ],
      scheduleTasks: catalog.scheduleTasks,
    );

    expect(
      () => const ExerciseTasksAiNormalizer().validateCodeItems(
        items: [
          for (var day = 1; day <= 2; day++)
            for (var index = 0; index < 2; index++)
              {'day': day, 'exercise_code': 'ex_draft_context_only'},
        ],
        catalog: inactiveCatalog,
        startDay: 1,
        days: 2,
        usedCodeCounts: const {},
      ),
      throwsFormatException,
    );
  });
}

List<Map<String, Object?>> _items() {
  return [
    for (var day = 1; day <= 7; day++) ...[
      {
        'day': day,
        'exercise_code': AiCatalogSeedData.exercises[(day - 1) * 2].code,
      },
      {
        'day': day,
        'exercise_code': AiCatalogSeedData.exercises[((day - 1) * 2) + 1].code,
      },
    ],
  ];
}

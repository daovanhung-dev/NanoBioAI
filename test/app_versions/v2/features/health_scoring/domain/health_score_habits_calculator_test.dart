import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';

void main() {
  group('HealthScoreHabitsCalculator', () {
    test('returns empty result when no inputs exist', () {
      final result = HealthScoreHabitsCalculator.calculate(
        _snapshot(entries: const [], logs: const []),
      );

      expect(result.hasInputs, isFalse);
      expect(result.score, 0);
      expect(result.breakdown, isEmpty);
      expect(result.habitProgress, isEmpty);
    });

    test('calculates local draft weighted score and formula version', () {
      final result = HealthScoreHabitsCalculator.calculate(
        _snapshot(
          entries: const [
            HealthScoreCompletionEntry(
              id: 'task-1',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'water',
              title: 'Drink water',
              isCompleted: true,
              isDue: true,
            ),
            HealthScoreCompletionEntry(
              id: 'task-2',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'body',
              title: 'Walk',
              isCompleted: false,
              isDue: true,
            ),
            HealthScoreCompletionEntry(
              id: 'meal-1',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.meals,
              category: 'meal',
              title: 'Breakfast',
              isCompleted: true,
              isDue: true,
            ),
          ],
          logs: const [
            HealthScoreDailyLogEntry(
              date: '2026-06-29',
              waterMl: 1000,
              sleepHours: 4,
            ),
          ],
        ),
      );

      expect(result.hasInputs, isTrue);
      expect(result.formulaVersion, healthScoreHabitsLocalDraftFormulaVersion);
      expect(result.score, 63);
      expect(result.breakdown.map((item) => item.code), [
        'tasks_habits',
        'meals',
        'water',
        'sleep',
      ]);
      expect(
        result.breakdown
            .firstWhere((item) => item.code == 'tasks_habits')
            .score,
        50,
      );
    });

    test('excludes not-due entries from denominator', () {
      final result = HealthScoreHabitsCalculator.calculate(
        _snapshot(
          entries: const [
            HealthScoreCompletionEntry(
              id: 'due',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'water',
              title: 'Due task',
              isCompleted: true,
              isDue: true,
            ),
            HealthScoreCompletionEntry(
              id: 'future',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'water',
              title: 'Future task',
              isCompleted: false,
              isDue: false,
            ),
          ],
          logs: const [],
        ),
      );

      expect(result.score, 100);
      expect(result.breakdown.single.totalCount, 1);
      expect(result.habitProgress.single.dueCount, 1);
    });

    test('aggregates habit progress by category', () {
      final result = HealthScoreHabitsCalculator.calculate(
        _snapshot(
          entries: const [
            HealthScoreCompletionEntry(
              id: 'water-1',
              date: '2026-06-29',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'water',
              title: 'Water',
              isCompleted: true,
              isDue: true,
            ),
            HealthScoreCompletionEntry(
              id: 'water-2',
              date: '2026-06-28',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'water',
              title: 'Water',
              isCompleted: false,
              isDue: true,
            ),
            HealthScoreCompletionEntry(
              id: 'sleep-1',
              date: '2026-06-28',
              group: HealthScoreCompletionGroup.tasksHabits,
              category: 'sleep',
              title: 'Sleep',
              isCompleted: true,
              isDue: true,
            ),
          ],
          logs: const [],
        ),
      );

      final water = result.habitProgress.firstWhere(
        (item) => item.code == 'water',
      );
      expect(water.completedCount, 1);
      expect(water.dueCount, 2);
      expect(water.progress, 0.5);
    });
  });
}

HealthScoreInputSnapshot _snapshot({
  required List<HealthScoreCompletionEntry> entries,
  required List<HealthScoreDailyLogEntry> logs,
}) {
  return HealthScoreInputSnapshot(
    userId: 'u1',
    period: const HealthScorePeriod(
      startDate: '2026-06-23',
      endDate: '2026-06-29',
    ),
    now: DateTime.parse('2026-06-29T12:00:00'),
    completionEntries: entries,
    dailyLogs: logs,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';

void main() {
  group('HealthScoreHabits subject access', () {
    test('FamilyPlus actor can calculate another subject score', () async {
      final repository = _CapturingHealthScoreHabitsRepository();
      final fn = HealthScoreHabitsFn01(repository: repository);

      await fn.execute(
        CalculateHealthScoreCommand(
          actorId: 'actor-1',
          subjectId: 'member-1',
          isFamilyPlus: true,
          now: DateTime.parse('2026-06-29T12:00:00'),
        ),
      );

      expect(repository.loadedUserId, 'member-1');
    });

    test('non-FamilyPlus actor cannot calculate another subject score', () {
      final fn = HealthScoreHabitsFn01(
        repository: _CapturingHealthScoreHabitsRepository(),
      );

      expect(
        fn.execute(
          CalculateHealthScoreCommand(
            actorId: 'actor-1',
            subjectId: 'member-1',
            now: DateTime.parse('2026-06-29T12:00:00'),
          ),
        ),
        throwsA(
          isA<HealthScoreHabitsException>().having(
            (error) => error.code,
            'code',
            'FORBIDDEN',
          ),
        ),
      );
    });
  });
}

class _CapturingHealthScoreHabitsRepository
    implements HealthScoreHabitsRepository {
  String? loadedUserId;

  @override
  Future<HealthScoreInputSnapshot> loadInputs({
    required String userId,
    required HealthScorePeriod period,
    required DateTime now,
  }) async {
    loadedUserId = userId;
    return HealthScoreInputSnapshot(
      userId: userId,
      period: period,
      now: now,
      completionEntries: const [
        HealthScoreCompletionEntry(
          id: 'task-1',
          date: '2026-06-29',
          group: HealthScoreCompletionGroup.tasksHabits,
          category: 'water',
          title: 'Water',
          isCompleted: true,
          isDue: true,
        ),
      ],
      dailyLogs: const [],
    );
  }
}

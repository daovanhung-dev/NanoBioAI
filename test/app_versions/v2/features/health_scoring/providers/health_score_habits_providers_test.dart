import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';

void main() {
  test(
    'summary provider returns auth-required state without user id',
    () async {
      final container = ProviderContainer(
        overrides: [
          healthScoreHabitsCurrentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        healthScoreHabitsSummaryProvider.future,
      );

      expect(result.status, HealthScoreHabitsViewStatus.authRequired);
    },
  );

  test(
    'summary provider returns ready state with local draft result',
    () async {
      final container = ProviderContainer(
        overrides: [
          healthScoreHabitsCurrentUserIdProvider.overrideWithValue('u1'),
          healthScoreHabitsNowProvider.overrideWithValue(
            () => DateTime.parse('2026-06-29T12:00:00'),
          ),
          healthScoreHabitsRepositoryProvider.overrideWithValue(
            _FakeHealthScoreHabitsRepository(
              entries: const [
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
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        healthScoreHabitsSummaryProvider.future,
      );

      expect(viewModel.status, HealthScoreHabitsViewStatus.ready);
      expect(viewModel.result?.score, 100);
      expect(viewModel.result?.habitProgress.single.code, 'water');
    },
  );
}

class _FakeHealthScoreHabitsRepository implements HealthScoreHabitsRepository {
  final List<HealthScoreCompletionEntry> entries;

  const _FakeHealthScoreHabitsRepository({this.entries = const []});

  @override
  Future<HealthScoreInputSnapshot> loadInputs({
    required String userId,
    required HealthScorePeriod period,
    required DateTime now,
  }) async {
    return HealthScoreInputSnapshot(
      userId: userId,
      period: period,
      now: now,
      completionEntries: entries,
      dailyLogs: const [],
    );
  }
}

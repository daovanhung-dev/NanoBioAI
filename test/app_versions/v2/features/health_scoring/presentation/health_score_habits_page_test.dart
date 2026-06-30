import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';

void main() {
  testWidgets('renders auth-required state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthScoreHabitsCurrentUserIdProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: HealthScoreHabitsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Can dang nhap'), findsOneWidget);
  });

  testWidgets('renders empty state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthScoreHabitsCurrentUserIdProvider.overrideWithValue('u1'),
          healthScoreHabitsNowProvider.overrideWithValue(
            () => DateTime.parse('2026-06-29T12:00:00'),
          ),
          healthScoreHabitsRepositoryProvider.overrideWithValue(
            const _FakeHealthScoreHabitsRepository(),
          ),
        ],
        child: const MaterialApp(home: HealthScoreHabitsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chua co lich su cham soc'), findsOneWidget);
  });

  testWidgets('renders success state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthScoreHabitsCurrentUserIdProvider.overrideWithValue('u1'),
          healthScoreHabitsNowProvider.overrideWithValue(
            () => DateTime.parse('2026-06-29T12:00:00'),
          ),
          healthScoreHabitsRepositoryProvider.overrideWithValue(
            const _FakeHealthScoreHabitsRepository(
              entries: [
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
        child: const MaterialApp(home: HealthScoreHabitsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100'), findsWidgets);
    expect(find.text('Thanh phan diem'), findsOneWidget);
    expect(find.text('Tien do thoi quen'), findsOneWidget);
  });
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

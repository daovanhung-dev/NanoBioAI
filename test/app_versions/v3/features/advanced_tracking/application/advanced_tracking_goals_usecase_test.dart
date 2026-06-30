import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/advanced_tracking/advanced_tracking.dart';

void main() {
  final paidActor = const AdvancedTrackingActorContext(
    actorId: 'u1',
    hasPaidAccess: true,
  );

  test('createAdvancedGoal stores hydration goal once per subject', () async {
    final repository = _FakeAdvancedTrackingRepository();
    final fn01 = AdvancedTrackingGoalsFn01(repository: repository);
    final now = DateTime.parse('2026-06-30T08:00:00');

    final first = await fn01.execute(
      CreateAdvancedGoalCommand(actor: paidActor, now: now),
    );
    final second = await fn01.execute(
      CreateAdvancedGoalCommand(actor: paidActor, now: now),
    );

    expect(first.id, second.id);
    expect(first.goalCode, advancedTrackingHydrationGoalCode);
    expect(repository.createCalls, 1);
  });

  test('createAdvancedGoal blocks free actor before storage write', () async {
    final repository = _FakeAdvancedTrackingRepository();
    final fn01 = AdvancedTrackingGoalsFn01(repository: repository);

    await expectLater(
      fn01.execute(
        const CreateAdvancedGoalCommand(
          actor: AdvancedTrackingActorContext(
            actorId: 'u1',
            hasPaidAccess: false,
          ),
        ),
      ),
      throwsA(isA<AdvancedTrackingException>()),
    );
    expect(repository.createCalls, 0);
  });

  test(
    'loadGoalRoadmap computes hydration progress by subject and period',
    () async {
      final repository = _FakeAdvancedTrackingRepository();
      final fn01 = AdvancedTrackingGoalsFn01(repository: repository);
      final fn02 = AdvancedTrackingGoalsFn02(repository: repository);
      final now = DateTime.parse('2026-06-30T08:00:00');
      const period = AdvancedTrackingPeriod(
        startDate: '2026-06-28',
        endDate: '2026-06-30',
      );
      repository.logsBySubject['u1'] = const [
        AdvancedTrackingHydrationLog(date: '2026-06-28', waterMl: 2100),
        AdvancedTrackingHydrationLog(date: '2026-06-29', waterMl: 1500),
        AdvancedTrackingHydrationLog(date: '2026-06-30', waterMl: 2200),
      ];
      repository.logsBySubject['u2'] = const [
        AdvancedTrackingHydrationLog(date: '2026-06-30', waterMl: 500),
      ];

      await fn01.execute(CreateAdvancedGoalCommand(actor: paidActor, now: now));
      final result = await fn02.execute(
        LoadGoalRoadmapCommand(actor: paidActor, period: period),
      );

      expect(result.hasGoal, isTrue);
      expect(result.steps, hasLength(3));
      expect(result.completedDays, 2);
      expect(result.progress, closeTo(2 / 3, 0.001));
      expect(result.averageWaterMl, 1933);
      expect(repository.lastLogSubject, 'u1');
    },
  );

  test('FamilyPlus actor can load another package subject locally', () async {
    final repository = _FakeAdvancedTrackingRepository();
    final fn01 = AdvancedTrackingGoalsFn01(repository: repository);
    const actor = AdvancedTrackingActorContext(
      actorId: 'owner',
      hasPaidAccess: true,
      isFamilyPlus: true,
    );

    final goal = await fn01.execute(
      const CreateAdvancedGoalCommand(actor: actor, subjectUserId: 'member'),
    );

    expect(goal.subjectUserId, 'member');
  });
}

class _FakeAdvancedTrackingRepository implements AdvancedTrackingRepository {
  final goals = <String, AdvancedTrackingGoal>{};
  final logsBySubject = <String, List<AdvancedTrackingHydrationLog>>{};
  int createCalls = 0;
  String? lastLogSubject;

  @override
  Future<AdvancedTrackingGoal?> loadActiveGoal({
    required String subjectUserId,
    required String goalCode,
  }) async {
    return goals['$subjectUserId:$goalCode'];
  }

  @override
  Future<AdvancedTrackingGoal> createHydrationGoal({
    required String subjectUserId,
    required DateTime now,
  }) async {
    createCalls++;
    final goal = AdvancedTrackingGoal(
      id: 'goal-$subjectUserId',
      subjectUserId: subjectUserId,
      goalCode: advancedTrackingHydrationGoalCode,
      goalName: advancedTrackingHydrationGoalName,
      isActive: true,
      createdAt: now.toIso8601String(),
    );
    goals['$subjectUserId:${goal.goalCode}'] = goal;
    return goal;
  }

  @override
  Future<List<AdvancedTrackingHydrationLog>> loadHydrationLogs({
    required String subjectUserId,
    required AdvancedTrackingPeriod period,
  }) async {
    lastLogSubject = subjectUserId;
    return logsBySubject[subjectUserId] ?? const [];
  }
}

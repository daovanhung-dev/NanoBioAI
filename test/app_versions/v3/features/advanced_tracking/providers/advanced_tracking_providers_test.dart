import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v3/features/advanced_tracking/advanced_tracking.dart';

void main() {
  test('summary provider returns auth-required without user id', () async {
    final container = ProviderContainer(
      overrides: [
        advancedTrackingCurrentUserIdProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(advancedTrackingSummaryProvider.future);

    expect(result.status, AdvancedTrackingViewStatus.authRequired);
  });

  test('summary provider returns locked for Free access', () async {
    final container = ProviderContainer(
      overrides: [
        advancedTrackingCurrentUserIdProvider.overrideWithValue('u1'),
        advancedTrackingEffectiveAccessProvider.overrideWith(
          (ref) async => _access(membershipPlan: 'free'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(advancedTrackingSummaryProvider.future);

    expect(result.status, AdvancedTrackingViewStatus.locked);
  });

  test(
    'summary provider returns ready for Plus access and existing goal',
    () async {
      final repository = _FakeAdvancedTrackingRepository()
        ..goals['u1:$advancedTrackingHydrationGoalCode'] = _goal('u1')
        ..logsBySubject['u1'] = const [
          AdvancedTrackingHydrationLog(date: '2026-06-30', waterMl: 2100),
        ];
      final container = ProviderContainer(
        overrides: [
          advancedTrackingCurrentUserIdProvider.overrideWithValue('u1'),
          advancedTrackingEffectiveAccessProvider.overrideWith(
            (ref) async => _access(membershipPlan: 'plus'),
          ),
          advancedTrackingNowProvider.overrideWithValue(
            () => DateTime.parse('2026-06-30T12:00:00'),
          ),
          advancedTrackingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        advancedTrackingSummaryProvider.future,
      );

      expect(result.status, AdvancedTrackingViewStatus.ready);
      expect(result.result?.completedDays, 1);
    },
  );

  test('create provider stores hydration goal for paid user', () async {
    final repository = _FakeAdvancedTrackingRepository();
    final container = ProviderContainer(
      overrides: [
        advancedTrackingCurrentUserIdProvider.overrideWithValue('u1'),
        advancedTrackingEffectiveAccessProvider.overrideWith(
          (ref) async => _access(membershipPlan: 'family_plus'),
        ),
        advancedTrackingNowProvider.overrideWithValue(
          () => DateTime.parse('2026-06-30T12:00:00'),
        ),
        advancedTrackingRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(advancedTrackingCreateHydrationGoalProvider)();

    expect(repository.createCalls, 1);
    expect(
      repository.goals.containsKey('u1:$advancedTrackingHydrationGoalCode'),
      isTrue,
    );
  });
}

EffectiveAccess _access({required String membershipPlan}) {
  return EffectiveAccess(
    userId: 'u1',
    isAnonymous: false,
    productAccess: 'member',
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}

AdvancedTrackingGoal _goal(String subjectUserId) {
  return AdvancedTrackingGoal(
    id: 'goal-$subjectUserId',
    subjectUserId: subjectUserId,
    goalCode: advancedTrackingHydrationGoalCode,
    goalName: advancedTrackingHydrationGoalName,
    isActive: true,
    createdAt: '2026-06-30T08:00:00',
  );
}

class _FakeAdvancedTrackingRepository implements AdvancedTrackingRepository {
  final goals = <String, AdvancedTrackingGoal>{};
  final logsBySubject = <String, List<AdvancedTrackingHydrationLog>>{};
  int createCalls = 0;

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
    final goal = _goal(subjectUserId);
    goals['$subjectUserId:${goal.goalCode}'] = goal;
    return goal;
  }

  @override
  Future<List<AdvancedTrackingHydrationLog>> loadHydrationLogs({
    required String subjectUserId,
    required AdvancedTrackingPeriod period,
  }) async {
    return logsBySubject[subjectUserId] ?? const [];
  }
}

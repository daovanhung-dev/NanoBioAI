import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/features/nabi/application/notifications/nabi_health_reminder_planner.dart';
import 'package:nano_app/features/nabi/data/health_review/sqlite_nabi_health_review_repository.dart';
import 'package:nano_app/features/nabi/data/notifications/nabi_health_reminder_repositories.dart';
import 'package:nano_app/features/nabi/domain/health_review/nabi_health_review_models.dart';
import 'package:nano_app/features/nabi/domain/health_review/nabi_health_review_repository.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_repositories.dart';
import 'package:nano_app/services/health_orchestration/health_domain_event_sink.dart';

final nabiHealthReviewRepositoryProvider = Provider<NabiHealthReviewRepository>(
  (_) => const SqliteNabiHealthReviewRepository(),
);

final nabiHealthReminderPreferencesRepositoryProvider =
    Provider<NabiHealthReminderPreferencesRepository>(
      (_) => const SqliteNabiHealthReminderPreferencesRepository(),
    );

final healthCheckInControllerProvider =
    AsyncNotifierProvider<HealthCheckInController, HealthCheckInViewData>(
      HealthCheckInController.new,
    );

final goalReviewControllerProvider =
    AsyncNotifierProvider<GoalReviewController, GoalReviewViewData>(
      GoalReviewController.new,
    );

final profileReviewControllerProvider =
    AsyncNotifierProvider<ProfileReviewController, ProfileReviewViewData>(
      ProfileReviewController.new,
    );

class HealthCheckInViewData {
  final String actorKey;
  final List<NabiHealthConditionReviewItem> conditions;

  const HealthCheckInViewData({
    required this.actorKey,
    required this.conditions,
  });
}

class GoalReviewViewData {
  final String actorKey;
  final Set<String> selectedGoalCodes;

  const GoalReviewViewData({
    required this.actorKey,
    required this.selectedGoalCodes,
  });
}

class ProfileReviewViewData {
  final String actorKey;
  final NabiMutableProfileSnapshot profile;

  const ProfileReviewViewData({required this.actorKey, required this.profile});
}

abstract base class _ActorScopedReviewController<T> extends AsyncNotifier<T> {
  Future<String> requireActor() async {
    final actor = (await resolveActiveNotificationSubject())?.trim();
    if (actor == null || actor.isEmpty) {
      throw StateError('active_subject_missing');
    }
    return actor;
  }

  Future<void> refreshReminders(String actorKey) {
    return NotificationBootstrap.refreshHealthCareReminders(
      subjectUserId: actorKey,
    );
  }

  Future<void> publishHealthEvent({
    required HealthEventType type,
    required String actorKey,
    required String sourceFeature,
    String? entityId,
    Set<String> changedFields = const <String>{},
  }) async {
    try {
      await ref.read(healthDomainEventSinkProvider).publish(
            HealthDomainEvent.create(
              type: type,
              subjectId: actorKey,
              sourceFeature: sourceFeature,
              entityId: entityId,
              changedFields: changedFields,
            ),
          );
    } catch (_) {
      // The authoritative write already succeeded. Cross-feature refresh is a
      // best-effort enhancement and must not turn persisted care data into an
      // apparent save failure.
    }
  }
}

final class HealthCheckInController
    extends _ActorScopedReviewController<HealthCheckInViewData> {
  @override
  Future<HealthCheckInViewData> build() async {
    final actor = await requireActor();
    final conditions = await ref
        .read(nabiHealthReviewRepositoryProvider)
        .loadConditions(actor);
    return HealthCheckInViewData(actorKey: actor, conditions: conditions);
  }

  Future<void> submit({
    required String overallFeeling,
    required Map<String, String> conditionStatusById,
    required String note,
  }) async {
    final current = state.requireValue;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(nabiHealthReviewRepositoryProvider)
          .saveHealthCheckIn(
            actorKey: current.actorKey,
            overallFeeling: overallFeeling,
            conditionStatusById: conditionStatusById,
            note: note,
          );
      final now = DateTime.now();
      await ref
          .read(nabiHealthReminderPreferencesRepositoryProvider)
          .markHealthCheckIn(current.actorKey, now);
      await refreshReminders(current.actorKey);
      await publishHealthEvent(
        type: HealthEventType.healthCheckInRecorded,
        actorKey: current.actorKey,
        sourceFeature: 'notification_care.health_checkin',
        entityId: 'health-checkin:${_localDateKey(now)}',
        changedFields: {
          'overall_feeling',
          'condition_statuses',
          if (note.trim().isNotEmpty) 'note_present',
        },
      );
      final conditions = await ref
          .read(nabiHealthReviewRepositoryProvider)
          .loadConditions(current.actorKey);
      return HealthCheckInViewData(
        actorKey: current.actorKey,
        conditions: conditions,
      );
    });
  }
}

final class GoalReviewController
    extends _ActorScopedReviewController<GoalReviewViewData> {
  @override
  Future<GoalReviewViewData> build() async {
    final actor = await requireActor();
    final snapshot = await ref
        .read(nabiHealthReviewRepositoryProvider)
        .loadGoals(actor);
    return GoalReviewViewData(
      actorKey: actor,
      selectedGoalCodes: snapshot.onboardingGoalCodes,
    );
  }

  Future<void> submit(Set<String> goalCodes) async {
    final current = state.requireValue;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(nabiHealthReviewRepositoryProvider)
          .replaceOnboardingGoals(
            actorKey: current.actorKey,
            goalCodes: goalCodes,
          );
      final now = DateTime.now();
      await ref
          .read(nabiHealthReminderPreferencesRepositoryProvider)
          .markGoalReview(
            current.actorKey,
            NabiHealthReminderPlanner.goalReviewPeriodKey(now),
          );
      await refreshReminders(current.actorKey);
      await publishHealthEvent(
        type: HealthEventType.goalUpdated,
        actorKey: current.actorKey,
        sourceFeature: 'notification_care.goal_review',
        entityId: NabiHealthReminderPlanner.goalReviewPeriodKey(now),
        changedFields: const {'goal_codes'},
      );
      return GoalReviewViewData(
        actorKey: current.actorKey,
        selectedGoalCodes: Set.unmodifiable(goalCodes),
      );
    });
  }
}

final class ProfileReviewController
    extends _ActorScopedReviewController<ProfileReviewViewData> {
  @override
  Future<ProfileReviewViewData> build() async {
    final actor = await requireActor();
    final profile = await ref
        .read(nabiHealthReviewRepositoryProvider)
        .loadMutableProfile(actor);
    return ProfileReviewViewData(actorKey: actor, profile: profile);
  }

  Future<void> submit(NabiMutableProfileSnapshot profile) async {
    final current = state.requireValue;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(nabiHealthReviewRepositoryProvider)
          .updateMutableProfile(actorKey: current.actorKey, profile: profile);
      final now = DateTime.now();
      await ref
          .read(nabiHealthReminderPreferencesRepositoryProvider)
          .markProfileReview(current.actorKey, now);
      await refreshReminders(current.actorKey);
      await publishHealthEvent(
        type: HealthEventType.profileUpdated,
        actorKey: current.actorKey,
        sourceFeature: 'notification_care.profile_review',
        changedFields: const {'mutable_profile'},
      );
      return ProfileReviewViewData(
        actorKey: current.actorKey,
        profile: profile,
      );
    });
  }
}

String _localDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

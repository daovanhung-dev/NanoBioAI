import 'nabi_health_reminder_preferences.dart';

class NabiScheduledHealthReminderRecord {
  final String occurrenceId;
  final String actorKey;
  final NabiHealthReminderCategory category;
  final int nativeNotificationId;
  final DateTime scheduledAt;

  const NabiScheduledHealthReminderRecord({
    required this.occurrenceId,
    required this.actorKey,
    required this.category,
    required this.nativeNotificationId,
    required this.scheduledAt,
  });
}

abstract interface class NabiHealthReminderPreferencesRepository {
  Future<NabiHealthReminderPreferences> loadOrCreate({
    required String actorKey,
    required bool legacyPushEnabled,
  });

  Future<void> save(NabiHealthReminderPreferences preferences);

  Future<void> markHealthCheckIn(String actorKey, DateTime at);

  Future<void> markGoalReview(String actorKey, String periodKey);

  Future<void> markProfileReview(String actorKey, DateTime at);
}

abstract interface class NabiHealthReminderScheduleRepository {
  Future<List<NabiScheduledHealthReminderRecord>> loadPendingForActor(
    String actorKey,
  );

  Future<List<NabiScheduledHealthReminderRecord>> loadPendingForOtherActors(
    String actorKey,
  );

  Future<NabiScheduledHealthReminderRecord> savePlanned({
    required String actorKey,
    required NabiPlannedHealthReminder reminder,
    required int nativeNotificationId,
  });

  Future<void> markCancelled(String occurrenceId);

  Future<void> markOpened(String occurrenceId);

  Future<void> markDeferred({
    required String occurrenceId,
    required DateTime deferredUntil,
  });

  Future<DateTime?> loadHealthProfileUpdatedAt(String actorKey);

  Future<bool> isWaterGoalCompletedToday({
    required String actorKey,
    required DateTime now,
  });

  Future<NabiQuietHours?> loadPersonalQuietHours({
    required String actorKey,
    required DateTime now,
  });
}

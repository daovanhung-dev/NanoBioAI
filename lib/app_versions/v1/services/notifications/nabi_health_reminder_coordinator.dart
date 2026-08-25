import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nano_app/features/nabi/application/notifications/nabi_health_reminder_planner.dart';
import 'package:nano_app/features/nabi/data/notifications/nabi_health_reminder_repositories.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_repositories.dart';

import 'active_notification_subject.dart';
import 'nabi_companion_notification_payload.dart';
import 'notification_constants.dart';
import 'notification_id_generator.dart';
import 'notification_navigation_coordinator.dart';
import 'reminder_notification_scheduler.dart';

class NabiHealthReminderCoordinator {
  final LocalReminderNotificationScheduler scheduler;
  final NabiHealthReminderPreferencesRepository preferencesRepository;
  final NabiHealthReminderScheduleRepository scheduleRepository;
  final NabiHealthReminderPlanner planner;
  final DateTime Function() now;

  NabiHealthReminderCoordinator({
    required this.scheduler,
    NabiHealthReminderPreferencesRepository? preferencesRepository,
    NabiHealthReminderScheduleRepository? scheduleRepository,
    this.planner = const NabiHealthReminderPlanner(),
    DateTime Function()? now,
  }) : preferencesRepository =
           preferencesRepository ??
           const SqliteNabiHealthReminderPreferencesRepository(),
       scheduleRepository =
           scheduleRepository ?? const SqliteNabiHealthReminderScheduleRepository(),
       now = now ?? DateTime.now;

  Future<NabiHealthReminderPreferences?> loadPreferences({
    String? subjectUserId,
  }) async {
    final actor = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    if (actor == null || actor.trim().isEmpty) return null;
    final shared = await SharedPreferences.getInstance();
    final legacyPush = shared.getBool('push_enabled') ?? false;
    return preferencesRepository.loadOrCreate(
      actorKey: actor,
      legacyPushEnabled: legacyPush,
    );
  }

  Future<void> refresh({String? subjectUserId}) async {
    final preferences = await loadPreferences(subjectUserId: subjectUserId);
    if (preferences == null) return;
    final actor = preferences.actorKey;

    await _cancelOtherActors(actor);
    final pending = await scheduleRepository.loadPendingForActor(actor);
    if (!preferences.masterEnabled) {
      await _cancelRecords(pending);
      return;
    }

    final currentTime = now();
    final quiet = preferences.usePersonalQuietHours
        ? await scheduleRepository.loadPersonalQuietHours(
                actorKey: actor,
                now: currentTime,
              ) ??
              NabiQuietHours(
                startMinutes: preferences.fallbackQuietStartMinutes,
                endMinutes: preferences.fallbackQuietEndMinutes,
              )
        : NabiQuietHours(
            startMinutes: preferences.fallbackQuietStartMinutes,
            endMinutes: preferences.fallbackQuietEndMinutes,
          );
    final profileUpdated =
        await scheduleRepository.loadHealthProfileUpdatedAt(actor);
    final waterDone = await scheduleRepository.isWaterGoalCompletedToday(
      actorKey: actor,
      now: currentTime,
    );
    final desired = planner.plan(
      NabiHealthReminderPlanningContext(
        now: currentTime,
        preferences: preferences,
        quietHours: quiet,
        healthProfileUpdatedAt: profileUpdated,
        waterCompletedToday: waterDone,
      ),
    );
    await _reconcile(
      actorKey: actor,
      preferences: preferences,
      pending: pending,
      desired: desired,
    );
  }

  Future<bool> handleResponse(
    NotificationResponse response,
    NabiCompanionNotificationPayload payload,
  ) async {
    final activeActor = await resolveActiveNotificationSubject();
    if (activeActor == null || activeActor.trim() != payload.actorKey.trim()) {
      final nativeId = response.id;
      if (nativeId != null) await scheduler.cancel(nativeId);
      await scheduleRepository.markCancelled(payload.occurrenceId);
      return true;
    }

    if (response.actionId == NotificationActionIds.nabiCompanionDefer) {
      await _defer(payload);
      return true;
    }

    await scheduleRepository.markOpened(payload.occurrenceId);
    _openCategory(payload.category);
    await refresh(subjectUserId: payload.actorKey);
    return true;
  }

  Future<void> clear({String? subjectUserId}) async {
    final actor = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    if (actor == null || actor.trim().isEmpty) return;
    await _cancelRecords(await scheduleRepository.loadPendingForActor(actor));
  }

  Future<void> _cancelOtherActors(String actorKey) async {
    final stale = await scheduleRepository.loadPendingForOtherActors(actorKey);
    await _cancelRecords(stale);
  }

  Future<void> _cancelRecords(
    Iterable<NabiScheduledHealthReminderRecord> records,
  ) async {
    for (final record in records) {
      await scheduler.cancel(record.nativeNotificationId);
      await scheduleRepository.markCancelled(record.occurrenceId);
    }
  }

  Future<void> _reconcile({
    required String actorKey,
    required NabiHealthReminderPreferences preferences,
    required List<NabiScheduledHealthReminderRecord> pending,
    required List<NabiPlannedHealthReminder> desired,
  }) async {
    final desiredKeys = desired.map((item) => item.sourceEventId).toSet();
    final pendingByKey = <String, NabiScheduledHealthReminderRecord>{};
    for (final item in pending) {
      final key = NabiPlannedHealthReminder(
        category: item.category,
        scheduledAt: item.scheduledAt,
      ).sourceEventId;
      if (!desiredKeys.contains(key) || item.scheduledAt.isBefore(now())) {
        await scheduler.cancel(item.nativeNotificationId);
        await scheduleRepository.markCancelled(item.occurrenceId);
      } else {
        pendingByKey[key] = item;
      }
    }

    for (final item in desired) {
      if (pendingByKey.containsKey(item.sourceEventId)) continue;
      final nativeId = deterministicNotificationId(
        'nabi_companion|$actorKey|${item.sourceEventId}',
      );
      final record = await scheduleRepository.savePlanned(
        actorKey: actorKey,
        reminder: item,
        nativeNotificationId: nativeId,
      );
      final payload = NabiCompanionNotificationPayload(
        occurrenceId: record.occurrenceId,
        actorKey: actorKey,
        category: item.category,
        scheduledAt: item.scheduledAt.toUtc().toIso8601String(),
        voiceEnabled: preferences.voiceEnabled,
      );
      await scheduler.scheduleNabiCompanionReminder(
        id: nativeId,
        title: item.category.title,
        body: item.category.body,
        scheduledAt: item.scheduledAt,
        payload: payload.toJsonString(),
        voiceEnabled: preferences.voiceEnabled,
      );
    }
  }

  Future<void> _defer(NabiCompanionNotificationPayload payload) async {
    final preferences = await loadPreferences(subjectUserId: payload.actorKey);
    if (preferences == null || !preferences.masterEnabled) {
      await scheduleRepository.markCancelled(payload.occurrenceId);
      return;
    }
    final base = now().add(const Duration(hours: 24));
    final quiet = preferences.usePersonalQuietHours
        ? await scheduleRepository.loadPersonalQuietHours(
                actorKey: payload.actorKey,
                now: base,
              ) ??
              NabiQuietHours(
                startMinutes: preferences.fallbackQuietStartMinutes,
                endMinutes: preferences.fallbackQuietEndMinutes,
              )
        : NabiQuietHours(
            startMinutes: preferences.fallbackQuietStartMinutes,
            endMinutes: preferences.fallbackQuietEndMinutes,
          );
    final deferredUntil = _moveOutOfQuiet(base, quiet);
    await scheduleRepository.markDeferred(
      occurrenceId: payload.occurrenceId,
      deferredUntil: deferredUntil,
    );
    final reminder = NabiPlannedHealthReminder(
      category: payload.category,
      scheduledAt: deferredUntil,
    );
    final nativeId = deterministicNotificationId(
      'nabi_companion|${payload.actorKey}|${reminder.sourceEventId}',
    );
    final record = await scheduleRepository.savePlanned(
      actorKey: payload.actorKey,
      reminder: reminder,
      nativeNotificationId: nativeId,
    );
    final deferredPayload = NabiCompanionNotificationPayload(
      occurrenceId: record.occurrenceId,
      actorKey: payload.actorKey,
      category: payload.category,
      scheduledAt: deferredUntil.toUtc().toIso8601String(),
      voiceEnabled: preferences.voiceEnabled,
    );
    await scheduler.scheduleNabiCompanionReminder(
      id: nativeId,
      title: payload.category.title,
      body: payload.category.body,
      scheduledAt: deferredUntil,
      payload: deferredPayload.toJsonString(),
      voiceEnabled: preferences.voiceEnabled,
    );
  }

  DateTime _moveOutOfQuiet(DateTime candidate, NabiQuietHours quiet) {
    if (!quiet.contains(candidate)) return candidate;
    final minute = candidate.hour * 60 + candidate.minute;
    final wraps = quiet.startMinutes > quiet.endMinutes;
    final dayOffset = wraps && minute >= quiet.startMinutes ? 1 : 0;
    return DateTime(
      candidate.year,
      candidate.month,
      candidate.day + dayOffset,
      quiet.endMinutes ~/ 60,
      quiet.endMinutes % 60,
    );
  }

  void _openCategory(NabiHealthReminderCategory category) {
    switch (category) {
      case NabiHealthReminderCategory.healthCheckIn:
        NotificationNavigationCoordinator.openHealthCheckIn();
      case NabiHealthReminderCategory.goalReview:
        NotificationNavigationCoordinator.openGoalReview();
      case NabiHealthReminderCategory.profileReview:
        NotificationNavigationCoordinator.openProfileReview();
      case NabiHealthReminderCategory.water:
        NotificationNavigationCoordinator.openWaterTracking();
    }
  }
}

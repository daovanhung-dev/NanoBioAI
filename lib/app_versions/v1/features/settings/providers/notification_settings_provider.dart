import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/flutter_tts_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/features/nabi/data/notifications/nabi_health_reminder_repositories.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_repositories.dart';

import 'settings_provider.dart';

final notificationSettingsRepositoryProvider =
    Provider<NabiHealthReminderPreferencesRepository>(
      (_) => const SqliteNabiHealthReminderPreferencesRepository(),
    );

final notificationSettingsControllerProvider = AsyncNotifierProvider<
  NotificationSettingsController,
  NabiHealthReminderPreferences
>(NotificationSettingsController.new);

class NotificationSettingsController
    extends AsyncNotifier<NabiHealthReminderPreferences> {
  late final NabiHealthReminderPreferencesRepository _repository;

  @override
  Future<NabiHealthReminderPreferences> build() async {
    _repository = ref.read(notificationSettingsRepositoryProvider);
    final actor = (await resolveActiveNotificationSubject())?.trim();
    if (actor == null || actor.isEmpty) {
      throw StateError('active_subject_missing');
    }
    final shared = await SharedPreferences.getInstance();
    return _repository.loadOrCreate(
      actorKey: actor,
      legacyPushEnabled: shared.getBool('push_enabled') ?? false,
    );
  }

  Future<bool> setMasterEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationBootstrap.requestPermissions();
      if (!granted) return false;
    }
    await _mutate((value) => value.copyWith(masterEnabled: enabled));
    final shared = await SharedPreferences.getInstance();
    await shared.setBool('push_enabled', enabled);
    ref.invalidate(settingsPreferencesControllerProvider);
    await NotificationBootstrap.scheduleGeneratedReminders(
      subjectUserId: state.value?.actorKey,
    );
    return true;
  }

  Future<void> setScheduleEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(scheduleEnabled: enabled),
        includeSchedule: true,
      );

  Future<void> setHealthCheckInEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(healthCheckInEnabled: enabled),
      );

  Future<void> setHealthCheckInInterval(int minutes) => _mutateAndRefresh(
        (value) => value.copyWith(
          healthCheckInIntervalMinutes: minutes.clamp(60, 240),
        ),
      );

  Future<void> setHealthCheckInWindow(int start, int end) => _mutateAndRefresh(
        (value) => value.copyWith(
          healthCheckInStartMinutes: NabiHealthReminderPreferences.clampMinute(start),
          healthCheckInEndMinutes: NabiHealthReminderPreferences.clampMinute(end),
        ),
      );

  Future<void> setGoalReviewEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(goalReviewEnabled: enabled),
      );

  Future<void> setGoalReviewTime(int minutes) => _mutateAndRefresh(
        (value) => value.copyWith(
          goalReviewMinutes: NabiHealthReminderPreferences.clampMinute(minutes),
        ),
      );

  Future<void> setProfileReviewEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(profileReviewEnabled: enabled),
      );

  Future<void> setProfileReviewIntervalDays(int days) => _mutateAndRefresh(
        (value) => value.copyWith(profileReviewIntervalDays: days.clamp(7, 180)),
      );

  Future<void> setProfileReviewTime(int minutes) => _mutateAndRefresh(
        (value) => value.copyWith(
          profileReviewMinutes: NabiHealthReminderPreferences.clampMinute(minutes),
        ),
      );

  Future<void> setWaterReminderEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(waterReminderEnabled: enabled),
      );

  Future<void> setWaterReminderInterval(int minutes) => _mutateAndRefresh(
        (value) => value.copyWith(
          waterReminderIntervalMinutes: minutes.clamp(60, 360),
        ),
      );

  Future<void> setWaterReminderWindow(int start, int end) => _mutateAndRefresh(
        (value) => value.copyWith(
          waterReminderStartMinutes: NabiHealthReminderPreferences.clampMinute(start),
          waterReminderEndMinutes: NabiHealthReminderPreferences.clampMinute(end),
        ),
      );

  Future<void> setVoiceEnabled(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(voiceEnabled: enabled),
      );

  Future<void> setUsePersonalQuietHours(bool enabled) => _mutateAndRefresh(
        (value) => value.copyWith(usePersonalQuietHours: enabled),
      );

  Future<void> setFallbackQuietHours(int start, int end) => _mutateAndRefresh(
        (value) => value.copyWith(
          fallbackQuietStartMinutes: NabiHealthReminderPreferences.clampMinute(start),
          fallbackQuietEndMinutes: NabiHealthReminderPreferences.clampMinute(end),
        ),
      );

  Future<bool> previewVoice() async {
    final voiceState = ref.read(aiVoiceControllerProvider);
    if (voiceState.isSessionInProgress) return false;
    try {
      final gateway = DeviceTextToSpeechGateway();
      await gateway.speak(
        'Nabi nhắc bạn chăm sóc sức khỏe một chút nhé. Bạn có thể tắt giọng nói bất cứ lúc nào.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _mutateAndRefresh(
    NabiHealthReminderPreferences Function(NabiHealthReminderPreferences) update, {
    bool includeSchedule = false,
  }) async {
    await _mutate(update);
    final actor = state.value?.actorKey;
    if (includeSchedule) {
      await NotificationBootstrap.scheduleGeneratedReminders(
        subjectUserId: actor,
      );
    } else {
      await NotificationBootstrap.refreshHealthCareReminders(
        subjectUserId: actor,
      );
    }
  }

  Future<void> _mutate(
    NabiHealthReminderPreferences Function(NabiHealthReminderPreferences) update,
  ) async {
    final current = state.requireValue;
    final next = update(current).copyWith(updatedAt: DateTime.now());
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

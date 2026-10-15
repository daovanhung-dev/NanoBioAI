import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/data/repositories/sqlite_medication_reminder_repository.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/storage/localdb/tables/nabi_notification_tables.dart';
import 'package:nano_app/features/nabi/data/notifications/nabi_health_reminder_repositories.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'active_notification_subject.dart';
import 'medication_reminder_coordinator.dart';
import 'nabi_companion_notification_payload.dart';
import 'nabi_health_reminder_coordinator.dart';
import 'notification_action_handler.dart';
import 'notification_navigation_coordinator.dart';
import 'reminder_notification_scheduler.dart';
import 'reminder_schedule_service.dart';

@pragma('vm:entry-point')
void bioAiNotificationBackgroundResponse(NotificationResponse response) {
  DartPluginRegistrant.ensureInitialized();
  unawaited(NotificationBootstrap.handleNotificationResponse(response));
}

class NotificationBootstrap {
  NotificationBootstrap._();

  static const _tag = 'NOTIFICATION_BOOTSTRAP';
  static const _fallbackTimezone = 'Asia/Ho_Chi_Minh';

  static final LocalReminderNotificationScheduler _scheduler =
      LocalReminderNotificationScheduler(
        onForegroundResponse: handleNotificationResponse,
        onBackgroundResponse: bioAiNotificationBackgroundResponse,
      );

  static bool _timezoneInitialized = false;
  static bool _initialized = false;
  static Future<void>? _initializing;
  static bool _launchResponseHandled = false;

  static ReminderNotificationScheduler get scheduler => _scheduler;

  static NabiHealthReminderCoordinator _careCoordinator() =>
      NabiHealthReminderCoordinator(scheduler: _scheduler);

  static MedicationReminderCoordinator _medicationCoordinator() =>
      MedicationReminderCoordinator(
        repository: const SqliteMedicationReminderRepository(),
        scheduler: _scheduler,
        masterEnabled: _medicationMasterEnabled,
      );

  static Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initializeOnce();
  }

  static Future<void> _initializeOnce() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeTimezone();
      await _scheduler.initialize();
      _initialized = true;
      await _handleLaunchResponseOnce();
      AppLogger.info(_tag, 'Notification bootstrap initialized');
    } finally {
      _initializing = null;
    }
  }

  static Future<void> _handleLaunchResponseOnce() async {
    if (_launchResponseHandled) return;
    _launchResponseHandled = true;
    try {
      final details = await _scheduler.plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        await handleNotificationResponse(response);
      }
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot restore notification navigation; errorType=${error.runtimeType}',
      );
    }
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    return _scheduler.requestPermissions();
  }

  static Future<void> scheduleGeneratedReminders({
    String? subjectUserId,
  }) async {
    await initialize();
    final subject = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    try {
      await _medicationCoordinator().refresh(subjectUserId: subject);
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Medication reminder refresh failed; errorType=${error.runtimeType}',
      );
    }
    final service = await ReminderScheduleService.create(
      scheduler: _scheduler,
      activeSubjectUserId: () async => subject,
    );
    final coordinator = _careCoordinator();
    final preferences = await coordinator.loadPreferences(
      subjectUserId: subject,
    );

    if (preferences?.masterEnabled == true &&
        preferences?.scheduleEnabled == true) {
      await service.scheduleGeneratedReminders();
    } else {
      await service.clearPendingReminders(subjectUserId: subject);
    }
    await coordinator.refresh(subjectUserId: subject);
  }

  /// Called after the user adds an onboarding medicine schedule. Permission
  /// denial keeps the local reminder and never blocks onboarding completion.
  static Future<bool> requestMedicationReminderPermissionAndEnable({
    String? subjectUserId,
  }) async {
    await initialize();
    final subject = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    if (subject == null) return false;
    final reminders = await const SqliteMedicationReminderRepository()
        .listForUser(subject);
    if (reminders.isEmpty) return true;

    final shared = await SharedPreferences.getInstance();
    var granted = false;
    try {
      granted = await _scheduler.requestPermissions();
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Medication reminder permission request failed; errorType=${error.runtimeType}',
      );
    }
    if (!granted) {
      await shared.setBool('medication_reminder_permission_denied', true);
      return false;
    }

    final preferencesRepository =
        const SqliteNabiHealthReminderPreferencesRepository();
    final preferences = await preferencesRepository.loadOrCreate(
      actorKey: subject,
      legacyPushEnabled: shared.getBool('push_enabled') ?? false,
    );
    await preferencesRepository.save(
      preferences.copyWith(masterEnabled: true, updatedAt: DateTime.now()),
    );
    await shared.setBool('push_enabled', true);
    await shared.setBool('medication_reminder_permission_denied', false);
    try {
      await _medicationCoordinator().refresh(subjectUserId: subject);
      await scheduleGeneratedReminders(subjectUserId: subject);
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Onboarding reminder scheduling failed; errorType=${error.runtimeType}',
      );
    }
    return true;
  }

  static Future<void> refreshHealthCareReminders({
    String? subjectUserId,
  }) async {
    await initialize();
    await _careCoordinator().refresh(subjectUserId: subjectUserId);
  }

  static Future<void> clearGeneratedReminders({String? subjectUserId}) async {
    await initialize();
    final subject = await resolveActiveNotificationSubject(
      requestedSubjectUserId: subjectUserId,
    );
    final service = await ReminderScheduleService.create(scheduler: _scheduler);
    await service.clearPendingReminders(subjectUserId: subject);
    await _careCoordinator().clear(subjectUserId: subject);
    try {
      await _medicationCoordinator().refresh(subjectUserId: subject);
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Medication reminder clear failed; errorType=${error.runtimeType}',
      );
    }
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      await initialize();
      if (MedicationReminderCoordinator.isMedicationPayload(response.payload)) {
        await _medicationCoordinator().handleResponse(response.payload);
        return;
      }
      final companion = NabiCompanionNotificationPayload.tryParse(
        response.payload,
      );
      if (companion != null) {
        await _careCoordinator().handleResponse(response, companion);
        return;
      }
      if (_isSleepSafetyArmPayload(response.payload)) {
        NotificationNavigationCoordinator.openSleepSafety();
        return;
      }
      final handler = await NotificationActionHandler.create(
        scheduler: _scheduler,
      );
      await handler.handleResponse(response);
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to handle notification response',
        error,
        stackTrace,
      );
    }
  }

  static Future<bool> _medicationMasterEnabled(String ownerId) async {
    final db = await DatabaseService.database;
    await NabiNotificationTables.ensureHealthReminderSchema(db);
    final rows = await db.query(
      NabiNotificationTables.carePreferences,
      columns: const ['master_enabled'],
      where: 'actor_key = ?',
      whereArgs: [ownerId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final value = rows.first['master_enabled'];
      return value == true || value == 1 || value?.toString() == 'true';
    }
    final shared = await SharedPreferences.getInstance();
    return shared.getBool('push_enabled') ?? false;
  }

  static bool _isSleepSafetyArmPayload(String? payload) {
    final raw = payload?.trim();
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      return decoded['type'] == 'sleep_safety' && decoded['action'] == 'arm';
    } catch (_) {
      return false;
    }
  }

  static Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    final timezoneName = await _resolveTimezoneName();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Unknown timezone "$timezoneName". Fallback to $_fallbackTimezone. errorType=${error.runtimeType}',
      );
      tz.setLocalLocation(tz.getLocation(_fallbackTimezone));
    }
    _timezoneInitialized = true;
  }

  static Future<String> _resolveTimezoneName() async {
    if (kIsWeb) return _fallbackTimezone;
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = timezoneInfo.identifier.trim();
      if (identifier.isEmpty) {
        AppLogger.warning(
          _tag,
          'Device timezone identifier is empty. Fallback to $_fallbackTimezone.',
        );
        return _fallbackTimezone;
      }
      return identifier;
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Cannot resolve device timezone. Fallback to $_fallbackTimezone. errorType=${error.runtimeType}',
      );
      return _fallbackTimezone;
    }
  }
}

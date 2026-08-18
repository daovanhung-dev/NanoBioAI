import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:sqflite/sqflite.dart';

import 'notification_constants.dart';
import 'notification_payload.dart';
import 'notification_navigation_coordinator.dart';
import 'active_notification_subject.dart';
import 'reminder_notification_scheduler.dart';

class NotificationActionHandler {
  static const _tag = 'NOTIFICATION_ACTION_HANDLER';
  static const deferDuration = Duration(minutes: 30);

  final NotificationsDao notificationsDao;
  final MealPlansDao mealPlansDao;
  final DailyHealthTasksDao dailyHealthTasksDao;
  final LifestyleScheduleItemsDao lifestyleScheduleItemsDao;
  final LifestyleScheduleLocalDatasource lifestyleScheduleDatasource;
  final ReminderNotificationScheduler scheduler;
  final Database? database;
  final ActiveNotificationSubjectReader _activeSubjectUserId;
  final DateTime Function() _now;

  NotificationActionHandler({
    required this.notificationsDao,
    required this.mealPlansDao,
    required this.dailyHealthTasksDao,
    required this.lifestyleScheduleItemsDao,
    required this.lifestyleScheduleDatasource,
    required this.scheduler,
    this.database,
    ActiveNotificationSubjectReader? activeSubjectUserId,
    DateTime Function()? now,
  }) : _activeSubjectUserId =
           activeSubjectUserId ?? resolveActiveNotificationSubject,
       _now = now ?? DateTime.now;

  factory NotificationActionHandler.fromDatabase(
    Database db, {
    required ReminderNotificationScheduler scheduler,
  }) {
    final now = DateTime.now;
    return NotificationActionHandler(
      notificationsDao: NotificationsDao(db),
      mealPlansDao: MealPlansDao(db),
      dailyHealthTasksDao: DailyHealthTasksDao(db),
      lifestyleScheduleItemsDao: LifestyleScheduleItemsDao(db),
      lifestyleScheduleDatasource: LifestyleScheduleLocalDatasource(
        databaseOverride: db,
        now: now,
      ),
      scheduler: scheduler,
      database: db,
      activeSubjectUserId: resolveActiveNotificationSubject,
      now: now,
    );
  }

  static Future<NotificationActionHandler> create({
    required ReminderNotificationScheduler scheduler,
  }) async {
    final db = await DatabaseService.database;
    return NotificationActionHandler.fromDatabase(db, scheduler: scheduler);
  }

  Future<void> handleResponse(NotificationResponse response) {
    return handleAction(
      actionId: response.actionId,
      notificationId: response.id,
      payload: response.payload,
    );
  }

  Future<void> handleAction({
    required String? actionId,
    required String? payload,
    int? notificationId,
  }) async {
    try {
      // Chạm vào thân thông báo không có actionId trên Android/iOS. Xem đây là
      // thao tác mở lịch; không thực hiện hoàn thành nhiệm vụ trong nền.
      final normalizedActionId = _normalizeActionId(actionId);
      if (!_isSupportedAction(normalizedActionId)) {
        AppLogger.info(_tag, 'Ignore unsupported action: $actionId');
        return;
      }

      if (payload == null || payload.trim().isEmpty) {
        AppLogger.warning(_tag, 'Ignore action with empty payload');
        return;
      }

      final parsedPayload = NotificationPayload.fromJsonString(payload);
      final resolvedNotificationId =
          notificationId ?? parsedPayload.notificationId;
      final notification = await notificationsDao.getByNotificationId(
        resolvedNotificationId,
      );

      if (notification == null) {
        AppLogger.warning(
          _tag,
          'No notification row for id=$resolvedNotificationId',
        );
        return;
      }

      if (!_isActionableStatus(notification.actionStatus)) {
        AppLogger.info(
          _tag,
          'Ignore already handled notification id=${notification.id}',
        );
        return;
      }

      // A defer rewrites scheduledAt/payload. A duplicated callback from the
      // notification that was already deferred must not push it another 30m.
      if (notification.actionStatus == NotificationActionStatuses.deferred &&
          !_matchesCurrentDelivery(parsedPayload, notification)) {
        AppLogger.info(_tag, 'Ignore stale deferred notification response');
        return;
      }

      final respondedAt = _now().toIso8601String();
      final sourceType = parsedPayload.sourceType.isNotEmpty
          ? parsedPayload.sourceType
          : notification.sourceType ?? '';
      final sourceId = parsedPayload.sourceId.isNotEmpty
          ? parsedPayload.sourceId
          : notification.sourceId ?? '';
      final subjectUserId = parsedPayload.subjectUserId ?? notification.userId;

      if (!_payloadMatchesNotification(parsedPayload, notification)) {
        await _recordActionFailure(
          notification: notification,
          respondedAt: respondedAt,
        );
        return;
      }

      // Notifications can outlive an account switch. Never let a response
      // from User A navigate or mutate state while User B is active.
      final activeSubjectUserId = await _activeSubjectUserId();
      if (!_isActiveSubject(subjectUserId, activeSubjectUserId)) {
        AppLogger.warning(
          _tag,
          'Notification action rejected for inactive subject',
        );
        await _recordActionFailure(
          notification: notification,
          respondedAt: respondedAt,
        );
        return;
      }

      final sourceMatchesSubject = await _sourceMatchesSubject(
        sourceType: sourceType,
        sourceId: sourceId,
        subjectUserId: subjectUserId,
      );
      if (!sourceMatchesSubject) {
        await _recordActionFailure(
          notification: notification,
          respondedAt: respondedAt,
        );
        return;
      }

      if (normalizedActionId == NotificationActionIds.defer) {
        await _deferNotification(
          notification: notification,
          payload: parsedPayload,
          respondedAt: respondedAt,
        );
        return;
      }

      // Notification chỉ mở ứng dụng. Mọi hoàn thành lịch đều phải đi qua
      // camera/check-in và transaction của source schedule tương ứng.
      await notificationsDao.updateActionStatus(
        id: notification.id,
        actionStatus: NotificationActionStatuses.opened,
        respondedAt: respondedAt,
        updatedAt: respondedAt,
      );
      LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
      NotificationNavigationCoordinator.openScheduleItem(sourceId);
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(_tag, 'Invalid notification payload', error, stackTrace);
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to handle notification action',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _deferNotification({
    required NotificationModel notification,
    required NotificationPayload payload,
    required String respondedAt,
  }) async {
    final notificationId = notification.notificationId;
    if (notificationId == null) {
      await _recordActionFailure(
        notification: notification,
        respondedAt: respondedAt,
      );
      return;
    }

    final deferredAt = _now().add(deferDuration);
    final deferredAtText = deferredAt.toIso8601String();
    final deferredPayload = NotificationPayload(
      payloadVersion: payload.payloadVersion,
      notificationId: notificationId,
      sourceType: payload.sourceType,
      sourceId: payload.sourceId,
      scheduledAt: deferredAtText,
      subjectUserId: payload.subjectUserId ?? notification.userId,
      actorUserId: payload.actorUserId,
      familyPackageId: payload.familyPackageId,
      correlationId: payload.correlationId ?? notification.id,
    ).toJsonString();

    await notificationsDao.updateDeferredSchedule(
      id: notification.id,
      scheduledAt: deferredAtText,
      payload: deferredPayload,
      respondedAt: respondedAt,
      updatedAt: respondedAt,
    );

    try {
      await scheduler.scheduleReminder(
        id: notificationId,
        title: notification.title,
        body: notification.body,
        scheduledAt: deferredAt,
        payload: deferredPayload,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to schedule deferred reminder',
        error,
        stackTrace,
      );
      await notificationsDao.updateActionStatus(
        id: notification.id,
        actionStatus: NotificationActionStatuses.scheduleFailed,
        respondedAt: respondedAt,
        updatedAt: _now().toIso8601String(),
      );
    }

    LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
  }

  bool _payloadMatchesNotification(
    NotificationPayload payload,
    NotificationModel notification,
  ) {
    final rowSourceType = notification.sourceType;
    final rowSourceId = notification.sourceId;
    if (payload.sourceType.isNotEmpty &&
        rowSourceType != null &&
        rowSourceType.isNotEmpty &&
        payload.sourceType != rowSourceType) {
      AppLogger.warning(_tag, 'Notification source type mismatch');
      return false;
    }
    if (payload.sourceId.isNotEmpty &&
        rowSourceId != null &&
        rowSourceId.isNotEmpty &&
        payload.sourceId != rowSourceId) {
      AppLogger.warning(_tag, 'Notification source id mismatch');
      return false;
    }
    if (!_sameSubject(payload.subjectUserId, notification.userId)) {
      AppLogger.warning(_tag, 'Notification subject mismatch');
      return false;
    }
    return true;
  }

  bool _matchesCurrentDelivery(
    NotificationPayload payload,
    NotificationModel notification,
  ) {
    final rowScheduledAt = notification.scheduledAt?.trim();
    final payloadScheduledAt = payload.scheduledAt.trim();
    if (rowScheduledAt == null ||
        rowScheduledAt.isEmpty ||
        payloadScheduledAt.isEmpty) {
      return true;
    }
    return rowScheduledAt == payloadScheduledAt;
  }

  Future<bool> _sourceMatchesSubject({
    required String sourceType,
    required String sourceId,
    required String? subjectUserId,
  }) async {
    final subject = _normalizeSubject(subjectUserId);
    if (subject == null || sourceId.trim().isEmpty) return true;

    if (sourceType == ReminderSourceTypes.meal) {
      final meal = await mealPlansDao.getById(sourceId);
      return meal != null && _sameSubject(subject, meal.userId);
    }

    if (sourceType == ReminderSourceTypes.dailyTask) {
      final task = await dailyHealthTasksDao.getById(sourceId);
      return task != null && _sameSubject(subject, task.userId);
    }

    if (sourceType == ReminderSourceTypes.lifestyleScheduleItem) {
      final item = await lifestyleScheduleItemsDao.getById(sourceId);
      return item != null && _sameSubject(subject, item.userId);
    }

    return sourceType.trim().isEmpty;
  }

  Future<void> _recordActionFailure({
    required NotificationModel notification,
    required String respondedAt,
  }) async {
    await notificationsDao.updateActionStatus(
      id: notification.id,
      actionStatus: NotificationActionStatuses.actionFailed,
      respondedAt: respondedAt,
      updatedAt: respondedAt,
    );
    LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
  }

  bool _sameSubject(String? left, String? right) {
    final normalizedLeft = _normalizeSubject(left);
    final normalizedRight = _normalizeSubject(right);
    if (normalizedLeft == null || normalizedRight == null) return true;
    return normalizedLeft == normalizedRight;
  }

  bool _isActiveSubject(String? notificationSubject, String? activeSubject) {
    final normalizedNotificationSubject = _normalizeSubject(
      notificationSubject,
    );
    final normalizedActiveSubject = _normalizeSubject(activeSubject);
    return normalizedNotificationSubject != null &&
        normalizedActiveSubject != null &&
        normalizedNotificationSubject == normalizedActiveSubject;
  }

  String? _normalizeSubject(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool _isActionableStatus(String status) {
    return status == NotificationActionStatuses.pending ||
        status == NotificationActionStatuses.deferred;
  }

  bool _isSupportedAction(String? actionId) {
    return actionId == NotificationActionIds.openSchedule ||
        actionId == NotificationActionIds.defer;
  }

  String _normalizeActionId(String? actionId) {
    final rawActionId = actionId?.trim();
    // The legacy `done` action remains compatible by opening the task; it
    // never completes the task silently in a background isolate.
    if (rawActionId == null ||
        rawActionId.isEmpty ||
        rawActionId == NotificationActionIds.done) {
      return NotificationActionIds.openSchedule;
    }
    // Legacy releases used `skipped` for the copy "Để sau". Preserve old
    // delivered notifications while converging runtime semantics on defer.
    if (rawActionId == NotificationActionIds.skipped) {
      return NotificationActionIds.defer;
    }
    return rawActionId;
  }
}

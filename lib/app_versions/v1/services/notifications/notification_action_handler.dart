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

class NotificationActionHandler {
  static const _tag = 'NOTIFICATION_ACTION_HANDLER';

  final NotificationsDao notificationsDao;
  final MealPlansDao mealPlansDao;
  final DailyHealthTasksDao dailyHealthTasksDao;
  final LifestyleScheduleItemsDao lifestyleScheduleItemsDao;
  final LifestyleScheduleLocalDatasource lifestyleScheduleDatasource;
  final Database? database;
  final DateTime Function() _now;

  NotificationActionHandler({
    required this.notificationsDao,
    required this.mealPlansDao,
    required this.dailyHealthTasksDao,
    required this.lifestyleScheduleItemsDao,
    required this.lifestyleScheduleDatasource,
    this.database,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  factory NotificationActionHandler.fromDatabase(Database db) {
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
      database: db,
      now: now,
    );
  }

  static Future<NotificationActionHandler> create() async {
    final db = await DatabaseService.database;
    return NotificationActionHandler.fromDatabase(db);
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
      final normalizedActionId = actionId?.trim();
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

      final respondedAt = _now().toIso8601String();
      if (notification.actionStatus != NotificationActionStatuses.pending) {
        AppLogger.info(
          _tag,
          'Ignore already handled notification id=${notification.id}',
        );
        return;
      }

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

      if (normalizedActionId == NotificationActionIds.skipped) {
        await notificationsDao.updateActionStatus(
          id: notification.id,
          actionStatus: NotificationActionStatuses.skipped,
          respondedAt: respondedAt,
          updatedAt: respondedAt,
        );
        LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
        return;
      }

      final sourceUpdated = await _tryMarkSourceDone(
        sourceType: sourceType,
        sourceId: sourceId,
        updatedAt: respondedAt,
      );

      await notificationsDao.updateActionStatus(
        id: notification.id,
        actionStatus: sourceUpdated
            ? NotificationActionStatuses.done
            : NotificationActionStatuses.actionFailed,
        respondedAt: respondedAt,
        updatedAt: respondedAt,
      );
      LocalUserDataSyncDispatcher.requestImmediateSync(database: database);
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

    return true;
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

  String? _normalizeSubject(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  Future<bool> _tryMarkSourceDone({
    required String sourceType,
    required String sourceId,
    required String updatedAt,
  }) async {
    try {
      return await _markSourceDone(
        sourceType: sourceType,
        sourceId: sourceId,
        updatedAt: updatedAt,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to mark notification source as done',
        error,
        stackTrace,
      );
      return false;
    }
  }

  bool _isSupportedAction(String? actionId) {
    return actionId == NotificationActionIds.done ||
        actionId == NotificationActionIds.skipped;
  }

  Future<bool> _markSourceDone({
    required String sourceType,
    required String sourceId,
    required String updatedAt,
  }) async {
    if (sourceType == ReminderSourceTypes.meal) {
      return _markMealDone(sourceId);
    }

    if (sourceType == ReminderSourceTypes.lifestyleScheduleItem) {
      return _markLifestyleScheduleItemDone(sourceId);
    }

    if (sourceType == ReminderSourceTypes.dailyTask) {
      return _markDailyTaskDone(sourceId, updatedAt);
    }

    AppLogger.warning(
      _tag,
      'Unsupported notification source type=$sourceType id=$sourceId',
    );
    return false;
  }

  Future<bool> _markMealDone(String sourceId) async {
    final meal = await mealPlansDao.getById(sourceId);
    if (meal == null) {
      AppLogger.warning(_tag, 'Meal source not found: $sourceId');
      return false;
    }

    await mealPlansDao.updateCompleted(id: sourceId, isCompleted: true);
    return true;
  }

  Future<bool> _markDailyTaskDone(String sourceId, String updatedAt) async {
    final task = await dailyHealthTasksDao.getById(sourceId);
    if (task == null) {
      AppLogger.warning(_tag, 'Daily task source not found: $sourceId');
      return false;
    }

    await dailyHealthTasksDao.updateTask(
      task.copyWith(
        currentValue: task.targetValue,
        isCompleted: true,
        updatedAt: updatedAt,
      ),
    );
    return true;
  }

  Future<bool> _markLifestyleScheduleItemDone(String sourceId) async {
    final item = await lifestyleScheduleItemsDao.getById(sourceId);
    if (item == null) {
      AppLogger.warning(_tag, 'Schedule source not found: $sourceId');
      return false;
    }

    await lifestyleScheduleDatasource.updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
    );
    return true;
  }
}

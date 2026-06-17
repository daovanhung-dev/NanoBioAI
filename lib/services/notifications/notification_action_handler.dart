import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/features/meal_plan/data/daos/meal_plan_dao.dart';
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
  final DateTime Function() _now;

  NotificationActionHandler({
    required this.notificationsDao,
    required this.mealPlansDao,
    required this.dailyHealthTasksDao,
    required this.lifestyleScheduleItemsDao,
    required this.lifestyleScheduleDatasource,
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
      await notificationsDao.updateActionStatus(
        id: notification.id,
        actionStatus: _actionStatusFor(normalizedActionId!),
        respondedAt: respondedAt,
        updatedAt: respondedAt,
      );

      if (normalizedActionId == NotificationActionIds.skipped) {
        return;
      }

      await _markSourceDone(
        sourceType: parsedPayload.sourceType.isNotEmpty
            ? parsedPayload.sourceType
            : notification.sourceType ?? '',
        sourceId: parsedPayload.sourceId.isNotEmpty
            ? parsedPayload.sourceId
            : notification.sourceId ?? '',
        updatedAt: respondedAt,
      );
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

  bool _isSupportedAction(String? actionId) {
    return actionId == NotificationActionIds.done ||
        actionId == NotificationActionIds.skipped;
  }

  String _actionStatusFor(String actionId) {
    if (actionId == NotificationActionIds.done) {
      return NotificationActionStatuses.done;
    }
    return NotificationActionStatuses.skipped;
  }

  Future<void> _markSourceDone({
    required String sourceType,
    required String sourceId,
    required String updatedAt,
  }) async {
    if (sourceType == ReminderSourceTypes.meal) {
      await _markMealDone(sourceId);
      return;
    }

    if (sourceType == ReminderSourceTypes.lifestyleScheduleItem) {
      await _markLifestyleScheduleItemDone(sourceId);
      return;
    }

    if (sourceType == ReminderSourceTypes.dailyTask) {
      await _markDailyTaskDone(sourceId, updatedAt);
      return;
    }

    AppLogger.warning(
      _tag,
      'Unsupported notification source type=$sourceType id=$sourceId',
    );
  }

  Future<void> _markMealDone(String sourceId) async {
    final meal = await mealPlansDao.getById(sourceId);
    if (meal == null) {
      AppLogger.warning(_tag, 'Meal source not found: $sourceId');
      return;
    }

    await mealPlansDao.updateCompleted(id: sourceId, isCompleted: true);
  }

  Future<void> _markDailyTaskDone(String sourceId, String updatedAt) async {
    final task = await dailyHealthTasksDao.getById(sourceId);
    if (task == null) {
      AppLogger.warning(_tag, 'Daily task source not found: $sourceId');
      return;
    }

    await dailyHealthTasksDao.updateTask(
      task.copyWith(
        currentValue: task.targetValue,
        isCompleted: true,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> _markLifestyleScheduleItemDone(String sourceId) async {
    final item = await lifestyleScheduleItemsDao.getById(sourceId);
    if (item == null) {
      AppLogger.warning(_tag, 'Schedule source not found: $sourceId');
      return;
    }

    await lifestyleScheduleDatasource.updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
    );
  }
}

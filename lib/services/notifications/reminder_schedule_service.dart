import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:sqflite/sqflite.dart';

import 'notification_constants.dart';
import 'notification_id_generator.dart';
import 'notification_payload.dart';
import 'reminder_notification_scheduler.dart';

class ReminderScheduleService {
  static const _tag = 'REMINDER_SCHEDULE_SERVICE';

  final LifestyleScheduleItemsDao scheduleItemsDao;
  final NotificationsDao notificationsDao;
  final ReminderNotificationScheduler scheduler;
  final DateTime Function() _now;

  ReminderScheduleService({
    required this.scheduleItemsDao,
    required this.notificationsDao,
    required this.scheduler,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  factory ReminderScheduleService.fromDatabase({
    required Database db,
    required ReminderNotificationScheduler scheduler,
    DateTime Function()? now,
  }) {
    return ReminderScheduleService(
      scheduleItemsDao: LifestyleScheduleItemsDao(db),
      notificationsDao: NotificationsDao(db),
      scheduler: scheduler,
      now: now,
    );
  }

  static Future<ReminderScheduleService> create({
    required ReminderNotificationScheduler scheduler,
    DateTime Function()? now,
  }) async {
    final db = await DatabaseService.database;
    return ReminderScheduleService.fromDatabase(
      db: db,
      scheduler: scheduler,
      now: now,
    );
  }

  Future<void> scheduleGeneratedReminders() async {
    final items = await scheduleItemsDao.getAll();

    await _deletePendingForSources(
      sourceType: ReminderSourceTypes.lifestyleScheduleItem,
      sourceIds: items.map((item) => item.id).toList(),
    );

    final candidates = items
        .where((item) => !item.isCompleted)
        .map(_scheduleItemCandidate)
        .whereType<_ReminderCandidate>()
        .where((candidate) => candidate.scheduledAt.isAfter(_now()))
        .toList();

    if (candidates.isEmpty) {
      AppLogger.info(_tag, 'No future reminder candidates to schedule');
      return;
    }

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      await _insertRowsWithStatus(
        candidates,
        NotificationActionStatuses.permissionDenied,
      );
      return;
    }

    for (final candidate in candidates) {
      await _scheduleCandidate(candidate);
    }
  }

  Future<void> _deletePendingForSources({
    required String sourceType,
    required List<String> sourceIds,
  }) async {
    if (sourceIds.isEmpty) return;

    final pending = await notificationsDao.getPendingBySources(
      sourceType: sourceType,
      sourceIds: sourceIds,
    );

    for (final notification in pending) {
      final notificationId = notification.notificationId;
      if (notificationId == null) continue;

      try {
        await scheduler.cancel(notificationId);
      } catch (error, stackTrace) {
        AppLogger.error(
          _tag,
          'Failed to cancel notification $notificationId',
          error,
          stackTrace,
        );
      }
    }

    await notificationsDao.deletePendingBySources(
      sourceType: sourceType,
      sourceIds: sourceIds,
    );
  }

  Future<bool> _requestPermission() async {
    try {
      return await scheduler.requestPermissions();
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to request notification permission',
        error,
        stackTrace,
      );
      return false;
    }
  }

  Future<void> _insertRowsWithStatus(
    List<_ReminderCandidate> candidates,
    String actionStatus,
  ) async {
    final updatedAt = _now().toIso8601String();
    final rows = candidates.map((candidate) {
      return _notificationFor(
        candidate,
      ).copyWith(actionStatus: actionStatus, updatedAt: updatedAt);
    }).toList();

    await notificationsDao.insertMany(rows);
  }

  Future<void> _scheduleCandidate(_ReminderCandidate candidate) async {
    final notification = _notificationFor(candidate);

    try {
      await notificationsDao.insert(notification);
      await scheduler.scheduleReminder(
        id: candidate.notificationId,
        title: candidate.title,
        body: candidate.body,
        scheduledAt: candidate.scheduledAt,
        payload: candidate.payload,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to schedule reminder ${candidate.rowId}',
        error,
        stackTrace,
      );
      await notificationsDao.insert(
        notification.copyWith(
          actionStatus: NotificationActionStatuses.scheduleFailed,
          updatedAt: _now().toIso8601String(),
        ),
      );
    }
  }

  NotificationModel _notificationFor(_ReminderCandidate candidate) {
    final nowText = _now().toIso8601String();
    return NotificationModel(
      id: candidate.rowId,
      userId: candidate.userId,
      title: candidate.title,
      body: candidate.body,
      type: NotificationTypes.reminder,
      sourceType: candidate.sourceType,
      sourceId: candidate.sourceId,
      scheduledAt: candidate.scheduledAtText,
      notificationId: candidate.notificationId,
      actionStatus: NotificationActionStatuses.pending,
      payload: candidate.payload,
      createdAt: nowText,
      updatedAt: nowText,
    );
  }

  _ReminderCandidate? _scheduleItemCandidate(LifestyleScheduleItemModel item) {
    final scheduledAt = _scheduledAt(item);
    if (scheduledAt == null) return null;

    final title = item.title.trim().isNotEmpty
        ? item.title
        : 'Nhắc việc sức khỏe';
    final body = item.description.trim().isNotEmpty
        ? item.description
        : item.encouragement.trim().isNotEmpty
        ? item.encouragement
        : 'Mở app để cập nhật tiến độ hôm nay';

    return _ReminderCandidate(
      userId: item.userId,
      sourceType: ReminderSourceTypes.lifestyleScheduleItem,
      sourceId: item.id,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );
  }

  DateTime? _scheduledAt(LifestyleScheduleItemModel item) {
    final date = DateTime.tryParse(item.scheduleDate);
    final parts = item.startTime.split(':');
    if (date == null || parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class _ReminderCandidate {
  final String? userId;
  final String sourceType;
  final String sourceId;
  final String title;
  final String body;
  final DateTime scheduledAt;

  _ReminderCandidate({
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  String get scheduledAtText => scheduledAt.toIso8601String();

  String get rowId => 'reminder_${sourceType}_${sourceId}_$scheduledAtText';

  int get notificationId => deterministicNotificationId(rowId);

  String get payload {
    return NotificationPayload(
      notificationId: notificationId,
      sourceType: sourceType,
      sourceId: sourceId,
      scheduledAt: scheduledAtText,
    ).toJsonString();
  }
}

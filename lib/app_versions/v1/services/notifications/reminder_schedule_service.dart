import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/lifestyle_schedule_window_policy.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';
import 'package:sqflite/sqflite.dart';

import 'notification_constants.dart';
import 'notification_id_generator.dart';
import 'notification_payload.dart';
import 'reminder_notification_scheduler.dart';

typedef ActiveReminderSubjectReader = Future<String?> Function();

class ReminderScheduleService {
  static const _tag = 'REMINDER_SCHEDULE_SERVICE';

  final LifestyleScheduleItemsDao scheduleItemsDao;
  final NotificationsDao notificationsDao;
  final ReminderNotificationScheduler scheduler;
  final ActiveReminderSubjectReader activeSubjectUserId;
  final DateTime Function() _now;

  ReminderScheduleService({
    required this.scheduleItemsDao,
    required this.notificationsDao,
    required this.scheduler,
    ActiveReminderSubjectReader? activeSubjectUserId,
    DateTime Function()? now,
  }) : activeSubjectUserId = activeSubjectUserId ?? _noActiveSubject,
       _now = now ?? DateTime.now;

  factory ReminderScheduleService.fromDatabase({
    required Database db,
    required ReminderNotificationScheduler scheduler,
    ActiveReminderSubjectReader? activeSubjectUserId,
    DateTime Function()? now,
  }) {
    return ReminderScheduleService(
      scheduleItemsDao: LifestyleScheduleItemsDao(db),
      notificationsDao: NotificationsDao(db),
      scheduler: scheduler,
      activeSubjectUserId: activeSubjectUserId,
      now: now,
    );
  }

  static Future<ReminderScheduleService> create({
    required ReminderNotificationScheduler scheduler,
    ActiveReminderSubjectReader? activeSubjectUserId,
    DateTime Function()? now,
  }) async {
    final db = await DatabaseService.database;
    return ReminderScheduleService.fromDatabase(
      db: db,
      scheduler: scheduler,
      activeSubjectUserId: activeSubjectUserId,
      now: now,
    );
  }

  Future<void> scheduleGeneratedReminders() async {
    final subjectUserId = _activeSubjectId(await activeSubjectUserId());
    final items = subjectUserId == null
        ? const <LifestyleScheduleItemModel>[]
        : await scheduleItemsDao.getAllByUserId(subjectUserId);

    await _clearPendingForRefresh(
      activeSubjectUserId: subjectUserId,
      activeSourceIds: items.map((item) => item.id).toSet(),
    );

    if (subjectUserId == null) {
      AppLogger.info(
        _tag,
        'Skip reminder scheduling because no subject is active',
      );
      return;
    }

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

  Future<void> clearPendingReminders({String? subjectUserId}) async {
    final activeSubject = _activeSubjectId(subjectUserId);
    final pending = await notificationsDao.getPendingBySourceType(
      ReminderSourceTypes.lifestyleScheduleItem,
    );

    for (final notification in pending) {
      if (activeSubject != null &&
          !_matchesSubject(notification.userId, activeSubject)) {
        continue;
      }
      await _cancelAndDelete(notification);
    }
  }

  Future<void> _clearPendingForRefresh({
    required String? activeSubjectUserId,
    required Set<String> activeSourceIds,
  }) async {
    final pending = await notificationsDao.getPendingBySourceType(
      ReminderSourceTypes.lifestyleScheduleItem,
    );

    for (final notification in pending) {
      final isActiveSubject =
          activeSubjectUserId != null &&
          _matchesSubject(notification.userId, activeSubjectUserId);
      final sourceStillExists =
          isActiveSubject &&
          notification.sourceId != null &&
          activeSourceIds.contains(notification.sourceId);

      // Every pending row for the active subject is replaced by this refresh.
      // Rows from another subject or a removed source must also be cancelled so
      // an account switch or a deleted task cannot leave an OS reminder behind.
      final cleanupReason = !isActiveSubject
          ? 'other_subject'
          : sourceStillExists
          ? 'refresh'
          : 'stale_source';
      AppLogger.info(_tag, 'Clear pending reminder reason=$cleanupReason');
      await _cancelAndDelete(notification);
    }
  }

  Future<void> _cancelAndDelete(NotificationModel notification) async {
    final notificationId = notification.notificationId;
    if (notificationId != null) {
      try {
        await scheduler.cancel(notificationId);
      } catch (error, stackTrace) {
        AppLogger.error(
          _tag,
          'Failed to cancel a pending reminder',
          error,
          stackTrace,
        );
        // Keep the pending row so a later refresh can retry the OS cancel.
        // Deleting it here would lose the durable cleanup signal while the
        // stale notification may still be scheduled by the platform.
        return;
      }
    }
    await notificationsDao.delete(notification.id);
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

    final title = vietnameseSystemUiText(
      item.title,
      fallback: 'Nhắc việc sức khỏe',
    );
    final bodySource = item.description.trim().isNotEmpty
        ? item.description
        : item.encouragement;
    final body = vietnameseSystemUiText(
      bodySource,
      fallback: 'Mở ứng dụng để chụp ảnh và cập nhật tiến độ hôm nay.',
    );

    return _ReminderCandidate(
      userId: item.userId,
      subjectUserId: item.userId,
      sourceType: ReminderSourceTypes.lifestyleScheduleItem,
      sourceId: item.id,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );
  }

  DateTime? _scheduledAt(LifestyleScheduleItemModel item) {
    return LifestyleScheduleWindowPolicy.parseScheduledAt(
      scheduleDate: item.scheduleDate,
      startTime: item.startTime,
    );
  }

  static Future<String?> _noActiveSubject() async => null;

  String? _activeSubjectId(String? userId) {
    final text = userId?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool _matchesSubject(String? left, String right) {
    return _subjectKey(left) == _subjectKey(right);
  }

  String _subjectKey(String? userId) {
    final text = userId?.trim();
    return text == null || text.isEmpty ? 'local_subject' : text;
  }
}

class _ReminderCandidate {
  final String? userId;
  final String? subjectUserId;
  final String sourceType;
  final String sourceId;
  final String title;
  final String body;
  final DateTime scheduledAt;

  _ReminderCandidate({
    required this.userId,
    required this.subjectUserId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  String get scheduledAtText => scheduledAt.toIso8601String();

  String get subjectKey {
    final text = subjectUserId?.trim();
    return text == null || text.isEmpty ? 'local_subject' : text;
  }

  String get rowId =>
      'reminder_${subjectKey}_${sourceType}_${sourceId}_$scheduledAtText';

  int get notificationId => deterministicNotificationId(rowId);

  String get payload {
    return NotificationPayload(
      notificationId: notificationId,
      sourceType: sourceType,
      sourceId: sourceId,
      scheduledAt: scheduledAtText,
      subjectUserId: subjectUserId,
      actorUserId: userId,
      correlationId: rowId,
    ).toJsonString();
  }
}

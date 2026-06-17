import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:nano_app/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/services/notifications/notification_action_handler.dart';
import 'package:nano_app/services/notifications/notification_constants.dart';
import 'package:nano_app/services/notifications/notification_payload.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late NotificationsDao notificationsDao;
  late MealPlansDao mealPlansDao;
  late LifestyleScheduleItemsDao scheduleItemsDao;
  late NotificationActionHandler handler;

  final fixedNow = DateTime.parse('2026-06-17T07:15:00.000');

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(NotificationsTable.createTable);
    await db.execute(MealPlansTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);

    notificationsDao = NotificationsDao(db);
    mealPlansDao = MealPlansDao(db);
    scheduleItemsDao = LifestyleScheduleItemsDao(db);
    handler = NotificationActionHandler(
      notificationsDao: notificationsDao,
      mealPlansDao: mealPlansDao,
      dailyHealthTasksDao: DailyHealthTasksDao(db),
      lifestyleScheduleItemsDao: scheduleItemsDao,
      lifestyleScheduleDatasource: LifestyleScheduleLocalDatasource(
        databaseOverride: db,
        now: () => fixedNow,
      ),
      now: () => fixedNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('done schedule item completes timeline item and linked meal', () async {
    await mealPlansDao.insert(_meal(id: 'meal-1'));
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-1',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-1',
      ),
    ]);
    await notificationsDao.insert(
      _notification(id: 'n-schedule-1', notificationId: 101),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 101,
      payload: _payload(notificationId: 101, sourceId: 'schedule-1'),
    );

    final notification = await notificationsDao.getByNotificationId(101);
    final schedule = await scheduleItemsDao.getById('schedule-1');
    final meal = await mealPlansDao.getById('meal-1');
    final log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'user-1', logDate: '2026-06-17');

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.done);
    expect(notification.isRead, isTrue);
    expect(schedule!.isCompleted, isTrue);
    expect(meal!.isCompleted, isTrue);
    expect(log!.dailyScore, 100);
  });

  test('skipped records response without completing schedule source', () async {
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-2',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
      ),
    ]);
    await notificationsDao.insert(
      _notification(id: 'n-schedule-2', notificationId: 201),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.skipped,
      notificationId: 201,
      payload: _payload(notificationId: 201, sourceId: 'schedule-2'),
    );

    final notification = await notificationsDao.getByNotificationId(201);
    final schedule = await scheduleItemsDao.getById('schedule-2');

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.skipped);
    expect(notification.isRead, isTrue);
    expect(schedule!.isCompleted, isFalse);
  });

  test('invalid payload does not crash or update notification', () async {
    await notificationsDao.insert(
      _notification(id: 'n-invalid', notificationId: 301),
    );

    await expectLater(
      handler.handleAction(
        actionId: NotificationActionIds.done,
        notificationId: 301,
        payload: '{invalid',
      ),
      completes,
    );

    final notification = await notificationsDao.getByNotificationId(301);

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.pending);
    expect(notification.isRead, isFalse);
  });
}

NotificationModel _notification({
  required String id,
  required int notificationId,
}) {
  return NotificationModel(
    id: id,
    userId: 'user-1',
    title: 'Reminder',
    body: 'Time to check in',
    type: NotificationTypes.reminder,
    sourceType: ReminderSourceTypes.lifestyleScheduleItem,
    sourceId: 'schedule-1',
    scheduledAt: '2026-06-17T07:00:00.000',
    notificationId: notificationId,
    actionStatus: NotificationActionStatuses.pending,
    payload: _payload(notificationId: notificationId, sourceId: 'schedule-1'),
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

String _payload({required int notificationId, required String sourceId}) {
  return NotificationPayload(
    notificationId: notificationId,
    sourceType: ReminderSourceTypes.lifestyleScheduleItem,
    sourceId: sourceId,
    scheduledAt: '2026-06-17T07:00:00.000',
  ).toJsonString();
}

MealPlanModel _meal({required String id}) {
  return MealPlanModel(
    id: id,
    userId: 'user-1',
    planDate: '2026-06-17',
    mealType: 'breakfast',
    mealName: 'Oatmeal',
    description: 'Light breakfast',
    calories: 350,
    protein: 12,
    carbs: 45,
    fat: 8,
    fiber: 6,
    waterMl: 300,
    mealOrder: 1,
    startTime: '07:00',
    endTime: '07:30',
    cookingInstructions: 'Cook oats. Add fruit.',
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

LifestyleScheduleItemModel _schedule({
  required String id,
  required String sourceType,
  required String sourceId,
}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: 'user-1',
    scheduleDate: '2026-06-17',
    startTime: '07:00',
    endTime: '07:30',
    title: 'Timeline task',
    description: 'Description',
    category: sourceType == LifestyleScheduleSourceTypes.mealPlan
        ? LifestyleScheduleCategories.meal
        : LifestyleScheduleCategories.routine,
    sourceType: sourceType,
    sourceId: sourceId.isEmpty ? null : sourceId,
    targetValue: 1,
    currentValue: 0,
    unit: 'lan',
    isCompleted: false,
    sortOrder: 1,
    aiGenerated: true,
    encouragement: 'Good',
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

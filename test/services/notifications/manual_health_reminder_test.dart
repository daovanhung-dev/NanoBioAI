import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/manual_health_task_draft.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_action_type.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_schedule_service.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late _FakeScheduler scheduler;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(NotificationsTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    scheduler = _FakeScheduler();
  });

  tearDown(() async => db.close());

  test('manual task with reminder disabled is not scheduled', () async {
    final dao = LifestyleScheduleItemsDao(db);
    await dao.upsertMany([
      _manualItem(id: 'manual-off', reminderEnabled: false),
      _manualItem(id: 'manual-on', reminderEnabled: true),
    ]);
    final service = ReminderScheduleService(
      scheduleItemsDao: dao,
      notificationsDao: NotificationsDao(db),
      scheduler: scheduler,
      activeSubjectUserId: () async => 'user-1',
      now: () => DateTime(2026, 8, 17, 8),
    );

    await service.scheduleGeneratedReminders();

    expect(scheduler.sourceTitles, ['Nghỉ mắt manual-on']);
    expect(scheduler.bodies.single, contains('cập nhật mốc chăm sóc'));
    expect(scheduler.bodies.single, isNot(contains('chụp ảnh')));
    final rows = await NotificationsDao(db).getAll();
    expect(rows, hasLength(1));
    expect(rows.single.sourceId, 'manual-on');
  });


  test('generated water reminder does not instruct user to take a photo', () async {
    final dao = LifestyleScheduleItemsDao(db);
    await dao.upsertMany([
      LifestyleScheduleItemModel(
        id: 'water-1',
        userId: 'user-1',
        scheduleDate: '2026-08-17',
        startTime: '12:00',
        title: 'Uống nước',
        category: LifestyleScheduleCategories.water,
        sourceType: LifestyleScheduleSourceTypes.dailyHealthTask,
        sourceId: 'water-source',
        createdAt: '2026-08-17T08:00:00.000',
        updatedAt: '2026-08-17T08:00:00.000',
      ),
    ]);
    final service = ReminderScheduleService(
      scheduleItemsDao: dao,
      notificationsDao: NotificationsDao(db),
      scheduler: scheduler,
      activeSubjectUserId: () async => 'user-1',
      now: () => DateTime(2026, 8, 17, 8),
    );

    await service.scheduleGeneratedReminders();

    expect(scheduler.bodies, hasLength(1));
    expect(scheduler.bodies.single, contains('cập nhật mốc chăm sóc'));
    expect(scheduler.bodies.single, isNot(contains('chụp ảnh')));
  });
}

LifestyleScheduleItemModel _manualItem({
  required String id,
  required bool reminderEnabled,
}) {
  final metadata = ManualHealthTaskMetadata(
    seriesId: '9bd3f704-f950-4ee1-95e4-7dc018b73b08',
    actionType: ScheduleHealthActionType.quickComplete,
    reminderEnabled: reminderEnabled,
  );
  return LifestyleScheduleItemModel(
    id: id,
    userId: 'user-1',
    scheduleDate: '2026-08-17',
    startTime: '12:00',
    title: 'Nghỉ mắt $id',
    category: LifestyleScheduleCategories.routine,
    sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
    sourceId: metadata.encode(),
    createdAt: '2026-08-17T08:00:00.000',
    updatedAt: '2026-08-17T08:00:00.000',
  );
}

class _FakeScheduler implements ReminderNotificationScheduler {
  final sourceTitles = <String>[];
  final bodies = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    sourceTitles.add(title);
    bodies.add(body);
  }

  @override
  Future<void> cancel(int id) async {}
}

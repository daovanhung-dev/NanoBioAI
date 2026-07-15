import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/tables/health_score_ledgers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_completion_proofs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_point_ledgers_table.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/models/daily_health_task_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_completion_proof_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/schedule_completion_proofs_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/schedule_completion_exception.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late LifestyleScheduleLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(MealPlansTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(ScheduleCompletionProofsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(HealthScoreLedgersTable.createTable);
    await db.execute(WellnessPointLedgersTable.createTable);
    datasource = LifestyleScheduleLocalDatasource(
      databaseOverride: db,
      now: () => DateTime.parse('2026-06-17T07:15:00.000'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('done meal-linked item marks meal completed', () async {
    await MealPlansDao(db).insert(_meal(id: 'meal-1'));
    await LifestyleScheduleItemsDao(db).upsertMany([
      _schedule(
        id: 'schedule-meal',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-1',
      ),
    ]);

    final updated = await datasource.updateItemCompletion(
      item: _schedule(
        id: 'schedule-meal',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-1',
      ).toEntity(),
      isCompleted: true,
      completionProofPath: '/local/proof-meal.jpg',
    );

    final meal = await MealPlansDao(db).getById('meal-1');

    expect(updated.isCompleted, isTrue);
    expect(meal, isNotNull);
    expect(meal!.isCompleted, isTrue);
  });

  test('completeItemById marks schedule item completed', () async {
    await LifestyleScheduleItemsDao(db).upsertMany([
      _schedule(
        id: 'schedule-1',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
      ),
    ]);

    final updated = await datasource.completeItemById(
      'schedule-1',
      completionProofPath: '/local/proof-schedule.jpg',
    );
    final restored = await LifestyleScheduleItemsDao(db).getById('schedule-1');

    expect(updated.isCompleted, isTrue);
    expect(restored, isNotNull);
    expect(restored!.isCompleted, isTrue);
    final proofs = await ScheduleCompletionProofsDao(db).getByUser('u1');
    expect(proofs, hasLength(1));
    expect(proofs.single.scheduleItemId, 'schedule-1');
  });

  test('done daily-task-linked item completes daily task', () async {
    await DailyHealthTasksDao(db).upsertMany([_task(id: 'task-1')]);
    await LifestyleScheduleItemsDao(db).upsertMany([
      _schedule(
        id: 'schedule-task',
        sourceType: LifestyleScheduleSourceTypes.dailyHealthTask,
        sourceId: 'task-1',
        targetValue: 2000,
      ),
    ]);

    await datasource.updateItemCompletion(
      item: _schedule(
        id: 'schedule-task',
        sourceType: LifestyleScheduleSourceTypes.dailyHealthTask,
        sourceId: 'task-1',
        targetValue: 2000,
      ).toEntity(),
      isCompleted: true,
      completionProofPath: '/local/proof-task.jpg',
    );

    final task = await DailyHealthTasksDao(db).getById('task-1');

    expect(task, isNotNull);
    expect(task!.isCompleted, isTrue);
    expect(task.currentValue, task.targetValue);
  });

  test('uncheck linked item resets source completion', () async {
    await DailyHealthTasksDao(db).upsertMany([
      _task(id: 'task-1').copyWith(currentValue: 2000, isCompleted: true),
    ]);
    await LifestyleScheduleItemsDao(db).upsertMany([
      _schedule(
        id: 'schedule-task',
        sourceType: LifestyleScheduleSourceTypes.dailyHealthTask,
        sourceId: 'task-1',
        targetValue: 2000,
        currentValue: 2000,
        isCompleted: true,
      ),
    ]);

    await datasource.updateItemCompletion(
      item: _schedule(
        id: 'schedule-task',
        sourceType: LifestyleScheduleSourceTypes.dailyHealthTask,
        sourceId: 'task-1',
        targetValue: 2000,
        currentValue: 2000,
        isCompleted: true,
      ).toEntity(),
      isCompleted: false,
    );

    final task = await DailyHealthTasksDao(db).getById('task-1');
    final schedule = await LifestyleScheduleItemsDao(
      db,
    ).getById('schedule-task');

    expect(task!.isCompleted, isFalse);
    expect(task.currentValue, 0);
    expect(schedule!.isCompleted, isFalse);
    expect(schedule.currentValue, 0);
  });

  test('cannot complete item before start time', () async {
    datasource = LifestyleScheduleLocalDatasource(
      databaseOverride: db,
      now: () => DateTime.parse('2026-06-17T06:59:00.000'),
    );
    final item = _schedule(
      id: 'future-task',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    await expectLater(
      datasource.updateItemCompletion(item: item.toEntity(), isCompleted: true),
      throwsA(isA<ScheduleCompletionException>()),
    );
  });

  test('cannot complete item after 30 minute window', () async {
    datasource = LifestyleScheduleLocalDatasource(
      databaseOverride: db,
      now: () => DateTime.parse('2026-06-17T07:31:00.000'),
    );
    final item = _schedule(
      id: 'locked-task',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    await expectLater(
      datasource.updateItemCompletion(
        item: item.toEntity(),
        isCompleted: true,
        completionProofPath: '/local/proof-locked.jpg',
      ),
      throwsA(isA<ScheduleCompletionException>()),
    );
  });

  test('complete without proof path is rejected', () async {
    final item = _schedule(
      id: 'missing-proof',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    await expectLater(
      datasource.updateItemCompletion(item: item.toEntity(), isCompleted: true),
      throwsA(isA<ScheduleCompletionException>()),
    );
  });

  test('completion writes daily score aggregate', () async {
    await LifestyleScheduleItemsDao(db).upsertMany([
      _schedule(
        id: 'schedule-1',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
      ),
      _schedule(
        id: 'schedule-2',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
        startTime: '07:15',
      ),
    ]);

    await datasource.updateItemCompletion(
      item: _schedule(
        id: 'schedule-1',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
      ).toEntity(),
      isCompleted: true,
      completionProofPath: '/local/proof-score-1.jpg',
    );

    var log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'u1', logDate: '2026-06-17');
    expect(log, isNotNull);
    expect(log!.dailyScore, 50);
    final scoreLedgers = await db.query('health_score_ledgers');
    expect(scoreLedgers, hasLength(1));
    expect(scoreLedgers.single['score'], 50);
    final pointRows = await db.query('wellness_point_ledgers');
    expect(
      pointRows,
      isEmpty,
      reason: 'Điểm đổi ưu đãi chỉ được ghi từ sự kiện server đã xác nhận.',
    );

    await datasource.updateItemCompletion(
      item: _schedule(
        id: 'schedule-2',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
        startTime: '07:15',
      ).toEntity(),
      isCompleted: true,
      completionProofPath: '/local/proof-score-2.jpg',
    );

    log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'u1', logDate: '2026-06-17');
    expect(log!.dailyScore, 100);
  });

  test('undo in open window preserves proof as reversed', () async {
    final item = _schedule(
      id: 'schedule-undo',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    final completed = await datasource.updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
      completionProofPath: '/local/proof-undo.jpg',
    );
    await datasource.updateItemCompletion(item: completed, isCompleted: false);

    final proofs = await ScheduleCompletionProofsDao(db).getByUser('u1');
    expect(proofs, hasLength(1));
    expect(proofs.single.status, ScheduleCompletionProofStatuses.reversed);
    expect(proofs.single.localPath, '/local/proof-undo.jpg');
    expect(proofs.single.reversedAt, isNotNull);
  });

  test('accepts Supabase time with seconds and fraction', () async {
    final item = _schedule(
      id: 'seconds-time',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
      startTime: '07:00:00.123456',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    final updated = await datasource.updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
      completionProofPath: 'schedule_proofs/proof.jpg',
    );

    expect(updated.isCompleted, isTrue);
  });

  test('exact 30 minute deadline is accepted', () async {
    datasource = LifestyleScheduleLocalDatasource(
      databaseOverride: db,
      now: () => DateTime.parse('2026-06-17T07:30:00.000'),
    );
    final item = _schedule(
      id: 'deadline-task',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    final completed = await datasource.updateItemCompletion(
      item: item.toEntity(),
      isCompleted: true,
      completionProofPath: 'schedule_proofs/deadline.jpg',
    );
    expect(completed.isCompleted, isTrue);
  });

  test('invalid stored time fails closed', () async {
    final item = _schedule(
      id: 'invalid-time',
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: '',
      startTime: '25:99:00',
    );
    await LifestyleScheduleItemsDao(db).upsertMany([item]);

    await expectLater(
      datasource.updateItemCompletion(
        item: item.toEntity(),
        isCompleted: true,
        completionProofPath: 'schedule_proofs/invalid.jpg',
      ),
      throwsA(
        isA<ScheduleCompletionException>().having(
          (error) => error.code,
          'code',
          ScheduleCompletionErrorCode.invalidScheduleTime,
        ),
      ),
    );
  });

  test(
    'completion rolls back schedule, linked source and proof together',
    () async {
      final item = _schedule(
        id: 'rollback-task',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'rollback-meal',
      );
      await MealPlansDao(db).insert(_meal(id: 'rollback-meal'));
      await LifestyleScheduleItemsDao(db).upsertMany([item]);
      await db.execute('''
      CREATE TRIGGER fail_health_score_insert
      BEFORE INSERT ON health_score_ledgers
      BEGIN
        SELECT RAISE(ABORT, 'test rollback');
      END
    ''');

      await expectLater(
        datasource.updateItemCompletion(
          item: item.toEntity(),
          isCompleted: true,
          completionProofPath: 'schedule_proofs/rollback.jpg',
        ),
        throwsA(anything),
      );

      final schedule = await LifestyleScheduleItemsDao(db).getById(item.id);
      final meal = await MealPlansDao(db).getById('rollback-meal');
      final proofs = await ScheduleCompletionProofsDao(db).getByUser('u1');
      expect(schedule!.isCompleted, isFalse);
      expect(meal!.isCompleted, isFalse);
      expect(proofs, isEmpty);
    },
  );

  test('schedule seed meals are filtered by user and generated week', () async {
    final dao = MealPlansDao(db);
    await dao.insert(_meal(id: 'in-start', planDate: '2026-06-18'));
    await dao.insert(_meal(id: 'in-end', planDate: '2026-06-24'));
    await dao.insert(_meal(id: 'old', planDate: '2026-06-17'));
    await dao.insert(_meal(id: 'after', planDate: '2026-06-25'));
    await dao.insert(
      _meal(id: 'other-user', userId: 'u2', planDate: '2026-06-18'),
    );

    final meals = await datasource.getMealPlansForScheduleSeed(
      userId: 'u1',
      startDate: DateTime(2026, 6, 18),
    );

    expect(meals.map((meal) => meal.id), ['in-start', 'in-end']);
  });
}

MealPlanModel _meal({
  required String id,
  String userId = 'u1',
  String planDate = '2026-06-17',
}) {
  return MealPlanModel(
    id: id,
    userId: userId,
    planDate: planDate,
    mealType: 'breakfast',
    mealName: 'Meal',
    description: 'Description',
    calories: 300,
    protein: 10,
    carbs: 30,
    fat: 8,
    fiber: 4,
    waterMl: 300,
    mealOrder: 1,
    cookingInstructions: 'Cook',
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-06-16T08:00:00',
    updatedAt: '2026-06-16T08:00:00',
  );
}

DailyHealthTaskModel _task({required String id}) {
  return DailyHealthTaskModel(
    id: id,
    userId: 'u1',
    taskDate: '2026-06-17',
    taskCode: 'ai_water',
    category: 'water',
    title: 'Drink water',
    description: 'Drink enough water',
    targetValue: 2000,
    currentValue: 0,
    unit: 'ml',
    isCompleted: false,
    sortOrder: 1,
    source: 'ai',
    encouragement: 'Good',
    createdAt: '2026-06-16T08:00:00',
    updatedAt: '2026-06-16T08:00:00',
  );
}

LifestyleScheduleItemModel _schedule({
  required String id,
  required String sourceType,
  required String sourceId,
  double targetValue = 1,
  double currentValue = 0,
  bool isCompleted = false,
  String startTime = '07:00',
}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: 'u1',
    scheduleDate: '2026-06-17',
    startTime: startTime,
    endTime: '07:30',
    title: 'Schedule',
    description: 'Description',
    category: sourceType == LifestyleScheduleSourceTypes.mealPlan
        ? LifestyleScheduleCategories.meal
        : LifestyleScheduleCategories.water,
    sourceType: sourceType,
    sourceId: sourceId,
    targetValue: targetValue,
    currentValue: currentValue,
    unit: 'lan',
    isCompleted: isCompleted,
    sortOrder: 1,
    aiGenerated: true,
    encouragement: 'Good',
    createdAt: '2026-06-16T08:00:00',
    updatedAt: '2026-06-16T08:00:00',
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_staging_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'staging resumes validated chunks, resets the retry window, and caps calls',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
      await db.insert('users', {'id': 'staging-user'});
      await db.execute(PersonalScheduleAiRequestsTable.createTable);
      await db.execute(PersonalScheduleAiStagingTable.createTable);

      final store = LocalPersonalScheduleAiRequestStore(databaseOverride: db);
      final startDate = DateTime(2026, 10, 13);
      await store.markGenerating(
        requestId: 'staging-request',
        userId: 'staging-user',
        actorMode: GeneratedPlanActorModes.initialGuest,
        startDate: startDate,
        days: 7,
      );
      final identity = await store.findIncompleteRequestId(
        userId: 'staging-user',
        actorMode: GeneratedPlanActorModes.initialGuest,
        days: 7,
      );
      expect(identity, 'staging-request');

      const inputFingerprint = 'input-hash';
      const catalogFingerprint = 'catalog-hash';
      const promptVersion = 'prompt-v1';
      await store.prepareStaging(
        requestId: 'staging-request',
        inputFingerprint: inputFingerprint,
        catalogFingerprint: catalogFingerprint,
        promptVersion: promptVersion,
      );
      const chunk = [
        {'day': 1, 'meal_type': 'breakfast', 'meal_code': 'meal-a'},
      ];
      await store.saveStagedChunk(
        requestId: 'staging-request',
        inputFingerprint: inputFingerprint,
        catalogFingerprint: catalogFingerprint,
        promptVersion: promptVersion,
        chunkKey: 'meal:1',
        payload: chunk,
        source: PlanGenerationSource.localFallback,
      );

      for (
        var index = 0;
        index <
            LocalPersonalScheduleAiRequestStore.maxBackendInvocationsPerSession;
        index++
      ) {
        await store.incrementBackendInvocationCount(
          requestId: 'staging-request',
          inputFingerprint: inputFingerprint,
          catalogFingerprint: catalogFingerprint,
          promptVersion: promptVersion,
        );
      }
      await expectLater(
        store.incrementBackendInvocationCount(
          requestId: 'staging-request',
          inputFingerprint: inputFingerprint,
          catalogFingerprint: catalogFingerprint,
          promptVersion: promptVersion,
        ),
        throwsA(isA<PersonalScheduleAiInvocationLimitException>()),
      );

      final resumed = await store.prepareStaging(
        requestId: 'staging-request',
        inputFingerprint: inputFingerprint,
        catalogFingerprint: catalogFingerprint,
        promptVersion: promptVersion,
      );
      expect(resumed.invocationCount, 0);
      expect(resumed.chunks['meal:1'], chunk);
      expect(
        resumed.chunkSources['meal:1'],
        PlanGenerationSource.localFallback,
      );

      final changedInput = await store.prepareStaging(
        requestId: 'staging-request',
        inputFingerprint: 'changed-input-hash',
        catalogFingerprint: catalogFingerprint,
        promptVersion: promptVersion,
      );
      expect(changedInput.chunks, isEmpty);
    },
  );

  test('committed days remain in SQLite after failure and resume', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(UsersTable.createTable);
    await db.insert(UsersTable.tableName, {'id': 'daily-user'});
    await db.execute(MealPlansTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(PersonalScheduleAiRequestsTable.createTable);
    await db.execute(PersonalScheduleAiStagingTable.createTable);

    final store = LocalPersonalScheduleAiRequestStore(databaseOverride: db);
    final startDate = DateTime(2026, 10, 13);
    const requestId = 'daily-request';
    await store.markGenerating(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
    );

    final dayOneMeals = _mealsForDay(startDate, 1);
    final dayOneSchedule = _scheduleForDay(startDate, 1);
    await db.insert(
      MealPlansTable.tableName,
      _mealsForDay(startDate, 99).first.copyWith(id: 'manual-meal').toMap(),
    );
    await db.insert(
      LifestyleScheduleItemsTable.tableName,
      _scheduleForDay(
        startDate,
        99,
      ).first.copyWith(id: 'manual-schedule', sourceType: 'custom').toMap(),
    );
    await store.saveGeneratedPlanDay(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
      day: 1,
      meals: dayOneMeals,
      schedule: dayOneSchedule,
      replaceExistingDay: false,
      mealCount: 5,
      exerciseCount: 2,
      scheduleItemCount: 11,
      generationSource: PlanGenerationSource.localFallback,
    );
    await store.markFailed(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
      errorCode: 'temporary_generation_error',
    );

    expect(
      await db.query(
        MealPlansTable.tableName,
        where: 'plan_date = ?',
        whereArgs: ['2026-10-13'],
      ),
      hasLength(6),
    );
    expect(
      await db.query(
        LifestyleScheduleItemsTable.tableName,
        where: 'schedule_date = ?',
        whereArgs: ['2026-10-13'],
      ),
      hasLength(12),
    );
    final failed = await store.findByRequestId(requestId);
    expect(failed?.status, GeneratedPlanRequestStatuses.failed);
    expect(failed?.mealCount, 5);
    expect(failed?.exerciseCount, 2);
    expect(failed?.scheduleItemCount, 11);
    expect(failed?.generationSource, PlanGenerationSource.localFallback);

    await store.markGenerating(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
    );
    final dayTwoDate = startDate.add(const Duration(days: 1));
    final dayTwoMeals = _mealsForDay(dayTwoDate, 2);
    final dayTwoSchedule = _scheduleForDay(dayTwoDate, 2);
    await store.saveGeneratedPlanDay(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
      day: 2,
      meals: dayTwoMeals,
      schedule: dayTwoSchedule,
      replaceExistingDay: true,
      mealCount: 10,
      exerciseCount: 4,
      scheduleItemCount: 22,
      generationSource: PlanGenerationSource.localFallback,
    );
    final meals = [...dayOneMeals, ...dayTwoMeals];
    final schedule = [...dayOneSchedule, ...dayTwoSchedule];
    await store.commitGeneratedPlan(
      requestId: requestId,
      userId: 'daily-user',
      actorMode: GeneratedPlanActorModes.initialGuest,
      startDate: startDate,
      days: 2,
      meals: meals,
      schedule: schedule,
      generationSource: PlanGenerationSource.localFallback,
      markGuestInitialPlanUsed: true,
    );

    final succeeded = await store.findByRequestId(requestId);
    expect(succeeded?.isSucceeded, isTrue);
    expect(succeeded?.mealCount, 10);
    expect(succeeded?.exerciseCount, 4);
    expect(succeeded?.scheduleItemCount, 22);
    expect(await db.query(MealPlansTable.tableName), hasLength(11));
    expect(
      await db.query(LifestyleScheduleItemsTable.tableName),
      hasLength(23),
    );
    final user = await db.query(UsersTable.tableName);
    expect(user.single['guest_initial_plan_used'], 1);
  });
}

List<MealPlanModel> _mealsForDay(DateTime date, int day) {
  final dateKey = _dateKey(date);
  return [
    for (var order = 1; order <= 5; order++)
      MealPlanModel(
        id: 'meal-$day-$order',
        userId: 'daily-user',
        planDate: dateKey,
        mealType: 'meal_$order',
        mealName: 'Meal $order',
        description: '',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        waterMl: 0,
        mealOrder: order,
        isCompleted: false,
        aiGenerated: true,
        createdAt: '2026-10-13T00:00:00.000',
        updatedAt: '2026-10-13T00:00:00.000',
      ),
  ];
}

List<LifestyleScheduleItemModel> _scheduleForDay(DateTime date, int day) {
  final dateKey = _dateKey(date);
  return [
    for (var index = 1; index <= 11; index++)
      LifestyleScheduleItemModel(
        id: 'schedule-$day-$index',
        userId: 'daily-user',
        scheduleDate: dateKey,
        startTime: '${index.toString().padLeft(2, '0')}:00',
        title: 'Schedule item $index',
        category: 'health',
        sourceType: index <= 2 ? 'exercise_task' : 'routine_task',
        createdAt: '2026-10-13T00:00:00.000',
        updatedAt: '2026-10-13T00:00:00.000',
      ),
  ];
}

String _dateKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

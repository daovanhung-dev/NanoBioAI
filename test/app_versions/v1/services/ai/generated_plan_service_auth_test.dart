import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/access/subject_access_context.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/data/datasources/exercise_planning_preferences_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_horizon.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/repositories/schedule_horizon_reader.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'generateNextPlan blocks unauthenticated users before AI or DB writes',
    () async {
      final repository = _GuardedDashboardRepository();
      final dailyHealthDatasource = _GuardedDailyHealthDatasource();
      final scheduleDatasource = _GuardedScheduleDatasource();
      final aiService = _GuardedAIService();
      var reminderCalls = 0;

      final service = GeneratedPlanService(
        dashboardRepository: repository,
        dailyHealthDatasource: dailyHealthDatasource,
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {
          reminderCalls++;
        },
      );

      await expectLater(
        service.generateNextPlan(requestId: 'member-request-1', days: 7),
        throwsA(isA<DashboardGenerationAuthRequiredException>()),
      );

      expect(repository.fetchCalls, 0);
      expect(repository.saveCalls, 0);
      expect(dailyHealthDatasource.fetchProfileCalls, 0);
      expect(scheduleDatasource.nextStartCalls, 0);
      expect(scheduleDatasource.getMealSeedCalls, 0);
      expect(scheduleDatasource.seedCalls, 0);
      expect(aiService.mealCalls, 0);
      expect(aiService.exerciseCalls, 0);
      expect(reminderCalls, 0);
    },
  );

  test(
    'generateInitialGuestPlan allows guest before auth quota gates',
    () async {
      final repository = _RecordingDashboardRepository();
      final dailyHealthDatasource = _RecordingDailyHealthDatasource(
        goals: const ['lose_weight'],
        conditions: const ['diabetes'],
      );
      final scheduleDatasource = _RecordingScheduleDatasource();
      final aiService = _RecordingAIService();
      final requestStore = _RecordingRequestStore();
      var reminderCalls = 0;
      final service = GeneratedPlanService(
        dashboardRepository: repository,
        dailyHealthDatasource: dailyHealthDatasource,
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {
          reminderCalls++;
        },
      );

      final result = await service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.days, 1);
      expect(result.mealCount, 5);
      expect(result.exerciseCount, 2);
      expect(result.scheduleItemCount, 11);
      expect(requestStore.commitCalls, 1);
      expect(requestStore.guestInitialPlanUsed, isTrue);
      expect(requestStore.promptVersions, [
        'personal_schedule_v12_unreviewed_wellness_candidates',
      ]);
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(requestStore.savedMealIds, hasLength(5));
      expect(requestStore.savedScheduleIds, hasLength(11));
      expect(requestStore.savedMealIds.every(uuidPattern.hasMatch), isTrue);
      expect(requestStore.savedScheduleIds.every(uuidPattern.hasMatch), isTrue);
      expect(requestStore.committedMealIds, requestStore.savedMealIds);
      expect(requestStore.committedScheduleIds, requestStore.savedScheduleIds);
      expect(repository.fetchCalls, 1);
      expect(repository.saveCalls, 0);
      expect(dailyHealthDatasource.fetchProfileCalls, 1);
      expect(scheduleDatasource.nextStartCalls, 0);
      expect(scheduleDatasource.getMealSeedCalls, 0);
      expect(scheduleDatasource.seedCalls, 0);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(aiService.lastEligibleCodesByType, isNotNull);
      expect(
        aiService.lastEligibleCodesByType!.values.every(
          (codes) => codes.isNotEmpty,
        ),
        isTrue,
      );
      expect(reminderCalls, 1);
    },
  );

  test(
    'initial wellness schedule accepts eligible unreviewed SQLite candidates',
    () async {
      final aiService = _RecordingAIService();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          goals: const ['lose_weight'],
          conditions: const ['diabetes'],
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: _UnreviewedCandidateCatalogDatasource(),
        requestStore: _RecordingRequestStore(),
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      final result = await service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.mealCount, 5);
      expect(aiService.lastEligibleCodesByType, isNotNull);
      expect(
        aiService.lastEligibleCodesByType!.values.every(
          (codes) =>
              codes.length == 5 &&
              codes.every((code) => code.startsWith('nabi_vn_')),
        ),
        isTrue,
      );
    },
  );

  test(
    'single-flight protects concurrent initial guest staging for one user',
    () async {
      final aiService = _BlockingAIService();
      final requestStore = _RecordingRequestStore();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          userId: 'concurrent-guest',
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      final first = service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );
      await aiService.started.future;
      final duplicate = service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(aiService.mealStartCount, 1);
      aiService.release.complete();

      final results = await Future.wait([first, duplicate]);

      expect(results[0].requestId, results[1].requestId);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(requestStore.commitCalls, 1);
    },
  );

  test(
    'seven day plan runs fourteen ordered AI chunks before commit',
    () async {
      final requestStore = _RecordingRequestStore();
      final aiService = _RecordingAIService();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _SevenDayCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      final result = await service.generateInitialGuestPlan(
        days: 7,
        startDate: DateTime(2026, 1, 2),
        requestId: 'guest-seven-day-plan',
      );

      expect(result.mealCount, 35);
      expect(result.exerciseCount, 14);
      expect(result.scheduleItemCount, 77);
      expect(aiService.callOrder, [
        for (var day = 1; day <= 7; day++) ...['meal:$day', 'exercise:$day'],
      ]);
      expect(requestStore.commitCalls, 1);
      expect(
        requestStore.stagedChunks.containsKey('guest-seven-day-plan'),
        isFalse,
      );
    },
  );

  test(
    'splits only the failed meal day into slots and resumes full days afterward',
    () async {
      final requestStore = _RecordingRequestStore();
      final aiService = _RecordingAIService()..failuresRemainingByDay[1] = 1;
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _SevenDayCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      final result = await service.generateInitialGuestPlan(
        days: 2,
        startDate: DateTime(2026, 1, 2),
        requestId: 'guest-split-meal-day',
      );

      expect(result.mealCount, 10);
      expect(result.exerciseCount, 4);
      expect(aiService.callOrder, [
        'meal:1',
        for (final slot in MealPlanAiNormalizer.mealSlots)
          'meal_slot:1:${slot.type}',
        'exercise:1',
        'meal:2',
        'exercise:2',
      ]);
      expect(requestStore.dailyCommitCalls, 2);
      expect(requestStore.commitCalls, 1);
    },
  );

  test('reports schedule progress only after each day is saved', () async {
    final requestStore = _RecordingRequestStore();
    final aiService = _RecordingAIService();
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      catalogDatasource: const _SevenDayCatalogDatasource(),
      requestStore: requestStore,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: const _FakeScheduleHorizonReader(),
      currentUserId: () => null,
      scheduleReminders: () async {},
    );
    final reports = <GeneratedPlanProgress>[];

    await service.generateInitialGuestPlan(
      days: 2,
      startDate: DateTime(2026, 1, 2),
      requestId: 'guest-plan-progress',
      onProgress: (progress) {
        reports.add(progress);
        expect(requestStore.committedDays, progress.savedDays);
      },
    );

    expect(reports.map((progress) => progress.savedDays).toList(), [
      [1],
      [1, 2],
    ]);
    expect(reports.map((progress) => progress.percentComplete).toList(), [
      50,
      100,
    ]);
  });

  test(
    'reports previously saved days immediately when generation resumes',
    () async {
      const requestId = 'guest-plan-progress-resume';
      final requestStore = _RecordingRequestStore();
      final aiService = _RecordingAIService()
        ..failuresRemainingByDay[2] = 1
        ..failSlotOnceFor = 'lunch';
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _SevenDayCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      await expectLater(
        service.generateInitialGuestPlan(
          days: 2,
          startDate: DateTime(2026, 1, 2),
          requestId: requestId,
        ),
        throwsFormatException,
      );
      expect(requestStore.committedDays, [1]);

      final resumedReports = <GeneratedPlanProgress>[];
      await service.generateInitialGuestPlan(
        days: 2,
        startDate: DateTime(2026, 1, 2),
        requestId: requestId,
        onProgress: resumedReports.add,
      );

      expect(resumedReports.first.savedDays, [1]);
      expect(resumedReports.first.percentComplete, 50);
      expect(resumedReports.last.savedDays, [1, 2]);
      expect(resumedReports.last.percentComplete, 100);
    },
  );

  test('resumes a failed meal slot without regenerating the day', () async {
    const requestId = 'guest-resume-meal-slot';
    final requestStore = _RecordingRequestStore();
    final aiService = _RecordingAIService()
      ..failuresRemainingByDay[1] = 1
      ..failSlotOnceFor = 'lunch';
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      catalogDatasource: const _SevenDayCatalogDatasource(),
      requestStore: requestStore,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: const _FakeScheduleHorizonReader(),
      currentUserId: () => null,
      scheduleReminders: () async {},
    );

    await expectLater(
      service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
        requestId: requestId,
      ),
      throwsFormatException,
    );

    expect(requestStore.stagedChunks[requestId]?.keys.toSet(), {
      'meal_slot:1:breakfast',
      'meal_slot:1:morning_snack',
    });
    expect(requestStore.dailyCommitCalls, 0);

    final result = await service.generateInitialGuestPlan(
      days: 1,
      startDate: DateTime(2026, 1, 2),
      requestId: requestId,
    );

    expect(result.mealCount, 5);
    expect(aiService.callOrder, [
      'meal:1',
      'meal_slot:1:breakfast',
      'meal_slot:1:morning_snack',
      'meal_slot:1:lunch',
      'meal_slot:1:lunch',
      'meal_slot:1:afternoon_snack',
      'meal_slot:1:dinner',
      'exercise:1',
    ]);
    expect(requestStore.dailyCommitCalls, 1);
    expect(requestStore.commitCalls, 1);
  });

  test(
    'empty local meal catalog fails without partial schedule writes',
    () async {
      final logs = <String>[];
      TerminalLogSink.setTestWriter(logs.add);
      addTearDown(() => TerminalLogSink.setTestWriter(null));
      final repository = _RecordingDashboardRepository();
      final scheduleDatasource = _RecordingScheduleDatasource();
      final aiService = _RecordingAIService();
      final requestStore = _RecordingRequestStore();
      final service = GeneratedPlanService(
        dashboardRepository: repository,
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _EmptyMealsCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      await expectLater(
        service.generateInitialGuestPlan(
          days: 1,
          startDate: DateTime(2026, 1, 2),
        ),
        throwsStateError,
      );

      expect(repository.saveCalls, 0);
      expect(scheduleDatasource.seedCalls, 0);
      expect(aiService.mealCalls, 0);
      expect(aiService.exerciseCalls, 0);
      expect(requestStore.commitCalls, 0);
      expect(requestStore.failedCalls, 1);
      final output = logs.join('\n');
      expect(output, contains('stage=load_catalog'));
      expect(output, contains('errorCode=invalid_generation'));
      expect(output, contains('errorType=StateError'));
      expect(output, contains('StackTrace:'));
    },
  );

  test(
    'generateInitialGuestPlan retries same request without AI duplication',
    () async {
      final repository = _RecordingDashboardRepository();
      final dailyHealthDatasource = _RecordingDailyHealthDatasource();
      final scheduleDatasource = _RecordingScheduleDatasource();
      final aiService = _RecordingAIService();
      final requestStore = _RecordingRequestStore();

      final service = GeneratedPlanService(
        dashboardRepository: repository,
        dailyHealthDatasource: dailyHealthDatasource,
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      await service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
        requestId: 'guest-request-1',
      );
      final retried = await service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
        requestId: 'guest-request-1',
      );

      expect(retried.reusedExistingRequest, isTrue);
      expect(retried.generationSource, PlanGenerationSource.ai);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(requestStore.commitCalls, 1);
    },
  );

  test(
    'generateInitialGuestPlan blocks a second guest request before AI',
    () async {
      final requestStore = _RecordingRequestStore();
      final aiService = _RecordingAIService();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );

      await service.generateInitialGuestPlan(
        days: 1,
        startDate: DateTime(2026, 1, 2),
        requestId: 'guest-request-1',
      );

      await expectLater(
        service.generateInitialGuestPlan(
          days: 1,
          startDate: DateTime(2026, 1, 3),
          requestId: 'guest-request-2',
        ),
        throwsA(isA<GuestInitialPlanAlreadyUsedException>()),
      );

      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(requestStore.commitCalls, 1);
    },
  );

  test('generateNextPlan blocks quota denied members before AI', () async {
    final requestStore = _RecordingRequestStore();
    final quotaGateway = _RecordingQuotaGateway(allowed: false);
    final aiService = _RecordingAIService();
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(userId: 'auth-user-1'),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(
        userId: 'auth-user-1',
      ),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      catalogDatasource: const _FakeCatalogDatasource(),
      requestStore: requestStore,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: const _FakeScheduleHorizonReader(),
      quotaGateway: quotaGateway,
      currentUserId: () => 'auth-user-1',
      scheduleReminders: () async {},
    );

    await expectLater(
      service.generateNextPlan(
        requestId: 'member-request-1',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      ),
      throwsA(isA<PersonalScheduleQuotaExceededException>()),
    );

    expect(quotaGateway.checkCalls, 1);
    expect(quotaGateway.commitCalls, 0);
    expect(aiService.mealCalls, 0);
    expect(aiService.exerciseCalls, 0);
    expect(requestStore.generatingCalls, 0);
    expect(requestStore.commitCalls, 0);
  });

  test(
    'generateNextPlan commits quota only after successful transaction',
    () async {
      final requestStore = _RecordingRequestStore();
      final quotaGateway = _RecordingQuotaGateway();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(
          userId: 'auth-user-1',
        ),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          userId: 'auth-user-1',
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: _RecordingAIService(),
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        quotaGateway: quotaGateway,
        currentUserId: () => 'auth-user-1',
        scheduleReminders: () async {},
      );

      final result = await service.generateNextPlan(
        requestId: 'member-request-1',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.scheduleItemCount, 11);
      expect(requestStore.generatingCalls, 1);
      expect(requestStore.commitCalls, 1);
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 1);
    },
  );

  test(
    'member AI plan commits quota once and survives reminder failure',
    () async {
      final requestStore = _RecordingRequestStore();
      final quotaGateway = _RecordingQuotaGateway();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(
          userId: 'auth-user-1',
        ),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          userId: 'auth-user-1',
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: _RecordingAIService(),
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        quotaGateway: quotaGateway,
        currentUserId: () => 'auth-user-1',
        scheduleReminders: () async {
          throw StateError('notification scheduling failed');
        },
      );

      final result = await service.generateNextPlan(
        requestId: 'member-ai-plan',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );
      final replay = await service.generateNextPlan(
        requestId: 'member-ai-plan',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.generationSource, PlanGenerationSource.ai);
      expect(replay.reusedExistingRequest, isTrue);
      expect(replay.generationSource, PlanGenerationSource.ai);
      expect(requestStore.commitCalls, 1);
      expect(
        requestStore.records['member-ai-plan']?.generationSource,
        PlanGenerationSource.ai,
      );
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 1);
    },
  );

  test(
    'generateNextPlan falls back locally after AI failure without quota commit',
    () async {
      final requestStore = _RecordingRequestStore();
      final quotaGateway = _RecordingQuotaGateway();
      final aiService = _FailingExerciseAIService();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(
          userId: 'auth-user-1',
        ),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          userId: 'auth-user-1',
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        quotaGateway: quotaGateway,
        currentUserId: () => 'auth-user-1',
        scheduleReminders: () async {},
      );

      final result = await service.generateNextPlan(
        requestId: 'member-request-1',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.generationSource, PlanGenerationSource.localFallback);
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(requestStore.generatingCalls, 1);
      expect(requestStore.failedCalls, 0);
      expect(requestStore.commitCalls, 1);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
    },
  );

  test(
    'AI daily-call failure falls back and persists a complete day',
    () async {
      final requestStore = _RecordingRequestStore();
      final aiService = _FailOnceExerciseAIService();
      final scheduleDatasource = _RecordingScheduleDatasource();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(),
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => null,
        scheduleReminders: () async {},
      );
      final startDate = DateTime(2026, 1, 2);

      final result = await service.generateInitialGuestPlan(
        requestId: 'resume-guest-plan',
        days: 1,
        startDate: startDate,
      );

      expect(result.mealCount, 5);
      expect(result.exerciseCount, 2);
      expect(result.generationSource, PlanGenerationSource.localFallback);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(requestStore.dailyCommitCalls, 1);
      expect(requestStore.committedDays, [1]);
      expect(requestStore.commitCalls, 1);
      expect(
        requestStore.stagedChunks.containsKey('resume-guest-plan'),
        isFalse,
      );
    },
  );

  test('member plan skips AI quota for local fallback', () async {
    final requestStore = _RecordingRequestStore();
    final aiService = _FailOnceExerciseAIService();
    final quotaGateway = _RecordingQuotaGateway();
    final horizon = _MutableScheduleHorizonReader(
      nextStartDate: DateTime(2026, 1, 2),
    );
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(userId: 'auth-user-1'),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(
        userId: 'auth-user-1',
      ),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      catalogDatasource: const _FakeCatalogDatasource(),
      requestStore: requestStore,
      quotaGateway: quotaGateway,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: horizon,
      currentUserId: () => 'auth-user-1',
      scheduleReminders: () async {},
    );

    final result = await service.generateNextPlan(
      requestId: 'member-attempt-1',
      days: 1,
    );

    expect(result.requestId, 'member-attempt-1');
    expect(result.startDate, DateTime(2026, 1, 2));
    expect(result.generationSource, PlanGenerationSource.localFallback);
    expect(aiService.mealCalls, 1);
    expect(aiService.exerciseCalls, 1);
    expect(quotaGateway.checkCalls, 1);
    expect(quotaGateway.commitCalls, 0);
    expect(requestStore.dailyCommitCalls, 1);
    expect(requestStore.commitCalls, 1);
  });

  test('generateNextPlan blocks active horizon before quota and AI', () async {
    final quotaGateway = _RecordingQuotaGateway();
    final aiService = _RecordingAIService();
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(userId: 'active-user'),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(
        userId: 'active-user',
      ),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      requestStore: _RecordingRequestStore(),
      quotaGateway: quotaGateway,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: const _FixedScheduleHorizonReader(
        remainingDays: 2,
      ),
      currentUserId: () => 'active-user',
      scheduleReminders: () async {},
    );

    await expectLater(
      service.generateNextPlan(requestId: 'active-request', days: 1),
      throwsA(
        isA<PersonalScheduleStillActiveException>().having(
          (error) => error.remainingDays,
          'remainingDays',
          2,
        ),
      ),
    );
    expect(quotaGateway.checkCalls, 0);
    expect(aiService.mealCalls, 0);
  });

  test('malformed horizon fails closed before quota and AI', () async {
    final quotaGateway = _RecordingQuotaGateway();
    final aiService = _RecordingAIService();
    final service = GeneratedPlanService(
      dashboardRepository: _RecordingDashboardRepository(userId: 'bad-user'),
      dailyHealthDatasource: _RecordingDailyHealthDatasource(
        userId: 'bad-user',
      ),
      scheduleDatasource: _RecordingScheduleDatasource(),
      aiService: aiService,
      nutritionProfileDatasource: const _FakeNutritionProfileLocalDatasource(),
      exercisePreferencesDatasource:
          const _FakeExercisePlanningPreferencesDatasource(),
      requestStore: _RecordingRequestStore(),
      quotaGateway: quotaGateway,
      routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
      scheduleHorizonReader: const _ThrowingScheduleHorizonReader(),
      currentUserId: () => 'bad-user',
      scheduleReminders: () async {},
    );

    await expectLater(
      service.generateNextPlan(requestId: 'bad-request', days: 1),
      throwsA(isA<ScheduleHorizonDataException>()),
    );
    expect(quotaGateway.checkCalls, 0);
    expect(aiService.mealCalls, 0);
  });

  test(
    'single-flight shares one generation across concurrent requests',
    () async {
      final quotaGateway = _RecordingQuotaGateway();
      final aiService = _BlockingAIService();
      final requestStore = _RecordingRequestStore();
      final service = GeneratedPlanService(
        dashboardRepository: _RecordingDashboardRepository(
          userId: 'concurrent-user',
        ),
        dailyHealthDatasource: _RecordingDailyHealthDatasource(
          userId: 'concurrent-user',
        ),
        scheduleDatasource: _RecordingScheduleDatasource(),
        aiService: aiService,
        nutritionProfileDatasource:
            const _FakeNutritionProfileLocalDatasource(),
        exercisePreferencesDatasource:
            const _FakeExercisePlanningPreferencesDatasource(),
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        quotaGateway: quotaGateway,
        routinePreferencesRepository: _FakeRoutinePreferencesRepository(),
        scheduleHorizonReader: const _FakeScheduleHorizonReader(),
        currentUserId: () => 'concurrent-user',
        scheduleReminders: () async {},
      );

      final first = service.generateNextPlan(
        requestId: 'concurrent-request-1',
        days: 1,
      );
      await aiService.started.future;
      final second = service.generateNextPlan(
        requestId: 'concurrent-request-2',
        days: 1,
      );
      aiService.release.complete();
      final results = await Future.wait([first, second]);

      expect(results[0].requestId, 'concurrent-request-1');
      expect(results[1].requestId, 'concurrent-request-1');
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 1);
      expect(requestStore.commitCalls, 1);
      expect(aiService.mealCalls, 1);
    },
  );

  test('requireAuthenticatedGeneratedPlanUser rejects missing user id', () {
    expect(
      () => requireAuthenticatedGeneratedPlanUser(null),
      throwsA(isA<DashboardGenerationAuthRequiredException>()),
    );
    expect(
      () => requireAuthenticatedGeneratedPlanUser('  '),
      throwsA(isA<DashboardGenerationAuthRequiredException>()),
    );
    expect(
      () => requireAuthenticatedGeneratedPlanUser('auth-user-1'),
      returnsNormally,
    );
  });
}

class _FakeRoutinePreferencesRepository
    implements DailyRoutinePreferencesRepository {
  final preferences = DailyRoutinePreferences.defaults();

  @override
  Future<DailyRoutinePreferences?> loadForCurrentUser() async => preferences;

  @override
  Future<DailyRoutinePreferences?> loadForUser(String userId) async =>
      preferences;

  @override
  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences) async {}

  @override
  Future<void> saveForUser(
    String userId,
    DailyRoutinePreferences preferences,
  ) async {}
}

class _FakeExercisePlanningPreferencesDatasource
    extends ExercisePlanningPreferencesLocalDatasource {
  const _FakeExercisePlanningPreferencesDatasource();

  @override
  Future<ExercisePlanningPreferences> loadForUser(String userId) async =>
      const ExercisePlanningPreferences();
}

class _FakeNutritionProfileLocalDatasource
    extends NutritionProfileLocalDatasource {
  const _FakeNutritionProfileLocalDatasource();

  @override
  Future<NutritionProfileEntity> load(String userId) async =>
      NutritionProfileEntity.empty(userId);
}

class _FakeScheduleHorizonReader implements ScheduleHorizonReader {
  const _FakeScheduleHorizonReader();

  @override
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  }) async {
    return ScheduleHorizon(
      lastScheduledDate: null,
      remainingDays: 0,
      nextStartDate: DateTime(2026, 1, 2),
    );
  }
}

class _FixedScheduleHorizonReader implements ScheduleHorizonReader {
  final int remainingDays;

  const _FixedScheduleHorizonReader({required this.remainingDays});

  @override
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  }) async {
    return ScheduleHorizon(
      lastScheduledDate: today.add(Duration(days: remainingDays - 1)),
      remainingDays: remainingDays,
      nextStartDate: today.add(Duration(days: remainingDays)),
    );
  }
}

class _MutableScheduleHorizonReader implements ScheduleHorizonReader {
  DateTime nextStartDate;

  _MutableScheduleHorizonReader({required this.nextStartDate});

  @override
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  }) async {
    return ScheduleHorizon(
      lastScheduledDate: null,
      remainingDays: 0,
      nextStartDate: nextStartDate,
    );
  }
}

class _ThrowingScheduleHorizonReader implements ScheduleHorizonReader {
  const _ThrowingScheduleHorizonReader();

  @override
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  }) {
    throw const ScheduleHorizonDataException();
  }
}

class _RecordingDashboardRepository implements DashboardRepository {
  final String userId;
  int fetchCalls = 0;
  int saveCalls = 0;

  _RecordingDashboardRepository({this.userId = 'guest-1'});

  @override
  Future<DashboardEntity> fetchDashboard({
    SubjectAccessContext? subjectAccess,
  }) async {
    fetchCalls++;
    return DashboardEntity(
      userId: userId,
      fullName: 'NabiGuest',
      email: 'guest@example.com',
      phone: '',
      gender: 'female',
      birthYear: 1995,
      occupation: 'office',
      heightCm: 165,
      weightKg: 55,
      bmi: 20.2,
      goals: ['overall_health'],
      conditions: [],
      habits: [],
      sleepQuality: 'good',
      activityLevel: 'moderate',
      waterPerDay: '2l',
      allergyName: '',
      allergyNote: '',
      treatmentName: '',
      medicationName: '',
      treatmentNote: '',
      concernText: '',
      surveyAnswers: {},
    );
  }

  @override
  Future<void> saveMealPlan(List<MealPlanModel> mealPlans) async {
    saveCalls++;
  }
}

class _RecordingDailyHealthDatasource
    extends DailyHealthTrackingLocalDatasource {
  final String userId;
  final List<String> goals;
  final List<String> conditions;
  int fetchProfileCalls = 0;

  _RecordingDailyHealthDatasource({
    this.userId = 'guest-1',
    this.goals = const [],
    this.conditions = const [],
  });

  @override
  Future<DailyHealthProfileEntity> fetchLatestProfile() async {
    fetchProfileCalls++;
    return DailyHealthProfileEntity(
      userId: userId,
      fullName: 'NabiGuest',
      goals: goals,
      conditions: conditions,
      habits: [],
      sleepQuality: 'good',
      activityLevel: 'moderate',
      waterPerDay: '2l',
    );
  }
}

class _RecordingRequestStore implements PersonalScheduleAiRequestStore {
  final records = <String, PersonalScheduleAiRequestRecord>{};
  final savedMealIds = <String>[];
  final savedScheduleIds = <String>[];
  final promptVersions = <String>[];
  final committedMealIds = <String>[];
  final committedScheduleIds = <String>[];
  final stagedChunks = <String, Map<String, List<Map<String, dynamic>>>>{};
  final stagedSources = <String, Map<String, PlanGenerationSource>>{};
  final _stageFingerprints = <String, (String, String, String)>{};
  final _invocationCounts = <String, int>{};
  final committedDays = <int>[];
  var guestInitialPlanUsed = false;
  var generatingCalls = 0;
  var failedCalls = 0;
  var commitCalls = 0;
  var dailyCommitCalls = 0;

  @override
  Future<PersonalScheduleAiRequestRecord?> findByRequestId(
    String requestId,
  ) async {
    return records[requestId];
  }

  @override
  Future<bool> isGuestInitialPlanUsed(String userId) async {
    return guestInitialPlanUsed;
  }

  @override
  Future<String?> findIncompleteRequestId({
    required String userId,
    required String actorMode,
    DateTime? startDate,
    required int days,
  }) async {
    for (final record in records.values) {
      if (record.userId == userId &&
          record.actorMode == actorMode &&
          record.days == days &&
          (startDate == null || record.startDate == startDate) &&
          !record.isSucceeded) {
        return record.requestId;
      }
    }
    return null;
  }

  @override
  Future<GeneratedPlanStagingSnapshot> prepareStaging({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  }) async {
    promptVersions.add(promptVersion);
    final next = (inputFingerprint, catalogFingerprint, promptVersion);
    if (_stageFingerprints[requestId] != next) {
      stagedChunks.remove(requestId);
      stagedSources.remove(requestId);
      _stageFingerprints[requestId] = next;
    }
    _invocationCounts[requestId] = 0;
    final savedChunks =
        stagedChunks[requestId] ?? const <String, List<Map<String, dynamic>>>{};
    return GeneratedPlanStagingSnapshot(
      invocationCount: 0,
      chunks: {
        for (final entry in savedChunks.entries)
          entry.key: entry.value
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
      },
      chunkSources: Map<String, PlanGenerationSource>.of(
        stagedSources[requestId] ?? const {},
      ),
    );
  }

  @override
  Future<int> incrementBackendInvocationCount({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
  }) async {
    if (_stageFingerprints[requestId] !=
        (inputFingerprint, catalogFingerprint, promptVersion)) {
      throw StateError('Staging fingerprint mismatch');
    }
    final count = (_invocationCounts[requestId] ?? 0) + 1;
    if (count >
        LocalPersonalScheduleAiRequestStore.maxBackendInvocationsPerSession) {
      throw const PersonalScheduleAiInvocationLimitException();
    }
    _invocationCounts[requestId] = count;
    return count;
  }

  @override
  Future<void> saveStagedChunk({
    required String requestId,
    required String inputFingerprint,
    required String catalogFingerprint,
    required String promptVersion,
    required String chunkKey,
    required List<Map<String, dynamic>> payload,
    PlanGenerationSource source = PlanGenerationSource.ai,
  }) async {
    if (_stageFingerprints[requestId] !=
        (inputFingerprint, catalogFingerprint, promptVersion)) {
      throw StateError('Staging fingerprint mismatch');
    }
    stagedChunks.putIfAbsent(requestId, () => {})[chunkKey] = payload
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    stagedSources.putIfAbsent(requestId, () => {})[chunkKey] = source;
  }

  @override
  Future<void> saveGeneratedPlanDay({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required int day,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required bool replaceExistingDay,
    required int mealCount,
    required int exerciseCount,
    required int scheduleItemCount,
    required PlanGenerationSource generationSource,
  }) async {
    dailyCommitCalls++;
    committedDays.add(day);
    savedMealIds.addAll(meals.map((meal) => meal.id));
    savedScheduleIds.addAll(schedule.map((item) => item.id));
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.generating,
      startDate: startDate,
      days: days,
      mealCount: mealCount,
      exerciseCount: exerciseCount,
      scheduleItemCount: scheduleItemCount,
      generationSource: generationSource,
    );
  }

  @override
  Future<void> markGenerating({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
  }) async {
    generatingCalls++;
    final previous = records[requestId];
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.generating,
      startDate: startDate,
      days: days,
      mealCount: previous?.mealCount ?? 0,
      exerciseCount: previous?.exerciseCount ?? 0,
      scheduleItemCount: previous?.scheduleItemCount ?? 0,
      generationSource:
          previous?.generationSource ?? PlanGenerationSource.unknown,
    );
  }

  @override
  Future<void> markFailed({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required String errorCode,
  }) async {
    failedCalls++;
    final previous = records[requestId];
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.failed,
      startDate: startDate,
      days: days,
      mealCount: previous?.mealCount ?? 0,
      exerciseCount: previous?.exerciseCount ?? 0,
      scheduleItemCount: previous?.scheduleItemCount ?? 0,
      generationSource:
          previous?.generationSource ?? PlanGenerationSource.unknown,
      errorCode: errorCode,
    );
  }

  @override
  Future<void> commitGeneratedPlan({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required List<MealPlanModel> meals,
    required List<LifestyleScheduleItemModel> schedule,
    required PlanGenerationSource generationSource,
    required bool markGuestInitialPlanUsed,
  }) async {
    commitCalls++;
    committedMealIds.addAll(meals.map((meal) => meal.id));
    committedScheduleIds.addAll(schedule.map((item) => item.id));
    if (markGuestInitialPlanUsed) {
      guestInitialPlanUsed = true;
    }
    stagedChunks.remove(requestId);
    stagedSources.remove(requestId);
    _stageFingerprints.remove(requestId);
    _invocationCounts.remove(requestId);
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.succeeded,
      startDate: startDate,
      days: days,
      mealCount: meals.length,
      exerciseCount: schedule
          .where((item) => item.sourceType == 'exercise_task')
          .length,
      scheduleItemCount: schedule.length,
      generationSource: generationSource,
    );
  }
}

class _RecordingQuotaGateway implements PersonalScheduleQuotaGateway {
  final bool allowed;
  int checkCalls = 0;
  int commitCalls = 0;

  _RecordingQuotaGateway({this.allowed = true});

  @override
  Future<PersonalScheduleQuotaDecision> checkGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    checkCalls++;
    return allowed
        ? const PersonalScheduleQuotaDecision.allowed()
        : const PersonalScheduleQuotaDecision.denied();
  }

  @override
  Future<void> commitGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    commitCalls++;
  }
}

class _RecordingScheduleDatasource extends LifestyleScheduleLocalDatasource {
  int nextStartCalls = 0;
  int getMealSeedCalls = 0;
  int seedCalls = 0;
  bool? lastReplaceExistingRange;

  @override
  Future<DateTime> getNextGeneratedPlanStartDate({
    required String userId,
    required DateTime fallbackStartDate,
  }) async {
    nextStartCalls++;
    return fallbackStartDate;
  }

  @override
  Future<List<MealPlanModel>> getMealPlansForScheduleSeed({
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    getMealSeedCalls++;
    return _mealPlans(userId: userId, startDate: startDate);
  }

  @override
  Future<void> seedGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    bool requireComplete = false,
    bool replaceExistingRange = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    seedCalls++;
    lastReplaceExistingRange = replaceExistingRange;
  }
}

class _RecordingAIService extends AIService {
  int mealCalls = 0;
  int exerciseCalls = 0;
  Map<String, Set<String>>? lastEligibleCodesByType;
  final callOrder = <String>[];
  final failuresRemainingByDay = <int, int>{};
  String? failSlotOnceFor;

  _RecordingAIService()
    : super(
        textGenerator: ({required modelName, required prompt}) async => '[]',
      );

  @override
  Future<List<Map<String, dynamic>>> generateMealDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    mealCalls++;
    lastEligibleCodesByType = eligibleCodesByType;
    callOrder.add('meal:$day');
    final failuresRemaining = failuresRemainingByDay[day] ?? 0;
    if (failuresRemaining > 0) {
      failuresRemainingByDay[day] = failuresRemaining - 1;
      throw const FormatException('Synthetic invalid full-day response.');
    }
    final usedToday = <String>{};
    return [
      for (final slot in MealPlanAiNormalizer.mealSlots)
        () {
          final candidates =
              catalog
                  .mealsForType(slot.type)
                  .where((item) => !usedToday.contains(item.code))
                  .where(
                    (item) =>
                        eligibleCodesByType == null ||
                        eligibleCodesByType[slot.type]?.contains(item.code) ==
                            true,
                  )
                  .toList()
                ..sort((left, right) {
                  final count = (usedCodeCounts[left.code] ?? 0).compareTo(
                    usedCodeCounts[right.code] ?? 0,
                  );
                  return count != 0 ? count : left.code.compareTo(right.code);
                });
          final chosen = candidates.first;
          usedToday.add(chosen.code);
          return {'day': day, 'meal_type': slot.type, 'meal_code': chosen.code};
        }(),
    ];
  }

  @override
  Future<AIGenerationResult<List<Map<String, dynamic>>>>
  generateMealSlotCodeItemWithSource({
    required DateTime startDate,
    required int day,
    required String mealType,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    required Set<String> dayMealCodes,
    Map<String, Set<String>>? eligibleFallbackCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    mealCalls++;
    callOrder.add('meal_slot:$day:$mealType');
    if (failSlotOnceFor == mealType) {
      failSlotOnceFor = null;
      throw const FormatException('Synthetic invalid meal-slot response.');
    }
    final candidates =
        catalog
            .mealsForType(mealType)
            .where((item) => !dayMealCodes.contains(item.code))
            .toList()
          ..sort((left, right) {
            final count = (usedCodeCounts[left.code] ?? 0).compareTo(
              usedCodeCounts[right.code] ?? 0,
            );
            return count != 0 ? count : left.code.compareTo(right.code);
          });
    return AIGenerationResult(
      value: [
        {'day': day, 'meal_type': mealType, 'meal_code': candidates.first.code},
      ],
      source: PlanGenerationSource.ai,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> generateExerciseDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    exerciseCalls++;
    callOrder.add('exercise:$day');
    final candidates = catalog.exercises.where((item) => item.isActive).toList()
      ..sort((left, right) {
        final count = (usedCodeCounts[left.code] ?? 0).compareTo(
          usedCodeCounts[right.code] ?? 0,
        );
        return count != 0 ? count : left.code.compareTo(right.code);
      });
    return [
      for (final exercise in candidates.take(2))
        {'day': day, 'exercise_code': exercise.code},
    ];
  }

  @override
  Future<List<MealPlanModel>> generateMealPlan({
    AiCatalogBundle? catalogOverride,
    int days = 7,
    required HealthDataInterface healthData,
    required DateTime startDate,
    required String userId,
  }) async {
    mealCalls++;
    return _mealPlans(userId: userId, startDate: startDate);
  }

  @override
  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    exerciseCalls++;
    final date = _dateKey(startDate);
    const now = '2026-01-01T00:00:00.000';
    return const [
      ExerciseTaskModel(
        id: 'exercise-1',
        userId: 'guest-1',
        scheduleDate: '2026-01-02',
        startTime: '06:30',
        endTime: '06:45',
        title: 'Đi bộ nhẹ',
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseTaskModel(
        id: 'exercise-2',
        userId: 'guest-1',
        scheduleDate: '2026-01-02',
        startTime: '17:30',
        endTime: '17:45',
        title: 'Giãn cơ',
        createdAt: now,
        updatedAt: now,
      ),
    ].map((item) => item.copyWith(scheduleDate: date)).toList();
  }

  @override
  Future<AIGenerationResult<List<MealPlanModel>>> generateMealPlanWithSource({
    AiCatalogBundle? catalogOverride,
    int days = 7,
    required HealthDataInterface healthData,
    required DateTime startDate,
    required String userId,
  }) async {
    return AIGenerationResult(
      value: await generateMealPlan(
        catalogOverride: catalogOverride,
        healthData: healthData,
        userId: userId,
        startDate: startDate,
        days: days,
      ),
      source: PlanGenerationSource.ai,
    );
  }

  @override
  Future<AIGenerationResult<List<ExerciseTaskModel>>>
  generateExerciseTasksWithSource({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    return AIGenerationResult(
      value: await generateExerciseTasks(
        profile: profile,
        startDate: startDate,
        days: days,
        catalogOverride: catalogOverride,
        availableTimeWindows: availableTimeWindows,
      ),
      source: PlanGenerationSource.ai,
    );
  }
}

class _FailingExerciseAIService extends _RecordingAIService {
  @override
  Future<List<Map<String, dynamic>>> generateExerciseDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    exerciseCalls++;
    throw StateError('exercise generation failed');
  }
}

class _FailOnceExerciseAIService extends _RecordingAIService {
  var shouldFail = true;

  @override
  Future<List<Map<String, dynamic>>> generateExerciseDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (shouldFail) {
      exerciseCalls++;
      shouldFail = false;
      throw const AIRateLimitedException();
    }
    return super.generateExerciseDayCodeItems(
      startDate: startDate,
      day: day,
      catalog: catalog,
      usedCodeCounts: usedCodeCounts,
      personalization: personalization,
      onBackendInvocation: onBackendInvocation,
    );
  }
}

class _BlockingAIService extends _RecordingAIService {
  final started = Completer<void>();
  final release = Completer<void>();
  var mealStartCount = 0;

  @override
  Future<List<Map<String, dynamic>>> generateMealDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    mealStartCount++;
    if (!started.isCompleted) started.complete();
    await release.future;
    return super.generateMealDayCodeItems(
      startDate: startDate,
      day: day,
      catalog: catalog,
      usedCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleCodesByType,
      personalization: personalization,
      onBackendInvocation: onBackendInvocation,
    );
  }
}

class _FakeCatalogDatasource extends AiCatalogLocalDatasource {
  const _FakeCatalogDatasource();

  @override
  Future<AiCatalogBundle> loadScheduleCatalogBundle() async {
    const now = '2026-01-01T00:00:00.000';
    const retrievedAt = now;
    return AiCatalogBundle(
      meals: [
        MealCatalogItemModel(
          code: 'fake_breakfast',
          mealType: 'breakfast',
          mealName: 'Bữa sáng mẫu',
          description: 'Món mẫu cho test.',
          cookingInstructions: 'Chuẩn bị món mẫu.',
          calories: 300,
          protein: 10,
          carbs: 35,
          fat: 8,
          fiber: 4,
          waterMl: 250,
          createdAt: now,
          updatedAt: now,
        ),
        MealCatalogItemModel(
          code: 'fake_morning_snack',
          mealType: 'morning_snack',
          mealName: 'Bữa phụ sáng mẫu',
          description: 'Món mẫu cho test.',
          cookingInstructions: 'Chuẩn bị món mẫu.',
          calories: 300,
          protein: 10,
          carbs: 35,
          fat: 8,
          fiber: 4,
          waterMl: 250,
          createdAt: now,
          updatedAt: now,
        ),
        MealCatalogItemModel(
          code: 'fake_lunch',
          mealType: 'lunch',
          mealName: 'Bữa trưa mẫu',
          description: 'Món mẫu cho test.',
          cookingInstructions: 'Chuẩn bị món mẫu.',
          calories: 300,
          protein: 10,
          carbs: 35,
          fat: 8,
          fiber: 4,
          waterMl: 250,
          createdAt: now,
          updatedAt: now,
        ),
        MealCatalogItemModel(
          code: 'fake_afternoon_snack',
          mealType: 'afternoon_snack',
          mealName: 'Bữa phụ chiều mẫu',
          description: 'Món mẫu cho test.',
          cookingInstructions: 'Chuẩn bị món mẫu.',
          calories: 300,
          protein: 10,
          carbs: 35,
          fat: 8,
          fiber: 4,
          waterMl: 250,
          createdAt: now,
          updatedAt: now,
        ),
        MealCatalogItemModel(
          code: 'fake_dinner',
          mealType: 'dinner',
          mealName: 'Bữa tối mẫu',
          description: 'Món mẫu cho test.',
          cookingInstructions: 'Chuẩn bị món mẫu.',
          calories: 300,
          protein: 10,
          carbs: 35,
          fat: 8,
          fiber: 4,
          waterMl: 250,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      exercises: [
        ExerciseCatalogItemModel(
          code: 'fake_walk',
          category: 'cardio',
          title: 'Đi bộ nhẹ',
          description: 'Đi bộ với cường độ nhẹ.',
          unit: 'phút',
          encouragement: '',
          minTarget: 5,
          maxTarget: 30,
          defaultTarget: 10,
          intensityLevel: 'light',
          movementAreas: const ['cardio', 'leg'],
          safetyStatus: 'general_wellness_unreviewed',
          createdAt: now,
          updatedAt: now,
        ),
        ExerciseCatalogItemModel(
          code: 'fake_mobility',
          category: 'mobility',
          title: 'Giãn cơ nhẹ',
          description: 'Giãn cơ trong biên độ thoải mái.',
          unit: 'phút',
          encouragement: '',
          minTarget: 5,
          maxTarget: 30,
          defaultTarget: 10,
          intensityLevel: 'light',
          movementAreas: const ['mobility', 'upper_body'],
          safetyStatus: 'general_wellness_unreviewed',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      scheduleTasks: [
        ScheduleTaskCatalogItemModel(
          code: 'routine_wake',
          category: 'routine',
          title: 'Thức dậy',
          description: 'Bắt đầu ngày mới nhẹ nhàng.',
          startTime: '06:00',
          endTime: '06:05',
          targetValue: 1,
          unit: 'lần',
          encouragement: 'Một ngày mới bắt đầu rồi.',
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
        ScheduleTaskCatalogItemModel(
          code: 'routine_water_morning',
          category: 'water',
          title: 'Uống nước buổi sáng',
          description: 'Bổ sung nước sau khi thức dậy.',
          startTime: '06:10',
          endTime: '06:15',
          targetValue: 250,
          unit: 'ml',
          encouragement: 'Một ly nước giúp cơ thể tỉnh táo hơn.',
          sortOrder: 2,
          createdAt: now,
          updatedAt: now,
        ),
        ScheduleTaskCatalogItemModel(
          code: 'routine_sleep_prepare',
          category: 'sleep',
          title: 'Chuẩn bị ngủ',
          description: 'Thả lỏng trước khi ngủ.',
          startTime: '21:30',
          endTime: '21:45',
          targetValue: 1,
          unit: 'lần',
          encouragement: 'Ngủ đủ giúp Nabitheo dõi sức khỏe tốt hơn.',
          sortOrder: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      ingredientEvidenceByName: {
        'yến mạch': FoodIngredientEvidence(
          normalizedName: 'yến mạch',
          queriedName: 'yến mạch',
          sourceFoodId: '',
          description: '',
          dataType: '',
          nutrients: null,
          sourceName: 'Viện Dinh dưỡng Quốc gia',
          sourceUrl:
              'https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham',
          datasetVersion: '',
          retrievedAt: retrievedAt,
          evidenceStatus: 'not_found_or_ambiguous',
        ),
      },
    );
  }
}

class _UnreviewedCandidateCatalogDatasource extends _FakeCatalogDatasource {
  @override
  Future<AiCatalogBundle> loadScheduleCatalogBundle() async {
    final base = await super.loadScheduleCatalogBundle();
    return AiCatalogBundle(
      meals: [
        for (final slot in MealPlanAiNormalizer.mealSlots)
          _unreviewedScheduleCandidate(slot.type),
      ],
      exercises: base.exercises,
      scheduleTasks: base.scheduleTasks,
      ingredientEvidenceByName: base.ingredientEvidenceByName,
    );
  }
}

MealCatalogItemModel _unreviewedScheduleCandidate(String slotType) {
  return MealCatalogItemModel(
    code: 'nabi_vn_candidate_$slotType',
    mealType: 'unclassified',
    mealName: 'Món wellness $slotType',
    description: 'Công thức kiểm thử chưa rà soát.',
    cookingInstructions: 'Nấu chín theo bước đã lưu.',
    calories: 350,
    protein: 12,
    carbs: 40,
    fat: 10,
    fiber: 5,
    waterMl: 0,
    ingredients: const ['nguyên liệu kiểm thử'],
    cookingSteps: const ['Nấu chín theo hướng dẫn.'],
    allergenVerificationStatus: 'unknown',
    nutritionStatus: 'estimated_unverified',
    constraintMetadataStatus: 'awaiting_professional_review',
    metadataStatus: 'ai_generated_needs_review',
    isPlanEligible: false,
    sourceName: MealCatalogItemModel.unreviewedWellnessCandidateSourceName,
    sourceHash: List.filled(64, 'c').join(),
    isActive: true,
    createdAt: '2026-01-01T00:00:00.000',
    updatedAt: '2026-01-01T00:00:00.000',
  );
}

class _SevenDayCatalogDatasource extends _FakeCatalogDatasource {
  const _SevenDayCatalogDatasource();

  @override
  Future<AiCatalogBundle> loadScheduleCatalogBundle() async {
    final base = await super.loadScheduleCatalogBundle();
    return AiCatalogBundle(
      meals: [
        for (final slot in MealPlanAiNormalizer.mealSlots)
          for (var index = 1; index <= 7; index++)
            MealCatalogItemModel(
              code: 'seven_${slot.type}_$index',
              mealType: slot.type,
              mealName: 'Món ${slot.type} $index',
              description: 'Món kiểm thử lịch bảy ngày.',
              cookingInstructions: '',
              calories: 300,
              protein: 10,
              carbs: 35,
              fat: 8,
              fiber: 4,
              waterMl: 250,
              createdAt: '2026-01-01T00:00:00.000',
              updatedAt: '2026-01-01T00:00:00.000',
            ),
      ],
      exercises: [
        for (var index = 1; index <= 4; index++)
          ExerciseCatalogItemModel(
            code: 'seven_exercise_$index',
            category: 'general',
            title: 'Vận động $index',
            description: 'Bài vận động kiểm thử.',
            unit: 'phút',
            encouragement: '',
            minTarget: 5,
            maxTarget: 30,
            defaultTarget: 10,
            intensityLevel: 'light',
            safetyStatus: 'general_wellness_unreviewed',
            createdAt: '2026-01-01T00:00:00.000',
            updatedAt: '2026-01-01T00:00:00.000',
          ),
      ],
      scheduleTasks: base.scheduleTasks,
      ingredientEvidenceByName: base.ingredientEvidenceByName,
    );
  }
}

class _EmptyMealsCatalogDatasource extends _FakeCatalogDatasource {
  const _EmptyMealsCatalogDatasource();

  @override
  Future<AiCatalogBundle> loadScheduleCatalogBundle() async {
    final bundle = await super.loadScheduleCatalogBundle();
    return AiCatalogBundle(
      meals: const [],
      exercises: bundle.exercises,
      scheduleTasks: bundle.scheduleTasks,
      ingredientEvidenceByName: bundle.ingredientEvidenceByName,
    );
  }
}

List<MealPlanModel> _mealPlans({
  required String userId,
  required DateTime startDate,
}) {
  final date = _dateKey(startDate);
  const now = '2026-01-01T00:00:00.000';
  const types = [
    ('breakfast', 'Bữa sáng', 1, '07:00', '07:30'),
    ('morning_snack', 'Bữa phụ sáng', 2, '09:30', '09:45'),
    ('lunch', 'Bữa trưa', 3, '12:00', '12:45'),
    ('afternoon_snack', 'Bữa phụ chiều', 4, '15:30', '15:45'),
    ('dinner', 'Bữa tối', 5, '18:30', '19:15'),
  ];

  return [
    for (final item in types)
      MealPlanModel(
        id: 'meal-${item.$3}',
        userId: userId,
        planDate: date,
        mealType: item.$1,
        mealName: item.$2,
        description: 'Món ăn cân bằng.',
        calories: 300,
        protein: 12,
        carbs: 35,
        fat: 8,
        fiber: 4,
        waterMl: 250,
        mealOrder: item.$3,
        startTime: item.$4,
        endTime: item.$5,
        isCompleted: false,
        aiGenerated: true,
        createdAt: now,
        updatedAt: now,
      ),
  ];
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

class _GuardedDashboardRepository implements DashboardRepository {
  int fetchCalls = 0;
  int saveCalls = 0;

  @override
  Future<DashboardEntity> fetchDashboard({
    SubjectAccessContext? subjectAccess,
  }) async {
    fetchCalls++;
    throw StateError('fetchDashboard should not be called without auth');
  }

  @override
  Future<void> saveMealPlan(List<MealPlanModel> mealPlans) async {
    saveCalls++;
    throw StateError('saveMealPlan should not be called without auth');
  }
}

class _GuardedDailyHealthDatasource extends DailyHealthTrackingLocalDatasource {
  int fetchProfileCalls = 0;

  @override
  Future<DailyHealthProfileEntity> fetchLatestProfile() async {
    fetchProfileCalls++;
    throw StateError('fetchLatestProfile should not be called without auth');
  }
}

class _GuardedScheduleDatasource extends LifestyleScheduleLocalDatasource {
  int nextStartCalls = 0;
  int getMealSeedCalls = 0;
  int seedCalls = 0;

  @override
  Future<DateTime> getNextGeneratedPlanStartDate({
    required String userId,
    required DateTime fallbackStartDate,
  }) async {
    nextStartCalls++;
    throw StateError('getNextGeneratedPlanStartDate should not be called');
  }

  @override
  Future<List<MealPlanModel>> getMealPlansForScheduleSeed({
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    getMealSeedCalls++;
    throw StateError('getMealPlansForScheduleSeed should not be called');
  }

  @override
  Future<void> seedGeneratedSchedule(
    List<LifestyleScheduleItemModel> items, {
    bool requireComplete = false,
    bool replaceExistingRange = false,
    DateTime? startDate,
    int days = 7,
  }) async {
    seedCalls++;
    throw StateError('seedGeneratedSchedule should not be called');
  }
}

class _GuardedAIService extends AIService {
  int mealCalls = 0;
  int exerciseCalls = 0;

  _GuardedAIService()
    : super(
        textGenerator: ({required modelName, required prompt}) async => '[]',
      );

  @override
  Future<List<Map<String, dynamic>>> generateMealDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    mealCalls++;
    throw StateError(
      'generateMealDayCodeItems should not be called without auth',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> generateExerciseDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    exerciseCalls++;
    throw StateError(
      'generateExerciseDayCodeItems should not be called without auth',
    );
  }

  @override
  Future<List<MealPlanModel>> generateMealPlan({
    AiCatalogBundle? catalogOverride,
    int days = 7,
    required HealthDataInterface healthData,
    required DateTime startDate,
    required String userId,
  }) async {
    mealCalls++;
    throw StateError('generateMealPlan should not be called without auth');
  }

  @override
  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    exerciseCalls++;
    throw StateError('generateExerciseTasks should not be called without auth');
  }

  @override
  Future<AIGenerationResult<List<MealPlanModel>>> generateMealPlanWithSource({
    AiCatalogBundle? catalogOverride,
    int days = 7,
    required HealthDataInterface healthData,
    required DateTime startDate,
    required String userId,
  }) async {
    return AIGenerationResult(
      value: await generateMealPlan(
        catalogOverride: catalogOverride,
        healthData: healthData,
        userId: userId,
        startDate: startDate,
        days: days,
      ),
      source: PlanGenerationSource.ai,
    );
  }

  @override
  Future<AIGenerationResult<List<ExerciseTaskModel>>>
  generateExerciseTasksWithSource({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    return AIGenerationResult(
      value: await generateExerciseTasks(
        profile: profile,
        startDate: startDate,
        days: days,
        catalogOverride: catalogOverride,
        availableTimeWindows: availableTimeWindows,
      ),
      source: PlanGenerationSource.ai,
    );
  }
}

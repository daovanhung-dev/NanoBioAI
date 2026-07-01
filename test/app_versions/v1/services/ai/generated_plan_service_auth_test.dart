import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/access/subject_access_context.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';

void main() {
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
      final dailyHealthDatasource = _RecordingDailyHealthDatasource();
      final scheduleDatasource = _RecordingScheduleDatasource();
      final aiService = _RecordingAIService();
      final requestStore = _RecordingRequestStore();
      var reminderCalls = 0;

      final service = GeneratedPlanService(
        dashboardRepository: repository,
        dailyHealthDatasource: dailyHealthDatasource,
        scheduleDatasource: scheduleDatasource,
        aiService: aiService,
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
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
      expect(result.scheduleItemCount, 10);
      expect(requestStore.commitCalls, 1);
      expect(requestStore.guestInitialPlanUsed, isTrue);
      expect(repository.fetchCalls, 1);
      expect(repository.saveCalls, 0);
      expect(dailyHealthDatasource.fetchProfileCalls, 1);
      expect(scheduleDatasource.nextStartCalls, 0);
      expect(scheduleDatasource.getMealSeedCalls, 0);
      expect(scheduleDatasource.seedCalls, 0);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
      expect(reminderCalls, 1);
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
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
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
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
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
      catalogDatasource: const _FakeCatalogDatasource(),
      requestStore: requestStore,
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
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
        quotaGateway: quotaGateway,
        currentUserId: () => 'auth-user-1',
        scheduleReminders: () async {},
      );

      final result = await service.generateNextPlan(
        requestId: 'member-request-1',
        days: 1,
        startDate: DateTime(2026, 1, 2),
      );

      expect(result.scheduleItemCount, 10);
      expect(requestStore.generatingCalls, 1);
      expect(requestStore.commitCalls, 1);
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 1);
    },
  );

  test(
    'generateNextPlan does not commit quota when AI generation fails',
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
        catalogDatasource: const _FakeCatalogDatasource(),
        requestStore: requestStore,
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
        throwsStateError,
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(requestStore.generatingCalls, 1);
      expect(requestStore.failedCalls, 1);
      expect(requestStore.commitCalls, 0);
      expect(aiService.mealCalls, 1);
      expect(aiService.exerciseCalls, 1);
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
  int fetchProfileCalls = 0;

  _RecordingDailyHealthDatasource({this.userId = 'guest-1'});

  @override
  Future<DailyHealthProfileEntity> fetchLatestProfile() async {
    fetchProfileCalls++;
    return DailyHealthProfileEntity(
      userId: userId,
      fullName: 'NabiGuest',
      goals: ['overall_health'],
      conditions: [],
      habits: [],
      sleepQuality: 'good',
      activityLevel: 'moderate',
      waterPerDay: '2l',
    );
  }
}

class _RecordingRequestStore implements PersonalScheduleAiRequestStore {
  final records = <String, PersonalScheduleAiRequestRecord>{};
  var guestInitialPlanUsed = false;
  var generatingCalls = 0;
  var failedCalls = 0;
  var commitCalls = 0;

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
  Future<void> markGenerating({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
  }) async {
    generatingCalls++;
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.generating,
      startDate: startDate,
      days: days,
      mealCount: 0,
      exerciseCount: 0,
      scheduleItemCount: 0,
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
    records[requestId] = PersonalScheduleAiRequestRecord(
      requestId: requestId,
      userId: userId,
      actorMode: actorMode,
      status: GeneratedPlanRequestStatuses.failed,
      startDate: startDate,
      days: days,
      mealCount: 0,
      exerciseCount: 0,
      scheduleItemCount: 0,
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
    required bool replaceExistingRange,
    required bool markGuestInitialPlanUsed,
  }) async {
    commitCalls++;
    if (markGuestInitialPlanUsed) {
      guestInitialPlanUsed = true;
    }
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

  _RecordingAIService()
    : super(
        textGenerator: ({required modelName, required prompt}) async => '[]',
      );

  @override
  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    mealCalls++;
    return _mealPlans(userId: userId, startDate: startDate);
  }

  @override
  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
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
}

class _FailingExerciseAIService extends _RecordingAIService {
  @override
  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    exerciseCalls++;
    throw StateError('exercise generation failed');
  }
}

class _FakeCatalogDatasource extends AiCatalogLocalDatasource {
  const _FakeCatalogDatasource();

  @override
  Future<AiCatalogBundle> loadActiveBundle() async {
    const now = '2026-01-01T00:00:00.000';
    return const AiCatalogBundle(
      meals: [],
      exercises: [],
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
  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    mealCalls++;
    throw StateError('generateMealPlan should not be called without auth');
  }

  @override
  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    exerciseCalls++;
    throw StateError('generateExerciseTasks should not be called without auth');
  }
}

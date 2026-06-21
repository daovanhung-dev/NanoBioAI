import 'package:flutter_test/flutter_test.dart';
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
        service.generateNextPlan(days: 7),
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

class _GuardedDashboardRepository implements DashboardRepository {
  int fetchCalls = 0;
  int saveCalls = 0;

  @override
  Future<DashboardEntity> fetchDashboard() async {
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

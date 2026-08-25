import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/application/nutrition_metrics_engine.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_intelligence_entity.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';

void main() {
  const engine = NutritionMetricsEngine();
  final selectedDate = DateTime(2026, 8, 24);

  test('calculates actual versus planned nutrients deterministically', () {
    final result = engine.analyze(
      selectedDate: selectedDate,
      allLogs: [
        NutritionLogModel(
          id: 'log-1',
          userId: 'user-1',
          foodName: 'Bữa thử nghiệm',
          calories: 600,
          protein: 30,
          carbs: 70,
          fat: 20,
          mealType: 'lunch',
          eatenAt: '2026-08-24T12:00:00',
          nutrition: const {
            'fiber_g': 8,
            'sodium_mg': 700,
            'potassium_mg': 900,
            'calcium_mg': 250,
            'iron_mg': 4,
          },
        ),
      ],
      allMeals: [_meal()],
      healthHistory: const [],
      hasProfileContext: true,
    );

    expect(result.actual.energyKcal, 600);
    expect(result.actual.fiberG, 8);
    expect(result.planned.energyKcal, 1000);
    expect(result.planned.fiberG, 25);
    expect(
      result.coverage.firstWhere((item) => item.code == 'fiber').status,
      NutritionCoverageStatus.low,
    );
    expect(result.dataQuality.richNutritionLogRatio, 1);
  });

  test('missing micronutrients stay unknown instead of becoming zero', () {
    final result = engine.analyze(
      selectedDate: selectedDate,
      allLogs: const [
        NutritionLogModel(
          id: 'log-legacy',
          userId: 'user-1',
          calories: 450,
          protein: 20,
          carbs: 60,
          fat: 14,
          mealType: 'lunch',
          eatenAt: '2026-08-24',
        ),
      ],
      allMeals: [_meal()],
      healthHistory: const [],
    );

    final fiber = result.coverage.firstWhere((item) => item.code == 'fiber');
    expect(fiber.actual, isNull);
    expect(fiber.dataCoverage, 0);
    expect(fiber.status, NutritionCoverageStatus.insufficientData);
  });

  test('builds seven day trend and health context from stored data', () {
    final result = engine.analyze(
      selectedDate: selectedDate,
      allLogs: const [
        NutritionLogModel(
          id: 'log-a',
          userId: 'user-1',
          calories: 500,
          eatenAt: '2026-08-23',
        ),
        NutritionLogModel(
          id: 'log-b',
          userId: 'user-1',
          calories: 700,
          eatenAt: '2026-08-24',
        ),
      ],
      allMeals: const [],
      healthHistory: const [
        HealthTrackingLogModel(
          id: 'health-1',
          userId: 'user-1',
          logDate: '2026-08-24',
          waterMl: 1800,
          sleepHours: 7.5,
          stepsCount: 6500,
          stressLevel: 2,
          createdAt: '2026-08-24T10:00:00Z',
          updatedAt: '2026-08-24T10:00:00Z',
        ),
      ],
    );

    expect(result.sevenDayTrend, hasLength(7));
    expect(result.sevenDayTrend.last.energyKcal, 700);
    expect(result.dataQuality.daysWithLogsInLast7, 2);
    expect(result.healthContext.waterMl, 1800);
    expect(result.healthContext.sleepHours, 7.5);
  });
}

MealPlanModel _meal() {
  return const MealPlanModel(
    id: 'meal-1',
    userId: 'user-1',
    planDate: '2026-08-24',
    mealType: 'lunch',
    mealName: 'Bữa kế hoạch',
    description: '',
    calories: 1000,
    protein: 50,
    carbs: 120,
    fat: 35,
    fiber: 25,
    waterMl: 500,
    sodiumMg: 1500,
    potassiumMg: 2500,
    calciumMg: 700,
    ironMg: 12,
    mealOrder: 2,
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-08-24T00:00:00Z',
    updatedAt: '2026-08-24T00:00:00Z',
  );
}

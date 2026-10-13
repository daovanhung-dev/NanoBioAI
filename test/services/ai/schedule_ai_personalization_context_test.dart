import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/schedule_ai_personalization_context.dart';

void main() {
  test('AI prompts receive safe, structured user personalization only', () {
    const profile = DailyHealthProfileEntity(
      userId: 'private-user-id',
      fullName: 'Private User Name',
      goals: ['lose_weight', 'Giảm cân', 'other_goal', 'private goal note'],
      conditions: [
        'blood_pressure_issue',
        'Huyết áp bất thường',
        'other_condition',
        'private condition note',
      ],
      habits: ['skip_breakfast', 'private habit note'],
      sleepQuality: 'sleep_late',
      activityLevel: 'activity_low',
      waterPerDay: 'water_less_1',
    );
    const dashboard = DashboardEntity(
      userId: 'private-user-id',
      fullName: 'Private User Name',
      email: 'private@example.com',
      phone: '+84000000000',
      gender: 'male',
      birthYear: 2000,
      occupation: 'healthcare',
      heightCm: 170,
      weightKg: 65,
      bmi: 22.5,
      goals: ['Private dashboard goal'],
      conditions: ['Private dashboard condition'],
      habits: ['Private dashboard habit'],
      sleepQuality: 'sleep_late',
      activityLevel: 'activity_low',
      waterPerDay: 'water_less_1',
      allergyName: 'shellfish',
      allergyNote: 'private allergy note',
      treatmentName: 'private treatment',
      medicationName: 'private medication',
      treatmentNote: 'private treatment note',
      concernText: 'private concern',
      surveyAnswers: {'concern_text': 'private survey note'},
    );
    const exercisePreferences = ExercisePlanningPreferences(
      availableEquipment: ['chair', 'private equipment'],
      mobilityLimitations: ['knee', 'other', 'private limitation'],
    );
    final nutritionProfile = NutritionProfileEntity.empty('private-user-id');

    final mealContext = ScheduleAiPersonalizationContext.forMeals(
      profile: profile,
      dashboard: dashboard,
      nutritionProfile: nutritionProfile,
    );
    final exerciseContext = ScheduleAiPersonalizationContext.forExercise(
      profile: profile,
      preferences: exercisePreferences,
      nutritionProfile: nutritionProfile,
    );
    final mealPrompt = MealPlanPrompt.generate(
      startDate: DateTime(2026, 10, 13),
      startDay: 1,
      days: 1,
      catalog: const [],
      usedMealCodeCounts: const {},
      personalization: mealContext,
    );
    final exercisePrompt = ExerciseTasksPrompt.generate(
      startDate: DateTime(2026, 10, 13),
      startDay: 1,
      days: 1,
      catalog: const [],
      usedExerciseCodeCounts: const {},
      personalization: exerciseContext,
    );
    final prompt = '$mealPrompt\n$exercisePrompt';

    expect(prompt, contains('lose_weight'));
    expect(prompt, contains('blood_pressure_issue'));
    expect(prompt, contains('shellfish'));
    expect(prompt, contains('activity_low'));
    expect(prompt, contains('skip_breakfast'));
    expect(prompt, contains('chair'));
    expect(prompt, contains('knee'));

    for (final privateValue in [
      'private-user-id',
      'Private User Name',
      'private@example.com',
      '+84000000000',
      'private goal note',
      'private condition note',
      'private habit note',
      'private allergy note',
      'private treatment',
      'private medication',
      'private concern',
      'private survey note',
      'private equipment',
      'private limitation',
    ]) {
      expect(prompt, isNot(contains(privateValue)));
    }

    expect(jsonEncode(mealContext), contains('Huyết áp bất thường'));
    expect(jsonEncode(exerciseContext), contains('Ít vận động'));
  });
}

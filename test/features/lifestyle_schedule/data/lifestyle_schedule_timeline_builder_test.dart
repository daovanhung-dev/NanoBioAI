import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'package:nano_app/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

void main() {
  const profile = DailyHealthProfileEntity(
    userId: 'u1',
    fullName: 'Test User',
    goals: ['sleep_better'],
    conditions: [],
    habits: [],
    sleepQuality: 'Good',
    activityLevel: 'Light',
    waterPerDay: '1.5-2L',
  );

  test('builds a valid seven-day timeline with seventy tasks', () {
    final startDate = DateTime(2026, 6, 17);
    final schedule = const LifestyleScheduleTimelineBuilder().generate(
      profile: profile,
      meals: _meals(startDate),
      exercises: _exercises(startDate),
      startDate: startDate,
      createdAt: '2026-06-16T08:00:00',
    );

    expect(schedule, hasLength(70));

    final dayItems = schedule
        .where((item) => item.scheduleDate == '2026-06-17')
        .toList();
    expect(dayItems, hasLength(10));
    expect(
      dayItems.where(
        (item) => item.sourceType == LifestyleScheduleSourceTypes.mealPlan,
      ),
      hasLength(5),
    );
    expect(
      dayItems.where(
        (item) => item.sourceType == LifestyleScheduleSourceTypes.exerciseTask,
      ),
      hasLength(2),
    );
    expect(
      dayItems.where(
        (item) => item.sourceType == LifestyleScheduleSourceTypes.aiSchedule,
      ),
      hasLength(3),
    );
    expect(dayItems.map((item) => item.startTime).toList(), [
      '06:00',
      '06:15',
      '07:00',
      '08:00',
      '09:30',
      '12:00',
      '15:30',
      '17:30',
      '18:30',
      '21:00',
    ]);
  });
}

List<MealPlanModel> _meals(DateTime startDate) {
  return const MealPlanAiNormalizer().normalize(
    items: _mealItems(DateTime(2025, 1, 1)),
    userId: 'u1',
    startDate: startDate,
    createdAt: '2026-06-16T08:00:00',
  );
}

List<Map<String, Object?>> _mealItems(DateTime aiStartDate) {
  return [
    for (var day = 0; day < 7; day++)
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'plan_date': _dateKey(aiStartDate.add(Duration(days: day))),
          'meal_type': slot.type,
          'meal_name': 'Meal',
          'description': 'Description',
          'calories': 300,
          'protein': 10,
          'carbs': 30,
          'fat': 8,
          'fiber': 4,
          'water_ml': 300,
          'cooking_instructions': 'Cook',
        },
  ];
}

List<ExerciseTaskModel> _exercises(DateTime startDate) {
  return [
    for (var day = 0; day < 7; day++) ...[
      ExerciseTaskModel(
        id: 'exercise-${day + 1}-1',
        userId: 'u1',
        scheduleDate: _dateKey(startDate.add(Duration(days: day))),
        startTime: '08:00',
        endTime: '08:25',
        title: 'Walk',
        description: 'Walk',
        targetValue: 1,
        unit: 'lan',
        encouragement: 'Good',
        createdAt: '2026-06-16T08:00:00',
        updatedAt: '2026-06-16T08:00:00',
      ),
      ExerciseTaskModel(
        id: 'exercise-${day + 1}-2',
        userId: 'u1',
        scheduleDate: _dateKey(startDate.add(Duration(days: day))),
        startTime: '17:30',
        endTime: '18:00',
        title: 'Mobility',
        description: 'Mobility',
        targetValue: 1,
        unit: 'lan',
        encouragement: 'Nice',
        createdAt: '2026-06-16T08:00:00',
        updatedAt: '2026-06-16T08:00:00',
      ),
    ],
  ];
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

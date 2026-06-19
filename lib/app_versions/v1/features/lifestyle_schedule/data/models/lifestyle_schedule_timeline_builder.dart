import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import 'exercise_task_model.dart';
import 'lifestyle_schedule_item_model.dart';

class LifestyleScheduleTimelineBuilder {
  static const mealItemsPerDay = 5;
  static const exerciseItemsPerDay = 2;
  static const routineItemsPerDay = 3;
  static const itemsPerDay =
      mealItemsPerDay + exerciseItemsPerDay + routineItemsPerDay;

  const LifestyleScheduleTimelineBuilder();

  List<LifestyleScheduleItemModel> generate({
    required DailyHealthProfileEntity profile,
    required List<MealPlanModel> meals,
    required List<ExerciseTaskModel> exercises,
    required AiCatalogBundle catalog,
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
    final scheduleCatalog = catalog.scheduleTasksByCode;
    final wakeTask = _requiredRoutine(scheduleCatalog, 'routine_wake');
    final waterTask = _requiredRoutine(
      scheduleCatalog,
      'routine_water_morning',
    );
    final sleepTask = _requiredRoutine(
      scheduleCatalog,
      'routine_sleep_prepare',
    );

    final mealsByDate = <String, List<MealPlanModel>>{};
    for (final meal in meals) {
      final date = _dateKeyFromText(meal.planDate);
      if (date == null) continue;
      mealsByDate.putIfAbsent(date, () => <MealPlanModel>[]).add(meal);
    }

    final exercisesByDate = <String, List<ExerciseTaskModel>>{};
    for (final exercise in exercises) {
      final date = _dateKeyFromText(exercise.scheduleDate);
      if (date == null) continue;
      exercisesByDate
          .putIfAbsent(date, () => <ExerciseTaskModel>[])
          .add(exercise);
    }

    final result = <LifestyleScheduleItemModel>[];
    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final dayMeals = [...mealsByDate[date] ?? <MealPlanModel>[]]
        ..sort((a, b) => a.mealOrder.compareTo(b.mealOrder));
      final dayExercises = [...exercisesByDate[date] ?? <ExerciseTaskModel>[]]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (dayMeals.length != mealItemsPerDay) {
        throw StateError('Expected $mealItemsPerDay meals for $date');
      }
      if (dayExercises.length != exerciseItemsPerDay) {
        throw StateError('Expected $exerciseItemsPerDay exercises for $date');
      }

      final dayItems = <LifestyleScheduleItemModel>[
        _routine(
          profile: profile,
          date: date,
          item: wakeTask,
          createdAt: createdAt,
        ),
        _routine(
          profile: profile,
          date: date,
          item: waterTask,
          createdAt: createdAt,
        ),
        ...dayMeals.map(
          (meal) => LifestyleScheduleItemModel(
            id: '',
            userId: profile.userId,
            scheduleDate: date,
            startTime: meal.startTime,
            endTime: meal.endTime,
            title: _mealTitle(meal),
            description: meal.description,
            category: LifestyleScheduleCategories.meal,
            sourceType: LifestyleScheduleSourceTypes.mealPlan,
            sourceId: meal.id,
            targetValue: 1,
            currentValue: 0,
            unit: 'lần',
            isCompleted: false,
            sortOrder: 0,
            aiGenerated: true,
            encouragement: 'Hoàn thành đúng bữa giúp lịch trình ổn định hơn.',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ),
        ...dayExercises.map(
          (exercise) => LifestyleScheduleItemModel(
            id: '',
            userId: profile.userId,
            scheduleDate: date,
            startTime: exercise.startTime,
            endTime: exercise.endTime,
            title: exercise.title,
            description: exercise.description,
            category: LifestyleScheduleCategories.body,
            sourceType: LifestyleScheduleSourceTypes.exerciseTask,
            sourceId: exercise.id,
            targetValue: exercise.targetValue,
            currentValue: 0,
            unit: exercise.unit,
            isCompleted: false,
            sortOrder: 0,
            aiGenerated: true,
            encouragement: exercise.encouragement,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ),
        _routine(
          profile: profile,
          date: date,
          item: sleepTask,
          createdAt: createdAt,
        ),
      ];

      dayItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      for (var index = 0; index < dayItems.length; index++) {
        final item = dayItems[index];
        result.add(
          item.copyWith(
            id: _id(
              profile.userId,
              date,
              index + 1,
              item.sourceType,
              item.sourceId ?? item.category,
            ),
            sortOrder: index + 1,
          ),
        );
      }
    }

    return result;
  }

  LifestyleScheduleItemModel _routine({
    required DailyHealthProfileEntity profile,
    required String date,
    required ScheduleTaskCatalogItemModel item,
    required String createdAt,
  }) {
    return LifestyleScheduleItemModel(
      id: '',
      userId: profile.userId,
      scheduleDate: date,
      startTime: item.startTime,
      endTime: item.endTime,
      title: item.title,
      description: item.description,
      category: item.category,
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: item.code,
      targetValue: item.targetValue,
      currentValue: 0,
      unit: item.unit,
      isCompleted: false,
      sortOrder: 0,
      aiGenerated: true,
      encouragement: item.encouragement,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  String _mealTitle(MealPlanModel meal) {
    switch (meal.mealType.trim().toLowerCase()) {
      case 'breakfast':
        return 'Ăn sáng: ${meal.mealName}';
      case 'morning_snack':
        return 'Bữa phụ sáng: ${meal.mealName}';
      case 'lunch':
        return 'Ăn trưa: ${meal.mealName}';
      case 'afternoon_snack':
        return 'Bữa phụ chiều: ${meal.mealName}';
      case 'dinner':
        return 'Ăn tối: ${meal.mealName}';
      default:
        return 'Dùng bữa: ${meal.mealName}';
    }
  }

  ScheduleTaskCatalogItemModel _requiredRoutine(
    Map<String, ScheduleTaskCatalogItemModel> catalog,
    String code,
  ) {
    final item = catalog[code];
    if (item == null) {
      throw StateError('Missing schedule_task_catalog code: $code');
    }
    return item;
  }

  String _id(
    String userId,
    String date,
    int index,
    String sourceType,
    String sourceKey,
  ) {
    final cleaned = '$sourceType-$sourceKey'
        .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return 'schedule_${userId}_${date}_${index}_$cleaned';
  }

  String? _dateKeyFromText(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    return _dateKey(parsed);
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

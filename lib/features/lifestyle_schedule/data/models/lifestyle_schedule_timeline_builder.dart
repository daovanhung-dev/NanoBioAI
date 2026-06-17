import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

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
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
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
          startTime: '06:00',
          endTime: '06:15',
          title: 'Thuc day',
          description: 'Bat dau ngay moi, ngoi day cham va gian co nhe.',
          category: 'wake',
          createdAt: createdAt,
        ),
        _routine(
          profile: profile,
          date: date,
          startTime: '06:15',
          endTime: '06:20',
          title: 'Uong nuoc dau ngay',
          description: 'Uong mot coc nuoc nho de khoi dong co the.',
          category: LifestyleScheduleCategories.water,
          targetValue: 250,
          unit: 'ml',
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
            unit: 'lan',
            isCompleted: false,
            sortOrder: 0,
            aiGenerated: true,
            encouragement: 'Hoan thanh dung bua giup lich trinh on dinh hon.',
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
          startTime: '21:00',
          endTime: '21:15',
          title: 'Di ngu',
          description: 'Giam anh sang man hinh va chuan bi ngu dung gio.',
          category: LifestyleScheduleCategories.sleep,
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
    required String startTime,
    required String endTime,
    required String title,
    required String description,
    required String category,
    double targetValue = 1,
    String unit = 'lan',
    required String createdAt,
  }) {
    return LifestyleScheduleItemModel(
      id: '',
      userId: profile.userId,
      scheduleDate: date,
      startTime: startTime,
      endTime: endTime,
      title: title,
      description: description,
      category: category,
      sourceType: LifestyleScheduleSourceTypes.aiSchedule,
      sourceId: null,
      targetValue: targetValue,
      currentValue: 0,
      unit: unit,
      isCompleted: false,
      sortOrder: 0,
      aiGenerated: true,
      encouragement: 'Hoan thanh mot moc nho giup ngay hom nay de theo hon.',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  String _mealTitle(MealPlanModel meal) {
    switch (meal.mealType.trim().toLowerCase()) {
      case 'breakfast':
        return 'An sang: ${meal.mealName}';
      case 'morning_snack':
        return 'Bua phu sang: ${meal.mealName}';
      case 'lunch':
        return 'An trua: ${meal.mealName}';
      case 'afternoon_snack':
        return 'Bua phu chieu: ${meal.mealName}';
      case 'dinner':
        return 'An toi: ${meal.mealName}';
      default:
        return 'Dung bua: ${meal.mealName}';
    }
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

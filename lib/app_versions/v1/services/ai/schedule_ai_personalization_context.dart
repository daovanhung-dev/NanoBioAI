import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';

/// Builds the small, structured profile summary sent with schedule prompts.
/// Direct identifiers, free-form notes, treatments, medications, and lab data
/// are intentionally excluded.
abstract final class ScheduleAiPersonalizationContext {
  static const _activityLabels = <String, String>{
    'activity_low': 'Ít vận động',
    'activity_walk': 'Đi bộ nhẹ',
    'activity_1_2': 'Tập 1–2 buổi mỗi tuần',
    'activity_3_4': 'Tập 3–4 buổi mỗi tuần',
    'activity_5_plus': 'Tập từ 5 buổi mỗi tuần',
    'activity_manual': 'Lao động thể lực',
    'activity_athlete': 'Hoạt động cường độ cao',
  };

  static const _sleepLabels = <String, String>{
    'sleep_great': 'Ngủ ngon',
    'sleep_good': 'Ngủ khá ổn',
    'sleep_light': 'Ngủ không sâu',
    'sleep_late': 'Hay thức khuya',
    'sleep_wake': 'Hay thức giấc',
    'sleep_hard': 'Khó đi vào giấc',
    'sleep_tired': 'Dậy vẫn mệt',
  };

  static const _allergyLabels = <String, String>{
    'seafood': 'Hải sản',
    'fish': 'Cá',
    'shellfish': 'Động vật có vỏ',
    'milk_lactose': 'Sữa hoặc lactose',
    'egg': 'Trứng',
    'peanut': 'Đậu phộng',
    'tree_nut': 'Các loại hạt',
    'soy': 'Đậu nành',
    'wheat_gluten': 'Lúa mì hoặc gluten',
    'sesame': 'Mè hoặc vừng',
    'beef': 'Thịt bò',
    'chicken': 'Thịt gà',
    'pork': 'Thịt heo',
    'mushroom': 'Nấm',
    'spicy': 'Đồ cay',
    'sour': 'Đồ chua',
    'oily': 'Đồ nhiều dầu',
    'caffeine': 'Caffeine',
    'alcohol': 'Rượu bia',
    'preservative': 'Chất bảo quản',
    'msg': 'Bột ngọt',
    'sugar': 'Đường',
  };

  static Map<String, Object?> forMeals({
    required DailyHealthProfileEntity profile,
    required DashboardEntity dashboard,
    required NutritionProfileEntity nutritionProfile,
  }) {
    final goals = <String>{
      ..._selectedCodes(profile.goals, OnboardingCatalog.goals),
      ..._selectedCodes(
        nutritionProfile.goals
            .where((goal) => goal.isActive)
            .map((goal) => goal.code),
        OnboardingCatalog.goals,
      ),
    }.toList()..sort();

    return {
      'wellness_goals': _labeledCodes(goals, OnboardingCatalog.goals),
      'user_reported_condition_categories': _labeledCodes(
        _selectedCodes(
          profile.conditions,
          OnboardingCatalog.conditions,
        ).where((code) => code != 'other_condition').toList()..sort(),
        OnboardingCatalog.conditions,
      ),
      'food_constraint_categories': _allergyCodes(dashboard.allergyName),
      'activity_level': _labeledValue(profile.activityLevel, _activityLabels),
      'sleep_pattern': _labeledValue(profile.sleepQuality, _sleepLabels),
      'habit_codes': _labeledCodes(
        _selectedCodes(profile.habits, OnboardingCatalog.habits)..sort(),
        OnboardingCatalog.habits,
      ),
    };
  }

  static Map<String, Object?> forExercise({
    required DailyHealthProfileEntity profile,
    required ExercisePlanningPreferences preferences,
    required NutritionProfileEntity nutritionProfile,
  }) {
    final goals = <String>{
      ..._selectedCodes(profile.goals, OnboardingCatalog.goals),
      ..._selectedCodes(
        nutritionProfile.goals
            .where((goal) => goal.isActive)
            .map((goal) => goal.code),
        OnboardingCatalog.goals,
      ),
    }.toList()..sort();

    return {
      'wellness_goals': _labeledCodes(goals, OnboardingCatalog.goals),
      'user_reported_condition_categories': _labeledCodes(
        _selectedCodes(
          profile.conditions,
          OnboardingCatalog.conditions,
        ).where((code) => code != 'other_condition').toList()..sort(),
        OnboardingCatalog.conditions,
      ),
      'activity_level': _labeledValue(profile.activityLevel, _activityLabels),
      'sleep_pattern': _labeledValue(profile.sleepQuality, _sleepLabels),
      'available_equipment_codes':
          preferences.availableEquipment
              .where(ExercisePlanningPreferences.equipmentOptions.containsKey)
              .toSet()
              .toList()
            ..sort(),
      'mobility_limitation_codes':
          preferences.mobilityLimitations
              .where(ExercisePlanningPreferences.limitationOptions.containsKey)
              .where((code) => code != 'other')
              .toSet()
              .toList()
            ..sort(),
    };
  }

  static List<String> _selectedCodes(
    Iterable<String> values,
    List<OnboardingChoiceOption> options,
  ) {
    final allowed = options.map((option) => option.code).toSet();
    return values
        .map((value) => value.trim())
        .where((value) => allowed.contains(value))
        .toSet()
        .toList();
  }

  static List<Map<String, String>> _labeledCodes(
    Iterable<String> codes,
    List<OnboardingChoiceOption> options,
  ) {
    final labels = {for (final option in options) option.code: option.label};
    return codes
        .where(labels.containsKey)
        .map((code) => {'code': code, 'label': labels[code]!})
        .toList(growable: false);
  }

  static Map<String, String>? _labeledValue(
    String value,
    Map<String, String> labels,
  ) {
    final code = value.trim();
    final label = labels[code];
    if (label == null) return null;
    return {'code': code, 'label': label};
  }

  static List<Map<String, String>> _allergyCodes(String value) {
    final code = value.trim();
    final label = _allergyLabels[code];
    if (label == null) return const [];
    return [
      <String, String>{'code': code, 'label': label},
    ];
  }
}

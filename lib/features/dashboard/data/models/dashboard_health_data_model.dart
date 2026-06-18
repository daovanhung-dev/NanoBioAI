import 'package:nano_app/features/dashboard/domain/entities/dashboard_health_input.dart';

/// Mapper model for composing dashboard calculation input from database rows.
///
/// This class is optional but useful when your datasource reads separated rows
/// from health_profiles, lifestyle_habits, health_tracking_logs,
/// health_goals and health_conditions.
class DashboardHealthDataModel extends DashboardHealthInput {
  const DashboardHealthDataModel({
    super.fullName,
    super.heightCm,
    super.weightKg,
    super.bmi,
    super.birthYear,
    super.sleepQuality,
    super.activityLevel,
    super.waterPerDay,
    super.conditions,
    super.goals,
    super.concernText,
    super.latestCalories,
    super.latestWaterMl,
    super.latestSleepHours,
    super.latestStressLevel,
    super.latestStepsCount,
  });

  factory DashboardHealthDataModel.fromDatabaseRows({
    Map<String, Object?>? user,
    Map<String, Object?>? healthProfile,
    Map<String, Object?>? lifestyleHabit,
    Map<String, Object?>? latestTrackingLog,
    Iterable<Map<String, Object?>> healthGoals = const <Map<String, Object?>>[],
    Iterable<Map<String, Object?>> healthConditions =
        const <Map<String, Object?>>[],
    Iterable<Map<String, Object?>> surveyAnswers =
        const <Map<String, Object?>>[],
  }) {
    return DashboardHealthDataModel(
      fullName: _asString(user?['full_name']) ?? 'Bạn',
      heightCm: _asNum(healthProfile?['height_cm']),
      weightKg: _asNum(healthProfile?['weight_kg']),
      bmi: _asNum(healthProfile?['bmi']),
      birthYear: _asInt(user?['birth_year']),
      sleepQuality: _asString(lifestyleHabit?['sleep_quality']),
      activityLevel: _asString(lifestyleHabit?['activity_level']),
      waterPerDay: _asString(lifestyleHabit?['water_per_day']),
      conditions: healthConditions
          .map((row) => _asString(row['condition_name']))
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      goals: healthGoals
          .map((row) => _asString(row['goal_name']))
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      concernText: _resolveConcernText(surveyAnswers),
      latestCalories: _asInt(latestTrackingLog?['calories']),
      latestWaterMl: _asInt(latestTrackingLog?['water_ml']),
      latestSleepHours: _asNum(latestTrackingLog?['sleep_hours']),
      latestStressLevel: _asInt(latestTrackingLog?['stress_level']),
      latestStepsCount: _asInt(latestTrackingLog?['steps_count']),
    );
  }

  static String? _resolveConcernText(Iterable<Map<String, Object?>> answers) {
    for (final answer in answers) {
      final code = _asString(answer['question_code'])?.toLowerCase();
      if (code == 'health_concern' || code == 'concern_text') {
        return _asString(answer['answer_value']);
      }
    }
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static num? _asNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(',', '.'));
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

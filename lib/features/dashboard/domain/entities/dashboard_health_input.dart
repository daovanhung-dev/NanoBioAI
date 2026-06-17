/// Raw health data used by the dashboard calculation layer.
///
/// This entity intentionally stays independent from Flutter/UI so it can be
/// tested in isolation and reused by datasource/repository/usecase layers.
class DashboardHealthInput {
  const DashboardHealthInput({
    this.fullName = 'Bạn',
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.birthYear,
    this.sleepQuality,
    this.activityLevel,
    this.waterPerDay,
    this.conditions = const <String>[],
    this.goals = const <String>[],
    this.concernText,
    this.latestCalories,
    this.latestWaterMl,
    this.latestSleepHours,
    this.latestStressLevel,
    this.latestStepsCount,
  });

  final String fullName;
  final num? heightCm;
  final num? weightKg;
  final num? bmi;
  final int? birthYear;

  /// Values collected from onboarding/lifestyle_habits table.
  final String? sleepQuality;
  final String? activityLevel;
  final String? waterPerDay;
  final List<String> conditions;
  final List<String> goals;
  final String? concernText;

  /// Latest daily tracking values from health_tracking_logs table.
  final int? latestCalories;
  final int? latestWaterMl;
  final num? latestSleepHours;
  final int? latestStressLevel;
  final int? latestStepsCount;

  DashboardHealthInput copyWith({
    String? fullName,
    num? heightCm,
    num? weightKg,
    num? bmi,
    int? birthYear,
    String? sleepQuality,
    String? activityLevel,
    String? waterPerDay,
    List<String>? conditions,
    List<String>? goals,
    String? concernText,
    int? latestCalories,
    int? latestWaterMl,
    num? latestSleepHours,
    int? latestStressLevel,
    int? latestStepsCount,
  }) {
    return DashboardHealthInput(
      fullName: fullName ?? this.fullName,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      birthYear: birthYear ?? this.birthYear,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      activityLevel: activityLevel ?? this.activityLevel,
      waterPerDay: waterPerDay ?? this.waterPerDay,
      conditions: conditions ?? this.conditions,
      goals: goals ?? this.goals,
      concernText: concernText ?? this.concernText,
      latestCalories: latestCalories ?? this.latestCalories,
      latestWaterMl: latestWaterMl ?? this.latestWaterMl,
      latestSleepHours: latestSleepHours ?? this.latestSleepHours,
      latestStressLevel: latestStressLevel ?? this.latestStressLevel,
      latestStepsCount: latestStepsCount ?? this.latestStepsCount,
    );
  }
}

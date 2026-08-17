class DailyHealthSnapshotEntity {
  final String userId;
  final String logDate;
  final int waterMl;
  final double? sleepHours;
  final int? stressLevel;
  final String? mood;
  final double? weightKg;
  final int? dailyScore;
  final String? updatedAt;

  const DailyHealthSnapshotEntity({
    required this.userId,
    required this.logDate,
    this.waterMl = 0,
    this.sleepHours,
    this.stressLevel,
    this.mood,
    this.weightKg,
    this.dailyScore,
    this.updatedAt,
  });

  static const empty = DailyHealthSnapshotEntity(userId: '', logDate: '');

  bool get hasMood => mood?.trim().isNotEmpty == true;
  bool get hasStress => stressLevel != null;
  bool get hasSleep => sleepHours != null;
  bool get hasWeight => weightKg != null;

  String get moodLabel => switch (mood?.trim().toLowerCase()) {
    'very_good' => 'Rất tốt',
    'good' => 'Tốt',
    'neutral' => 'Bình thường',
    'tired' => 'Hơi mệt',
    'stressed' => 'Căng thẳng',
    _ => 'Chưa ghi nhận',
  };
}

class DailyHealthCheckInInput {
  final int waterDeltaMl;
  final double? sleepHours;
  final int? stressLevel;
  final String? mood;
  final double? weightKg;

  const DailyHealthCheckInInput({
    this.waterDeltaMl = 0,
    this.sleepHours,
    this.stressLevel,
    this.mood,
    this.weightKg,
  });

  bool get isEmpty =>
      waterDeltaMl == 0 &&
      sleepHours == null &&
      stressLevel == null &&
      (mood == null || mood!.trim().isEmpty) &&
      weightKg == null;

  Map<String, Object?> toRewardPayload() {
    return {
      if (waterDeltaMl > 0) 'amount_ml': waterDeltaMl,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (mood?.trim().isNotEmpty == true) 'mood': mood!.trim(),
      if (weightKg != null) 'weight_kg': weightKg,
    };
  }
}

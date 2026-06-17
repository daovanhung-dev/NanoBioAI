class HealthTrackingLogModel {
  final String id;
  final String? userId;
  final String logDate;
  final double? weightKg;
  final int? calories;
  final int waterMl;
  final double? sleepHours;
  final int? stressLevel;
  final int stepsCount;
  final int? dailyScore;
  final String? mood;
  final String createdAt;
  final String updatedAt;

  const HealthTrackingLogModel({
    required this.id,
    this.userId,
    required this.logDate,
    this.weightKg,
    this.calories,
    this.waterMl = 0,
    this.sleepHours,
    this.stressLevel,
    this.stepsCount = 0,
    this.dailyScore,
    this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthTrackingLogModel.fromMap(Map<String, dynamic> map) {
    return HealthTrackingLogModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      logDate:
          map['log_date']?.toString() ?? map['created_at']?.toString() ?? '',
      weightKg: _readDouble(map['weight_kg']),
      calories: _readInt(map['calories']),
      waterMl: _readInt(map['water_ml']) ?? 0,
      sleepHours: _readDouble(map['sleep_hours']),
      stressLevel: _readInt(map['stress_level']),
      stepsCount: _readInt(map['steps_count']) ?? 0,
      dailyScore: _readInt(map['daily_score']),
      mood: map['mood']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt:
          map['updated_at']?.toString() ?? map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'log_date': logDate,
      'weight_kg': weightKg,
      'calories': calories,
      'water_ml': waterMl,
      'sleep_hours': sleepHours,
      'stress_level': stressLevel,
      'steps_count': stepsCount,
      'daily_score': dailyScore,
      'mood': mood,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory HealthTrackingLogModel.fromJson(Map<String, dynamic> json) {
    return HealthTrackingLogModel.fromMap(json);
  }

  HealthTrackingLogModel copyWith({
    String? id,
    String? userId,
    String? logDate,
    double? weightKg,
    int? calories,
    int? waterMl,
    double? sleepHours,
    int? stressLevel,
    int? stepsCount,
    int? dailyScore,
    String? mood,
    String? createdAt,
    String? updatedAt,
  }) {
    return HealthTrackingLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      weightKg: weightKg ?? this.weightKg,
      calories: calories ?? this.calories,
      waterMl: waterMl ?? this.waterMl,
      sleepHours: sleepHours ?? this.sleepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      stepsCount: stepsCount ?? this.stepsCount,
      dailyScore: dailyScore ?? this.dailyScore,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

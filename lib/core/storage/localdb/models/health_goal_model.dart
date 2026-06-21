class HealthGoalModel {
  final String id;
  final String? userId;
  final String? goalCode;
  final String? goalName;
  final bool isActive;
  final String? createdAt;

  const HealthGoalModel({
    required this.id,
    this.userId,
    this.goalCode,
    this.goalName,
    this.isActive = true,
    this.createdAt,
  });

  factory HealthGoalModel.fromMap(Map<String, Object?> map) {
    return HealthGoalModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      goalCode: _readString(map['goal_code']),
      goalName: _readString(map['goal_name']),
      isActive: _readBool(map['is_active']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory HealthGoalModel.fromJson(Map<String, Object?> json) =>
      HealthGoalModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal_code': goalCode,
      'goal_name': goalName,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  HealthGoalModel copyWith({
    String? id,
    String? userId,
    String? goalCode,
    String? goalName,
    bool? isActive,
    String? createdAt,
  }) {
    return HealthGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalCode: goalCode ?? this.goalCode,
      goalName: goalName ?? this.goalName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _readBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

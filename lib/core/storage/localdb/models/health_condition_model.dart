class HealthConditionModel {
  final String id;
  final String? userId;
  final String? conditionCode;
  final String? conditionName;
  final int? severityLevel;
  final String? createdAt;

  const HealthConditionModel({
    required this.id,
    this.userId,
    this.conditionCode,
    this.conditionName,
    this.severityLevel,
    this.createdAt,
  });

  factory HealthConditionModel.fromMap(Map<String, Object?> map) {
    return HealthConditionModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      conditionCode: _readString(map['condition_code']),
      conditionName: _readString(map['condition_name']),
      severityLevel: _readInt(map['severity_level']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory HealthConditionModel.fromJson(Map<String, Object?> json) => HealthConditionModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'condition_code': conditionCode,
      'condition_name': conditionName,
      'severity_level': severityLevel,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  HealthConditionModel copyWith({
    String? id,
    String? userId,
    String? conditionCode,
    String? conditionName,
    int? severityLevel,
    String? createdAt,
  }) {
    return HealthConditionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conditionCode: conditionCode ?? this.conditionCode,
      conditionName: conditionName ?? this.conditionName,
      severityLevel: severityLevel ?? this.severityLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _readBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

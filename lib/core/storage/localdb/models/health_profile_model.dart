class HealthProfileModel {
  final String id;
  final String? userId;
  final String? occupation;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bloodPressure;
  final String? bloodSugar;
  final String? createdAt;
  final String? updatedAt;

  const HealthProfileModel({
    required this.id,
    this.userId,
    this.occupation,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.bloodPressure,
    this.bloodSugar,
    this.createdAt,
    this.updatedAt,
  });

  factory HealthProfileModel.fromMap(Map<String, Object?> map) {
    return HealthProfileModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      occupation: _readString(map['occupation']),
      heightCm: _readDouble(map['height_cm']),
      weightKg: _readDouble(map['weight_kg']),
      bmi: _readDouble(map['bmi']),
      bloodPressure: _readString(map['blood_pressure']),
      bloodSugar: _readString(map['blood_sugar']),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  factory HealthProfileModel.fromJson(Map<String, Object?> json) =>
      HealthProfileModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'occupation': occupation,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'blood_pressure': bloodPressure,
      'blood_sugar': bloodSugar,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  HealthProfileModel copyWith({
    String? id,
    String? userId,
    String? occupation,
    double? heightCm,
    double? weightKg,
    double? bmi,
    String? bloodPressure,
    String? bloodSugar,
    String? createdAt,
    String? updatedAt,
  }) {
    return HealthProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      occupation: occupation ?? this.occupation,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

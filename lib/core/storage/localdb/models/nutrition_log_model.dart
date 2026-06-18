class NutritionLogModel {
  final String id;
  final String? userId;
  final String? foodName;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? mealType;
  final String? eatenAt;

  const NutritionLogModel({
    required this.id,
    this.userId,
    this.foodName,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.mealType,
    this.eatenAt,
  });

  factory NutritionLogModel.fromMap(Map<String, Object?> map) {
    return NutritionLogModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      foodName: _readString(map['food_name']),
      calories: _readInt(map['calories']),
      protein: _readDouble(map['protein']),
      carbs: _readDouble(map['carbs']),
      fat: _readDouble(map['fat']),
      mealType: _readString(map['meal_type']),
      eatenAt: _readString(map['eaten_at']),
    );
  }

  factory NutritionLogModel.fromJson(Map<String, Object?> json) =>
      NutritionLogModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'meal_type': mealType,
      'eaten_at': eatenAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  NutritionLogModel copyWith({
    String? id,
    String? userId,
    String? foodName,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? mealType,
    String? eatenAt,
  }) {
    return NutritionLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
      eatenAt: eatenAt ?? this.eatenAt,
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

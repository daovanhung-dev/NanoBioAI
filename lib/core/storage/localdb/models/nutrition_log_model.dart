import 'dart:convert';

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

  /// Rich local-only nutrition details. These fields are stored in the
  /// `nutrition_log_details` companion table so the legacy Supabase snapshot
  /// contract for `nutrition_logs` remains unchanged.
  final double? servingQuantity;
  final String? servingUnit;
  final Map<String, dynamic> nutrition;
  final String? nutritionSource;
  final double? nutritionConfidence;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

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
    this.servingQuantity,
    this.servingUnit,
    this.nutrition = const {},
    this.nutritionSource,
    this.nutritionConfidence,
    this.notes,
    this.createdAt,
    this.updatedAt,
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
      servingQuantity: _readDouble(
        map['detail_serving_quantity'] ?? map['serving_quantity'],
      ),
      servingUnit: _readString(
        map['detail_serving_unit'] ?? map['serving_unit'],
      ),
      nutrition: _readJsonMap(
        map['detail_nutrition_json'] ??
            map['nutrition_json'] ??
            map['nutrition'],
      ),
      nutritionSource: _readString(
        map['detail_nutrition_source'] ?? map['nutrition_source'],
      ),
      nutritionConfidence: _readDouble(
        map['detail_nutrition_confidence'] ?? map['nutrition_confidence'],
      ),
      notes: _readString(map['detail_notes'] ?? map['notes']),
      createdAt: _readString(
        map['detail_created_at'] ?? map['created_at'],
      ),
      updatedAt: _readString(
        map['detail_updated_at'] ?? map['updated_at'],
      ),
    );
  }

  factory NutritionLogModel.fromJson(Map<String, Object?> json) =>
      NutritionLogModel.fromMap(json);

  /// Legacy synced table payload. Do not add rich-local columns here.
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

  Map<String, Object?> toJson() => {
        ...toMap(),
        'serving_quantity': servingQuantity,
        'serving_unit': servingUnit,
        'nutrition': nutrition,
        'nutrition_source': nutritionSource,
        'nutrition_confidence': nutritionConfidence,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  bool get hasRichNutritionDetails =>
      servingQuantity != null ||
      (servingUnit?.trim().isNotEmpty ?? false) ||
      nutrition.isNotEmpty ||
      (nutritionSource?.trim().isNotEmpty ?? false) ||
      nutritionConfidence != null ||
      (notes?.trim().isNotEmpty ?? false);

  Map<String, Object?>? toDetailsMap({String? fallbackCreatedAt}) {
    final uid = userId?.trim();
    if (uid == null || uid.isEmpty || id.trim().isEmpty) return null;
    if (!hasRichNutritionDetails) return null;
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'nutrition_log_id': id,
      'user_id': uid,
      'serving_quantity': servingQuantity,
      'serving_unit': servingUnit,
      'nutrition_json': jsonEncode(nutrition),
      'nutrition_source': nutritionSource,
      'nutrition_confidence': nutritionConfidence,
      'notes': notes,
      'created_at': createdAt ?? fallbackCreatedAt ?? now,
      'updated_at': updatedAt ?? now,
    };
  }

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
    double? servingQuantity,
    String? servingUnit,
    Map<String, dynamic>? nutrition,
    String? nutritionSource,
    double? nutritionConfidence,
    String? notes,
    String? createdAt,
    String? updatedAt,
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
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      nutrition: nutrition ?? this.nutrition,
      nutritionSource: nutritionSource ?? this.nutritionSource,
      nutritionConfidence: nutritionConfidence ?? this.nutritionConfidence,
      notes: notes ?? this.notes,
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

Map<String, dynamic> _readJsonMap(Object? value) {
  if (value == null) return const {};
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  final text = value.toString().trim();
  if (text.isEmpty) return const {};
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      return decoded.map((key, item) => MapEntry(key.toString(), item));
    }
  } catch (_) {
    // Malformed legacy/local detail must not prevent the nutrition log itself
    // from loading. The metrics engine will treat rich nutrition as missing.
  }
  return const {};
}

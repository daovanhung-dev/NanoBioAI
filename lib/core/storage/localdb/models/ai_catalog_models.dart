class AiCatalogBundle {
  final List<MealCatalogItemModel> meals;
  final List<ExerciseCatalogItemModel> exercises;
  final List<ScheduleTaskCatalogItemModel> scheduleTasks;

  const AiCatalogBundle({
    required this.meals,
    required this.exercises,
    required this.scheduleTasks,
  });

  Map<String, MealCatalogItemModel> get mealsByCode => {
    for (final item in meals) item.code: item,
  };

  Map<String, ExerciseCatalogItemModel> get exercisesByCode => {
    for (final item in exercises) item.code: item,
  };

  Map<String, ScheduleTaskCatalogItemModel> get scheduleTasksByCode => {
    for (final item in scheduleTasks) item.code: item,
  };

  List<MealCatalogItemModel> mealsForType(String mealType) {
    final type = mealType.trim().toLowerCase();
    return meals.where((item) => item.mealType == type).toList(growable: false);
  }
}

class MealCatalogItemModel {
  final String code;
  final String mealType;
  final String mealName;
  final String description;
  final String cookingInstructions;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const MealCatalogItemModel({
    required this.code,
    required this.mealType,
    required this.mealName,
    required this.description,
    required this.cookingInstructions,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.waterMl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealCatalogItemModel.fromMap(Map<String, Object?> map) {
    return MealCatalogItemModel(
      code: _readString(map['code']),
      mealType: _readString(map['meal_type']).toLowerCase(),
      mealName: _readString(map['meal_name']),
      description: _readString(map['description']),
      cookingInstructions: _readString(map['cooking_instructions']),
      calories: _readInt(map['calories']),
      protein: _readDouble(map['protein']),
      carbs: _readDouble(map['carbs']),
      fat: _readDouble(map['fat']),
      fiber: _readDouble(map['fiber']),
      waterMl: _readInt(map['water_ml']),
      isActive: _readBool(map['is_active'], fallback: true),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'code': code,
      'meal_type': mealType,
      'meal_name': mealName,
      'description': description,
      'cooking_instructions': cookingInstructions,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'water_ml': waterMl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ExerciseCatalogItemModel {
  final String code;
  final String category;
  final String title;
  final String description;
  final String unit;
  final String encouragement;
  final double minTarget;
  final double maxTarget;
  final double defaultTarget;
  final String intensityLevel;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const ExerciseCatalogItemModel({
    required this.code,
    required this.category,
    required this.title,
    required this.description,
    required this.unit,
    required this.encouragement,
    required this.minTarget,
    required this.maxTarget,
    required this.defaultTarget,
    required this.intensityLevel,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseCatalogItemModel.fromMap(Map<String, Object?> map) {
    return ExerciseCatalogItemModel(
      code: _readString(map['code']),
      category: _readString(map['category']),
      title: _readString(map['title']),
      description: _readString(map['description']),
      unit: _readString(map['unit']),
      encouragement: _readString(map['encouragement']),
      minTarget: _readDouble(map['min_target']),
      maxTarget: _readDouble(map['max_target']),
      defaultTarget: _readDouble(map['default_target']),
      intensityLevel: _readString(map['intensity_level']),
      isActive: _readBool(map['is_active'], fallback: true),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'code': code,
      'category': category,
      'title': title,
      'description': description,
      'unit': unit,
      'encouragement': encouragement,
      'min_target': minTarget,
      'max_target': maxTarget,
      'default_target': defaultTarget,
      'intensity_level': intensityLevel,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ScheduleTaskCatalogItemModel {
  final String code;
  final String category;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final double targetValue;
  final String unit;
  final String encouragement;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const ScheduleTaskCatalogItemModel({
    required this.code,
    required this.category,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.targetValue,
    required this.unit,
    required this.encouragement,
    required this.sortOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleTaskCatalogItemModel.fromMap(Map<String, Object?> map) {
    return ScheduleTaskCatalogItemModel(
      code: _readString(map['code']),
      category: _readString(map['category']),
      title: _readString(map['title']),
      description: _readString(map['description']),
      startTime: _readString(map['start_time']),
      endTime: _readString(map['end_time']),
      targetValue: _readDouble(map['target_value']),
      unit: _readString(map['unit']),
      encouragement: _readString(map['encouragement']),
      sortOrder: _readInt(map['sort_order']),
      isActive: _readBool(map['is_active'], fallback: true),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'code': code,
      'category': category,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'target_value': targetValue,
      'unit': unit,
      'encouragement': encouragement,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

String _readString(Object? value) => value?.toString().trim() ?? '';

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

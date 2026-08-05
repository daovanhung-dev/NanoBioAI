import 'dart:convert';

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
  final String healthTopicCode;
  final String healthTopicName;
  final String healthTopicDescription;
  final int? chapterNumber;
  final String chapterName;
  final List<String> ingredients;
  final List<String> cookingSteps;
  final String benefits;
  final String servingSize;
  final List<String> allergenTags;
  final List<String> avoidConditionTags;
  final String nutritionStatus;
  final String constraintMetadataStatus;
  final String metadataStatus;
  final bool isPlanEligible;
  final String sourceName;
  final int? sourcePage;
  final String sourceChapter;
  final String sourceTopic;
  final int? sourceRecipeOrder;
  final String sourceHash;
  final int version;
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
    this.healthTopicCode = '',
    this.healthTopicName = '',
    this.healthTopicDescription = '',
    this.chapterNumber,
    this.chapterName = '',
    this.ingredients = const [],
    this.cookingSteps = const [],
    this.benefits = '',
    this.servingSize = '',
    this.allergenTags = const [],
    this.avoidConditionTags = const [],
    this.nutritionStatus = 'approved',
    this.constraintMetadataStatus = 'approved',
    this.metadataStatus = 'approved',
    this.isPlanEligible = true,
    this.sourceName = '',
    this.sourcePage,
    this.sourceChapter = '',
    this.sourceTopic = '',
    this.sourceRecipeOrder,
    this.sourceHash = '',
    this.version = 1,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealCatalogItemModel.fromMap(Map<String, Object?> map) {
    final cookingInstructions = _readString(map['cooking_instructions']);
    final parsedSteps = _readStringList(map['cooking_steps_json']);
    return MealCatalogItemModel(
      code: _readString(map['code']),
      mealType: _readString(map['meal_type']).toLowerCase(),
      mealName: _readString(map['meal_name']),
      description: _readString(map['description']),
      cookingInstructions: cookingInstructions,
      calories: _readInt(map['calories']),
      protein: _readDouble(map['protein']),
      carbs: _readDouble(map['carbs']),
      fat: _readDouble(map['fat']),
      fiber: _readDouble(map['fiber']),
      waterMl: _readInt(map['water_ml']),
      healthTopicCode: _readString(map['health_topic_code']),
      healthTopicName: _readString(map['health_topic_name']),
      healthTopicDescription: _readString(map['health_topic_description']),
      chapterNumber: _readNullableInt(map['chapter_number']),
      chapterName: _readString(map['chapter_name']),
      ingredients: _readStringList(map['ingredients_json']),
      cookingSteps: parsedSteps.isEmpty && cookingInstructions.isNotEmpty
          ? cookingInstructions
              .split(RegExp(r'\n+'))
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : parsedSteps,
      benefits: _readString(map['benefits']),
      servingSize: _readString(map['serving_size']),
      allergenTags: _readStringList(map['allergen_tags_json']),
      avoidConditionTags: _readStringList(map['avoid_condition_tags_json']),
      nutritionStatus: _readStringOr(map['nutrition_status'], 'approved'),
      constraintMetadataStatus: _readStringOr(
        map['constraint_metadata_status'],
        'approved',
      ),
      metadataStatus: _readStringOr(map['metadata_status'], 'approved'),
      isPlanEligible: _readBool(map['is_plan_eligible'], fallback: true),
      sourceName: _readString(map['source_name']),
      sourcePage: _readNullableInt(map['source_page']),
      sourceChapter: _readString(map['source_chapter']),
      sourceTopic: _readString(map['source_topic']),
      sourceRecipeOrder: _readNullableInt(map['source_recipe_order']),
      sourceHash: _readString(map['source_hash']),
      version: _readIntOr(map['version'], 1),
      isActive: _readBool(map['is_active'], fallback: true),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  factory MealCatalogItemModel.fromSourceJson(
    Map<String, Object?> json, {
    required String timestamp,
  }) {
    final steps = _readStringList(json['cooking_steps']);
    return MealCatalogItemModel(
      code: _readString(json['code']),
      mealType: _readStringOr(json['meal_type'], 'unclassified'),
      mealName: _readString(json['meal_name']),
      description: _readString(json['description']),
      cookingInstructions: steps.join('\n'),
      calories: _readInt(json['calories']),
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
      fiber: _readDouble(json['fiber']),
      waterMl: _readInt(json['water_ml']),
      healthTopicCode: _readString(json['health_topic_code']),
      healthTopicName: _readString(json['health_topic_name']),
      healthTopicDescription: _readString(json['health_topic_description']),
      chapterNumber: _readNullableInt(json['chapter_number']),
      chapterName: _readString(json['chapter_name']),
      ingredients: _readStringList(json['ingredients']),
      cookingSteps: steps,
      benefits: _readString(json['benefits']),
      servingSize: _readString(json['serving_size']),
      allergenTags: _readStringList(json['allergen_tags']),
      avoidConditionTags: _readStringList(json['avoid_condition_tags']),
      nutritionStatus: _readStringOr(
        json['nutrition_status'],
        'missing_source_data',
      ),
      constraintMetadataStatus: _readStringOr(
        json['constraint_metadata_status'],
        'awaiting_professional_review',
      ),
      metadataStatus: _readStringOr(json['metadata_status'], 'source_imported'),
      isPlanEligible: _readBool(json['is_plan_eligible']),
      sourceName: _readString(json['source_name']),
      sourcePage: _readNullableInt(json['source_page']),
      sourceChapter: _readString(json['source_chapter']),
      sourceTopic: _readString(json['source_topic']),
      sourceRecipeOrder: _readNullableInt(json['source_recipe_order']),
      sourceHash: _readString(json['source_hash']),
      version: _readIntOr(json['version'], 1),
      isActive: _readBool(json['is_active'], fallback: true),
      createdAt: timestamp,
      updatedAt: timestamp,
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
      'health_topic_code': healthTopicCode,
      'health_topic_name': healthTopicName,
      'health_topic_description': healthTopicDescription,
      'chapter_number': chapterNumber,
      'chapter_name': chapterName,
      'ingredients_json': jsonEncode(ingredients),
      'cooking_steps_json': jsonEncode(cookingSteps),
      'benefits': benefits,
      'serving_size': servingSize,
      'allergen_tags_json': jsonEncode(allergenTags),
      'avoid_condition_tags_json': jsonEncode(avoidConditionTags),
      'nutrition_status': nutritionStatus,
      'constraint_metadata_status': constraintMetadataStatus,
      'metadata_status': metadataStatus,
      'is_plan_eligible': isPlanEligible ? 1 : 0,
      'source_name': sourceName,
      'source_page': sourcePage,
      'source_chapter': sourceChapter,
      'source_topic': sourceTopic,
      'source_recipe_order': sourceRecipeOrder,
      'source_hash': sourceHash,
      'version': version,
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

String _readStringOr(Object? value, String fallback) {
  final text = _readString(value);
  return text.isEmpty ? fallback : text;
}

int _readIntOr(Object? value, int fallback) {
  if (value == null) return fallback;
  final parsed = _readInt(value);
  return parsed == 0 && value.toString().trim() != '0' ? fallback : parsed;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<String> _readStringList(Object? value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final text = value.toString().trim();
  if (text.isEmpty) return const [];
  try {
    final decoded = jsonDecode(text);
    if (decoded is List) {
      return decoded
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  } catch (_) {
    // Legacy values may be newline-separated; keep content without logging it.
  }
  return text
      .split(RegExp(r'\n+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

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

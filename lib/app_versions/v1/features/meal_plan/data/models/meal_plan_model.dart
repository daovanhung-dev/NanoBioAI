import 'dart:convert';

import '../../domain/entities/meal_plan_entity.dart';

class MealPlanModel {
  const MealPlanModel({
    required this.id,
    this.userId,
    required this.planDate,
    required this.mealType,
    required this.mealName,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.waterMl,
    this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
    this.cholesterolMg,
    this.potassiumMg,
    this.calciumMg,
    this.ironMg,
    this.nutritionStatus = '',
    required this.mealOrder,
    this.startTime = '',
    this.endTime = '',
    this.cookingInstructions = '',
    this.catalogCode = '',
    this.servingSize = '',
    this.topicCode = '',
    this.topicName = '',
    this.ingredients = const [],
    this.cookingSteps = const [],
    this.benefits = '',
    this.allergenTags = const [],
    this.conditionTags = const [],
    this.provenanceSource = '',
    this.sourceHash = '',
    this.catalogSchemaVersion = 1,
    this.replacementCount = 0,
    required this.isCompleted,
    required this.aiGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? userId;
  final String planDate;
  final String mealType;
  final String mealName;
  final String description;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? cholesterolMg;
  final double? potassiumMg;
  final double? calciumMg;
  final double? ironMg;
  final String nutritionStatus;
  final int mealOrder;
  final String startTime;
  final String endTime;
  final String cookingInstructions;
  final String catalogCode;
  final String servingSize;
  final String topicCode;
  final String topicName;
  final List<String> ingredients;
  final List<String> cookingSteps;
  final String benefits;
  final List<String> allergenTags;
  final List<String> conditionTags;
  final String provenanceSource;
  final String sourceHash;
  final int catalogSchemaVersion;
  final int replacementCount;
  final bool isCompleted;
  final bool aiGenerated;
  final String createdAt;
  final String updatedAt;

  factory MealPlanModel.fromMap(Map<String, dynamic> map) {
    final mealType = _string(map['meal_type']);
    return MealPlanModel(
      id: _string(map['id']),
      userId: map['user_id']?.toString(),
      planDate: _string(map['plan_date']),
      mealType: mealType,
      mealName: _string(map['meal_name']),
      description: _string(map['description']),
      calories: _integer(map['calories']),
      protein: _double(map['protein']),
      carbs: _double(map['carbs']),
      fat: _double(map['fat']),
      fiber: _double(map['fiber']),
      waterMl: _integer(map['water_ml']),
      sugarG: _nullableDouble(map['sugar_g']),
      saturatedFatG: _nullableDouble(map['saturated_fat_g']),
      sodiumMg: _nullableDouble(map['sodium_mg']),
      cholesterolMg: _nullableDouble(map['cholesterol_mg']),
      potassiumMg: _nullableDouble(map['potassium_mg']),
      calciumMg: _nullableDouble(map['calcium_mg']),
      ironMg: _nullableDouble(map['iron_mg']),
      nutritionStatus: _string(map['nutrition_status']),
      mealOrder: _integer(map['meal_order']),
      startTime: _readTime(map['start_time'], fallback: _defaultStartTime(mealType)),
      endTime: _readTime(map['end_time'], fallback: _defaultEndTime(mealType)),
      cookingInstructions: _string(map['cooking_instructions']),
      catalogCode: _string(map['catalog_code']),
      servingSize: _string(map['serving_size']),
      topicCode: _string(map['health_topic_code']),
      topicName: _string(map['health_topic_name']),
      ingredients: _stringList(map['ingredients_json']),
      cookingSteps: _stringList(map['cooking_steps_json']),
      benefits: _string(map['benefits']),
      allergenTags: _stringList(map['allergen_tags_json']),
      conditionTags: _stringList(map['avoid_condition_tags_json']),
      provenanceSource: _string(map['source_name']),
      sourceHash: _string(map['source_hash']),
      catalogSchemaVersion: _integer(map['snapshot_schema_version'], fallback: 1),
      replacementCount: _integer(map['replacement_count']),
      isCompleted: _boolean(map['is_completed']),
      aiGenerated: _boolean(map['ai_generated']),
      createdAt: _string(map['created_at']),
      updatedAt: _string(map['updated_at']),
    );
  }

  factory MealPlanModel.fromJson(Map<String, dynamic> json) => MealPlanModel.fromMap(json);

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'plan_date': planDate,
        'meal_type': mealType,
        'meal_name': mealName,
        'description': description,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'water_ml': waterMl,
        'sugar_g': sugarG,
        'saturated_fat_g': saturatedFatG,
        'sodium_mg': sodiumMg,
        'cholesterol_mg': cholesterolMg,
        'potassium_mg': potassiumMg,
        'calcium_mg': calciumMg,
        'iron_mg': ironMg,
        'nutrition_status': nutritionStatus,
        'meal_order': mealOrder,
        'start_time': startTime,
        'end_time': endTime,
        'cooking_instructions': cookingInstructions,
        'catalog_code': catalogCode,
        'serving_size': servingSize,
        'health_topic_code': topicCode,
        'health_topic_name': topicName,
        'ingredients_json': jsonEncode(ingredients),
        'cooking_steps_json': jsonEncode(cookingSteps),
        'benefits': benefits,
        'allergen_tags_json': jsonEncode(allergenTags),
        'avoid_condition_tags_json': jsonEncode(conditionTags),
        'source_name': provenanceSource,
        'source_hash': sourceHash,
        'snapshot_schema_version': catalogSchemaVersion,
        'replacement_count': replacementCount,
        'is_completed': isCompleted ? 1 : 0,
        'ai_generated': aiGenerated ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Map<String, dynamic> toJson() => {
        ...toMap(),
        'is_completed': isCompleted,
        'ai_generated': aiGenerated,
        'ingredients': ingredients,
        'cooking_steps': cookingSteps,
        'allergen_tags': allergenTags,
        'condition_tags': conditionTags,
      };

  MealPlanEntity toEntity() => MealPlanEntity(
        id: id,
        userId: userId,
        planDate: planDate,
        mealType: mealType,
        mealName: mealName,
        description: description,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        waterMl: waterMl,
        sugarG: sugarG,
        saturatedFatG: saturatedFatG,
        sodiumMg: sodiumMg,
        cholesterolMg: cholesterolMg,
        potassiumMg: potassiumMg,
        calciumMg: calciumMg,
        ironMg: ironMg,
        nutritionStatus: nutritionStatus,
        mealOrder: mealOrder,
        startTime: startTime,
        endTime: endTime,
        cookingInstructions: cookingInstructions,
        catalogCode: catalogCode,
        servingSize: servingSize,
        topicCode: topicCode,
        topicName: topicName,
        ingredients: ingredients,
        cookingSteps: cookingSteps,
        benefits: benefits,
        allergenTags: allergenTags,
        conditionTags: conditionTags,
        provenanceSource: provenanceSource,
        sourceHash: sourceHash,
        catalogSchemaVersion: catalogSchemaVersion,
        replacementCount: replacementCount,
        isCompleted: isCompleted,
        aiGenerated: aiGenerated,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory MealPlanModel.fromEntity(MealPlanEntity entity) => MealPlanModel(
        id: entity.id,
        userId: entity.userId,
        planDate: entity.planDate,
        mealType: entity.mealType,
        mealName: entity.mealName,
        description: entity.description,
        calories: entity.calories,
        protein: entity.protein,
        carbs: entity.carbs,
        fat: entity.fat,
        fiber: entity.fiber,
        waterMl: entity.waterMl,
        sugarG: entity.sugarG,
        saturatedFatG: entity.saturatedFatG,
        sodiumMg: entity.sodiumMg,
        cholesterolMg: entity.cholesterolMg,
        potassiumMg: entity.potassiumMg,
        calciumMg: entity.calciumMg,
        ironMg: entity.ironMg,
        nutritionStatus: entity.nutritionStatus,
        mealOrder: entity.mealOrder,
        startTime: entity.startTime,
        endTime: entity.endTime,
        cookingInstructions: entity.cookingInstructions,
        catalogCode: entity.catalogCode,
        servingSize: entity.servingSize,
        topicCode: entity.topicCode,
        topicName: entity.topicName,
        ingredients: entity.ingredients,
        cookingSteps: entity.cookingSteps,
        benefits: entity.benefits,
        allergenTags: entity.allergenTags,
        conditionTags: entity.conditionTags,
        provenanceSource: entity.provenanceSource,
        sourceHash: entity.sourceHash,
        catalogSchemaVersion: entity.catalogSchemaVersion,
        replacementCount: entity.replacementCount,
        isCompleted: entity.isCompleted,
        aiGenerated: entity.aiGenerated,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  MealPlanModel copyWith({
    String? id, String? userId, String? planDate, String? mealType, String? mealName,
    String? description, int? calories, double? protein, double? carbs, double? fat,
    double? fiber, int? waterMl, double? sugarG, double? saturatedFatG,
    double? sodiumMg, double? cholesterolMg, double? potassiumMg, double? calciumMg,
    double? ironMg, String? nutritionStatus, int? mealOrder, String? startTime, String? endTime,
    String? cookingInstructions, String? catalogCode, String? servingSize,
    String? topicCode, String? topicName, List<String>? ingredients,
    List<String>? cookingSteps, String? benefits, List<String>? allergenTags,
    List<String>? conditionTags, String? provenanceSource, String? sourceHash,
    int? catalogSchemaVersion, int? replacementCount, bool? isCompleted,
    bool? aiGenerated, String? createdAt, String? updatedAt,
  }) => MealPlanModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        planDate: planDate ?? this.planDate,
        mealType: mealType ?? this.mealType,
        mealName: mealName ?? this.mealName,
        description: description ?? this.description,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber ?? this.fiber,
        waterMl: waterMl ?? this.waterMl,
        sugarG: sugarG ?? this.sugarG,
        saturatedFatG: saturatedFatG ?? this.saturatedFatG,
        sodiumMg: sodiumMg ?? this.sodiumMg,
        cholesterolMg: cholesterolMg ?? this.cholesterolMg,
        potassiumMg: potassiumMg ?? this.potassiumMg,
        calciumMg: calciumMg ?? this.calciumMg,
        ironMg: ironMg ?? this.ironMg,
        nutritionStatus: nutritionStatus ?? this.nutritionStatus,
        mealOrder: mealOrder ?? this.mealOrder,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        cookingInstructions: cookingInstructions ?? this.cookingInstructions,
        catalogCode: catalogCode ?? this.catalogCode,
        servingSize: servingSize ?? this.servingSize,
        topicCode: topicCode ?? this.topicCode,
        topicName: topicName ?? this.topicName,
        ingredients: ingredients ?? this.ingredients,
        cookingSteps: cookingSteps ?? this.cookingSteps,
        benefits: benefits ?? this.benefits,
        allergenTags: allergenTags ?? this.allergenTags,
        conditionTags: conditionTags ?? this.conditionTags,
        provenanceSource: provenanceSource ?? this.provenanceSource,
        sourceHash: sourceHash ?? this.sourceHash,
        catalogSchemaVersion: catalogSchemaVersion ?? this.catalogSchemaVersion,
        replacementCount: replacementCount ?? this.replacementCount,
        isCompleted: isCompleted ?? this.isCompleted,
        aiGenerated: aiGenerated ?? this.aiGenerated,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String _string(Object? value) => value?.toString().trim() ?? '';
  static int _integer(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
  static double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    return text.isEmpty ? null : double.tryParse(text);
  }
  static bool _boolean(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
  static List<String> _stringList(Object? value) {
    if (value is List) return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false);
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false);
    } catch (_) {}
    return text.split(RegExp(r'[\n;]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }
  static String _readTime(Object? value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return RegExp(r'^\d{2}:\d{2}$').hasMatch(text) ? text : fallback;
  }
  static String _defaultStartTime(String type) => switch (type.trim().toLowerCase()) {
    'breakfast' => '07:00', 'morning_snack' => '09:30', 'lunch' => '12:00',
    'afternoon_snack' => '15:30', 'dinner' => '18:30', _ => '',
  };
  static String _defaultEndTime(String type) => switch (type.trim().toLowerCase()) {
    'breakfast' => '07:30', 'morning_snack' => '09:45', 'lunch' => '12:45',
    'afternoon_snack' => '15:45', 'dinner' => '19:15', _ => '',
  };
}

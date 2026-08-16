import 'meal_catalog_detail_entity.dart';

class MealPlanEntity {
  const MealPlanEntity({
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
    this.catalogDetail,
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
  final MealCatalogDetailEntity? catalogDetail;
  final bool isCompleted;
  final bool aiGenerated;
  final String createdAt;
  final String updatedAt;

  bool get hasRecipeDetails =>
      ingredients.isNotEmpty ||
      cookingSteps.isNotEmpty ||
      cookingInstructions.trim().isNotEmpty;

  MealPlanEntity copyWith({
    String? id,
    String? userId,
    String? planDate,
    String? mealType,
    String? mealName,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
    int? mealOrder,
    String? startTime,
    String? endTime,
    String? cookingInstructions,
    String? catalogCode,
    String? servingSize,
    String? topicCode,
    String? topicName,
    List<String>? ingredients,
    List<String>? cookingSteps,
    String? benefits,
    List<String>? allergenTags,
    List<String>? conditionTags,
    String? provenanceSource,
    String? sourceHash,
    int? catalogSchemaVersion,
    int? replacementCount,
    MealCatalogDetailEntity? catalogDetail,
    bool? isCompleted,
    bool? aiGenerated,
    String? createdAt,
    String? updatedAt,
  }) {
    return MealPlanEntity(
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
      catalogSchemaVersion:
          catalogSchemaVersion ?? this.catalogSchemaVersion,
      replacementCount: replacementCount ?? this.replacementCount,
      catalogDetail: catalogDetail ?? this.catalogDetail,
      isCompleted: isCompleted ?? this.isCompleted,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

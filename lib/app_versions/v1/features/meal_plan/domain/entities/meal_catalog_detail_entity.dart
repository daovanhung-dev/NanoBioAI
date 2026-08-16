class MealCatalogDetailEntity {
  const MealCatalogDetailEntity({
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
    required this.healthTopicCode,
    required this.healthTopicName,
    required this.healthTopicDescription,
    required this.chapterNumber,
    required this.chapterName,
    required this.ingredients,
    required this.cookingSteps,
    required this.benefits,
    required this.servingSize,
    required this.allergenTags,
    required this.avoidConditionTags,
    required this.nutritionStatus,
    required this.constraintMetadataStatus,
    required this.metadataStatus,
    required this.isPlanEligible,
    required this.sourceName,
    required this.sourcePage,
    required this.sourceChapter,
    required this.sourceTopic,
    required this.sourceRecipeOrder,
    required this.sourceHash,
    required this.version,
    required this.isActive,
  });

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
}

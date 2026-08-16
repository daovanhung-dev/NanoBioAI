import 'meal_plan_entity.dart';

class MealReplacementCandidateEntity {
  const MealReplacementCandidateEntity({
    required this.code,
    required this.mealType,
    required this.mealName,
    required this.description,
    required this.calories,
    required this.servingSize,
    required this.healthTopicName,
  });

  final String code;
  final String mealType;
  final String mealName;
  final String description;
  final int calories;
  final String servingSize;
  final String healthTopicName;
}

enum MealReplacementSyncStatus { synced, pending, localOnly }

class MealReplacementResult {
  const MealReplacementResult({
    required this.meal,
    required this.syncStatus,
  });

  final MealPlanEntity meal;
  final MealReplacementSyncStatus syncStatus;
}

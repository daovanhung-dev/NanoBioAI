class MealPlanEntity {
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
  final bool isCompleted;
  final bool aiGenerated;
  final String createdAt;
  final String updatedAt;

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
    required this.isCompleted,
    required this.aiGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

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
      isCompleted: isCompleted ?? this.isCompleted,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

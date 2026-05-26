class MealPlanModelAI {
  final String id;

  final String userId;

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

  const MealPlanModelAI({
    required this.id,

    required this.userId,

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

  factory MealPlanModelAI.fromJson(Map<String, dynamic> json) {
    return MealPlanModelAI(
      id: json['id'] ?? '',

      userId: json['user_id'] ?? '',

      planDate: json['plan_date'] ?? '',

      mealType: json['meal_type'] ?? '',

      mealName: json['meal_name'] ?? '',

      description: json['description'] ?? '',

      calories: json['calories'] ?? 0,

      protein: (json['protein'] ?? 0).toDouble(),

      carbs: (json['carbs'] ?? 0).toDouble(),

      fat: (json['fat'] ?? 0).toDouble(),

      fiber: (json['fiber'] ?? 0).toDouble(),

      waterMl: json['water_ml'] ?? 0,

      mealOrder: json['meal_order'] ?? 0,

      isCompleted: (json['is_completed'] ?? 0) == 1,

      aiGenerated: (json['ai_generated'] ?? 1) == 1,

      createdAt: json['created_at'] ?? '',

      updatedAt: json['updated_at'] ?? '',
    );
  }

  factory MealPlanModelAI.fromMap(Map<String, dynamic> map) {
    return MealPlanModelAI(
      id: map['id'] ?? '',

      userId: map['user_id'] ?? '',

      planDate: map['plan_date'] ?? '',

      mealType: map['meal_type'] ?? '',

      mealName: map['meal_name'] ?? '',

      description: map['description'] ?? '',

      calories: map['calories'] ?? 0,

      protein: (map['protein'] ?? 0).toDouble(),

      carbs: (map['carbs'] ?? 0).toDouble(),

      fat: (map['fat'] ?? 0).toDouble(),

      fiber: (map['fiber'] ?? 0).toDouble(),

      waterMl: map['water_ml'] ?? 0,

      mealOrder: map['meal_order'] ?? 0,

      isCompleted: (map['is_completed'] ?? 0) == 1,

      aiGenerated: (map['ai_generated'] ?? 1) == 1,

      createdAt: map['created_at'] ?? '',

      updatedAt: map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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

      'meal_order': mealOrder,

      'is_completed': isCompleted ? 1 : 0,

      'ai_generated': aiGenerated ? 1 : 0,

      'created_at': createdAt,

      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  MealPlanModelAI copyWith({
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
    return MealPlanModelAI(
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

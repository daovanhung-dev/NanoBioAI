import '../../domain/entities/meal_plan_entity.dart';

class MealPlanModel {
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
    required this.mealOrder,
    required this.isCompleted,
    required this.aiGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealPlanModel.fromMap(Map<String, dynamic> map) {
    return MealPlanModel(
      id: map['id'],
      userId: map['user_id'],
      planDate: map['plan_date'],
      mealType: map['meal_type'],
      mealName: map['meal_name'],
      description: map['description'],
      calories: map['calories'],
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      waterMl: map['water_ml'],
      mealOrder: map['meal_order'],
      isCompleted: map['is_completed'] == 1,
      aiGenerated: map['ai_generated'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'],
      userId: json['user_id'],
      planDate: json['plan_date'],
      mealType: json['meal_type'],
      mealName: json['meal_name'],
      description: json['description'],
      calories: json['calories'],
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      waterMl: json['water_ml'],
      mealOrder: json['meal_order'],
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      aiGenerated: json['ai_generated'] == true || json['ai_generated'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
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
      'is_completed': isCompleted,
      'ai_generated': aiGenerated,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  MealPlanEntity toEntity() {
    return MealPlanEntity(
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
      mealOrder: mealOrder,
      isCompleted: isCompleted,
      aiGenerated: aiGenerated,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory MealPlanModel.fromEntity(MealPlanEntity entity) {
    return MealPlanModel(
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
      mealOrder: entity.mealOrder,
      isCompleted: entity.isCompleted,
      aiGenerated: entity.aiGenerated,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MealPlanModel copyWith({
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
    return MealPlanModel(
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

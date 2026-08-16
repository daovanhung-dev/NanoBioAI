import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_catalog_detail_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_detail_content_formatter.dart';

void main() {
  test('shows estimated per-serving label and micronutrients', () {
    final content = MealDetailContentFormatter.fromMeal(
      _meal(
        detail: _detail(
          nutritionStatus: 'estimated_from_ingredients',
          sodiumMg: 120,
          potassiumMg: 410,
        ),
      ),
    );

    expect(content.showNutrition, isTrue);
    expect(content.isEstimated, isTrue);
    expect(content.nutritionLabel, 'Dinh dưỡng ước tính • 1 khẩu phần');
    expect(content.sodiumMg, 120);
    expect(content.potassiumMg, 410);
  });

  test('uses estimated snapshot status when catalog detail is unavailable', () {
    final content = MealDetailContentFormatter.fromMeal(
      _meal(
        nutritionStatus: 'estimated_from_ingredients',
        sodiumMg: 90,
      ),
    );

    expect(content.isEstimated, isTrue);
    expect(content.nutritionLabel, 'Dinh dưỡng ước tính • 1 khẩu phần');
    expect(content.sodiumMg, 90);
  });

  test('does not turn unknown micronutrients into zero', () {
    final content = MealDetailContentFormatter.fromMeal(
      _meal(detail: _detail(nutritionStatus: 'approved')),
    );
    expect(content.sodiumMg, isNull);
    expect(content.ironMg, isNull);
  });
}

MealPlanEntity _meal({
  MealCatalogDetailEntity? detail,
  String nutritionStatus = '',
  double? sodiumMg,
}) =>
    MealPlanEntity(
      id: 'meal-1',
      userId: 'user-1',
      planDate: '2026-08-16',
      mealType: 'breakfast',
      mealName: 'Cháo yến mạch',
      description: '',
      calories: 300,
      protein: 10,
      carbs: 50,
      fat: 7,
      fiber: 5,
      waterMl: 0,
      sodiumMg: sodiumMg,
      nutritionStatus: nutritionStatus,
      mealOrder: 1,
      catalogDetail: detail,
      isCompleted: false,
      aiGenerated: true,
      createdAt: '2026-08-16T00:00:00Z',
      updatedAt: '2026-08-16T00:00:00Z',
    );

MealCatalogDetailEntity _detail({
  required String nutritionStatus,
  double? sodiumMg,
  double? potassiumMg,
}) =>
    MealCatalogDetailEntity(
      code: 'meal-1',
      mealType: 'breakfast',
      mealName: 'Cháo yến mạch',
      description: '',
      cookingInstructions: '',
      calories: 300,
      protein: 10,
      carbs: 50,
      fat: 7,
      fiber: 5,
      waterMl: 0,
      sodiumMg: sodiumMg,
      potassiumMg: potassiumMg,
      healthTopicCode: '',
      healthTopicName: '',
      healthTopicDescription: '',
      chapterNumber: null,
      chapterName: '',
      ingredients: const ['50g yến mạch'],
      cookingSteps: const [],
      benefits: '',
      servingSize: '1 khẩu phần (ước tính)',
      allergenTags: const [],
      avoidConditionTags: const [],
      nutritionStatus: nutritionStatus,
      constraintMetadataStatus: 'awaiting_professional_review',
      metadataStatus: 'source_imported',
      isPlanEligible: false,
      sourceName: 'Sức Khỏe Từ Nhà Bếp',
      sourcePage: null,
      sourceChapter: '',
      sourceTopic: '',
      sourceRecipeOrder: 1,
      sourceHash: 'hash',
      version: 1,
      isActive: true,
    );

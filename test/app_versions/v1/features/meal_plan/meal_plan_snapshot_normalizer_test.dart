import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  test('hydrates immutable display and provenance snapshot from catalog', () {
    const catalog = AiCatalogBundle(
      meals: <MealCatalogItemModel>[
        MealCatalogItemModel(
          code: 'breakfast_1',
          mealType: 'breakfast',
          mealName: 'Cháo thử nghiệm',
          description: 'Mô tả từ catalog',
          cookingInstructions: 'Nấu chín và dùng ấm.',
          calories: 280,
          protein: 12,
          carbs: 40,
          fat: 7,
          fiber: 5,
          waterMl: 120,
          healthTopicCode: 'topic_1',
          healthTopicName: 'Chủ đề 1',
          ingredients: <String>['Gạo', 'Rau'],
          cookingSteps: <String>['Rửa nguyên liệu', 'Nấu chín'],
          benefits: 'Theo tài liệu tham khảo.',
          servingSize: '1 bát',
          allergenTags: <String>['soy'],
          avoidConditionTags: <String>['reflux'],
          sourceName: 'Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md',
          sourcePage: 12,
          sourceHash: 'source-hash-1',
          version: 3,
          createdAt: '2026-08-02T00:00:00Z',
          updatedAt: '2026-08-02T00:00:00Z',
        ),
        MealCatalogItemModel(
          code: 'morning_snack_1',
          mealType: 'morning_snack',
          mealName: 'Phụ sáng',
          description: 'Mô tả',
          cookingInstructions: 'Chuẩn bị',
          calories: 100,
          protein: 2,
          carbs: 20,
          fat: 1,
          fiber: 2,
          waterMl: 0,
          createdAt: '2026-08-02T00:00:00Z',
          updatedAt: '2026-08-02T00:00:00Z',
        ),
        MealCatalogItemModel(
          code: 'lunch_1',
          mealType: 'lunch',
          mealName: 'Bữa trưa',
          description: 'Mô tả',
          cookingInstructions: 'Chuẩn bị',
          calories: 500,
          protein: 20,
          carbs: 60,
          fat: 12,
          fiber: 6,
          waterMl: 0,
          createdAt: '2026-08-02T00:00:00Z',
          updatedAt: '2026-08-02T00:00:00Z',
        ),
        MealCatalogItemModel(
          code: 'afternoon_snack_1',
          mealType: 'afternoon_snack',
          mealName: 'Phụ chiều',
          description: 'Mô tả',
          cookingInstructions: 'Chuẩn bị',
          calories: 110,
          protein: 3,
          carbs: 18,
          fat: 2,
          fiber: 2,
          waterMl: 0,
          createdAt: '2026-08-02T00:00:00Z',
          updatedAt: '2026-08-02T00:00:00Z',
        ),
        MealCatalogItemModel(
          code: 'dinner_1',
          mealType: 'dinner',
          mealName: 'Bữa tối',
          description: 'Mô tả',
          cookingInstructions: 'Chuẩn bị',
          calories: 420,
          protein: 18,
          carbs: 50,
          fat: 10,
          fiber: 5,
          waterMl: 0,
          createdAt: '2026-08-02T00:00:00Z',
          updatedAt: '2026-08-02T00:00:00Z',
        ),
      ],
      exercises: <ExerciseCatalogItemModel>[],
      scheduleTasks: <ScheduleTaskCatalogItemModel>[],
    );

    final meals = const MealPlanAiNormalizer().normalize(
      items: const <Map<String, Object?>>[
        {
          'day': 1,
          'meal_type': 'breakfast',
          'meal_code': 'breakfast_1',
        },
        {
          'day': 1,
          'meal_type': 'morning_snack',
          'meal_code': 'morning_snack_1',
        },
        {'day': 1, 'meal_type': 'lunch', 'meal_code': 'lunch_1'},
        {
          'day': 1,
          'meal_type': 'afternoon_snack',
          'meal_code': 'afternoon_snack_1',
        },
        {'day': 1, 'meal_type': 'dinner', 'meal_code': 'dinner_1'},
      ],
      catalog: catalog,
      userId: 'user-1',
      startDate: DateTime(2026, 8, 2),
      days: 1,
      createdAt: '2026-08-02T00:00:00Z',
    );

    final breakfast = meals.first;
    expect(breakfast.catalogCode, 'breakfast_1');
    expect(breakfast.ingredients, <String>['Gạo', 'Rau']);
    expect(breakfast.cookingSteps, <String>['Rửa nguyên liệu', 'Nấu chín']);
    expect(breakfast.provenanceSource, contains('Suc_Khoe_Tu_Nha_Bep'));
    expect(breakfast.sourceHash, 'source-hash-1');
    expect(breakfast.catalogSchemaVersion, 3);
  });
}

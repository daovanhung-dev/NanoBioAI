import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/application/food_scan_prompts.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/domain/entities/food_scan_models.dart';

void main() {
  test('vision prompt requires multiple foods, allergens and structured JSON', () {
    final prompt = FoodScanPrompts.vision();
    expect(prompt, contains('is_food_image'));
    expect(prompt, contains('estimated_weight_g'));
    expect(prompt, contains('possible_allergens'));
    expect(prompt, contains('nutrition_label'));
    expect(prompt, contains('JSON'));
  });

  test('health prompt keeps medical safety boundaries and per-condition review', () {
    const item = FoodScanItem(
      id: '1',
      name: 'Cơm trắng',
      normalizedName: 'com trang',
      estimatedWeightGrams: 180,
      confirmedWeightGrams: 180,
      portionDescription: '1 bát',
      cookingMethod: 'nấu',
      ingredients: ['gạo'],
      possibleAllergens: [],
      confidence: .9,
      nutrition: NutritionEstimate(caloriesKcal: 234),
      nutritionSource: 'internal_catalog',
    );

    final prompt = FoodScanPrompts.health(
      healthContext: {
        'health_conditions': [
          {'condition_name': 'Ví dụ bệnh', 'severity_level': 1},
        ],
      },
      items: const [item],
      totalNutrition: const NutritionEstimate(caloriesKcal: 234),
      deterministicWarnings: const [],
    );

    expect(prompt, contains('Không khuyên người dùng tự ngừng/bỏ/dừng thuốc'));
    expect(prompt, contains('Không nói "an toàn tuyệt đối"'));
    expect(prompt, contains('Phân tích riêng từng bệnh lý'));
    expect(prompt, contains('suitability_score'));
  });
  test('health result keeps daily goal comparison for UI', () {
    final evaluation = FoodHealthEvaluation.fromJson({
      'overall': {
        'status': 'can_nhac',
        'suitability_score': 70,
        'summary_vi': 'Có thể dùng với điều chỉnh nhỏ.',
      },
      'daily_goal_review': {
        'summary_vi': 'Bữa này chiếm khoảng một phần mục tiêu ngày.',
        'items': [
          {
            'label': 'Năng lượng',
            'current': 600,
            'target': 2000,
            'unit': 'kcal',
            'assessment_vi': 'Còn dư địa cho các bữa sau.',
          },
        ],
      },
    });

    expect(evaluation.dailyGoalSummary, contains('mục tiêu ngày'));
    expect(evaluation.dailyGoalNotes.single, contains('Năng lượng'));
    expect(evaluation.dailyGoalNotes.single, contains('600'));
  });

  test('unsafe medical AI wording is replaced before UI', () {
    final evaluation = FoodHealthEvaluation.fromJson({
      'overall': {
        'status': 'khong_phu_hop',
        'suitability_score': 10,
        'summary_vi': 'Bạn nên ngừng thuốc ngay và chỉ ăn món này.',
      },
    });

    expect(evaluation.summary, isNot(contains('ngừng thuốc ngay')));
    expect(evaluation.summary, contains('bác sĩ'));
  });

}

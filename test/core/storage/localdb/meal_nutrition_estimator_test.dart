import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/seeders/meal_nutrition_estimator.dart';

void main() {
  test('estimates quantified smoothie per serving', () {
    final value = MealNutritionEstimator.estimate(
      ingredients: const [
        '1 quả chuối chín',
        '30g hạt điều',
        '200ml sữa hạnh nhân',
        '1 thìa mật ong',
      ],
      mealName: 'Sinh tố chuối hạt điều',
    );

    expect(value, isNotNull);
    expect(value!.calories, greaterThan(250));
    expect(value.protein, greaterThan(5));
    expect(value.servingSize, '1 khẩu phần (ước tính)');
  });

  test('does not invent unquantified seasoning', () {
    final value = MealNutritionEstimator.estimate(
      ingredients: const ['200g thịt bò', 'Gia vị: muối, tiêu, dầu ăn'],
      mealName: 'Bò áp chảo',
    );

    expect(value, isNotNull);
    expect(value!.sodiumMg, lessThan(200));
  });

  test('returns null when recipe has no quantified estimable ingredient', () {
    final value = MealNutritionEstimator.estimate(
      ingredients: const ['Gia vị vừa ăn'],
      mealName: 'Món thử',
    );

    expect(value, isNull);
  });
}

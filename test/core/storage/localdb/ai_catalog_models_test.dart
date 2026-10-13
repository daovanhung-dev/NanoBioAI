import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

void main() {
  test(
    'parses prefix and suffix ingredient amounts without losing source text',
    () {
      final meal = MealCatalogItemModel.fromSourceJson({
        'code': 'meal-1',
        'meal_name': 'Món thử',
        'ingredients': [
          '40 g yến mạch',
          'trứng 1 quả',
          'dầu ăn 1 muỗng canh',
          'muối vừa đủ',
        ],
      }, timestamp: '2026-10-13T00:00:00Z');

      expect(meal.ingredientQuantities, hasLength(4));
      expect(meal.ingredientQuantities[0].name, 'yến mạch');
      expect(meal.ingredientQuantities[0].quantity, 40);
      expect(meal.ingredientQuantities[0].unit, 'g');
      expect(meal.ingredientQuantities[0].sourceText, '40 g yến mạch');
      expect(meal.ingredientQuantities[1].name, 'trứng');
      expect(meal.ingredientQuantities[1].quantity, 1);
      expect(meal.ingredientQuantities[1].unit, 'quả');
      expect(meal.ingredientQuantities[2].name, 'dầu ăn');
      expect(meal.ingredientQuantities[2].quantity, 1);
      expect(meal.ingredientQuantities[2].unit, 'muỗng canh');
      expect(meal.ingredientQuantities[3].name, 'muối vừa đủ');
      expect(meal.ingredientQuantities[3].quantity, isNull);
      expect(meal.ingredientQuantities[3].unit, isEmpty);
    },
  );
}

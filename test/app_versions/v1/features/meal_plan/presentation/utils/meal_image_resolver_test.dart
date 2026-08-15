import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';

void main() {
  group('MealImageResolver', () {
    test('normalizes Vietnamese meal names deterministically', () {
      expect(
        MealImageResolver.slugFor('CANH THỊT BÒ RAU CẢI BÓ XÔI'),
        'canh_thit_bo_rau_cai_bo_xoi',
      );
      expect(
        MealImageResolver.slugFor('Cháo thịt bò – bí đỏ'),
        'chao_thit_bo_bi_do',
      );
      expect(
        MealImageResolver.slugFor('  Sinh tố cà rốt và dứa  '),
        'sinh_to_ca_rot_va_dua',
      );
    });

    test('builds a local WebP asset path', () {
      expect(
        MealImageResolver.assetPathForName('Trà gừng và mật ong'),
        'assets/images/meals/pdf_health_book/tra_gung_va_mat_ong.webp',
      );
    });
  });
}

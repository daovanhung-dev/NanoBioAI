import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';

void main() {
  group('MealImageResolver', () {
    test('resolves verified Vietnamese dish names exactly', () {
      expect(
        MealImageResolver.resolveAssetPath('Canh bí đao nấu tôm'),
        'assets/images/meals/pdf_health_book/canh_bi_dao_nau_tom.webp',
      );
      expect(
        MealImageResolver.resolveAssetPath('SÚP KHOAI TÂY VÀ CAROT'),
        'assets/images/meals/pdf_health_book/sup_khoai_tay_va_carot.webp',
      );
      expect(
        MealImageResolver.resolveAssetPath('Trà hoa cúc mật ong'),
        'assets/images/meals/pdf_health_book/tra_hoa_cuc_mat_ong.webp',
      );
    });

    test('keeps canonical slug normalization deterministic', () {
      expect(
        MealImageResolver.slugFor('  Sinh tố cần tây và táo!  '),
        'sinh_to_can_tay_va_tao',
      );
      expect(
        MealImageResolver.canonicalSlug('Canh cá chép nấu rau cần'),
        'canh_ca_chep_nau_rau_can',
      );
    });

    test('never guesses an image for an unknown meal', () {
      expect(MealImageResolver.resolveAssetPath('Món hoàn toàn mới'), isNull);
      expect(
        MealImageResolver.assetPathForName('Món hoàn toàn mới'),
        'assets/images/meals/pdf_health_book/__unknown_meal__.webp',
      );
    });

    test('compatibility API returns the same exact verified path', () {
      expect(
        MealImageResolver.assetPathForName('Canh bí đao nấu tôm'),
        MealImageResolver.resolveAssetPath('Canh bí đao nấu tôm'),
      );
    });
  });
}

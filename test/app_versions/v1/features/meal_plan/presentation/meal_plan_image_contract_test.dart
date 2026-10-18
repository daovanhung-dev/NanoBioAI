import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart';

void main() {
  test('meal plan cards, details, and replacement choices render MealPhoto', () {
    final source = File(
      'lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_replacement_picker.dart',
    ).readAsStringSync();

    expect(source, contains("presentation/widgets/meal_photo.dart"));
    expect('MealPhoto('.allMatches(source).length, greaterThanOrEqualTo(2));
    expect(picker, contains('MealPhoto.catalogItem('));
    expect(picker, contains('catalogCode: candidate.code'));
    expect(picker, contains('mealName: candidate.mealName'));
  });

  test('MealPhoto resolves code-keyed assets before building Image.asset', () {
    final source = File(
      'lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart',
    ).readAsStringSync();

    expect(source, contains('MealImageResolver.assetPathsForCatalogItem('));
    expect(source, contains('assetPaths.isEmpty'));
    expect(source, contains('Image.asset('));
    expect(source, contains('_MealPhotoFallback('));
  });

  testWidgets('MealPhoto loads verified catalog images from the asset bundle', (
    tester,
  ) async {
    const meals = <(String, String)>[
      (
        'nabi_vn_0041_chao_ca_ro_dong_cai_ngot_gao_lut',
        'Cháo cá rô đồng cải ngọt gạo lứt',
      ),
      ('nabi_vn_0042_chao_luon_cai_ngot_gao_lut', 'Cháo lươn cải ngọt gạo lứt'),
      ('nabi_vn_0043_com_chien_thit_ech_su_su', 'Cơm chiên thịt ếch su su'),
      (
        'nabi_vn_0044_chao_ca_chep_cai_thia_gao_lut',
        'Cháo cá chép cải thìa gạo lứt',
      ),
      (
        'nabi_vn_0045_uc_ga_nuong_nuoc_dua_kem_ca_tim',
        'Ức gà nướng nước dừa kèm cà tím',
      ),
      (
        'nabi_vn_0046_hu_tieu_kho_ca_ro_dong_ca_chua',
        'Hủ tiếu khô cá rô đồng cà chua',
      ),
      ('nabi_vn_0047_goi_ga_ta_ngo_sen_voi_dua', 'Gỏi gà ta ngó sen với dứa'),
      (
        'nabi_vn_0048_oc_buou_xao_can_tay_voi_ot_chuong',
        'Ốc bươu xào cần tây với ớt chuông',
      ),
      ('nabi_vn_0049_banh_canh_thit_vit_gia_do', 'Bánh canh thịt vịt giá đỗ'),
      ('nabi_vn_0050_xoi_gac_me_den', 'Xôi gấc mè đen'),
      (
        'nabi_vn_0051_canh_bap_cai_nau_tom_tuoi_va_ca_chua',
        'Canh bắp cải nấu tôm tươi và cà chua',
      ),
      (
        'nabi_vn_0052_dau_hu_non_hap_tieu_xanh_cung_nam_rom',
        'Đậu hũ non hấp tiêu xanh cùng nấm rơm',
      ),
      ('nabi_vn_0053_chao_ngheu_su_su_gao_lut', 'Cháo nghêu su su gạo lứt'),
      (
        'nabi_vn_0054_nam_dui_ga_xao_cai_ngot_voi_nam_rom',
        'Nấm đùi gà xào cải ngọt với nấm rơm',
      ),
      (
        'nabi_vn_0055_che_chuoi_nuoc_cot_dua_huong_la_dua',
        'Chè chuối nước cốt dừa hương lá dứa',
      ),
      ('nabi_vn_0066_chao_luon_ca_rot_gao_lut', 'Cháo lươn cà rốt gạo lứt'),
      (
        'nabi_vn_0067_thit_vit_nuong_mam_toi_kem_dua',
        'Thịt vịt nướng mắm tỏi kèm dứa',
      ),
      (
        'nabi_vn_0068_ghe_hap_nghe_sa_cung_nam_rom',
        'Ghẹ hấp nghệ sả cùng nấm rơm',
      ),
      (
        'nabi_vn_0069_ga_ta_kho_toi_ot_voi_dau_hu',
        'Gà ta kho tỏi ớt với đậu hũ',
      ),
      (
        'nabi_vn_0070_ca_thu_nuong_sa_gung_kem_ca_tim',
        'Cá thu nướng sả gừng kèm cà tím',
      ),
      (
        'nabi_vn_0071_thit_ech_kho_gung_voi_khe_chua',
        'Thịt ếch kho gừng với khế chua',
      ),
      (
        'nabi_vn_0072_ga_ta_kho_gung_voi_mang_tuoi',
        'Gà ta kho gừng với măng tươi',
      ),
      ('nabi_vn_0073_banh_beo_nhan_hen_bap_cai', 'Bánh bèo nhân hến bắp cải'),
      (
        'nabi_vn_0074_nam_dui_ga_nuong_tieu_xanh_kem_dua',
        'Nấm đùi gà nướng tiêu xanh kèm dứa',
      ),
      (
        'nabi_vn_0075_ca_loc_hap_toi_ot_cung_ca_rot',
        'Cá lóc hấp tỏi ớt cùng cà rốt',
      ),
      (
        'nabi_vn_0076_banh_trang_cuon_nam_rom_hanh_tay',
        'Bánh tráng cuốn nấm rơm hành tây',
      ),
      (
        'nabi_vn_0077_thit_vit_kho_hanh_tim_voi_cai_chua',
        'Thịt vịt kho hành tím với cải chua',
      ),
      (
        'nabi_vn_0078_canh_kho_qua_nau_thit_heo_xay_va_ca_rot',
        'Canh khổ qua nấu thịt heo xay và cà rốt',
      ),
      (
        'nabi_vn_0079_ca_ro_phi_kho_hanh_tim_voi_dua',
        'Cá rô phi kho hành tím với dứa',
      ),
      (
        'nabi_vn_0080_chao_tep_dong_hat_sen_tuoi_gao_lut',
        'Cháo tép đồng hạt sen tươi gạo lứt',
      ),
      (
        'nabi_vn_0081_banh_canh_thit_nac_heo_cai_thia',
        'Bánh canh thịt nạc heo cải thìa',
      ),
      ('nabi_vn_0082_mien_nuoc_thit_ga_ca_chua', 'Miến nước thịt gà cà chua'),
      (
        'nabi_vn_0083_banh_xeo_nhan_thit_vit_ca_rot',
        'Bánh xèo nhân thịt vịt cà rốt',
      ),
      (
        'nabi_vn_0084_canh_muop_huong_nau_tep_dong_va_ca_rot',
        'Canh mướp hương nấu tép đồng và cà rốt',
      ),
      (
        'nabi_vn_0085_canh_rau_muong_nau_tom_tuoi_va_doc_mung',
        'Canh rau muống nấu tôm tươi và dọc mùng',
      ),
      (
        'nabi_vn_0086_com_chien_thit_vit_cai_ngot',
        'Cơm chiên thịt vịt cải ngọt',
      ),
      (
        'nabi_vn_0087_hu_tieu_kho_suon_non_mang_tuoi',
        'Hủ tiếu khô sườn non măng tươi',
      ),
      (
        'nabi_vn_0088_canh_bap_cai_nau_thit_bo_va_nam_huong',
        'Canh bắp cải nấu thịt bò và nấm hương',
      ),
      (
        'nabi_vn_0089_dau_hu_kho_nuoc_mau_voi_nam_rom',
        'Đậu hũ kho nước màu với nấm rơm',
      ),
      (
        'nabi_vn_0090_dui_ga_nuong_sa_gung_kem_ot_chuong',
        'Đùi gà nướng sả gừng kèm ớt chuông',
      ),
      (
        'nabi_vn_0091_thit_ba_chi_xao_su_su_voi_nam_rom',
        'Thịt ba chỉ xào su su với nấm rơm',
      ),
      (
        'nabi_vn_0092_goi_luon_bap_cai_voi_rau_ram',
        'Gỏi lươn bắp cải với rau răm',
      ),
      (
        'nabi_vn_0093_hu_tieu_nuoc_thit_vit_cai_thao',
        'Hủ tiếu nước thịt vịt cải thảo',
      ),
      (
        'nabi_vn_0094_tom_tuoi_kho_nuoc_mau_voi_dua',
        'Tôm tươi kho nước màu với dứa',
      ),
      (
        'nabi_vn_0095_tom_su_hap_nam_huong_cung_cai_thao',
        'Tôm sú hấp nấm hương cùng cải thảo',
      ),
      ('nabi_vn_0096_dau_phu_chien_sa_ot', 'Đậu phụ chiên sả ớt'),
      (
        'nabi_vn_0097_dau_hu_non_hap_gung_hanh_cung_cai_thao',
        'Đậu hũ non hấp gừng hành cùng cải thảo',
      ),
      (
        'nabi_vn_0098_ga_ta_nuong_rieng_me_kem_dua',
        'Gà ta nướng riềng mẻ kèm dứa',
      ),
      (
        'nabi_vn_0099_che_vai_me_den_huong_la_dua',
        'Chè vải mè đen hương lá dứa',
      ),
      (
        'nabi_vn_0100_thit_bo_xao_bong_thien_ly_voi_hanh_tay',
        'Thịt bò xào bông thiên lý với hành tây',
      ),
      (
        'nabi_vn_0101_goi_thit_vit_cu_hu_dua_voi_dua',
        'Gỏi thịt vịt củ hũ dừa với dứa',
      ),
      (
        'nabi_vn_0102_chao_thit_heo_xay_khoai_mon_gao_lut',
        'Cháo thịt heo xay khoai môn gạo lứt',
      ),
      (
        'nabi_vn_0103_banh_nam_nhan_nam_rom_nam_huong',
        'Bánh nậm nhân nấm rơm nấm hương',
      ),
      ('nabi_vn_0104_tom_tuoi_kho_sa_voi_dau_hu', 'Tôm tươi kho sả với đậu hũ'),
      (
        'nabi_vn_0105_thit_ech_nuong_nuoc_dua_kem_ot_chuong',
        'Thịt ếch nướng nước dừa kèm ớt chuông',
      ),
    ];
    final bundledAssets = (await AssetManifest.loadFromAssetBundle(
      rootBundle,
    )).listAssets();

    for (final meal in meals) {
      expect(
        bundledAssets,
        contains('assets/images/meals/catalog_v1/${meal.$1}.png'),
        reason: meal.$1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealPhoto.catalogItem(
              catalogCode: meal.$1,
              mealName: meal.$2,
              width: 160,
              height: 220,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget, reason: meal.$1);
      expect(find.text('Chưa có ảnh món ăn'), findsNothing, reason: meal.$1);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>(), reason: meal.$1);
      final provider = image.image;
      if (provider is AssetImage) {
        expect(
          provider.assetName,
          'assets/images/meals/catalog_v1/${meal.$1}.png',
          reason: meal.$1,
        );
      }
    }
  });
}

import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';

/// Resolves meal names to the exact source-backed images extracted from
/// "Sức Khỏe Từ Nhà Bếp".
///
/// The resolver intentionally performs no fuzzy/substring matching. A meal is
/// allowed to use an image only when its normalized canonical name produces a
/// filename that exists in [_knownAssetFiles]. Unknown meals return `null` so
/// the UI can render a neutral placeholder instead of a potentially wrong dish.
abstract final class MealImageResolver {
  static const String basePath = 'assets/images/meals/pdf_health_book';
  static const String assetRoot = basePath;
  static const String _fallbackAssetPath = '$basePath/__unknown_meal__.webp';

  static const Set<String> _knownAssetFiles = <String>{
    'canh_bi_dao_nau_tom.webp',
    'canh_bi_dao_va_nam.webp',
    'canh_bi_do_nau_thit_ga.webp',
    'canh_ca_chep_nau_rau_can.webp',
    'canh_ca_chep_va_rau_can.webp',
    'canh_ca_chua_nau_dau_phu.webp',
    'canh_ca_chua_nau_trung_ga.webp',
    'canh_ca_hoi_va_bong_cai_xanh.webp',
    'canh_ca_hoi_voi_cai_bo_xoi.webp',
    'canh_ca_loc_nau_rau_cai.webp',
    'canh_ca_loc_nau_rau_can.webp',
    'canh_ca_loc_nau_rau_mong_toi.webp',
    'canh_ca_rot_ham_xuong.webp',
    'canh_ca_rot_voi_hat_sen.webp',
    'canh_cai_xanh_voi_tom.webp',
    'canh_cu_cai_va_rau_cai_bo_xoi.webp',
    'canh_cu_cai_voi_rau_cai_bo_xoi.webp',
    'canh_dau_bap_nau_nam_rom.webp',
    'canh_dau_den_va_rong_bien.webp',
    'canh_dau_do_nau_ga.webp',
    'canh_du_du_ham_suon_non.webp',
    'canh_ga_ham_thuoc_bac.webp',
    'canh_ga_nau_nam.webp',
    'canh_ga_nau_rau_cai_thao.webp',
    'canh_ga_nau_rau_ngot.webp',
    'canh_hau_va_rau_can_tay.webp',
    'canh_mong_toi_nau_cua.webp',
    'canh_nam_dong_co_va_rau_ngot.webp',
    'canh_nam_dong_co_va_rong_bien.webp',
    'canh_nam_huong_va_dau_hu.webp',
    'canh_nam_huong_va_ga.webp',
    'canh_rau_cai_xoan_va_hat_chia.webp',
    'canh_rau_can_tay_va_ca_rot.webp',
    'canh_rau_cu_cai_voi_thit_ga.webp',
    'canh_rau_cu_cai_voi_tom.webp',
    'canh_rau_den_do_voi_hat_sen.webp',
    'canh_rau_den_do_voi_tom.webp',
    'canh_rau_ma_cu_den.webp',
    'canh_rau_ma_va_ca_rot.webp',
    'canh_rau_mong_toi_va_dau_hu.webp',
    'canh_rau_mong_toi_voi_dau_phu.webp',
    'canh_rau_ngot_nau_thit_bam.webp',
    'canh_rau_ngot_voi_tom.webp',
    'canh_rau_sam.webp',
    'canh_rong_bien_va_dau_hu.webp',
    'canh_thit_bo_nau_ngoc_truc_va_ky_tu.webp',
    'canh_thit_bo_rau_cai_bo_xoi.webp',
    'canh_xuong_ham_du_du.webp',
    'chao_bot_gao_voi_hat_chia.webp',
    'chao_bot_gao_voi_hat_sen.webp',
    'chao_dau_do_va_hat_sen.webp',
    'chao_ga_va_hat_sen.webp',
    'chao_gao_lut_dau_den.webp',
    'chao_gao_lut_voi_dau_xanh.webp',
    'chao_hanh_tia_to.webp',
    'chao_hat_sen_dau_xanh.webp',
    'chao_hau_bien_va_hat_sen.webp',
    'chao_khoai_lang_hat_dieu.webp',
    'chao_khoai_lang_tim_va_gao_lut.webp',
    'chao_thit_bo_bi_do.webp',
    'chao_yen_mach_va_thit_ga.webp',
    'dau_nanh_ham_lac_dau_phong.webp',
    'nuoc_ep_buoi_va_tao_do.webp',
    'nuoc_ep_ca_rot_va_cu_cai_do.webp',
    'nuoc_ep_ca_rot_va_cu_den.webp',
    'nuoc_ep_cam_va_bac_ha.webp',
    'nuoc_ep_cam_va_chanh.webp',
    'nuoc_ep_dua_hau_va_bac_ha.webp',
    'nuoc_ep_dua_hau_va_gung.webp',
    'nuoc_ep_dua_hau_va_la_bac_ha.webp',
    'nuoc_ep_dua_hau_va_la_huong_duong.webp',
    'nuoc_ep_dua_tuoi.webp',
    'nuoc_ep_kho_qua_va_tao_xanh.webp',
    'nuoc_ep_mat_ong_va_chanh.webp',
    'nuoc_hat_dau_nanh_vung_den.webp',
    'salad_cai_bo_xoi_va_qua_bo.webp',
    'salad_cai_xoan_va_hat_chia.webp',
    'salad_dau_o_liu_va_hat_chia.webp',
    'salad_rau_diep_ca_va_ca_chua.webp',
    'salad_rau_diep_ca_va_qua_oc_cho.webp',
    'sinh_to_bo_va_dua.webp',
    'sinh_to_bo_va_hat_oc_cho.webp',
    'sinh_to_bo_va_sua_chua.webp',
    'sinh_to_ca_rot_ca_chua.webp',
    'sinh_to_ca_rot_va_cu_den.webp',
    'sinh_to_ca_rot_va_dua.webp',
    'sinh_to_cam_va_bac_ha.webp',
    'sinh_to_cam_va_ca_rot.webp',
    'sinh_to_cam_va_chanh.webp',
    'sinh_to_cam_va_cu_den.webp',
    'sinh_to_cam_va_gung.webp',
    'sinh_to_can_tay_va_tao.webp',
    'sinh_to_chuoi_hat_dieu.webp',
    'sinh_to_chuoi_va_dau_tay.webp',
    'sinh_to_chuoi_va_hat_dieu.webp',
    'sinh_to_diep_ca_va_nha_dam.webp',
    'sinh_to_du_du_sua_chua.webp',
    'sinh_to_du_du_va_sua_chua.webp',
    'sinh_to_dua_hau_va_bac_ha.webp',
    'sinh_to_dua_hau_va_dua_chuot.webp',
    'sinh_to_dua_va_gung.webp',
    'sinh_to_khoai_lang_va_nghe.webp',
    'sinh_to_la_trau_khong_va_dua.webp',
    'sinh_to_rau_bina_va_dua_chuot.webp',
    'sinh_to_rau_ma_va_dua_chuot.webp',
    'sinh_to_sua_hat_dieu_va_chuoi.webp',
    'sinh_to_xoai_hanh_nhan.webp',
    'sinh_to_xoai_sua_chua.webp',
    'sua_nghe_hat_sen.webp',
    'sup_bi_do_hat_sen.webp',
    'sup_chuoi_xanh.webp',
    'sup_khoai_tay_va_carot.webp',
    'tra_cam_thao_va_que.webp',
    'tra_chanh_mat_ong.webp',
    'tra_gung_nghe_mat_ong.webp',
    'tra_gung_que_mat_ong.webp',
    'tra_gung_va_chanh.webp',
    'tra_gung_va_mat_ong.webp',
    'tra_hoa_cuc_mat_ong.webp',
    'tra_hoa_cuc_va_bac_ha.webp',
    'tra_la_xoai.webp',
    'tra_nhan_sam_va_mat_ong.webp',
    'tra_xanh_va_bac_ha.webp',
    'trung_ga_hap_mat_ong.webp',
  };

  /// Compatibility API used by the existing MealPhoto widget.
  ///
  /// Unknown meals intentionally return a guaranteed-missing sentinel path so
  /// Image.asset invokes its errorBuilder instead of displaying a wrong dish.
  static String assetPathFor(MealPlanEntity meal) {
    return assetPathForName(meal.mealName);
  }

  /// Compatibility API retained for older call sites.
  static String assetPathForName(String mealName) {
    return resolveAssetPath(mealName) ?? _fallbackAssetPath;
  }

  /// Compatibility alias for the previous resolver API.
  static String slugFor(String value) => canonicalSlug(value);

  /// Returns an exact asset path for [mealName], or `null` when no verified
  /// image exists in the health-book asset inventory.
  static String? resolveAssetPath(String mealName) {
    final slug = canonicalSlug(mealName);
    if (slug.isEmpty) return null;

    final fileName = '$slug.webp';
    if (!_knownAssetFiles.contains(fileName)) return null;
    return '$basePath/$fileName';
  }

  /// Converts a Vietnamese canonical dish name to the filename convention used
  /// by the health-book image directory.
  ///
  /// This is deterministic normalization only; it does not approximate names.
  static String canonicalSlug(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';

    final buffer = StringBuffer();
    var pendingSeparator = false;

    for (final rune in normalized.runes) {
      final source = String.fromCharCode(rune);
      final folded = _foldVietnamese(source);
      for (final codeUnit in folded.codeUnits) {
        final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
        final isDigit = codeUnit >= 48 && codeUnit <= 57;
        if (isAsciiLetter || isDigit) {
          if (pendingSeparator && buffer.length > 0) buffer.write('_');
          buffer.write(String.fromCharCode(codeUnit));
          pendingSeparator = false;
        } else if (buffer.length > 0) {
          pendingSeparator = true;
        }
      }
    }

    return buffer.toString();
  }

  static String _foldVietnamese(String value) {
    switch (value) {
      case 'à':
      case 'á':
      case 'ạ':
      case 'ả':
      case 'ã':
      case 'â':
      case 'ầ':
      case 'ấ':
      case 'ậ':
      case 'ẩ':
      case 'ẫ':
      case 'ă':
      case 'ằ':
      case 'ắ':
      case 'ặ':
      case 'ẳ':
      case 'ẵ':
        return 'a';
      case 'è':
      case 'é':
      case 'ẹ':
      case 'ẻ':
      case 'ẽ':
      case 'ê':
      case 'ề':
      case 'ế':
      case 'ệ':
      case 'ể':
      case 'ễ':
        return 'e';
      case 'ì':
      case 'í':
      case 'ị':
      case 'ỉ':
      case 'ĩ':
        return 'i';
      case 'ò':
      case 'ó':
      case 'ọ':
      case 'ỏ':
      case 'õ':
      case 'ô':
      case 'ồ':
      case 'ố':
      case 'ộ':
      case 'ổ':
      case 'ỗ':
      case 'ơ':
      case 'ờ':
      case 'ớ':
      case 'ợ':
      case 'ở':
      case 'ỡ':
        return 'o';
      case 'ù':
      case 'ú':
      case 'ụ':
      case 'ủ':
      case 'ũ':
      case 'ư':
      case 'ừ':
      case 'ứ':
      case 'ự':
      case 'ử':
      case 'ữ':
        return 'u';
      case 'ỳ':
      case 'ý':
      case 'ỵ':
      case 'ỷ':
      case 'ỹ':
        return 'y';
      case 'đ':
        return 'd';
      default:
        return value;
    }
  }
}

import 'package:nano_app/core/constants/onboarding_constants.dart';

/// Presentation-only onboarding data.
///
/// All selectable values use [OnboardingChoiceOption]. This removes the old
/// mix of raw strings, maps, chip models, and bespoke option classes.
abstract final class OnboardingOptions {
  static List<int> get birthYears {
    final latest = DateTime.now().year - 6;
    return List<int>.generate(latest - 1920 + 1, (index) => latest - index);
  }

  static const List<OnboardingChoiceOption> sleepQualityChoices = [
    OnboardingChoiceOption(code: 'sleep_great', label: 'Ngủ ngon', emoji: '😴'),
    OnboardingChoiceOption(
      code: 'sleep_good',
      label: 'Ngủ khá ổn',
      emoji: '🙂',
    ),
    OnboardingChoiceOption(
      code: 'sleep_light',
      label: 'Ngủ không sâu',
      emoji: '🌙',
    ),
    OnboardingChoiceOption(
      code: 'sleep_late',
      label: 'Hay thức khuya',
      emoji: '🌌',
    ),
    OnboardingChoiceOption(
      code: 'sleep_wake',
      label: 'Hay thức giấc',
      emoji: '⏰',
    ),
    OnboardingChoiceOption(
      code: 'sleep_hard',
      label: 'Khó đi vào giấc',
      emoji: '🫠',
    ),
    OnboardingChoiceOption(
      code: 'sleep_tired',
      label: 'Dậy vẫn mệt',
      emoji: '🥱',
    ),
  ];

  static const List<OnboardingChoiceOption> activityChoices = [
    OnboardingChoiceOption(
      code: 'activity_low',
      label: 'Ít vận động',
      emoji: '🪑',
    ),
    OnboardingChoiceOption(
      code: 'activity_walk',
      label: 'Đi bộ nhẹ',
      emoji: '🚶',
    ),
    OnboardingChoiceOption(
      code: 'activity_1_2',
      label: 'Tập 1–2 buổi/tuần',
      emoji: '🧘',
    ),
    OnboardingChoiceOption(
      code: 'activity_3_4',
      label: 'Tập 3–4 buổi/tuần',
      emoji: '🏃',
    ),
    OnboardingChoiceOption(
      code: 'activity_5_plus',
      label: 'Tập từ 5 buổi/tuần',
      emoji: '🏋️',
    ),
    OnboardingChoiceOption(
      code: 'activity_manual',
      label: 'Lao động thể lực',
      emoji: '🛠️',
    ),
    OnboardingChoiceOption(
      code: 'activity_athlete',
      label: 'Cường độ cao',
      emoji: '⚡',
    ),
  ];

  static const List<OnboardingChoiceOption> waterChoices = [
    OnboardingChoiceOption(
      code: 'water_less_1',
      label: 'Dưới 1 lít/ngày',
      emoji: '🥤',
    ),
    OnboardingChoiceOption(
      code: 'water_1_1_5',
      label: '1–1,5 lít/ngày',
      emoji: '💧',
    ),
    OnboardingChoiceOption(
      code: 'water_1_5_2',
      label: '1,5–2 lít/ngày',
      emoji: '💦',
    ),
    OnboardingChoiceOption(
      code: 'water_2_2_5',
      label: '2–2,5 lít/ngày',
      emoji: '🚰',
    ),
    OnboardingChoiceOption(
      code: 'water_2_5_3',
      label: '2,5–3 lít/ngày',
      emoji: '🫗',
    ),
    OnboardingChoiceOption(
      code: 'water_more_3',
      label: 'Trên 3 lít/ngày',
      emoji: '🌊',
    ),
    OnboardingChoiceOption(
      code: 'water_unsure',
      label: 'Chưa ước lượng được',
      emoji: '🤔',
    ),
  ];

  /// 25 options for the allergy / food restriction picker.
  static const List<OnboardingChoiceOption> allergyChoices = [
    OnboardingChoiceOption(code: 'none', label: 'Không / chưa rõ', emoji: '✅'),
    OnboardingChoiceOption(code: 'seafood', label: 'Hải sản', emoji: '🦐'),
    OnboardingChoiceOption(code: 'fish', label: 'Cá', emoji: '🐟'),
    OnboardingChoiceOption(
      code: 'shellfish',
      label: 'Động vật có vỏ',
      emoji: '🦀',
    ),
    OnboardingChoiceOption(
      code: 'milk_lactose',
      label: 'Sữa / lactose',
      emoji: '🥛',
    ),
    OnboardingChoiceOption(code: 'egg', label: 'Trứng', emoji: '🥚'),
    OnboardingChoiceOption(code: 'peanut', label: 'Đậu phộng', emoji: '🥜'),
    OnboardingChoiceOption(
      code: 'tree_nut',
      label: 'Các loại hạt',
      emoji: '🌰',
    ),
    OnboardingChoiceOption(code: 'soy', label: 'Đậu nành', emoji: '🫘'),
    OnboardingChoiceOption(
      code: 'wheat_gluten',
      label: 'Lúa mì / gluten',
      emoji: '🌾',
    ),
    OnboardingChoiceOption(code: 'sesame', label: 'Mè / vừng', emoji: '⚪'),
    OnboardingChoiceOption(code: 'beef', label: 'Thịt bò', emoji: '🥩'),
    OnboardingChoiceOption(code: 'chicken', label: 'Thịt gà', emoji: '🍗'),
    OnboardingChoiceOption(code: 'pork', label: 'Thịt heo', emoji: '🥓'),
    OnboardingChoiceOption(code: 'mushroom', label: 'Nấm', emoji: '🍄'),
    OnboardingChoiceOption(code: 'spicy', label: 'Đồ cay', emoji: '🌶️'),
    OnboardingChoiceOption(code: 'sour', label: 'Đồ chua', emoji: '🍋'),
    OnboardingChoiceOption(code: 'oily', label: 'Đồ nhiều dầu', emoji: '🍟'),
    OnboardingChoiceOption(code: 'caffeine', label: 'Caffeine', emoji: '☕'),
    OnboardingChoiceOption(code: 'alcohol', label: 'Rượu bia', emoji: '🍺'),
    OnboardingChoiceOption(
      code: 'preservative',
      label: 'Chất bảo quản',
      emoji: '🧴',
    ),
    OnboardingChoiceOption(code: 'msg', label: 'Bột ngọt', emoji: '🧂'),
    OnboardingChoiceOption(code: 'sugar', label: 'Đường', emoji: '🍬'),
    OnboardingChoiceOption(
      code: 'other_food',
      label: 'Thực phẩm khác',
      emoji: '✍️',
    ),
    OnboardingChoiceOption(code: 'unknown', label: 'Chưa xác định', emoji: '❔'),
  ];

  /// 25 choices for current health monitoring / treatment.
  static const List<OnboardingChoiceOption> treatmentChoices = [
    OnboardingChoiceOption(
      code: 'none',
      label: 'Không điều trị hiện tại',
      emoji: '✅',
    ),
    OnboardingChoiceOption(
      code: 'blood_pressure',
      label: 'Theo dõi huyết áp',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'blood_sugar',
      label: 'Theo dõi đường huyết',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(
      code: 'digestive',
      label: 'Dạ dày / tiêu hóa',
      emoji: '🌿',
    ),
    OnboardingChoiceOption(code: 'heart', label: 'Tim mạch', emoji: '💓'),
    OnboardingChoiceOption(code: 'thyroid', label: 'Tuyến giáp', emoji: '🦋'),
    OnboardingChoiceOption(
      code: 'kidney',
      label: 'Thận / tiết niệu',
      emoji: '💧',
    ),
    OnboardingChoiceOption(code: 'liver', label: 'Gan', emoji: '🫀'),
    OnboardingChoiceOption(code: 'respiratory', label: 'Hô hấp', emoji: '🫁'),
    OnboardingChoiceOption(
      code: 'bone_joint',
      label: 'Cơ xương khớp',
      emoji: '🦴',
    ),
    OnboardingChoiceOption(code: 'sleep', label: 'Giấc ngủ', emoji: '😴'),
    OnboardingChoiceOption(
      code: 'mental_wellbeing',
      label: 'Sức khỏe tinh thần',
      emoji: '🌤️',
    ),
    OnboardingChoiceOption(code: 'skin', label: 'Da liễu', emoji: '🌸'),
    OnboardingChoiceOption(code: 'dental', label: 'Răng miệng', emoji: '🦷'),
    OnboardingChoiceOption(
      code: 'vision',
      label: 'Mắt / thị lực',
      emoji: '👁️',
    ),
    OnboardingChoiceOption(
      code: 'weight_management',
      label: 'Quản lý cân nặng',
      emoji: '⚖️',
    ),
    OnboardingChoiceOption(
      code: 'rehabilitation',
      label: 'Phục hồi chức năng',
      emoji: '🧑‍🦽',
    ),
    OnboardingChoiceOption(
      code: 'post_surgery',
      label: 'Sau phẫu thuật',
      emoji: '🩹',
    ),
    OnboardingChoiceOption(
      code: 'physical_therapy',
      label: 'Vật lý trị liệu',
      emoji: '🤲',
    ),
    OnboardingChoiceOption(
      code: 'allergy_treatment',
      label: 'Điều trị dị ứng',
      emoji: '🌼',
    ),
    OnboardingChoiceOption(
      code: 'regular_checkup',
      label: 'Khám định kỳ',
      emoji: '🩺',
    ),
    OnboardingChoiceOption(
      code: 'nutrition_counseling',
      label: 'Tư vấn dinh dưỡng',
      emoji: '🥗',
    ),
    OnboardingChoiceOption(
      code: 'pregnancy_postpartum',
      label: 'Thai sản / sau sinh',
      emoji: '🫶',
    ),
    OnboardingChoiceOption(
      code: 'specialist_followup',
      label: 'Theo dõi chuyên khoa',
      emoji: '📋',
    ),
    OnboardingChoiceOption(code: 'other', label: 'Khác', emoji: '✍️'),
  ];

  /// 25 choices for medicines / supplements currently used.
  static const List<OnboardingChoiceOption> medicationChoices = [
    OnboardingChoiceOption(
      code: 'none',
      label: 'Không dùng thường xuyên',
      emoji: '✅',
    ),
    OnboardingChoiceOption(
      code: 'blood_pressure',
      label: 'Thuốc huyết áp',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'blood_sugar',
      label: 'Thuốc đường huyết',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(code: 'gastric', label: 'Thuốc dạ dày', emoji: '🌿'),
    OnboardingChoiceOption(code: 'allergy', label: 'Thuốc dị ứng', emoji: '🌼'),
    OnboardingChoiceOption(
      code: 'pain_relief',
      label: 'Thuốc giảm đau',
      emoji: '💊',
    ),
    OnboardingChoiceOption(
      code: 'sleep_support',
      label: 'Hỗ trợ giấc ngủ',
      emoji: '😴',
    ),
    OnboardingChoiceOption(
      code: 'thyroid',
      label: 'Thuốc tuyến giáp',
      emoji: '🦋',
    ),
    OnboardingChoiceOption(
      code: 'cholesterol',
      label: 'Thuốc mỡ máu',
      emoji: '🧪',
    ),
    OnboardingChoiceOption(code: 'asthma', label: 'Thuốc hô hấp', emoji: '🫁'),
    OnboardingChoiceOption(
      code: 'antibiotic',
      label: 'Kháng sinh',
      emoji: '🦠',
    ),
    OnboardingChoiceOption(
      code: 'vitamin',
      label: 'Vitamin tổng hợp',
      emoji: '🌈',
    ),
    OnboardingChoiceOption(code: 'iron', label: 'Sắt', emoji: '🧲'),
    OnboardingChoiceOption(code: 'calcium', label: 'Canxi', emoji: '🦴'),
    OnboardingChoiceOption(code: 'omega_3', label: 'Omega-3', emoji: '🐟'),
    OnboardingChoiceOption(
      code: 'probiotic',
      label: 'Men vi sinh',
      emoji: '🦠',
    ),
    OnboardingChoiceOption(
      code: 'liver_support',
      label: 'Hỗ trợ gan',
      emoji: '🫀',
    ),
    OnboardingChoiceOption(
      code: 'kidney_support',
      label: 'Hỗ trợ thận',
      emoji: '💧',
    ),
    OnboardingChoiceOption(
      code: 'skin_treatment',
      label: 'Thuốc da liễu',
      emoji: '🌸',
    ),
    OnboardingChoiceOption(
      code: 'hormonal',
      label: 'Thuốc nội tiết',
      emoji: '🧬',
    ),
    OnboardingChoiceOption(
      code: 'anticoagulant',
      label: 'Thuốc chống đông',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(
      code: 'neurological',
      label: 'Thuốc thần kinh',
      emoji: '🧠',
    ),
    OnboardingChoiceOption(code: 'herbal', label: 'Thảo dược', emoji: '🌿'),
    OnboardingChoiceOption(
      code: 'prescription_other',
      label: 'Thuốc kê đơn khác',
      emoji: '📄',
    ),
    OnboardingChoiceOption(code: 'other', label: 'Khác', emoji: '✍️'),
  ];

  /// 25 common concerns. One value is persisted in the existing `concernText`
  /// field; the optional note lets the user add details.
  static const List<OnboardingChoiceOption> concernChoices = [
    OnboardingChoiceOption(
      code: 'none',
      label: 'Chưa có băn khoăn cụ thể',
      emoji: '✅',
    ),
    OnboardingChoiceOption(
      code: 'low_energy',
      label: 'Thiếu năng lượng',
      emoji: '🥱',
    ),
    OnboardingChoiceOption(code: 'sleep', label: 'Ngủ chưa tốt', emoji: '😴'),
    OnboardingChoiceOption(code: 'weight', label: 'Cân nặng', emoji: '⚖️'),
    OnboardingChoiceOption(code: 'body_shape', label: 'Vóc dáng', emoji: '🪞'),
    OnboardingChoiceOption(
      code: 'diet',
      label: 'Ăn uống thất thường',
      emoji: '🍽️',
    ),
    OnboardingChoiceOption(code: 'digestion', label: 'Tiêu hóa', emoji: '🌿'),
    OnboardingChoiceOption(code: 'skin', label: 'Da', emoji: '✨'),
    OnboardingChoiceOption(code: 'pain', label: 'Đau nhức', emoji: '🩹'),
    OnboardingChoiceOption(
      code: 'blood_pressure',
      label: 'Huyết áp',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'blood_sugar',
      label: 'Đường huyết',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(code: 'heart', label: 'Tim mạch', emoji: '💓'),
    OnboardingChoiceOption(code: 'stress', label: 'Căng thẳng', emoji: '🧠'),
    OnboardingChoiceOption(code: 'focus', label: 'Tập trung', emoji: '🎯'),
    OnboardingChoiceOption(code: 'water', label: 'Uống nước', emoji: '💧'),
    OnboardingChoiceOption(code: 'exercise', label: 'Vận động', emoji: '🏃'),
    OnboardingChoiceOption(code: 'immune', label: 'Sức đề kháng', emoji: '🛡️'),
    OnboardingChoiceOption(code: 'cholesterol', label: 'Mỡ máu', emoji: '🧪'),
    OnboardingChoiceOption(code: 'liver', label: 'Sức khỏe gan', emoji: '🫀'),
    OnboardingChoiceOption(code: 'kidney', label: 'Sức khỏe thận', emoji: '🚰'),
    OnboardingChoiceOption(
      code: 'checkup',
      label: 'Chỉ số sức khỏe',
      emoji: '📊',
    ),
    OnboardingChoiceOption(
      code: 'family_history',
      label: 'Tiền sử gia đình',
      emoji: '👨‍👩‍👧',
    ),
    OnboardingChoiceOption(
      code: 'medication',
      label: 'Dùng thuốc',
      emoji: '💊',
    ),
    OnboardingChoiceOption(
      code: 'routine',
      label: 'Xây thói quen tốt',
      emoji: '🌱',
    ),
    OnboardingChoiceOption(code: 'other', label: 'Điều khác', emoji: '✍️'),
  ];

  static String codeForLabel(
    Iterable<OnboardingChoiceOption> options,
    String label,
  ) {
    final normalized = label.trim();
    for (final option in options) {
      if (option.label == normalized || option.code == normalized) {
        return option.code;
      }
    }
    return '';
  }

  static String labelFor(
    Iterable<OnboardingChoiceOption> options,
    String codeOrLabel, {
    String fallback = 'Chưa cập nhật',
  }) {
    final normalized = codeOrLabel.trim();
    if (normalized.isEmpty) return fallback;
    for (final option in options) {
      if (option.code == normalized || option.label == normalized) {
        return option.label;
      }
    }
    return normalized;
  }

  static String labelsFor(
    Iterable<OnboardingChoiceOption> options,
    Iterable<String> codes, {
    String fallback = 'Chưa chọn',
  }) {
    final labels = codes
        .map((code) => labelFor(options, code, fallback: ''))
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    return labels.isEmpty ? fallback : labels.join(', ');
  }
}

/// Legacy aliases retained to avoid breaking smaller call sites while the
/// onboarding UI migrates to [OnboardingOptions].
final birthYears = OnboardingOptions.birthYears;
final occupations = OnboardingCatalog.occupations;
final genders = OnboardingCatalog.genders;
final healthGoals = OnboardingCatalog.goals;
final healthConditions = OnboardingCatalog.conditions;
final activityLevels = OnboardingOptions.activityChoices;
final sleepQualities = OnboardingOptions.sleepQualityChoices;
final waterIntakes = OnboardingOptions.waterChoices;
final lifestyleHabits = OnboardingCatalog.habits;

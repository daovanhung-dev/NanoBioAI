import 'package:flutter/foundation.dart';

/// A compact, serializable option used by every onboarding selector.
///
/// [code] is the value saved to local storage / sent to AI. [label] and [emoji]
/// are presentation-only and must remain Vietnamese so generated health plans
/// stay easy to read.
@immutable
class OnboardingChoiceOption {
  final String code;
  final String label;
  final String emoji;
  final String? description;

  const OnboardingChoiceOption({
    required this.code,
    required this.label,
    required this.emoji,
    this.description,
  });
}

/// Shared choices that are persisted as codes in the onboarding profile.
///
/// Keep option codes stable after release. New options may be appended, but
/// renaming an existing code would break saved local snapshots and AI mappings.
abstract final class OnboardingCatalog {
  static const List<OnboardingChoiceOption> genders = [
    OnboardingChoiceOption(code: 'male', label: 'Nam', emoji: '👨'),
    OnboardingChoiceOption(code: 'female', label: 'Nữ', emoji: '👩'),
    OnboardingChoiceOption(code: 'other', label: 'Khác', emoji: '🧑'),
  ];

  /// 25 compact occupation choices for the Basic information view.
  static const List<OnboardingChoiceOption> occupations = [
    OnboardingChoiceOption(code: 'student', label: 'Sinh viên', emoji: '🎓'),
    OnboardingChoiceOption(
      code: 'office_worker',
      label: 'Nhân viên văn phòng',
      emoji: '💼',
    ),
    OnboardingChoiceOption(
      code: 'remote_worker',
      label: 'Làm việc từ xa',
      emoji: '💻',
    ),
    OnboardingChoiceOption(
      code: 'developer_it',
      label: 'Công nghệ thông tin',
      emoji: '🧑‍💻',
    ),
    OnboardingChoiceOption(code: 'teacher', label: 'Giáo viên', emoji: '📚'),
    OnboardingChoiceOption(code: 'healthcare', label: 'Y tế', emoji: '🩺'),
    OnboardingChoiceOption(code: 'engineer', label: 'Kỹ sư', emoji: '⚙️'),
    OnboardingChoiceOption(
      code: 'business_owner',
      label: 'Kinh doanh tự do',
      emoji: '🏪',
    ),
    OnboardingChoiceOption(code: 'sales', label: 'Bán hàng', emoji: '🤝'),
    OnboardingChoiceOption(
      code: 'customer_service',
      label: 'Dịch vụ khách hàng',
      emoji: '🎧',
    ),
    OnboardingChoiceOption(code: 'designer', label: 'Thiết kế', emoji: '🎨'),
    OnboardingChoiceOption(
      code: 'factory_worker',
      label: 'Công nhân',
      emoji: '🏭',
    ),
    OnboardingChoiceOption(code: 'driver', label: 'Tài xế', emoji: '🚗'),
    OnboardingChoiceOption(
      code: 'agriculture',
      label: 'Nông nghiệp',
      emoji: '🌾',
    ),
    OnboardingChoiceOption(
      code: 'hospitality',
      label: 'Nhà hàng / khách sạn',
      emoji: '🍽️',
    ),
    OnboardingChoiceOption(
      code: 'freelancer',
      label: 'Làm việc tự do',
      emoji: '🪄',
    ),
    OnboardingChoiceOption(code: 'homemaker', label: 'Nội trợ', emoji: '🏠'),
    OnboardingChoiceOption(code: 'retired', label: 'Nghỉ hưu', emoji: '🌿'),
    OnboardingChoiceOption(
      code: 'seeking_work',
      label: 'Đang tìm việc',
      emoji: '🔎',
    ),
    OnboardingChoiceOption(
      code: 'public_service',
      label: 'Công chức / viên chức',
      emoji: '🏛️',
    ),
    OnboardingChoiceOption(
      code: 'researcher',
      label: 'Nghiên cứu',
      emoji: '🔬',
    ),
    OnboardingChoiceOption(
      code: 'creator',
      label: 'Sáng tạo nội dung',
      emoji: '🎬',
    ),
    OnboardingChoiceOption(
      code: 'athlete',
      label: 'Thể thao chuyên nghiệp',
      emoji: '🏃',
    ),
    OnboardingChoiceOption(
      code: 'manager',
      label: 'Quản lý / điều hành',
      emoji: '📈',
    ),
    OnboardingChoiceOption(code: 'other', label: 'Khác', emoji: '✨'),
  ];

  /// 25 goals for the Health goals view.
  static const List<OnboardingChoiceOption> goals = [
    OnboardingChoiceOption(
      code: 'maintain_weight',
      label: 'Giữ cân',
      emoji: '⚖️',
    ),
    OnboardingChoiceOption(code: 'lose_weight', label: 'Giảm cân', emoji: '🔥'),
    OnboardingChoiceOption(code: 'gain_weight', label: 'Tăng cân', emoji: '📈'),
    OnboardingChoiceOption(
      code: 'lose_belly_fat',
      label: 'Giảm mỡ bụng',
      emoji: '⚡',
    ),
    OnboardingChoiceOption(code: 'gain_muscle', label: 'Tăng cơ', emoji: '💪'),
    OnboardingChoiceOption(
      code: 'improve_strength',
      label: 'Tăng sức bền',
      emoji: '🏋️',
    ),
    OnboardingChoiceOption(
      code: 'improve_cardio',
      label: 'Tốt cho tim mạch',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'improve_flexibility',
      label: 'Linh hoạt hơn',
      emoji: '🤸',
    ),
    OnboardingChoiceOption(
      code: 'daily_activity',
      label: 'Tập đều hơn',
      emoji: '🚶',
    ),
    OnboardingChoiceOption(
      code: 'sleep_better',
      label: 'Ngủ ngon hơn',
      emoji: '😴',
    ),
    OnboardingChoiceOption(
      code: 'reduce_stress',
      label: 'Giảm căng thẳng',
      emoji: '🌤️',
    ),
    OnboardingChoiceOption(
      code: 'improve_focus',
      label: 'Tăng tập trung',
      emoji: '🎯',
    ),
    OnboardingChoiceOption(
      code: 'increase_energy',
      label: 'Nhiều năng lượng',
      emoji: '⚡',
    ),
    OnboardingChoiceOption(
      code: 'improve_digestion',
      label: 'Dễ tiêu hóa hơn',
      emoji: '🌿',
    ),
    OnboardingChoiceOption(
      code: 'healthy_eating',
      label: 'Ăn lành mạnh',
      emoji: '🥗',
    ),
    OnboardingChoiceOption(
      code: 'balanced_nutrition',
      label: 'Ăn đủ chất',
      emoji: '🍱',
    ),
    OnboardingChoiceOption(
      code: 'beautify_skin',
      label: 'Da khỏe hơn',
      emoji: '✨',
    ),
    OnboardingChoiceOption(
      code: 'immune_boost',
      label: 'Tăng đề kháng',
      emoji: '🛡️',
    ),
    OnboardingChoiceOption(
      code: 'stable_blood_sugar',
      label: 'Ổn định đường huyết',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(
      code: 'stable_blood_pressure',
      label: 'Ổn định huyết áp',
      emoji: '🫀',
    ),
    OnboardingChoiceOption(
      code: 'heart_health',
      label: 'Chăm sóc tim',
      emoji: '💓',
    ),
    OnboardingChoiceOption(
      code: 'joint_health',
      label: 'Khỏe xương khớp',
      emoji: '🦴',
    ),
    OnboardingChoiceOption(
      code: 'regular_meals',
      label: 'Ăn đúng bữa',
      emoji: '⏰',
    ),
    OnboardingChoiceOption(
      code: 'detox_body',
      label: 'Cơ thể nhẹ nhàng',
      emoji: '🌱',
    ),
    OnboardingChoiceOption(
      code: 'overall_health',
      label: 'Khỏe toàn diện',
      emoji: '💚',
    ),
  ];

  /// 25 health conditions / symptoms. “Không có” is exclusive in the controller.
  static const List<OnboardingChoiceOption> conditions = [
    OnboardingChoiceOption(
      code: 'no_special_issue',
      label: 'Không có vấn đề đặc biệt',
      emoji: '✅',
    ),
    OnboardingChoiceOption(
      code: 'stomach_pain',
      label: 'Đau dạ dày',
      emoji: '🤕',
    ),
    OnboardingChoiceOption(
      code: 'acid_reflux',
      label: 'Trào ngược',
      emoji: '🔥',
    ),
    OnboardingChoiceOption(code: 'constipation', label: 'Táo bón', emoji: '🚽'),
    OnboardingChoiceOption(
      code: 'bloating',
      label: 'Đầy hơi, khó tiêu',
      emoji: '🎈',
    ),
    OnboardingChoiceOption(
      code: 'diarrhea',
      label: 'Rối loạn tiêu hóa',
      emoji: '🌧️',
    ),
    OnboardingChoiceOption(code: 'insomnia', label: 'Khó ngủ', emoji: '😴'),
    OnboardingChoiceOption(code: 'stress', label: 'Căng thẳng', emoji: '🧠'),
    OnboardingChoiceOption(code: 'anxiety', label: 'Hay lo lắng', emoji: '🌫️'),
    OnboardingChoiceOption(
      code: 'joint_pain',
      label: 'Đau xương khớp',
      emoji: '🦴',
    ),
    OnboardingChoiceOption(
      code: 'back_pain',
      label: 'Đau lưng / cổ vai gáy',
      emoji: '🪑',
    ),
    OnboardingChoiceOption(
      code: 'headache',
      label: 'Đau đầu thường xuyên',
      emoji: '🤯',
    ),
    OnboardingChoiceOption(
      code: 'high_blood_sugar',
      label: 'Đường huyết cao',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(
      code: 'blood_pressure_issue',
      label: 'Huyết áp bất thường',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'high_cholesterol',
      label: 'Mỡ máu cao',
      emoji: '🧪',
    ),
    OnboardingChoiceOption(
      code: 'fatty_liver',
      label: 'Gan nhiễm mỡ',
      emoji: '🫀',
    ),
    OnboardingChoiceOption(
      code: 'thyroid_issue',
      label: 'Tuyến giáp',
      emoji: '🦋',
    ),
    OnboardingChoiceOption(
      code: 'respiratory_issue',
      label: 'Hô hấp / hen',
      emoji: '🫁',
    ),
    OnboardingChoiceOption(
      code: 'kidney_issue',
      label: 'Thận / tiết niệu',
      emoji: '💧',
    ),
    OnboardingChoiceOption(
      code: 'skin_issue',
      label: 'Da / dị ứng',
      emoji: '🌸',
    ),
    OnboardingChoiceOption(
      code: 'tired_always',
      label: 'Hay mệt mỏi',
      emoji: '🥱',
    ),
    OnboardingChoiceOption(code: 'overweight', label: 'Thừa cân', emoji: '⚖️'),
    OnboardingChoiceOption(
      code: 'underweight',
      label: 'Gầy, khó tăng cân',
      emoji: '🪶',
    ),
    OnboardingChoiceOption(
      code: 'menstrual_issue',
      label: 'Chu kỳ không ổn định',
      emoji: '📅',
    ),
    OnboardingChoiceOption(
      code: 'other_condition',
      label: 'Vấn đề khác',
      emoji: '✍️',
    ),
  ];

  /// 25 daily habits. These codes are also written into survey answers so
  /// older SQLite schemas retain every selected value.
  static const List<OnboardingChoiceOption> habits = [
    OnboardingChoiceOption(
      code: 'skip_breakfast',
      label: 'Bỏ bữa sáng',
      emoji: '🌤️',
    ),
    OnboardingChoiceOption(
      code: 'irregular_meals',
      label: 'Ăn thất thường',
      emoji: '🕒',
    ),
    OnboardingChoiceOption(code: 'eat_late', label: 'Ăn khuya', emoji: '🌙'),
    OnboardingChoiceOption(code: 'fast_food', label: 'Ăn nhanh', emoji: '🍔'),
    OnboardingChoiceOption(
      code: 'eat_sweet',
      label: 'Ăn nhiều đồ ngọt',
      emoji: '🍩',
    ),
    OnboardingChoiceOption(
      code: 'eat_oily',
      label: 'Ăn nhiều dầu mỡ',
      emoji: '🍟',
    ),
    OnboardingChoiceOption(code: 'high_salt', label: 'Ăn mặn', emoji: '🧂'),
    OnboardingChoiceOption(
      code: 'low_vegetable',
      label: 'Ăn ít rau',
      emoji: '🥬',
    ),
    OnboardingChoiceOption(
      code: 'low_fruit',
      label: 'Ăn ít trái cây',
      emoji: '🍎',
    ),
    OnboardingChoiceOption(
      code: 'low_water',
      label: 'Uống ít nước',
      emoji: '💧',
    ),
    OnboardingChoiceOption(
      code: 'sugary_drinks',
      label: 'Uống nước ngọt',
      emoji: '🥤',
    ),
    OnboardingChoiceOption(
      code: 'snacking',
      label: 'Ăn vặt nhiều',
      emoji: '🍪',
    ),
    OnboardingChoiceOption(
      code: 'stress_eating',
      label: 'Ăn khi căng thẳng',
      emoji: '😮‍💨',
    ),
    OnboardingChoiceOption(
      code: 'alcohol',
      label: 'Uống rượu bia',
      emoji: '🍺',
    ),
    OnboardingChoiceOption(code: 'smoking', label: 'Hút thuốc', emoji: '🚬'),
    OnboardingChoiceOption(
      code: 'coffee_high',
      label: 'Nhiều trà / cà phê',
      emoji: '☕',
    ),
    OnboardingChoiceOption(code: 'sedentary', label: 'Ngồi lâu', emoji: '🪑'),
    OnboardingChoiceOption(
      code: 'no_breaks',
      label: 'Ít nghỉ giữa giờ',
      emoji: '⏳',
    ),
    OnboardingChoiceOption(
      code: 'late_sleep',
      label: 'Thức khuya',
      emoji: '🌌',
    ),
    OnboardingChoiceOption(
      code: 'screen_late',
      label: 'Dùng màn hình khuya',
      emoji: '📱',
    ),
    OnboardingChoiceOption(
      code: 'meal_prep',
      label: 'Tự chuẩn bị bữa ăn',
      emoji: '🥣',
    ),
    OnboardingChoiceOption(
      code: 'self_cook',
      label: 'Tự nấu thường xuyên',
      emoji: '🍳',
    ),
    OnboardingChoiceOption(
      code: 'regular_walk',
      label: 'Đi bộ hằng ngày',
      emoji: '🚶',
    ),
    OnboardingChoiceOption(
      code: 'exercise_routine',
      label: 'Tập luyện đều',
      emoji: '🏃',
    ),
    OnboardingChoiceOption(
      code: 'mindful_break',
      label: 'Có thời gian thư giãn',
      emoji: '🧘',
    ),
  ];

  /// Legacy string lists retained for older non-onboarding call sites.
  static const List<String> sleepQualities = [
    'Ngủ ngon',
    'Khó ngủ',
    'Ngủ không sâu',
    'Hay thức khuya',
    'Mệt sau khi ngủ dậy',
  ];

  static const List<String> activityLevels = [
    'Ít vận động',
    'Đi bộ nhẹ',
    'Tập 1–3 buổi/tuần',
    'Tập thường xuyên',
    'Lao động nặng',
  ];

  static const List<String> waterIntakeOptions = [
    'Dưới 1 lít nước/ngày',
    '1–1,5 lít/ngày',
    '1,5–2 lít/ngày',
    'Trên 2 lít/ngày',
  ];

  static const int totalSteps = 9;

  static String labelOf(
    Iterable<OnboardingChoiceOption> options,
    String code, {
    String fallback = 'Chưa cập nhật',
  }) {
    final normalized = code.trim();
    if (normalized.isEmpty) return fallback;
    for (final option in options) {
      if (option.code == normalized) return option.label;
    }
    return normalized.replaceAll('_', ' ');
  }
}

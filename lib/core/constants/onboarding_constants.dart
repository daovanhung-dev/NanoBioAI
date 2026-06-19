class OnboardingChoiceOption {
  final String code;
  final String label;
  final String emoji;

  const OnboardingChoiceOption({
    required this.code,
    required this.label,
    required this.emoji,
  });
}

class OnboardingCatalog {
  static const List<OnboardingChoiceOption> genders = [
    OnboardingChoiceOption(code: 'male', label: 'Nam', emoji: '👨'),
    OnboardingChoiceOption(code: 'female', label: 'Nữ', emoji: '👩'),
  ];

  static const List<OnboardingChoiceOption> goals = [
    OnboardingChoiceOption(code: 'lose_weight', label: 'Giảm cân', emoji: '🔥'),
    OnboardingChoiceOption(code: 'gain_weight', label: 'Tăng cân', emoji: '📈'),
    OnboardingChoiceOption(
      code: 'lose_belly_fat',
      label: 'Giảm mỡ bụng',
      emoji: '⚡',
    ),
    OnboardingChoiceOption(code: 'gain_muscle', label: 'Tăng cơ', emoji: '💪'),
    OnboardingChoiceOption(
      code: 'improve_digestion',
      label: 'Cải thiện tiêu hóa',
      emoji: '🌿',
    ),
    OnboardingChoiceOption(
      code: 'sleep_better',
      label: 'Ngủ ngon hơn',
      emoji: '😴',
    ),
    OnboardingChoiceOption(
      code: 'reduce_fatigue',
      label: 'Giảm mệt mỏi',
      emoji: '🥱',
    ),
    OnboardingChoiceOption(
      code: 'increase_energy',
      label: 'Tăng năng lượng',
      emoji: '⚡',
    ),
    OnboardingChoiceOption(
      code: 'beautify_skin',
      label: 'Làm đẹp da',
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
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'joint_health',
      label: 'Cải thiện xương khớp',
      emoji: '🦴',
    ),
    OnboardingChoiceOption(
      code: 'detox_body',
      label: 'Thanh lọc cơ thể',
      emoji: '🌱',
    ),
    OnboardingChoiceOption(
      code: 'overall_health',
      label: 'Cải thiện sức khỏe tổng thể',
      emoji: '💚',
    ),
  ];

  static const List<OnboardingChoiceOption> conditions = [
    OnboardingChoiceOption(
      code: 'stomach_pain',
      label: 'Đau dạ dày',
      emoji: '🤕',
    ),
    OnboardingChoiceOption(code: 'constipation', label: 'Táo bón', emoji: '🚽'),
    OnboardingChoiceOption(
      code: 'bloating',
      label: 'Đầy hơi, khó tiêu',
      emoji: '🎈',
    ),
    OnboardingChoiceOption(code: 'insomnia', label: 'Mất ngủ', emoji: '😴'),
    OnboardingChoiceOption(
      code: 'stress',
      label: 'Stress, căng thẳng',
      emoji: '🧠',
    ),
    OnboardingChoiceOption(
      code: 'joint_pain',
      label: 'Đau nhức xương khớp',
      emoji: '🦴',
    ),
    OnboardingChoiceOption(
      code: 'high_blood_sugar',
      label: 'Đường huyết cao',
      emoji: '🩸',
    ),
    OnboardingChoiceOption(
      code: 'blood_pressure_issue',
      label: 'Huyết áp cao/thấp',
      emoji: '❤️',
    ),
    OnboardingChoiceOption(
      code: 'high_cholesterol',
      label: 'Mỡ máu cao',
      emoji: '🥩',
    ),
    OnboardingChoiceOption(
      code: 'fatty_liver',
      label: 'Gan nhiễm mỡ',
      emoji: '🫀',
    ),
    OnboardingChoiceOption(
      code: 'tired_always',
      label: 'Hay mệt mỏi',
      emoji: '🥱',
    ),
    OnboardingChoiceOption(
      code: 'overweight',
      label: 'Thừa cân/béo phì',
      emoji: '⚖️',
    ),
    OnboardingChoiceOption(
      code: 'underweight',
      label: 'Gầy yếu, khó hấp thu',
      emoji: '🪶',
    ),
    OnboardingChoiceOption(
      code: 'no_special_issue',
      label: 'Không có vấn đề đặc biệt',
      emoji: '✅',
    ),
  ];

  static const List<OnboardingChoiceOption> habits = [
    OnboardingChoiceOption(
      code: 'skip_breakfast',
      label: 'Bỏ bữa sáng',
      emoji: '🌤️',
    ),
    OnboardingChoiceOption(code: 'eat_late', label: 'Ăn khuya', emoji: '🌙'),
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
    OnboardingChoiceOption(
      code: 'low_vegetable',
      label: 'Ăn ít rau xanh',
      emoji: '🥬',
    ),
    OnboardingChoiceOption(
      code: 'low_water',
      label: 'Uống ít nước',
      emoji: '💧',
    ),
    OnboardingChoiceOption(
      code: 'fast_food',
      label: 'Hay dùng fast food',
      emoji: '🍔',
    ),
    OnboardingChoiceOption(
      code: 'alcohol',
      label: 'Thường xuyên rượu bia',
      emoji: '🍺',
    ),
    OnboardingChoiceOption(
      code: 'coffee_high',
      label: 'Uống nhiều trà/cà phê',
      emoji: '☕',
    ),
  ];

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

  static const int totalSteps = 8;
}

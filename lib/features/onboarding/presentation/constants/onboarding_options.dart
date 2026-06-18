/// Onboarding Input Options
///
/// Centralized predefined options for dropdowns, chips, and pickers
/// used throughout the onboarding flow.
///
/// **Validates: Requirements 5.7, 5.8, 5.9, 6.12, 11.1-11.9**

// Birth Year Options (1920-2024, descending)
final birthYears = List<int>.generate(2024 - 1920 + 1, (index) => 2024 - index);

// Occupation Options
const occupations = [
  {'code': 'office', 'label': 'Nhân viên văn phòng'},
  {'code': 'teacher', 'label': 'Giáo viên'},
  {'code': 'healthcare', 'label': 'Y tế'},
  {'code': 'engineer', 'label': 'Kỹ sư'},
  {'code': 'business', 'label': 'Kinh doanh'},
  {'code': 'student', 'label': 'Sinh viên'},
  {'code': 'retired', 'label': 'Hưu trí'},
  {'code': 'freelance', 'label': 'Tự do'},
  {'code': 'other', 'label': 'Khác'},
];

// Gender Options
const genders = [
  {'code': 'male', 'label': 'Nam'},
  {'code': 'female', 'label': 'Nữ'},
  {'code': 'other', 'label': 'Khác'},
];

// Health Goals
const healthGoals = [
  {'code': 'lose_weight', 'label': 'Giảm cân'},
  {'code': 'gain_weight', 'label': 'Tăng cân'},
  {'code': 'maintain_weight', 'label': 'Duy trì cân nặng'},
  {'code': 'build_muscle', 'label': 'Xây dựng cơ bắp'},
  {'code': 'improve_cardio', 'label': 'Cải thiện sức khỏe tim mạch'},
  {'code': 'increase_energy', 'label': 'Tăng năng lượng'},
  {'code': 'improve_sleep', 'label': 'Cải thiện giấc ngủ'},
  {'code': 'reduce_stress', 'label': 'Giảm stress'},
];

// Health Conditions
const healthConditions = [
  {'code': 'diabetes', 'label': 'Tiểu đường'},
  {'code': 'hypertension', 'label': 'Huyết áp cao'},
  {'code': 'asthma', 'label': 'Hen suyễn'},
  {'code': 'food_allergy', 'label': 'Dị ứng thực phẩm'},
  {'code': 'thyroid', 'label': 'Suy giáp'},
  {'code': 'arthritis', 'label': 'Viêm khớp'},
  {'code': 'heart_disease', 'label': 'Bệnh tim'},
  {'code': 'none', 'label': 'Không có'},
];

// Activity Levels
const activityLevels = [
  {
    'code': 'sedentary',
    'label': 'Ít vận động',
    'description': 'Ngồi nhiều, ít hoạt động',
  },
  {'code': 'light', 'label': 'Nhẹ', 'description': '1-2 ngày/tuần'},
  {'code': 'moderate', 'label': 'Trung bình', 'description': '3-5 ngày/tuần'},
  {'code': 'active', 'label': 'Năng động', 'description': '6-7 ngày/tuần'},
  {
    'code': 'very_active',
    'label': 'Rất năng động',
    'description': 'Vận động viên',
  },
];

// Sleep Quality Options
const sleepQualities = [
  {'code': 'excellent', 'label': 'Ngủ ngon'},
  {'code': 'good', 'label': 'Ngủ tốt'},
  {'code': 'fair', 'label': 'Ngủ khá'},
  {'code': 'poor', 'label': 'Ngủ kém'},
  {'code': 'very_poor', 'label': 'Mất ngủ'},
];

// Water Intake Options
const waterIntakes = [
  {'code': 'less_1', 'label': 'Dưới 1 lít nước/ngày'},
  {'code': '1_to_1_5', 'label': '1-1.5 lít nước/ngày'},
  {'code': '1_5_to_2', 'label': '1.5-2 lít nước/ngày'},
  {'code': '2_to_3', 'label': '2-3 lít nước/ngày'},
  {'code': 'more_3', 'label': 'Trên 3 lít nước/ngày'},
];

// Lifestyle Habits
const lifestyleHabits = [
  {'code': 'smoking', 'label': 'Hút thuốc'},
  {'code': 'alcohol', 'label': 'Uống rượu'},
  {'code': 'coffee', 'label': 'Uống cà phê'},
  {'code': 'tea', 'label': 'Uống trà'},
  {'code': 'fast_food', 'label': 'Ăn đồ ăn nhanh'},
  {'code': 'snacking', 'label': 'Ăn vặt'},
  {'code': 'late_meals', 'label': 'Ăn khuya'},
  {'code': 'skip_meals', 'label': 'Bỏ bữa'},
];

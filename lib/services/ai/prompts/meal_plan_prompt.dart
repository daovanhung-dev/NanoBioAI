import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';

class MealPlanPrompt {
  const MealPlanPrompt._();

  static String generate({
    required HealthDataInterface healthData,
    required DateTime startDate,
    required int days,
  }) {
    final goals = _clean(healthData.goals);
    final conditions = _clean(healthData.conditions);
    final habits = _clean(healthData.habits);
    final endDate = startDate.add(Duration(days: days - 1));
    final expectedCount = days * MealPlanAiNormalizer.mealsPerDay;

    return '''
Bạn là chuyên gia dinh dưỡng.
Tạo thực đơn $days ngày, từ ${_dateKey(startDate)} đến ${_dateKey(endDate)}.
Tổng số object bắt buộc: $expectedCount.

Yêu cầu:
- Mỗi ngày đúng 5 bữa theo thứ tự: breakfast, morning_snack, lunch, afternoon_snack, dinner.
- Chỉ dùng các field trong cấu trúc bên dưới; ứng dụng sẽ tự gán ngày, giờ, thứ tự và id.
- Field meal_type phải giữ đúng enum kỹ thuật đã nêu.
- Field meal_name, description, cooking_instructions phải là tiếng Việt có dấu.
- description tối đa 18 từ, nêu món chính và lợi ích ngắn gọn.
- cooking_instructions tối đa 35 từ, gồm 2 đến 3 bước ngắn.
- calories, protein, carbs, fat, fiber, water_ml phải là số.
- Ưu tiên món Việt Nam, dễ nấu, phù hợp mục tiêu và tình trạng sức khỏe.

Cấu trúc mỗi object:
[
  {
    "meal_type": "breakfast",
    "meal_name": "Cháo yến mạch trứng gà",
    "description": "Bữa sáng giàu đạm, nhẹ bụng và hỗ trợ no lâu.",
    "calories": 350,
    "protein": 12.5,
    "carbs": 45,
    "fat": 8,
    "fiber": 6,
    "water_ml": 300,
    "cooking_instructions": "Bước 1 nấu yến mạch mềm. Bước 2 thêm trứng và rau xanh."
  }
]

Hồ sơ người dùng:
- Tên: ${healthData.fullName}
- BMI: ${healthData.bmi}
- Mục tiêu: ${goals.isEmpty ? 'Không có' : goals}
- Tình trạng sức khỏe: ${conditions.isEmpty ? 'Không có' : conditions}
- Thói quen: ${habits.isEmpty ? 'Không có' : habits}
- Giấc ngủ: ${healthData.sleepQuality}
- Hoạt động: ${healthData.activityLevel}
- Lượng nước: ${healthData.waterPerDay}
- Mối quan tâm: ${healthData.concernText}
''';
  }

  static String _clean(List<String> items) =>
      items.where((item) => item.trim().isNotEmpty).join(', ');

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

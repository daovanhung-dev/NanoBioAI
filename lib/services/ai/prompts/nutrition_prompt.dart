import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

final nutritionPromptProvider = Provider<NutritionPrompt>((ref) {
  return NutritionPrompt();
});

class NutritionPrompt {
  static String _clean(List<String> items) =>
      items.where((e) => e.trim().isNotEmpty).join(', ');

  static String generateMealPlan({required DashboardEntity healthData}) {
    final goals = _clean(healthData.goals);
    final conditions = _clean(healthData.conditions);
    final habits = _clean(healthData.habits);

    return '''
Bạn là chuyên gia dinh dưỡng.
Viết hoàn toàn bằng tiếng Việt.
Tạo thực đơn 7 ngày, bắt đầu từ ngày mai.
Mỗi ngày 3 bữa: breakfast, lunch, dinner.
Trả về DUY NHẤT JSON hợp lệ, không markdown, không giải thích, không text thừa.
Không thêm key ngoài schema.
Giá trị số phải là number, không phải string.
Ngày theo định dạng YYYY-MM-DD.

Schema:
[
  {
    "id": "uuid",
    "user_id": "1",
    "plan_date": "2026-05-24",
    "meal_type": "breakfast",
    "meal_name": "string",
    "description": "string",
    "calories": 350,
    "protein": 12.5,
    "carbs": 45,
    "fat": 8,
    "fiber": 6,
    "water_ml": 300,
    "meal_order": 1,
    "is_completed": 0,
    "ai_generated": 1,
    "created_at": "2026-05-24T08:00:00Z",
    "updated_at": "2026-05-24T08:00:00Z"
  }
]

Dữ liệu người dùng:
name: ${healthData.fullName}
bmi: ${healthData.bmi}
goals: ${goals.isEmpty ? 'none' : goals}
conditions: ${conditions.isEmpty ? 'none' : conditions}
habits: ${habits.isEmpty ? 'none' : habits}
sleep: ${healthData.sleepQuality}
activity: ${healthData.activityLevel}
water: ${healthData.waterPerDay}
concern: ${healthData.concernText}
''';
  }
}

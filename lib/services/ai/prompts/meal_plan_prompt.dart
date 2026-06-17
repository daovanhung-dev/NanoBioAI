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
Ban la chuyen gia dinh duong.
Viet hoan toan bang tieng Viet có dấu.
Tao thuc don $days ngay, bat dau tu ${_dateKey(startDate)} den ${_dateKey(endDate)}.
Moi ngay dung 5 bua, sap xep theo tung ngay va theo dung thu tu:
- breakfast start_time 07:00 end_time 07:30 meal_order 1
- morning_snack start_time 09:30 end_time 09:45 meal_order 2
- lunch start_time 12:00 end_time 12:45 meal_order 3
- afternoon_snack start_time 15:30 end_time 15:45 meal_order 4
- dinner start_time 18:30 end_time 19:15 meal_order 5
Tong so object bat buoc la $expectedCount.
Tra ve DUY NHAT JSON hop le, khong markdown, khong giai thich, khong text thua.
Khong them key ngoai schema.
Gia tri so phai la number, khong phai string.
Truong cooking_instructions la chuoi tieng Viet ngan, gom 2-4 buoc che bien.
App se tu gan id, user_id, plan_date, start_time, end_time, meal_order, is_completed, ai_generated, created_at, updated_at.
Ban chi can tra dung meal_type va noi dung bua an.

Schema:
[
  {
    "meal_type": "breakfast",
    "meal_name": "string",
    "description": "string",
    "calories": 350,
    "protein": 12.5,
    "carbs": 45,
    "fat": 8,
    "fiber": 6,
    "water_ml": 300,
    "cooking_instructions": "Buoc 1... Buoc 2..."
  }
]

Du lieu nguoi dung:
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

  static String _clean(List<String> items) =>
      items.where((item) => item.trim().isNotEmpty).join(', ');

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

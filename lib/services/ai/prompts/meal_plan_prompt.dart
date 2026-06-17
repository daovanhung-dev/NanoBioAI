import 'package:nano_app/core/interfaces/health_data_interface.dart';

class MealPlanPrompt {
  const MealPlanPrompt._();

  static String generate({required HealthDataInterface healthData}) {
    final goals = _clean(healthData.goals);
    final conditions = _clean(healthData.conditions);
    final habits = _clean(healthData.habits);

    return '''
Ban la chuyen gia dinh duong.
Viet hoan toan bang tieng Viet.
Tao thuc don 7 ngay, bat dau tu ngay mai.
Moi ngay dung 5 bua:
- breakfast start_time 07:00 end_time 07:30 meal_order 1
- morning_snack start_time 09:30 end_time 09:45 meal_order 2
- lunch start_time 12:00 end_time 12:45 meal_order 3
- afternoon_snack start_time 15:30 end_time 15:45 meal_order 4
- dinner start_time 18:30 end_time 19:15 meal_order 5
Tong so object bat buoc la 35.
Tra ve DUY NHAT JSON hop le, khong markdown, khong giai thich, khong text thua.
Khong them key ngoai schema.
Gia tri so phai la number, khong phai string.
Ngay theo dinh dang YYYY-MM-DD.
Gio theo dinh dang HH:mm local time, dung dung cac moc gio theo meal_type.
Truong cooking_instructions la chuoi tieng Viet ngan, gom 2-4 buoc che bien.

Schema:
[
  {
    "id": "uuid",
    "user_id": "1",
    "plan_date": "2026-05-24",
    "meal_type": "breakfast",
    "start_time": "07:00",
    "end_time": "07:30",
    "meal_name": "string",
    "description": "string",
    "calories": 350,
    "protein": 12.5,
    "carbs": 45,
    "fat": 8,
    "fiber": 6,
    "water_ml": 300,
    "meal_order": 1,
    "cooking_instructions": "Buoc 1... Buoc 2...",
    "is_completed": 0,
    "ai_generated": 1,
    "created_at": "2026-05-24T08:00:00Z",
    "updated_at": "2026-05-24T08:00:00Z"
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
}

import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';

class MealPlanPrompt {
  const MealPlanPrompt._();

  static String generate({
    required HealthDataInterface healthData,
    required DateTime startDate,
    required int startDay,
    required int days,
    required List<MealCatalogItemModel> catalog,
    required List<String> usedMealCodes,
  }) {
    final goals = _clean(healthData.goals);
    final conditions = _clean(healthData.conditions);
    final habits = _clean(healthData.habits);
    final chunkStartDate = startDate.add(Duration(days: startDay - 1));
    final chunkEndDate = chunkStartDate.add(Duration(days: days - 1));
    final endDay = startDay + days - 1;
    final expectedCount = days * MealPlanAiNormalizer.mealsPerDay;

    return '''
Bạn là bộ chọn mã thực đơn cho ứng dụng BioAI.
Chọn thực đơn cho ngày $startDay đến ngày $endDay, tương ứng ${_dateKey(chunkStartDate)} đến ${_dateKey(chunkEndDate)}.
Tổng số object bắt buộc: $expectedCount.

Schema mỗi object:
{
  "day": 1,
  "meal_type": "breakfast",
  "meal_code": "br_oat_egg",
  "portion_level": "standard",
  "priority": 1
}

Quy tắc:
- day phải là số từ $startDay đến $endDay.
- Mỗi ngày bắt buộc đủ 5 meal_type theo thứ tự: breakfast, morning_snack, lunch, afternoon_snack, dinner.
- meal_code phải nằm trong danh sách allowed đúng meal_type.
- Không tự tạo meal_code mới.
- Không trả về meal_name, description, cooking_instructions, title, unit hoặc encouragement.
- portion_level chỉ dùng một trong: small, standard, large.
- Tránh dùng lại các mã đã dùng nếu còn lựa chọn phù hợp.

Mã đã dùng trước đó:
${usedMealCodes.isEmpty ? 'Không có' : usedMealCodes.join(', ')}

Allowed meal codes:
${_allowedMealCodes(catalog)}

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

  static String _allowedMealCodes(List<MealCatalogItemModel> catalog) {
    final buffer = StringBuffer();
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final codes =
          catalog
              .where((item) => item.mealType == slot.type)
              .map((item) => item.code)
              .toList()
            ..sort();
      buffer.writeln('- ${slot.type}: ${codes.join(', ')}');
    }
    return buffer.toString().trim();
  }

  static String _clean(List<String> items) =>
      items.where((item) => item.trim().isNotEmpty).join(', ');

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';

class ExerciseTasksPrompt {
  const ExerciseTasksPrompt._();

  static String generate({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    required int startDay,
    required int days,
    required List<ExerciseCatalogItemModel> catalog,
    required List<String> usedExerciseCodes,
  }) {
    final chunkStartDate = startDate.add(Duration(days: startDay - 1));
    final chunkEndDate = chunkStartDate.add(Duration(days: days - 1));
    final endDay = startDay + days - 1;
    final expectedCount = days * ExerciseTasksAiNormalizer.exercisesPerDay;

    return '''
Bạn là bộ chọn mã vận động cho ứng dụng BioAI.
Chọn bài tập cho ngày $startDay đến ngày $endDay, tương ứng ${_dateKey(chunkStartDate)} đến ${_dateKey(chunkEndDate)}.
Tổng số object bắt buộc: $expectedCount.

Schema mỗi object:
{
  "day": 1,
  "exercise_code": "ex_walk_relaxed",
  "start_time": "08:00",
  "end_time": "08:25",
  "intensity": "light",
  "target_value": 1,
  "priority": 1
}

Quy tắc:
- day phải là số từ $startDay đến $endDay.
- Mỗi ngày bắt buộc đúng 2 bài tập.
- exercise_code phải nằm trong danh sách allowed.
- Không tự tạo exercise_code mới.
- Không trả về title, description, unit, encouragement, meal_name hoặc cooking_instructions.
- start_time và end_time dùng HH:mm; end_time phải sau start_time.
- Bài sáng nên nằm khoảng 08:00-08:25; bài chiều nên nằm khoảng 17:30-18:00.
- intensity chỉ dùng một trong: light, moderate.
- target_value phải là số dương trong khoảng hợp lý của bài tập.
- Tránh dùng lại các mã đã dùng nếu còn lựa chọn phù hợp.

Mã đã dùng trước đó:
${usedExerciseCodes.isEmpty ? 'Không có' : usedExerciseCodes.join(', ')}

Allowed exercise codes:
${_allowedExerciseCodes(catalog)}

Hồ sơ người dùng:
- Tên: ${profile.fullName}
- Mục tiêu: ${profile.goals.isEmpty ? 'Không có' : profile.goals.join(', ')}
- Tình trạng sức khỏe: ${profile.conditions.isEmpty ? 'Không có' : profile.conditions.join(', ')}
- Thói quen: ${profile.habits.isEmpty ? 'Không có' : profile.habits.join(', ')}
- Giấc ngủ: ${profile.sleepQuality}
- Hoạt động: ${profile.activityLevel}
- Lượng nước: ${profile.waterPerDay}
''';
  }

  static String _allowedExerciseCodes(List<ExerciseCatalogItemModel> catalog) {
    final sorted = [...catalog]..sort((a, b) => a.code.compareTo(b.code));
    return sorted
        .map(
          (item) =>
              '- ${item.code}: intensity=${item.intensityLevel}, target=${item.minTarget}-${item.maxTarget} ${item.unit}',
        )
        .join('\n');
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

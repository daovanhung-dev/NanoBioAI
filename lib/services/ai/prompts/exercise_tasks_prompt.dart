import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';

class ExerciseTasksPrompt {
  const ExerciseTasksPrompt._();

  static String generate({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    required int days,
  }) {
    final endDate = startDate.add(Duration(days: days - 1));
    final expectedCount = days * ExerciseTasksAiNormalizer.exercisesPerDay;

    return '''
Bạn là huấn luyện viên sức khỏe cá nhân.
Tạo lịch vận động $days ngày, từ ${_dateKey(startDate)} đến ${_dateKey(endDate)}.
Tổng số object bắt buộc: $expectedCount.

Yêu cầu:
- Mỗi ngày đúng 2 bài tập an toàn, nhẹ đến vừa, phù hợp hồ sơ người dùng.
- schedule_date dùng định dạng YYYY-MM-DD; start_time và end_time dùng HH:mm.
- Bài sáng nên nằm khoảng 08:00-08:25; bài chiều nên nằm khoảng 17:30-18:00.
- Field title, description, unit, encouragement phải là tiếng Việt có dấu.
- title tối đa 8 từ; description tối đa 20 từ; encouragement tối đa 18 từ.
- target_value phải là số dương.
- Không chẩn đoán y tế, không đưa bài tập nguy hiểm.

Cấu trúc mỗi object:
[
  {
    "schedule_date": "${_dateKey(startDate)}",
    "start_time": "08:00",
    "end_time": "08:25",
    "title": "Đi bộ thư giãn",
    "description": "Đi bộ chậm, giữ nhịp thở đều và thả lỏng vai.",
    "target_value": 1,
    "unit": "lần",
    "encouragement": "Bạn đang chăm sóc cơ thể rất tốt."
  }
]

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

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

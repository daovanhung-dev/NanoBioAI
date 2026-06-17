import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';

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
Ban la chuyen gia huan luyen suc khoe ca nhan.
Viet hoan toan bang tieng Viet có dấu.
Tao lich bai tap the duc cho $days ngay, bat dau tu ${_dateKey(startDate)} den ${_dateKey(endDate)}.
Moi ngay bat buoc co dung 2 bai tap van dong an toan, phu hop tinh trang suc khoe va muc do hoat dong.
Tong so object bat buoc la $expectedCount.
Tra ve DUY NHAT JSON hop le, khong markdown, khong giai thich, khong text thua.
Khong them key ngoai schema.
Ngay theo dinh dang YYYY-MM-DD.
Gio theo HH:mm local time.
Gia tri so phai la number, khong phai string.
Khong chan doan y te, khong dua bai tap nguy hiem; neu co tinh trang suc khoe thi uu tien bai tap nhe.

Goi y thoi diem:
- Bai tap sang: 08:00-08:25 hoac phu hop sau bua sang.
- Bai tap chieu: 17:30-18:00 hoac phu hop truoc bua toi.

Schema:
[
  {
    "schedule_date": "${_dateKey(startDate)}",
    "start_time": "08:00",
    "end_time": "08:25",
    "title": "string",
    "description": "string",
    "target_value": 1,
    "unit": "lan",
    "encouragement": "string"
  }
]

Du lieu nguoi dung:
name: ${profile.fullName}
goals: ${profile.goals.isEmpty ? 'none' : profile.goals.join(', ')}
conditions: ${profile.conditions.isEmpty ? 'none' : profile.conditions.join(', ')}
habits: ${profile.habits.isEmpty ? 'none' : profile.habits.join(', ')}
sleep: ${profile.sleepQuality}
activity: ${profile.activityLevel}
water: ${profile.waterPerDay}
''';
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

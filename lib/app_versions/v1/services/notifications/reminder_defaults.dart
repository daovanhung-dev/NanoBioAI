class ReminderDefaults {
  static const mealTimes = {
    'breakfast': '07:00',
    'lunch': '12:00',
    'dinner': '18:30',
  };

  static const dailyTaskTimes = {
    'water': '09:00',
    'body': '17:30',
    'mind': '21:00',
    'brain': '20:00',
  };

  static DateTime? mealScheduledAt({
    required String planDate,
    required String mealType,
  }) {
    final time = mealTimes[mealType.trim().toLowerCase()];
    if (time == null) return null;
    return _combineDateAndTime(planDate, time);
  }

  static DateTime? dailyTaskScheduledAt({
    required String taskDate,
    required String category,
  }) {
    final time = dailyTaskTimes[category.trim().toLowerCase()];
    if (time == null) return null;
    return _combineDateAndTime(taskDate, time);
  }

  static String mealTitle(String mealType) {
    switch (mealType.trim().toLowerCase()) {
      case 'breakfast':
        return 'Đến giờ ăn sáng';
      case 'lunch':
        return 'Đến giờ ăn trưa';
      case 'dinner':
        return 'Đến giờ ăn tối';
      default:
        return 'Đến giờ dùng bữa';
    }
  }

  static DateTime? _combineDateAndTime(String date, String time) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return null;

    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }
}

class NotificationActionIds {
  static const categoryId = 'bioai_reminder_actions';
  static const openSchedule = 'open_schedule';
  static const defer = 'defer';
  // Chỉ giữ để xử lý notification cũ sau khi người dùng nâng cấp ứng dụng.
  static const done = 'done';
  // Legacy <= v20: `skipped` thực tế mang copy "Để sau". Runtime mới
  // normalize action này thành defer để không làm thay đổi source task.
  static const skipped = 'skipped';
}

class NotificationChannels {
  static const reminderId = 'bioai_reminder_channel';
  static const reminderName = 'Nhắc nhiệm vụ sức khỏe';
  static const reminderDescription =
      'Nhắc bạn hoàn thành bữa ăn, vận động và các nhiệm vụ chăm sóc sức khỏe hằng ngày.';
}

class ReminderSourceTypes {
  static const lifestyleScheduleItem = 'lifestyle_schedule_item';
  static const meal = 'meal';
  static const dailyTask = 'daily_task';
}

class NotificationTypes {
  static const reminder = 'reminder';
}

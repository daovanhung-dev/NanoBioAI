class NotificationActionIds {
  static const categoryId = 'bioai_reminder_actions';
  static const openSchedule = 'open_schedule';
  static const defer = 'defer';

  static const nabiCompanionCategoryId = 'nabi_companion_care_actions';
  static const nabiCompanionOpen = 'nabi_companion_open';
  static const nabiCompanionDefer = 'nabi_companion_defer';
  static const nabiCompanionSettings = 'nabi_companion_settings';

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

  static const nabiCareId = 'nabi_care_reminders_v1';
  static const nabiCareName = 'Nabi nhắc chăm sóc sức khỏe';
  static const nabiCareDescription =
      'Nhắc hỏi thăm sức khỏe, xem lại mục tiêu, cập nhật hồ sơ và uống nước.';

  /// Android notification-channel sound is immutable after channel creation,
  /// therefore voice reminders use a separate versioned channel.
  static const nabiCareVoiceId = 'nabi_care_voice_reminders_v1';
  static const nabiCareVoiceName = 'Nabi nhắc bằng giọng nói';
  static const nabiCareVoiceDescription =
      'Phát lời nhắc ngắn của Nabi cho các nhắc nhở chăm sóc sức khỏe đã bật.';
}

class ReminderSourceTypes {
  static const lifestyleScheduleItem = 'lifestyle_schedule_item';
  static const meal = 'meal';
  static const dailyTask = 'daily_task';
}

class NotificationTypes {
  static const reminder = 'reminder';
  static const nabiCompanion = 'nabi_companion';
}

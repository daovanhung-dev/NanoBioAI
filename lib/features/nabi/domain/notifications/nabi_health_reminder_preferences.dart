enum NabiHealthReminderCategory {
  healthCheckIn,
  goalReview,
  profileReview,
  water,
}

extension NabiHealthReminderCategoryX on NabiHealthReminderCategory {
  String get sourceType => switch (this) {
    NabiHealthReminderCategory.healthCheckIn => 'health_check_in',
    NabiHealthReminderCategory.goalReview => 'health_goal_review',
    NabiHealthReminderCategory.profileReview => 'profile_review',
    NabiHealthReminderCategory.water => 'water_tracking',
  };

  String get payloadValue => switch (this) {
    NabiHealthReminderCategory.healthCheckIn => 'health_check_in',
    NabiHealthReminderCategory.goalReview => 'goal_review',
    NabiHealthReminderCategory.profileReview => 'profile_review',
    NabiHealthReminderCategory.water => 'water',
  };

  String get notificationDefinitionId => switch (this) {
    NabiHealthReminderCategory.healthCheckIn => 'NBI-HEALTH-CHECKIN-001',
    NabiHealthReminderCategory.goalReview => 'NBI-GOAL-REVIEW-001',
    NabiHealthReminderCategory.profileReview => 'NBI-PROFILE-REVIEW-001',
    NabiHealthReminderCategory.water => 'NBI-WATER-001',
  };

  String get title => switch (this) {
    NabiHealthReminderCategory.healthCheckIn => 'Nabi hỏi thăm bạn một chút',
    NabiHealthReminderCategory.goalReview => 'Mình xem lại mục tiêu nhé',
    NabiHealthReminderCategory.profileReview => 'Mình cập nhật thông tin sức khỏe nhé',
    NabiHealthReminderCategory.water => 'Đến giờ uống một chút nước rồi 💧',
  };

  String get body => switch (this) {
    NabiHealthReminderCategory.healthCheckIn =>
      'Hiện tại bạn cảm thấy thế nào? Nabi cùng bạn cập nhật tình trạng hôm nay nhé.',
    NabiHealthReminderCategory.goalReview =>
      'Mục tiêu có thể thay đổi theo thời gian. Bạn muốn xem lại mục tiêu hiện tại không?',
    NabiHealthReminderCategory.profileReview =>
      'Một vài thông tin có thể đã thay đổi. Cập nhật lại giúp Nabi đồng hành phù hợp hơn.',
    NabiHealthReminderCategory.water =>
      'Uống vài ngụm nước và ghi lại khi thuận tiện nhé.',
  };

  String get primaryLabel => switch (this) {
    NabiHealthReminderCategory.healthCheckIn => 'Cập nhật tình trạng',
    NabiHealthReminderCategory.goalReview => 'Xem lại mục tiêu',
    NabiHealthReminderCategory.profileReview => 'Cập nhật thông tin',
    NabiHealthReminderCategory.water => 'Ghi lượng nước',
  };

  String get voiceText => switch (this) {
    NabiHealthReminderCategory.healthCheckIn =>
      'Nabi hỏi thăm bạn một chút nhé. Hiện tại bạn cảm thấy thế nào?',
    NabiHealthReminderCategory.goalReview =>
      'Nabi nhắc bạn xem lại mục tiêu sức khỏe khi thuận tiện nhé.',
    NabiHealthReminderCategory.profileReview =>
      'Nabi nhắc bạn cập nhật một vài thông tin sức khỏe khi thuận tiện nhé.',
    NabiHealthReminderCategory.water =>
      'Đến giờ uống một chút nước rồi. Mình uống vài ngụm nước nhé.',
  };

}


NabiHealthReminderCategory? nabiHealthReminderCategoryFromValue(String value) {
  for (final category in NabiHealthReminderCategory.values) {
    if (category.payloadValue == value || category.sourceType == value) {
      return category;
    }
  }
  return null;
}

class NabiHealthReminderPreferences {
  final String actorKey;
  final bool masterEnabled;
  final bool scheduleEnabled;
  final bool healthCheckInEnabled;
  final int healthCheckInIntervalMinutes;
  final int healthCheckInStartMinutes;
  final int healthCheckInEndMinutes;
  final bool goalReviewEnabled;
  final int goalReviewMinutes;
  final bool profileReviewEnabled;
  final int profileReviewIntervalDays;
  final int profileReviewMinutes;
  final bool waterReminderEnabled;
  final int waterReminderIntervalMinutes;
  final int waterReminderStartMinutes;
  final int waterReminderEndMinutes;
  final bool voiceEnabled;
  final bool usePersonalQuietHours;
  final int fallbackQuietStartMinutes;
  final int fallbackQuietEndMinutes;
  final String? lastGoalReviewPeriod;
  final DateTime? lastProfileReviewedAt;
  final DateTime? lastHealthCheckInAt;
  final DateTime updatedAt;

  const NabiHealthReminderPreferences({
    required this.actorKey,
    required this.masterEnabled,
    required this.scheduleEnabled,
    required this.healthCheckInEnabled,
    required this.healthCheckInIntervalMinutes,
    required this.healthCheckInStartMinutes,
    required this.healthCheckInEndMinutes,
    required this.goalReviewEnabled,
    required this.goalReviewMinutes,
    required this.profileReviewEnabled,
    required this.profileReviewIntervalDays,
    required this.profileReviewMinutes,
    required this.waterReminderEnabled,
    required this.waterReminderIntervalMinutes,
    required this.waterReminderStartMinutes,
    required this.waterReminderEndMinutes,
    required this.voiceEnabled,
    required this.usePersonalQuietHours,
    required this.fallbackQuietStartMinutes,
    required this.fallbackQuietEndMinutes,
    required this.updatedAt,
    this.lastGoalReviewPeriod,
    this.lastProfileReviewedAt,
    this.lastHealthCheckInAt,
  });

  factory NabiHealthReminderPreferences.defaults({
    required String actorKey,
    required bool legacyPushEnabled,
    DateTime? now,
  }) {
    return NabiHealthReminderPreferences(
      actorKey: actorKey,
      masterEnabled: legacyPushEnabled,
      scheduleEnabled: true,
      healthCheckInEnabled: false,
      healthCheckInIntervalMinutes: 60,
      healthCheckInStartMinutes: 8 * 60,
      healthCheckInEndMinutes: 21 * 60,
      goalReviewEnabled: false,
      goalReviewMinutes: 9 * 60,
      profileReviewEnabled: false,
      profileReviewIntervalDays: 30,
      profileReviewMinutes: 9 * 60,
      waterReminderEnabled: false,
      waterReminderIntervalMinutes: 120,
      waterReminderStartMinutes: 8 * 60,
      waterReminderEndMinutes: 20 * 60,
      voiceEnabled: false,
      usePersonalQuietHours: true,
      fallbackQuietStartMinutes: 21 * 60,
      fallbackQuietEndMinutes: 7 * 60,
      updatedAt: now ?? DateTime.now(),
    );
  }

  NabiHealthReminderPreferences copyWith({
    bool? masterEnabled,
    bool? scheduleEnabled,
    bool? healthCheckInEnabled,
    int? healthCheckInIntervalMinutes,
    int? healthCheckInStartMinutes,
    int? healthCheckInEndMinutes,
    bool? goalReviewEnabled,
    int? goalReviewMinutes,
    bool? profileReviewEnabled,
    int? profileReviewIntervalDays,
    int? profileReviewMinutes,
    bool? waterReminderEnabled,
    int? waterReminderIntervalMinutes,
    int? waterReminderStartMinutes,
    int? waterReminderEndMinutes,
    bool? voiceEnabled,
    bool? usePersonalQuietHours,
    int? fallbackQuietStartMinutes,
    int? fallbackQuietEndMinutes,
    String? lastGoalReviewPeriod,
    bool clearLastGoalReviewPeriod = false,
    DateTime? lastProfileReviewedAt,
    bool clearLastProfileReviewedAt = false,
    DateTime? lastHealthCheckInAt,
    bool clearLastHealthCheckInAt = false,
    DateTime? updatedAt,
  }) {
    return NabiHealthReminderPreferences(
      actorKey: actorKey,
      masterEnabled: masterEnabled ?? this.masterEnabled,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      healthCheckInEnabled:
          healthCheckInEnabled ?? this.healthCheckInEnabled,
      healthCheckInIntervalMinutes:
          healthCheckInIntervalMinutes ?? this.healthCheckInIntervalMinutes,
      healthCheckInStartMinutes:
          healthCheckInStartMinutes ?? this.healthCheckInStartMinutes,
      healthCheckInEndMinutes:
          healthCheckInEndMinutes ?? this.healthCheckInEndMinutes,
      goalReviewEnabled: goalReviewEnabled ?? this.goalReviewEnabled,
      goalReviewMinutes: goalReviewMinutes ?? this.goalReviewMinutes,
      profileReviewEnabled: profileReviewEnabled ?? this.profileReviewEnabled,
      profileReviewIntervalDays:
          profileReviewIntervalDays ?? this.profileReviewIntervalDays,
      profileReviewMinutes: profileReviewMinutes ?? this.profileReviewMinutes,
      waterReminderEnabled:
          waterReminderEnabled ?? this.waterReminderEnabled,
      waterReminderIntervalMinutes:
          waterReminderIntervalMinutes ?? this.waterReminderIntervalMinutes,
      waterReminderStartMinutes:
          waterReminderStartMinutes ?? this.waterReminderStartMinutes,
      waterReminderEndMinutes:
          waterReminderEndMinutes ?? this.waterReminderEndMinutes,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      usePersonalQuietHours:
          usePersonalQuietHours ?? this.usePersonalQuietHours,
      fallbackQuietStartMinutes:
          fallbackQuietStartMinutes ?? this.fallbackQuietStartMinutes,
      fallbackQuietEndMinutes:
          fallbackQuietEndMinutes ?? this.fallbackQuietEndMinutes,
      lastGoalReviewPeriod: clearLastGoalReviewPeriod
          ? null
          : lastGoalReviewPeriod ?? this.lastGoalReviewPeriod,
      lastProfileReviewedAt: clearLastProfileReviewedAt
          ? null
          : lastProfileReviewedAt ?? this.lastProfileReviewedAt,
      lastHealthCheckInAt: clearLastHealthCheckInAt
          ? null
          : lastHealthCheckInAt ?? this.lastHealthCheckInAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get hasAnyCareReminder =>
      healthCheckInEnabled ||
      goalReviewEnabled ||
      profileReviewEnabled ||
      waterReminderEnabled;

  static int clampMinute(int value) => value.clamp(0, 1439);
}

class NabiQuietHours {
  final int startMinutes;
  final int endMinutes;

  const NabiQuietHours({required this.startMinutes, required this.endMinutes});

  bool contains(DateTime dateTime) {
    final minute = dateTime.hour * 60 + dateTime.minute;
    if (startMinutes == endMinutes) return false;
    return startMinutes < endMinutes
        ? minute >= startMinutes && minute < endMinutes
        : minute >= startMinutes || minute < endMinutes;
  }
}

class NabiPlannedHealthReminder {
  final NabiHealthReminderCategory category;
  final DateTime scheduledAt;

  const NabiPlannedHealthReminder({
    required this.category,
    required this.scheduledAt,
  });

  String get sourceEventId =>
      '${category.sourceType}:${scheduledAt.toLocal().toIso8601String()}';
}

/// SettingsPreferencesEntity represents all application settings and user preferences
/// stored in SharedPreferences for fast access and persistence across app sessions.
///
/// This is a pure Dart entity with no external dependencies, following
/// Clean Architecture principles.
class SettingsPreferencesEntity {
  /// Whether dark mode is enabled
  final bool isDarkMode;

  /// Current language code ('vi' for Vietnamese, 'en' for English)
  final String languageCode;

  /// Whether biometric authentication (Face ID/Touch ID) is enabled
  final bool biometricEnabled;

  /// Whether push notifications are enabled
  final bool pushEnabled;

  /// Whether meal reminder notifications are enabled
  final bool mealReminderEnabled;

  /// Time for meal reminders in HH:mm format (e.g., '12:00')
  final String? mealReminderTime;

  /// Whether health goal reminder notifications are enabled
  final bool goalReminderEnabled;

  /// Whether AI chat notifications are enabled
  final bool aiChatNotificationEnabled;

  /// AI personality preference ('professional', 'friendly', or 'motivational')
  final String aiPersonality;

  /// Data privacy mode ('local' for local-only storage, 'cloud' for cloud sync)
  final String dataPrivacyMode;

  const SettingsPreferencesEntity({
    required this.isDarkMode,
    required this.languageCode,
    required this.biometricEnabled,
    required this.pushEnabled,
    required this.mealReminderEnabled,
    this.mealReminderTime,
    required this.goalReminderEnabled,
    required this.aiChatNotificationEnabled,
    required this.aiPersonality,
    required this.dataPrivacyMode,
  });

  /// Creates a default instance with sensible defaults
  factory SettingsPreferencesEntity.defaults() {
    return const SettingsPreferencesEntity(
      isDarkMode: false,
      languageCode: 'vi',
      biometricEnabled: false,
      pushEnabled: false,
      mealReminderEnabled: false,
      mealReminderTime: null,
      goalReminderEnabled: false,
      aiChatNotificationEnabled: false,
      aiPersonality: 'friendly',
      dataPrivacyMode: 'local',
    );
  }

  /// Creates a copy of this entity with optionally modified fields
  SettingsPreferencesEntity copyWith({
    bool? isDarkMode,
    String? languageCode,
    bool? biometricEnabled,
    bool? pushEnabled,
    bool? mealReminderEnabled,
    String? mealReminderTime,
    bool? goalReminderEnabled,
    bool? aiChatNotificationEnabled,
    String? aiPersonality,
    String? dataPrivacyMode,
  }) {
    return SettingsPreferencesEntity(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      mealReminderEnabled: mealReminderEnabled ?? this.mealReminderEnabled,
      mealReminderTime: mealReminderTime ?? this.mealReminderTime,
      goalReminderEnabled: goalReminderEnabled ?? this.goalReminderEnabled,
      aiChatNotificationEnabled:
          aiChatNotificationEnabled ?? this.aiChatNotificationEnabled,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      dataPrivacyMode: dataPrivacyMode ?? this.dataPrivacyMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsPreferencesEntity &&
        other.isDarkMode == isDarkMode &&
        other.languageCode == languageCode &&
        other.biometricEnabled == biometricEnabled &&
        other.pushEnabled == pushEnabled &&
        other.mealReminderEnabled == mealReminderEnabled &&
        other.mealReminderTime == mealReminderTime &&
        other.goalReminderEnabled == goalReminderEnabled &&
        other.aiChatNotificationEnabled == aiChatNotificationEnabled &&
        other.aiPersonality == aiPersonality &&
        other.dataPrivacyMode == dataPrivacyMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDarkMode,
      languageCode,
      biometricEnabled,
      pushEnabled,
      mealReminderEnabled,
      mealReminderTime,
      goalReminderEnabled,
      aiChatNotificationEnabled,
      aiPersonality,
      dataPrivacyMode,
    );
  }

  @override
  String toString() {
    return 'SettingsPreferencesEntity('
        'isDarkMode: $isDarkMode, '
        'languageCode: $languageCode, '
        'biometricEnabled: $biometricEnabled, '
        'pushEnabled: $pushEnabled, '
        'mealReminderEnabled: $mealReminderEnabled, '
        'mealReminderTime: $mealReminderTime, '
        'goalReminderEnabled: $goalReminderEnabled, '
        'aiChatNotificationEnabled: $aiChatNotificationEnabled, '
        'aiPersonality: $aiPersonality, '
        'dataPrivacyMode: $dataPrivacyMode)';
  }
}

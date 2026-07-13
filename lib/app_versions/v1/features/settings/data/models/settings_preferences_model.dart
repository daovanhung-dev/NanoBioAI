import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/settings_preferences_entity.dart';

/// SettingsPreferencesModel extends SettingsPreferencesEntity to add
/// SharedPreferences serialization capabilities.
///
/// This model handles loading preferences from SharedPreferences storage
/// and provides helper methods for working with preference keys.
class SettingsPreferencesModel extends SettingsPreferencesEntity {
  const SettingsPreferencesModel({
    required super.isDarkMode,
    required super.languageCode,
    required super.biometricEnabled,
    required super.pushEnabled,
    required super.mealReminderEnabled,
    super.mealReminderTime,
    required super.goalReminderEnabled,
    required super.aiChatNotificationEnabled,
    required super.aiPersonality,
    required super.dataPrivacyMode,
  });

  /// SharedPreferences keys used for storing settings
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyPushEnabled = 'push_enabled';
  static const String keyMealReminderEnabled = 'meal_reminder_enabled';
  static const String keyMealReminderTime = 'meal_reminder_time';
  static const String keyGoalReminderEnabled = 'goal_reminder_enabled';
  static const String keyAiChatNotificationEnabled =
      'ai_chat_notification_enabled';
  static const String keyAiPersonality = 'ai_personality';
  static const String keyDataPrivacyMode = 'data_privacy_mode';

  /// Creates a SettingsPreferencesModel from SharedPreferences.
  ///
  /// Loads all preference values from SharedPreferences, using sensible defaults
  /// for any missing values.
  factory SettingsPreferencesModel.fromPreferences(SharedPreferences prefs) {
    // Theme mode: stored as "light" or "dark" string
    final themeMode = prefs.getString(keyThemeMode) ?? 'light';
    final isDarkMode = themeMode == 'dark';

    return SettingsPreferencesModel(
      isDarkMode: isDarkMode,
      // Các phiên bản cũ từng lưu `en`. Giao diện hiện chỉ hỗ trợ tiếng Việt,
      // vì vậy mọi giá trị cũ/không hợp lệ đều được nâng cấp an toàn về `vi`.
      languageCode: normalizeLanguageCode(prefs.getString(keyLanguageCode)),
      biometricEnabled: prefs.getBool(keyBiometricEnabled) ?? false,
      pushEnabled: prefs.getBool(keyPushEnabled) ?? false,
      mealReminderEnabled: prefs.getBool(keyMealReminderEnabled) ?? false,
      mealReminderTime: prefs.getString(keyMealReminderTime),
      goalReminderEnabled: prefs.getBool(keyGoalReminderEnabled) ?? false,
      aiChatNotificationEnabled:
          prefs.getBool(keyAiChatNotificationEnabled) ?? false,
      aiPersonality: prefs.getString(keyAiPersonality) ?? 'friendly',
      dataPrivacyMode: prefs.getString(keyDataPrivacyMode) ?? 'local',
    );
  }

  /// Creates a SettingsPreferencesModel from a SettingsPreferencesEntity.
  factory SettingsPreferencesModel.fromEntity(
    SettingsPreferencesEntity entity,
  ) {
    return SettingsPreferencesModel(
      isDarkMode: entity.isDarkMode,
      languageCode: normalizeLanguageCode(entity.languageCode),
      biometricEnabled: entity.biometricEnabled,
      pushEnabled: entity.pushEnabled,
      mealReminderEnabled: entity.mealReminderEnabled,
      mealReminderTime: entity.mealReminderTime,
      goalReminderEnabled: entity.goalReminderEnabled,
      aiChatNotificationEnabled: entity.aiChatNotificationEnabled,
      aiPersonality: entity.aiPersonality,
      dataPrivacyMode: entity.dataPrivacyMode,
    );
  }

  /// Converts the theme mode boolean to a string for storage.
  String get themeModeString => isDarkMode ? 'dark' : 'light';

  /// Converts this model to a Map for JSON serialization or debugging.
  Map<String, dynamic> toMap() {
    return {
      keyThemeMode: themeModeString,
      keyLanguageCode: languageCode,
      keyBiometricEnabled: biometricEnabled,
      keyPushEnabled: pushEnabled,
      keyMealReminderEnabled: mealReminderEnabled,
      keyMealReminderTime: mealReminderTime,
      keyGoalReminderEnabled: goalReminderEnabled,
      keyAiChatNotificationEnabled: aiChatNotificationEnabled,
      keyAiPersonality: aiPersonality,
      keyDataPrivacyMode: dataPrivacyMode,
    };
  }

  /// Saves all preferences to SharedPreferences.
  ///
  /// This is a convenience method for saving all settings at once.
  Future<bool> saveToPreferences(SharedPreferences prefs) async {
    final results = await Future.wait([
      prefs.setString(keyThemeMode, themeModeString),
      prefs.setString(keyLanguageCode, normalizeLanguageCode(languageCode)),
      prefs.setBool(keyBiometricEnabled, biometricEnabled),
      prefs.setBool(keyPushEnabled, pushEnabled),
      prefs.setBool(keyMealReminderEnabled, mealReminderEnabled),
      prefs.setBool(keyGoalReminderEnabled, goalReminderEnabled),
      prefs.setBool(keyAiChatNotificationEnabled, aiChatNotificationEnabled),
      prefs.setString(keyAiPersonality, aiPersonality),
      prefs.setString(keyDataPrivacyMode, dataPrivacyMode),
      if (mealReminderTime != null)
        prefs.setString(keyMealReminderTime, mealReminderTime!)
      else
        prefs.remove(keyMealReminderTime),
    ]);

    // Return true if all operations succeeded
    return results.every((result) => result);
  }

  /// Creates a new instance with default values.
  factory SettingsPreferencesModel.defaults() {
    return const SettingsPreferencesModel(
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

  /// Creates a copy with updated fields.
  @override
  SettingsPreferencesModel copyWith({
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
    return SettingsPreferencesModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: normalizeLanguageCode(languageCode ?? this.languageCode),
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

  static String normalizeLanguageCode(String? _) => 'vi';
}

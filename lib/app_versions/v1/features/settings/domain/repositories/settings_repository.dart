import '../entities/settings_preferences_entity.dart';
import '../entities/user_profile_entity.dart';

/// Abstract repository interface defining the contract for all settings-related
/// data operations.
///
/// This interface follows Clean Architecture principles by defining the contract
/// at the domain layer, allowing the data layer to implement it while keeping
/// the domain layer independent of implementation details.
///
/// The repository handles three main categories of operations:
/// - Profile management (user profile and avatar)
/// - Preferences management (theme, language, notifications, AI settings)
/// - System operations (security, storage, logout)
abstract class SettingsRepository {
  // ============================================================================
  // Profile Operations
  // ============================================================================

  /// Retrieves the complete user profile for the given [userId].
  ///
  /// Returns a [UserProfileEntity] if the user exists, or null if not found.
  /// Combines data from both the users table and health_profiles table.
  ///
  /// Example:
  /// ```dart
  /// final profile = await repository.getUserProfile('user-123');
  /// if (profile != null) {
  ///   print('Name: ${profile.fullName}, BMI: ${profile.bmi}');
  /// }
  /// ```
  Future<UserProfileEntity?> getUserProfile(String userId);

  /// Updates the user profile with the provided [profile] data for [userId].
  ///
  /// Updates both the users table (name, email, phone, gender, birthYear)
  /// and health_profiles table (occupation, height, weight, BMI).
  ///
  /// Throws an exception if validation fails or database operation fails.
  ///
  /// Example:
  /// ```dart
  /// final updatedProfile = profile.copyWith(
  ///   fullName: 'New Name',
  ///   heightCm: 175.0,
  /// );
  /// await repository.updateUserProfile('user-123', updatedProfile);
  /// ```
  Future<void> updateUserProfile(String userId, UserProfileEntity profile);

  /// Updates the user's avatar image path for [userId].
  ///
  /// The [avatarPath] should be a local file path or URL to the avatar image.
  /// Updates the avatar_url field in the users table.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateAvatar('user-123', '/path/to/avatar.jpg');
  /// ```
  Future<void> updateAvatar(String userId, String avatarPath);

  // ============================================================================
  // Preferences Operations
  // ============================================================================

  /// Retrieves all application preferences and settings.
  ///
  /// Returns a [SettingsPreferencesEntity] with all current preference values
  /// loaded from SharedPreferences. Returns default values if no preferences
  /// have been saved yet.
  ///
  /// Example:
  /// ```dart
  /// final prefs = await repository.getPreferences();
  /// print('Dark mode: ${prefs.isDarkMode}');
  /// print('Language: ${prefs.languageCode}');
  /// ```
  Future<SettingsPreferencesEntity> getPreferences();

  /// Updates the theme preference.
  ///
  /// Sets [isDarkMode] to true for dark theme, false for light theme.
  /// The theme change should be applied immediately to the UI.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateTheme(true); // Enable dark mode
  /// ```
  Future<void> updateTheme(bool isDarkMode);

  /// Updates the application language.
  ///
  /// [languageCode] must be `vi` while the app ships Vietnamese UI only.
  /// The language change should be applied immediately to the UI.
  ///
  /// Throws an exception if an invalid language code is provided.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateLanguage('vi');
  /// ```
  Future<void> updateLanguage(String languageCode);

  /// Updates the biometric authentication preference.
  ///
  /// Sets biometric authentication (Face ID/Touch ID) to [enabled].
  /// This should only be called after successful biometric authentication
  /// when enabling the feature.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateBiometric(true); // Enable biometric auth
  /// ```
  Future<void> updateBiometric(bool enabled);

  /// Updates a specific notification preference.
  ///
  /// [key] should be one of:
  /// - 'push_enabled': Push notifications
  /// - 'meal_reminder_enabled': Meal reminder notifications
  /// - 'goal_reminder_enabled': Health goal reminder notifications
  /// - 'ai_chat_notification_enabled': AI chat notifications
  ///
  /// [value] is the new enabled/disabled state for that notification type.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateNotificationPreference('push_enabled', true);
  /// ```
  Future<void> updateNotificationPreference(String key, bool value);

  /// Updates the meal reminder time.
  ///
  /// [time] should be in HH:mm format (e.g., '12:00', '18:30').
  /// This sets when meal reminder notifications should be sent.
  ///
  /// Throws an exception if the time format is invalid.
  ///
  /// Example:
  /// ```dart
  /// await repository.updateMealReminderTime('12:00'); // Noon reminder
  /// ```
  Future<void> updateMealReminderTime(String time);

  /// Updates the AI assistant personality preference.
  ///
  /// [personality] should be one of:
  /// - 'professional': Formal and concise responses
  /// - 'friendly': Casual and warm responses
  /// - 'motivational': Encouraging and supportive responses
  ///
  /// Example:
  /// ```dart
  /// await repository.updateAIPersonality('motivational');
  /// ```
  Future<void> updateAIPersonality(String personality);

  /// Updates the data privacy mode preference.
  ///
  /// [mode] should be either:
  /// - 'local': Store data only on device
  /// - 'cloud': Sync data with cloud storage
  ///
  /// Example:
  /// ```dart
  /// await repository.updateDataPrivacyMode('cloud'); // Enable cloud sync
  /// ```
  Future<void> updateDataPrivacyMode(String mode);

  // ============================================================================
  // Security Operations
  // ============================================================================

  /// Changes the user's password.
  ///
  /// Requires the [currentPassword] for verification and the [newPassword]
  /// to set. This operation communicates with Supabase authentication service.
  ///
  /// Throws an [AuthException] if:
  /// - Current password is incorrect
  /// - New password doesn't meet security requirements
  /// - Network connection fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await repository.changePassword('oldPass123', 'newPass456');
  ///   print('Password changed successfully');
  /// } on AuthException catch (e) {
  ///   print('Password change failed: ${e.message}');
  /// }
  /// ```
  Future<void> changePassword(String currentPassword, String newPassword);

  // ============================================================================
  // Storage Operations
  // ============================================================================

  /// Calculates the total size of cached data in bytes.
  ///
  /// Returns the size of the application cache directory, which may include:
  /// - Temporary files
  /// - Image caches
  /// - API response caches
  ///
  /// Example:
  /// ```dart
  /// final sizeBytes = await repository.getCacheSize();
  /// final sizeMB = sizeBytes / (1024 * 1024);
  /// print('Cache size: ${sizeMB.toStringAsFixed(2)} MB');
  /// ```
  Future<int> getCacheSize();

  /// Clears all cached data.
  ///
  /// Deletes all files in the application cache directory to free up storage space.
  /// This operation cannot be undone.
  ///
  /// Example:
  /// ```dart
  /// final sizeBefore = await repository.getCacheSize();
  /// await repository.clearCache();
  /// final sizeAfter = await repository.getCacheSize();
  /// print('Freed: ${(sizeBefore - sizeAfter) / (1024 * 1024)} MB');
  /// ```
  Future<void> clearCache();

  /// Deletes all meal plans for the specified [userId].
  ///
  /// Removes all meal plan records from the local database.
  /// This operation cannot be undone.
  ///
  /// Example:
  /// ```dart
  /// await repository.deleteMealPlans('user-123');
  /// print('All meal plans deleted');
  /// ```
  Future<void> deleteMealPlans(String userId);

  // ============================================================================
  // Logout Operations
  // ============================================================================

  /// Logs out the current user and optionally clears local data.
  ///
  /// Always clears the Supabase authentication session.
  ///
  /// If [clearLocalData] is true, also:
  /// - Deletes all records from the local database (users, health profiles,
  ///   health goals, meal plans, chat history)
  /// - Clears all SharedPreferences values
  /// - Resets the onboarding_completed flag to false
  ///
  /// If [clearLocalData] is false, preserves all local data for the next login.
  ///
  /// Example:
  /// ```dart
  /// // Logout but keep local data (switch accounts)
  /// await repository.logout(clearLocalData: false);
  ///
  /// // Logout and clear everything (fresh start)
  /// await repository.logout(clearLocalData: true);
  /// ```
  Future<void> logout({required bool clearLocalData});
}

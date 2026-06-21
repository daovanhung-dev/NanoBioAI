import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _pendingGuestUserIdKey = 'pending_guest_user_id';
  static const String _lastCloudSyncAtKey = 'last_cloud_sync_at';

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_onboardingKey, value);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setPendingGuestUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = userId.trim();

    if (trimmed.isEmpty) {
      await prefs.remove(_pendingGuestUserIdKey);
      return;
    }

    await prefs.setString(_pendingGuestUserIdKey, trimmed);
  }

  static Future<String?> pendingGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_pendingGuestUserIdKey)?.trim();

    return userId == null || userId.isEmpty ? null : userId;
  }

  static Future<void> clearPendingGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pendingGuestUserIdKey);
  }

  static Future<void> setLastCloudSyncAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_lastCloudSyncAtKey, value.toUtc().toIso8601String());
  }

  static Future<DateTime?> lastCloudSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastCloudSyncAtKey);
    if (value == null || value.trim().isEmpty) return null;

    return DateTime.tryParse(value);
  }
}

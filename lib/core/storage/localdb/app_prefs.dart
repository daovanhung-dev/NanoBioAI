import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _pendingGuestUserIdKey = 'pending_guest_user_id';
  static const String _lastCloudSyncAtKey = 'last_cloud_sync_at';
  static const String _cloudPullRetryPendingKey = 'cloud_pull_retry_pending';
  static const String _pendingGuestSyncAuthUserIdKey =
      'pending_guest_sync_auth_user_id';
  static const String _pendingGuestSyncActionKey =
      'pending_guest_sync_action';

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

  static Future<void> setPendingGuestSyncDecision({
    required String authUserId,
    required String action,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingGuestSyncAuthUserIdKey, authUserId.trim());
    await prefs.setString(_pendingGuestSyncActionKey, action.trim());
  }

  static Future<String?> pendingGuestSyncActionFor(String authUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs
        .getString(_pendingGuestSyncAuthUserIdKey)
        ?.trim();
    if (storedUserId == null || storedUserId != authUserId.trim()) return null;

    final action = prefs.getString(_pendingGuestSyncActionKey)?.trim();
    return action == null || action.isEmpty ? null : action;
  }

  static Future<void> clearPendingGuestSyncDecision() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingGuestSyncAuthUserIdKey);
    await prefs.remove(_pendingGuestSyncActionKey);
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

  static Future<void> setCloudPullRetryPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudPullRetryPendingKey, value);
  }

  static Future<bool> isCloudPullRetryPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudPullRetryPendingKey) ?? false;
  }
}

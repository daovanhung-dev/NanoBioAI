import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _aiChatThinkingPhraseNextIndexKey =
      'ai_chat_thinking_phrase_next_index';
  static const Duration _thinkingPhraseStorageTimeout = Duration(
    milliseconds: 250,
  );
  static const String _pendingGuestUserIdKey = 'pending_guest_user_id';
  static const String _lastCloudSyncAtKey = 'last_cloud_sync_at';
  static const String _cloudPullRetryPendingKey = 'cloud_pull_retry_pending';
  static const String _cloudRevisionKeyPrefix = 'cloud_revision_v1_';
  static const String _pendingGuestSyncAuthUserIdKey =
      'pending_guest_sync_auth_user_id';
  static const String _pendingGuestSyncActionKey = 'pending_guest_sync_action';
  static const String _pendingGuestReminderTransferAuthUserIdKey =
      'pending_guest_reminder_transfer_auth_user_id';
  static Future<void>? _thinkingPhraseInitialization;
  static SharedPreferences? _thinkingPhrasePreferences;
  static int? _thinkingPhraseNextIndex;
  static bool _thinkingPhraseCursorInitialized = false;
  static bool _useThinkingPhraseMemoryFallback = false;

  /// Reserves the next local chat thinking phrase index and advances the cursor.
  ///
  /// Loads the cursor once, then advances it synchronously before any write.
  /// If local preferences are unavailable, the sequence continues in memory
  /// for the current app session.
  static Future<int> reserveNextAiChatThinkingPhraseIndex({
    required int phraseCount,
  }) async {
    if (phraseCount <= 0) {
      throw ArgumentError.value(phraseCount, 'phraseCount');
    }

    await _initializeAiChatThinkingPhraseCursor(phraseCount);

    var currentIndex = _thinkingPhraseNextIndex ?? 0;
    if (currentIndex < 0 || currentIndex >= phraseCount) currentIndex = 0;
    _thinkingPhraseNextIndex = (currentIndex + 1) % phraseCount;

    final preferences = _thinkingPhrasePreferences;
    if (preferences == null || _useThinkingPhraseMemoryFallback) {
      _useThinkingPhraseMemoryFallback = true;
      return currentIndex;
    }

    try {
      final saved = await preferences
          .setInt(_aiChatThinkingPhraseNextIndexKey, _thinkingPhraseNextIndex!)
          .timeout(_thinkingPhraseStorageTimeout);
      _useThinkingPhraseMemoryFallback = !saved;
    } catch (_) {
      _useThinkingPhraseMemoryFallback = true;
    }

    return currentIndex;
  }

  static Future<void> _initializeAiChatThinkingPhraseCursor(int phraseCount) {
    if (_thinkingPhraseCursorInitialized) return Future<void>.value();

    return _thinkingPhraseInitialization ??= () async {
      try {
        final preferences = await SharedPreferences.getInstance().timeout(
          _thinkingPhraseStorageTimeout,
        );
        _thinkingPhrasePreferences = preferences;
        final storedIndex =
            preferences.getInt(_aiChatThinkingPhraseNextIndexKey) ?? 0;
        _thinkingPhraseNextIndex = storedIndex >= 0 && storedIndex < phraseCount
            ? storedIndex
            : 0;
      } catch (_) {
        _thinkingPhraseNextIndex = 0;
        _useThinkingPhraseMemoryFallback = true;
      }
      _thinkingPhraseCursorInitialized = true;
    }();
  }

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
    await prefs.remove(_pendingGuestReminderTransferAuthUserIdKey);
  }

  static Future<void> setPendingGuestMedicationReminderTransfer({
    required String authUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingGuestReminderTransferAuthUserIdKey,
      authUserId.trim(),
    );
  }

  static Future<bool> shouldPreserveGuestMedicationRemindersFor(
    String authUserId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
            .getString(_pendingGuestReminderTransferAuthUserIdKey)
            ?.trim() ==
        authUserId.trim();
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

  static Future<int?> cloudRevisionFor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_cloudRevisionKeyPrefix$userId');
  }

  static Future<void> setCloudRevisionFor(String userId, int revision) async {
    if (userId.trim().isEmpty || revision < 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_cloudRevisionKeyPrefix$userId', revision);
  }

  /// Removes every locally persisted preference after an account deletion.
  ///
  /// Settings are intentionally device-local, but clearing the store prevents
  /// an unauthenticated launch from restoring account-scoped onboarding,
  /// sync, or notification state from the deleted account.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _thinkingPhrasePreferences = prefs;
    _thinkingPhraseNextIndex = 0;
    _thinkingPhraseInitialization = null;
    _thinkingPhraseCursorInitialized = true;
    _useThinkingPhraseMemoryFallback = false;
  }
}

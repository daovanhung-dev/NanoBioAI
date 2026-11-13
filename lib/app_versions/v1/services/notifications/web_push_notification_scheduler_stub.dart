import 'web_push_notification_scheduler.dart';

class UnsupportedWebPushNotificationScheduler
    implements WebPushNotificationScheduler {
  @override
  String? get availabilityMessage =>
      'Web Push chưa được hỗ trợ trên nền tảng này.';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {}

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {}

  @override
  Future<void> scheduleNabiCompanionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
    required bool voiceEnabled,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelMedicationReminders({String? ownerId}) async {}

  @override
  Future<void> synchronize() async {}

  @override
  Future<void> unsubscribe() async {}
}

WebPushNotificationScheduler createWebPushNotificationScheduler() =>
    UnsupportedWebPushNotificationScheduler();

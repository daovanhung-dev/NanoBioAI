import 'web_push_notification_scheduler_stub.dart'
    if (dart.library.js_interop) 'web_push_notification_scheduler_web.dart'
    as platform;

import 'reminder_notification_scheduler.dart';

abstract interface class WebPushNotificationScheduler
    implements
        ReminderNotificationScheduler,
        MedicationDailyNotificationScheduler,
        NabiCompanionReminderNotificationScheduler {
  Future<void> synchronize();

  Future<void> unsubscribe();

  String? get availabilityMessage;
}

WebPushNotificationScheduler createWebPushNotificationScheduler() =>
    platform.createWebPushNotificationScheduler();

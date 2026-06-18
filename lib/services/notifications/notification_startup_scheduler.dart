import 'package:nano_app/core/utils/logger/app_logger.dart';

class NotificationStartupScheduler {
  static const _tag = 'NOTIFICATION_STARTUP';

  final Future<bool> Function() isOnboardingCompleted;
  final Future<void> Function() scheduleGeneratedReminders;

  const NotificationStartupScheduler({
    required this.isOnboardingCompleted,
    required this.scheduleGeneratedReminders,
  });

  Future<void> refreshGeneratedReminders() async {
    try {
      final completed = await isOnboardingCompleted();
      if (!completed) {
        AppLogger.info(_tag, 'Skip reminder refresh before onboarding');
        return;
      }

      await scheduleGeneratedReminders();
      AppLogger.success(_tag, 'Refreshed generated reminder notifications');
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to refresh generated reminder notifications',
        error,
        stackTrace,
      );
    }
  }
}

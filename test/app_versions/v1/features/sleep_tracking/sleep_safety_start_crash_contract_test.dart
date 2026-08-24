import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M31 start permission path does not request exact alarm access', () {
    final providers = File(
      'lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart',
    ).readAsStringSync();
    final reminder = File(
      'lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_reminder_service.dart',
    ).readAsStringSync();

    expect(providers, isNot(contains('NotificationBootstrap.scheduler.requestPermissions')));
    expect(
      providers,
      contains('SleepSafetyNotificationPermissionGateway'),
    );
    expect(reminder, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
    expect(reminder, isNot(contains('scheduler.requestPermissions()')));
  });

  test('Android start path converts foreground-service failures to safe errors', () {
    final channel = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt',
    ).readAsStringSync();
    final service = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt',
    ).readAsStringSync();

    expect(channel, contains('result.error(code, safeMessage(code), null)'));
    expect(channel, contains('microphone_fgs_not_allowed'));
    expect(channel, contains('service_not_registered'));
    expect(service, contains('promoteToForegroundSafely()'));

    final promotionIndex = service.indexOf('if (!promoteToForegroundSafely()) return');
    final activeIndex = service.indexOf('SleepSafetyRuntimeStatus.active = true');
    expect(promotionIndex, greaterThanOrEqualTo(0));
    expect(activeIndex, greaterThan(promotionIndex));
  });

  test('AudioRecord worker catches runtime failures instead of crashing process', () {
    final capture = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyAudioCapture.kt',
    ).readAsStringSync();

    expect(capture, contains('private val failureSignaled = AtomicBoolean(false)'));
    expect(capture, contains('catch (_: RuntimeException)'));
    expect(capture, contains('signalFailure("audio_capture_failed")'));
  });
}

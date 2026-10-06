import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final androidService = File(
    'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt',
  ).readAsStringSync();
  final androidNotification = File(
    'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNotificationFactory.kt',
  ).readAsStringSync();
  final androidHandler = File(
    'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt',
  ).readAsStringSync();
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final ios = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  test(
    'Android alert action opens ACTION_DIAL from the configured contact',
    () {
      expect(androidNotification, contains('Intent.ACTION_DIAL'));
      expect(androidNotification, contains('Uri.parse("tel:'));
      expect(androidNotification, isNot(contains('Intent.ACTION_CALL')));
      expect(androidService, contains('phoneFallbackEnabled'));
      expect(androidService, contains('notifications.alert(eventId'));
    },
  );

  test(
    'baseline Android manifest has no restricted call or SMS permissions',
    () {
      expect(manifest, isNot(contains('READ_CALL_LOG')));
      expect(manifest, isNot(contains('WRITE_CALL_LOG')));
      expect(manifest, isNot(contains('PROCESS_OUTGOING_CALLS')));
      expect(manifest, isNot(contains('SEND_SMS')));
    },
  );

  test(
    'iOS call notification action opens tel only after the user selects it',
    () {
      expect(ios, contains('actionCall'));
      expect(ios, contains('UIApplication.shared.open(url'));
      expect(ios, contains('URL(string: "tel:\\(phone)")'));
      expect(ios, contains('phoneFallbackRequested'));
      expect(ios, contains('phoneFallbackEnabled'));
    },
  );

  test(
    'native escalation timers are 15 seconds with no 30-second reminder',
    () {
      expect(androidService, contains('handler.postDelayed(it, 15_000L)'));
      expect(androidService, isNot(contains('30_000L')));
      expect(androidService, isNot(contains('alertReminder')));
      expect(ios, contains('deadline: .now() + 15, execute: escalation'));
      expect(ios, isNot(contains('reminderWork')));
      expect(ios, isNot(contains('alertReminder')));
    },
  );

  test(
    'Android silences the alert only after a call or dialer launch succeeds',
    () {
      final directCall = androidHandler
          .split('private fun startCall')
          .last
          .split('private fun openDialer')
          .first;
      final dialer = androidHandler
          .split('private fun openDialer')
          .last
          .split('private fun start(args')
          .first;
      final silence = androidService
          .split('private fun silenceAlertAfterCallHandoff')
          .last
          .split('private fun updateConfig')
          .first;

      expect(directCall, contains('Intent.ACTION_CALL'));
      expect(
        directCall.indexOf('context.startActivity'),
        lessThan(directCall.indexOf('silenceAlertAfterCallHandoff')),
      );
      expect(dialer, contains('Intent.ACTION_DIAL'));
      expect(
        dialer.indexOf('context.startActivity'),
        lessThan(dialer.indexOf('silenceAlertAfterCallHandoff')),
      );
      expect(silence, contains('cancelAlertTimers()'));
      expect(silence, contains('stopPersistentAlert()'));
      expect(
        directCall.split('} catch').last,
        isNot(contains('silenceAlertAfterCallHandoff')),
      );
      expect(
        dialer.split('} catch').last,
        isNot(contains('silenceAlertAfterCallHandoff')),
      );
    },
  );

  test(
    'iOS silences the safety notification only after tel handoff succeeds',
    () {
      final phoneHandoff = ios
          .split('case "openDialer"')
          .last
          .split('case "dismissAlert"')
          .first;

      expect(phoneHandoff, contains('URL(string: "tel:\\(phone)")'));
      expect(phoneHandoff, contains('if opened'));
      expect(
        phoneHandoff.indexOf('silenceAlertAfterCallHandoff'),
        greaterThan(phoneHandoff.indexOf('UIApplication.shared.open')),
      );
      expect(phoneHandoff, contains('result(opened)'));
    },
  );
}

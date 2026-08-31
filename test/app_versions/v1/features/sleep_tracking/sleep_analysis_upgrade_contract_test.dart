import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SQLite v24 wires v22 and v23 migrations and forbids raw audio columns', () {
    final version = File('lib/core/storage/localdb/database_version.dart').readAsStringSync();
    final service = File('lib/core/storage/localdb/database_service.dart').readAsStringSync();
    final tables = File('lib/core/storage/localdb/tables/sleep_safety_tables.dart').readAsStringSync();

    expect(version, contains('currentVersion = 24'));
    expect(service, contains('MigrationV22.run'));
    expect(service, contains('MigrationV23.run'));
    expect(service, contains('MigrationV22.ensureSchema'));
    expect(service, contains('MigrationV23.ensureSchema'));
    expect(tables, contains('sleep_safety_night_analyses'));
    expect(tables, isNot(contains('audio_blob')));
    expect(tables, isNot(contains('audio_path')));
    expect(tables, isNot(contains('transcript')));
  });

  test('Android uses separate foreground and persistent alert notifications', () {
    final factory = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNotificationFactory.kt',
    ).readAsStringSync();
    final service = File(
      'android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt',
    ).readAsStringSync();

    expect(factory, contains('MONITOR_NOTIFICATION_ID = 319001'));
    expect(factory, contains('ALERT_NOTIFICATION_ID = 319002'));
    expect(service, contains('alertTone.start()'));
    expect(service, contains('stopPersistentAlert()'));
    expect(service, contains('MONITOR_NOTIFICATION_ID'));
    expect(service, contains('ALERT_NOTIFICATION_ID'));
  });
}

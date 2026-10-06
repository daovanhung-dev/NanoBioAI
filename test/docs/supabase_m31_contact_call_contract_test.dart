import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final schema = File('docs/supabase/01_build_system.sql').readAsStringSync();
  final contactDatasource = File(
    'lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart',
  ).readAsStringSync();
  final contactPage = File(
    'lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart',
  ).readAsStringSync();
  final migration = File(
    'supabase/migrations/20261006120000_m31_remove_zalo_channel.sql',
  ).readAsStringSync();
  final edgeHandler = File(
    'supabase/functions/sleep-safety-dispatch/handler.ts',
  ).readAsStringSync();

  test('canonical M31 schema has only voice and SMS server channels', () {
    expect(schema.toLowerCase(), isNot(contains('zalo')));
    expect(schema, contains('channel in (\'sms\', \'voice\')'));
    expect(
      schema,
      contains('phone_fallback_enabled boolean not null default false'),
    );
    expect(
      schema,
      contains('allow_phone_fallback boolean not null default true'),
    );
    expect(
      schema,
      contains('allow_unverified_voice_alert boolean not null default false'),
    );
  });

  test('forward migration removes Zalo without deleting contacts', () {
    final sql = migration.toLowerCase();
    expect(sql, contains('drop column if exists zalo_enabled'));
    expect(sql, contains('drop column if exists allow_zalo_alert'));
    expect(sql, contains("where channel = 'zalo'"));
    expect(sql, contains('m31_legacy_zalo_dispatch_rows_require_review'));
    expect(sql, contains("check (channel in ('sms', 'voice'))"));
    expect(sql, contains('p_allow_phone_fallback boolean'));
    expect(sql, contains('p_allow_unverified_voice_alert boolean'));
    expect(sql, isNot(contains('delete from public.sleep_safety_contacts')));
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('truncate')));
  });

  test('client contact API and UI no longer expose a Zalo option', () {
    expect(contactDatasource.toLowerCase(), isNot(contains('zalo')));
    expect(contactPage.toLowerCase(), isNot(contains('zalo')));
    expect(
      contactDatasource,
      contains("'p_allow_unverified_voice_alert': allowUnverifiedVoiceAlert"),
    );
    expect(
      contactPage,
      contains('contact?.allowUnverifiedVoiceAlert ?? false'),
    );
  });

  test('Edge escalation only accepts no-response voice and SMS routes', () {
    expect(edgeHandler, contains('event.response !== "noResponse"'));
    expect(edgeHandler, contains('channel: "voice"'));
    expect(edgeHandler, contains('channel: "sms"'));
    expect(edgeHandler.toLowerCase(), isNot(contains('zalo')));
  });
}

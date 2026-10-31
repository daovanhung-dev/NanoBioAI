import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase Storage fixture runner contract', () {
    test('uses safe environment configuration and Storage APIs', () {
      final script = File(
        'docs/archive/legacy-supabase/tools/Seed-StorageFixtures.ps1',
      ).readAsStringSync();

      for (final token in [
        'NANOBIO_SUPABASE_URL',
        'NANOBIO_SUPABASE_ANON_KEY',
        'NANOBIO_SUPABASE_SERVICE_ROLE_KEY',
        'AllowNonLocal',
        'storage/v1/object/list/',
        'storage/v1/object/authenticated/',
        'begin_my_schedule_completion',
        'finalize_my_schedule_completion',
        'undo_my_schedule_completion',
        'Select-Object -First 2',
        'Complete-ScheduleFixtureEligibility',
        'get_my_sale_conversions',
        "'x-upsert'",
        "'false'",
        'Remove-AbandonedScheduleFixtureObjects',
        'Assert-FreshStorageFixtureRun',
        'one-shot after a destructive rebuild',
      ]) {
        expect(script, contains(token), reason: token);
      }

      expect(script, isNot(contains('psql')));
      expect(script, isNot(contains('Invoke-Sqlcmd')));
      expect(script, contains(r'(^|[.-])sandbox([.-]|$)'));
      expect(script, isNot(contains('(sandbox|staging)')));
    });

    test('keeps rollout defaults explicit in the local seed script', () {
      final seed = File('docs/archive/legacy-supabase/sql/02_seed_data.sql').readAsStringSync();

      for (final token in [
        'wellness_rewards_rollout',
        'sale_point_conversion',
        'nabi_companion_notifications_rollout',
        '"enabled": false',
        'Default disabled Sale point conversion policy.',
        'M30 rollout remains disabled until sandbox and device acceptance pass.',
      ]) {
        expect(seed, contains(token), reason: token);
      }
    });

    test(
      'does not permit overwriting Sale payout evidence from the Admin app',
      () {
        final source = File(
          'lib/app_versions/admin/features/admin_panel/data/datasources/admin_payout_proof_remote_datasource.dart',
        ).readAsStringSync();

        expect(source, contains("'/api/v1/files/sale-payout-proofs"));
        expect(source, contains('uploadBytes('));
      },
    );
  });
}

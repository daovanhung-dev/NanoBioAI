import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const componentPaths = [
    'docs/supabase/01_schema_rebuild_local_sandbox.sql',
    'docs/supabase/02_schema_meal_nutrition_v18.sql',
    'docs/supabase/03_schema_daily_health_hub_rewards.sql',
    'docs/supabase/04_schema_auth_account_lock.sql',
    'docs/supabase/05_seed_local_sandbox.sql',
    'docs/supabase/06_schema_runtime_support.sql',
  ];

  test(
    'numbers the destructive local/sandbox rebuild and generated config',
    () {
      for (final path in componentPaths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }

      final readme = File('docs/supabase/README.md').readAsStringSync();
      final config = File('docs/supabase/config.sql').readAsStringSync();

      for (final filename in componentPaths.map(
        (path) => path.split('/').last,
      )) {
        expect(readme, contains(filename), reason: filename);
        expect(config, contains('-- BEGIN $filename'), reason: filename);
        expect(config, contains('-- END $filename'), reason: filename);
      }
      expect(config, contains('DESTRUCTIVE LOCAL/SANDBOX SCRIPT ONLY'));
    },
  );

  test('seeds the requested local Plus account server-side', () {
    final seed = File(
      'docs/supabase/05_seed_local_sandbox.sql',
    ).readAsStringSync();

    for (final token in [
      'Thuytien8994@gmail.com',
      "'plus'::public.nb_membership_plan",
      'crypt(',
      'LOCAL_PLUS_SEED_AUTH_INVALID',
      'LOCAL_PLUS_SEED_PLAN_INVALID',
      'LOCAL_PLUS_SEED_AI_CHAT_ENTITLEMENT_INVALID',
      'entitlement_key = \'ai_chat\'',
      "'{\"enabled\":true,\"unlimited\":true}'::jsonb",
    ]) {
      expect(seed, contains(token), reason: token);
    }
  });

  test('keeps VietQR creation server-issued, idempotent, and rollback-only', () {
    final smoke = File(
      'docs/supabase/93_validate_membership_vietqr.sql',
    ).readAsStringSync();

    expect(smoke, startsWith('-- Rollback-only'));
    expect(smoke, contains('create_membership_payment_request'));
    expect(smoke, contains("'^NB[0-9A-F]{12}$'"));
    expect(smoke, contains('VIETQR_IDEMPOTENCY_BROKEN'));
    expect(smoke, contains('VIETQR_OPEN_REQUEST_GUARD_MISSING'));
    expect(smoke.trimRight(), endsWith('rollback;'));
  });

  test('keeps runtime Storage and RPC support separate from fixtures', () {
    final runtime = File(
      'docs/supabase/06_schema_runtime_support.sql',
    ).readAsStringSync();
    final seed = File('docs/supabase/05_seed_local_sandbox.sql')
        .readAsStringSync();
    final smoke = File('docs/supabase/94_validate_runtime_support.sql')
        .readAsStringSync();

    for (final bucket in [
      'schedule-completion-proofs',
      'sale-payout-proofs',
    ]) {
      expect(runtime, contains(bucket), reason: bucket);
      expect(seed, isNot(contains('insert into storage.buckets')));
    }
    expect(runtime, contains('RUNTIME_RPC_MISSING_'));
    expect(runtime, contains('grant execute on function public.%I'));
    expect(smoke, contains('RUNTIME_STORAGE_BUCKET_INVALID_'));
    expect(smoke.trimRight(), endsWith('rollback;'));
  });
}

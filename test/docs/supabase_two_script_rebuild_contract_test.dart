import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _buildPath = 'docs/supabase/01_build_system.sql';
const _seedPath = 'docs/supabase/02_seed_data.sql';
const _aiRuntimePath = 'docs/supabase/03_ai_runtime_enablement.sql';

void main() {
  group('Supabase rebuild and AI preflight contract', () {
    late String build;
    late String seed;
    late String aiRuntime;

    setUpAll(() {
      build = File(_buildPath).readAsStringSync();
      seed = File(_seedPath).readAsStringSync();
      aiRuntime = File(_aiRuntimePath).readAsStringSync();
    });

    test(
      'keeps two authoritative rebuild scripts and one optional preflight',
      () {
        final sqlFiles =
            Directory('docs/supabase')
                .listSync(followLinks: false)
                .whereType<File>()
                .where((file) => file.path.endsWith('.sql'))
                .map((file) => file.uri.pathSegments.last)
                .toList()
              ..sort();

        expect(sqlFiles, [
          '01_build_system.sql',
          '02_seed_data.sql',
          '03_ai_runtime_enablement.sql',
        ]);
      },
    );

    test(
      'documents the destructive rebuild followed by the optional preflight',
      () {
        final readme = File('docs/supabase/README.md').readAsStringSync();
        final buildIndex = readme.indexOf('01_build_system.sql');
        final seedIndex = readme.indexOf('02_seed_data.sql');
        final aiRuntimeIndex = readme.indexOf('03_ai_runtime_enablement.sql');

        expect(buildIndex, greaterThanOrEqualTo(0));
        expect(seedIndex, greaterThan(buildIndex));
        expect(aiRuntimeIndex, greaterThan(seedIndex));
        expect(readme, contains('ON_ERROR_STOP'));
        expect(
          readme,
          matches(
            RegExp(r'không\s+thuộc\s+rebuild sequence', caseSensitive: false),
          ),
        );
        expect(build, contains('DESTRUCTIVE LOCAL/SANDBOX SCRIPT ONLY'));
        expect(build, contains('drop schema if exists public cascade'));
        expect(seed, contains('DEV/SANDBOX ONLY'));
        expect(seed, contains('truncate table auth.users cascade'));
        expect(seed, contains('insert into auth.users'));
        expect(seed, isNot(contains('drop schema if exists public cascade')));
      },
    );

    test('keeps the AI preflight read-only and provider-secret free', () {
      for (final token in [
        'OPTIONAL AI RUNTIME PREFLIGHT (READ ONLY)',
        'begin read only;',
        'AI_RUNTIME_TABLE_MISSING_',
        'AI_RUNTIME_RPC_MISSING_',
        'AI_RUNTIME_RLS_MISSING_',
        'AI_RUNTIME_QUOTA_RULE_MISSING_',
        'rollback;',
      ]) {
        expect(aiRuntime, contains(token), reason: token);
      }

      final mutatingStatement = RegExp(
        r'^\s*(?:drop\s+schema|truncate|create\s+table|alter\s+table|insert\s+into|update\s+|delete\s+from|grant\s+|revoke\s+)',
        caseSensitive: false,
        multiLine: true,
      );
      expect(mutatingStatement.hasMatch(aiRuntime), isFalse);
      expect(aiRuntime.toLowerCase(), isNot(contains('gemini_api_key')));
    });

    test('keeps M31 rollout in the build without granting membership', () {
      final marker = 'SLEEP_SAFETY_RUNTIME_CONFIG_MISSING';
      final transactionStart = build.lastIndexOf(
        'begin;',
        build.indexOf(marker),
      );
      final transactionEnd = build.indexOf('commit;', build.indexOf(marker));
      expect(transactionStart, greaterThanOrEqualTo(0));
      expect(transactionEnd, greaterThan(transactionStart));
      final rollout = build.substring(transactionStart, transactionEnd);

      for (final token in [
        "to_regclass('public.sleep_safety_runtime_config')",
        "where config_key = 'default'",
        'set enabled = true',
        'SLEEP_SAFETY_RUNTIME_CONFIG_MISSING',
        'SLEEP_SAFETY_DEFAULT_CONFIG_MISSING',
      ]) {
        expect(rollout, contains(token), reason: token);
      }
      expect(rollout, isNot(contains('membership_plan =')));
    });

    test('keeps runtime Storage and M31 contact RPCs in the build', () {
      final systemValidation = build.indexOf(
        '-- BEGIN FAIL-FAST SYSTEM VALIDATION',
      );
      final sleepSafetySchema = build.indexOf(
        'create table if not exists public.sleep_safety_runtime_config',
      );
      final runtimeSupport = build.indexOf('RUNTIME_RPC_MISSING_');
      final rollout = build.indexOf('SLEEP_SAFETY_DEFAULT_CONFIG_MISSING');

      expect(runtimeSupport, greaterThan(sleepSafetySchema));
      expect(rollout, greaterThan(runtimeSupport));
      expect(systemValidation, greaterThan(rollout));
      for (final token in [
        'schedule-completion-proofs',
        'sale-payout-proofs',
        'insert into storage.buckets',
        'upsert_sleep_safety_contact',
        'delete_sleep_safety_contact',
        'grant execute on function public.upsert_sleep_safety_contact',
        'grant execute on function public.delete_sleep_safety_contact',
        'RUNTIME_RPC_MISSING_',
        'RUNTIME_STORAGE_BUCKET_INVALID_',
        'RUNTIME_RPC_GRANT_MISSING_upsert_sleep_safety_contact',
        'RUNTIME_RPC_GRANT_MISSING_delete_sleep_safety_contact',
        'DAILY_HEALTH_HUB_TABLE_MISSING',
        'DAILY_HEALTH_HUB_REWARD_POINTS_INVALID',
        'DAILY_HEALTH_HUB_RPC_MISSING_',
        'DAILY_HEALTH_HUB_GRANT_INVALID',
        'DAILY_HEALTH_HUB_ELIGIBILITY_NULLABILITY_INVALID',
        'AI_RUNTIME_TABLE_MISSING_',
        'AI_RUNTIME_RPC_MISSING_',
        'AI_RUNTIME_RLS_MISSING_',
        'AI_RUNTIME_RLS_POLICY_MISSING_',
        'AI_RUNTIME_REPORT_GRANT_INVALID',
        'AI_RUNTIME_ANON_RPC_GRANT_INVALID_',
      ]) {
        expect(build, contains(token), reason: token);
      }
      expect(seed, isNot(contains('insert into storage.buckets')));
    });

    test(
      'keeps generated catalog data and fail-fast checks inside the seed',
      () {
        const catalogBegin = '-- BEGIN GENERATED MEAL CATALOG';
        const catalogEnd = '-- END GENERATED MEAL CATALOG';
        const validationBegin = '-- BEGIN FAIL-FAST SEED VALIDATION';
        const vietQrBegin = '-- BEGIN ROLLBACK-ONLY VIETQR SMOKE';
        final catalogStart = seed.indexOf(catalogBegin);
        final catalogEndIndex = seed.indexOf(catalogEnd);
        final validationStart = seed.indexOf(validationBegin);
        final commitIndex = seed.indexOf('commit;');
        final vietQrStart = seed.indexOf(vietQrBegin);

        expect(catalogStart, greaterThanOrEqualTo(0));
        expect(catalogEndIndex, greaterThan(catalogStart));
        expect(validationStart, greaterThan(catalogEndIndex));
        expect(commitIndex, greaterThan(validationStart));
        expect(vietQrStart, greaterThan(commitIndex));

        final catalog = seed.substring(catalogStart, catalogEndIndex);
        expect(
          RegExp(
            r'insert into public\.meal_catalog',
            caseSensitive: false,
          ).allMatches(catalog).length,
          163,
        );
        for (final token in [
          'MEAL_CATALOG_RECIPE_COUNT_MISMATCH',
          'MEAL_CATALOG_TOPIC_COUNT_MISMATCH',
          'MEAL_CATALOG_CHAPTER_COUNT_MISMATCH',
          'MEAL_CATALOG_SOURCE_FIELDS_INCOMPLETE',
          'MEAL_CATALOG_UNAPPROVED_METADATA_STATE',
          'MEAL_CATALOG_DUPLICATE_SOURCE_HASH',
          'MEAL_NUTRITION_ESTIMATED_REQUIRED_FIELDS_MISSING',
          'MEAL_NUTRITION_NEGATIVE_VALUE',
          'MEAL_NUTRITION_ESTIMATED_ALL_ZERO',
          'MEAL_NUTRITION_MACRO_CALORIE_SANITY_FAILED',
          'MEAL_NUTRITION_STATUS_UNSUPPORTED',
        ]) {
          expect(seed, contains(token), reason: token);
        }
      },
    );

    test('keeps VietQR smoke server-issued, idempotent, and rollback-only', () {
      const smokeMarker = '-- BEGIN ROLLBACK-ONLY VIETQR SMOKE';
      final smokeStart = seed.indexOf(smokeMarker);
      expect(smokeStart, greaterThanOrEqualTo(0));
      final smoke = seed.substring(smokeStart);

      for (final token in [
        'create_membership_payment_request',
        r"'^NB[0-9A-F]{12}$'",
        'VIETQR_IDEMPOTENCY_BROKEN',
        'VIETQR_OPEN_REQUEST_GUARD_MISSING',
      ]) {
        expect(smoke, contains(token), reason: token);
      }
      expect(smoke, contains('\nrollback;'));
      expect(smoke, isNot(contains('\ncommit;')));
    });
  });
}

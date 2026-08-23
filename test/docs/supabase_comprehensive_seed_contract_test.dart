import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _configPath = 'docs/supabase/config.sql';
const _seedPath = 'docs/supabase/05_seed_local_sandbox.sql';
const _smokeFixturePath =
    'test/docs/fixtures/supabase_comprehensive_seed_smoke.sql';
const _seedName = '05_seed_local_sandbox.sql';
const _fixtureMarker = 'dev-sandbox-comprehensive-v1';

const _schemaOnlyTables = {
  'food_restrictions',
  'health_symptoms',
  'lab_results',
  'meal_schedule_preferences',
  'medication_records',
  'nutrition_goals',
  'nutrition_preference_rules',
  'nutrition_profiles',
  'schedule_health_checkins',
};

const _legacyAccounts = <_LegacyAccount>[
  _LegacyAccount(
    id: '10000000-0000-4000-8000-000000000101',
    email: 'dev.free@nanobio.local',
  ),
  _LegacyAccount(
    id: '10000000-0000-4000-8000-000000000102',
    email: 'dev.plus@nanobio.local',
  ),
  _LegacyAccount(
    id: '10000000-0000-4000-8000-000000000103',
    email: 'dev.family@nanobio.local',
  ),
  _LegacyAccount(
    id: '10000000-0000-4000-8000-000000000104',
    email: 'dev.admin@nanobio.local',
  ),
];

void main() {
  group('Supabase comprehensive local/sandbox seed', () {
    late String config;
    late String seed;

    setUpAll(() {
      config = File(_configPath).readAsStringSync();
      seed = File(_seedPath).readAsStringSync();
    });

    test(
      'mirrors numbered seed exactly once before runtime support',
      () {
        final block = _markedBlock(config, _seedName);

        expect(block.beginMatches, hasLength(1));
        expect(block.endMatches, hasLength(1));
        expect(
          _normaliseSql(block.body),
          _normaliseSql(seed),
          reason:
              'The authoritative seed and the config.sql rebuild copy must stay '
              'byte-equivalent apart from line endings/trailing whitespace.',
        );

        final runtimeStart = config.indexOf(
          '-- BEGIN 06_schema_runtime_support.sql',
        );
        expect(runtimeStart, greaterThanOrEqualTo(0));
        expect(
          block.end.end,
          lessThan(runtimeStart),
          reason: 'The numbered seed must run before runtime support.',
        );
      },
    );

    test(
      'tracks seeded and intentionally schema-only public tables',
      () {
        final publicTables = _publicTableNames(config);
        expect(publicTables, hasLength(73));

        final missingTables =
            publicTables
                .where((table) => !_hasFixtureEvidence(seed, table))
                .toSet();
        expect(
          missingTables,
          equals(_schemaOnlyTables),
          reason:
              'New schema-only tables must be classified explicitly until the '
              'local fixture intentionally covers them.',
        );

        for (final table in ['auth.users', 'auth.identities']) {
          expect(
            RegExp(
              '\\binsert\\s+into\\s+${RegExp.escape(table)}\\b',
              caseSensitive: false,
            ).hasMatch(seed),
            isTrue,
            reason: table,
          );
        }
        expect(seed, contains(_fixtureMarker));
        expect(seed, contains('dev.fixture.'));
        expect(seed, contains('Asia/Ho_Chi_Minh'));
      },
    );

    test('preserves the four stable account UUID/email bindings', () {
      for (final account in _legacyAccounts) {
        expect(
          _containsLegacySeedTuple(config, account),
          isTrue,
          reason: 'config.sql: ${account.email}',
        );
        expect(
          _containsLegacySeedTuple(seed, account),
          isTrue,
          reason: 'numbered seed: ${account.email}',
        );
      }
    });

    test('keeps the account matrix inside the authoritative numbered seed', () {
      final configuredEmails = _devAccountEmails(seed);

      expect(
        configuredEmails,
        containsAll(_legacyAccounts.map((e) => e.email)),
      );
      expect(
        configuredEmails.any((email) => email.startsWith('dev.fixture.')),
        isTrue,
      );
      final normalizedSeed = seed.toLowerCase();
      expect(seed, contains('NanoBio@123456'));
      expect(normalizedSeed, contains('local'));
      expect(normalizedSeed, contains('sandbox'));
      expect(normalizedSeed, contains('production'));
      expect(
        RegExp(
          r'(không|khong|not).{0,40}production',
          dotAll: true,
        ).hasMatch(normalizedSeed),
        isTrue,
        reason: 'The numbered seed must prohibit production use.',
      );
      for (final token in ['free', 'plus', 'sale', 'admin', 'family']) {
        expect(normalizedSeed, contains(token), reason: token);
      }
      expect(normalizedSeed, contains('family_plus'));
    });

    test('keeps fixture rollout defaults explicit in the numbered seed', () {
      for (final token in [
        'wellness_rewards_rollout',
        'sale_point_conversion',
        'nabi_companion_notifications_rollout',
        '"enabled": false',
        'M30 rollout remains disabled until sandbox and device acceptance pass.',
      ]) {
        expect(seed, contains(token), reason: token);
      }
    });

    test(
      'keeps both proof buckets private and policy-bound in the rebuild',
      () {
        for (final bucket in [
          'schedule-completion-proofs',
          'sale-payout-proofs',
        ]) {
          expect(config, contains("'$bucket'"), reason: bucket);
          expect(
            config,
            contains("bucket_id = '$bucket'"),
            reason: 'Storage policy for $bucket',
          );
        }
        expect(config, contains('insert into storage.buckets'));
      },
    );

    test(
      'documents the comprehensive seed and supplies a rollback-only smoke fixture',
      () {
        final readme = File('docs/supabase/README.md').readAsStringSync();
        final smoke = File(_smokeFixturePath).readAsStringSync();

        for (final token in [
          '05_seed_local_sandbox.sql',
          'config.sql',
          'Sandbox runtime (thực thi 01 → 06 rồi 90 → 94): `UNVERIFIED`',
        ]) {
          expect(readme, contains(token), reason: token);
        }

        for (final table in _publicTableNames(config).where(
          (table) => !_schemaOnlyTables.contains(table),
        )) {
          expect(smoke, contains("'$table'"), reason: table);
        }

        for (final token in [
          'begin;',
          'rollback;',
          'COMPREHENSIVE_SEED_TABLE_EMPTY',
          'COMPREHENSIVE_SEED_QUOTA_RETRY_FAILED',
          'COMPREHENSIVE_SEED_FAMILY_RLS_LEAK',
          'COMPREHENSIVE_SEED_DIRECT_ONLY_VIOLATION',
          'COMPREHENSIVE_SEED_STORAGE_OBJECT_MISSING',
        ]) {
          expect(smoke, contains(token), reason: token);
        }
        expect(
          smoke.toLowerCase(),
          isNot(contains('commit;')),
          reason: 'Smoke assertions must never persist rows or state.',
        );
      },
    );
  });
}

class _LegacyAccount {
  const _LegacyAccount({required this.id, required this.email});

  final String id;
  final String email;
}

class _MarkedBlock {
  const _MarkedBlock({
    required this.beginMatches,
    required this.endMatches,
    required this.begin,
    required this.end,
    required this.body,
  });

  final List<RegExpMatch> beginMatches;
  final List<RegExpMatch> endMatches;
  final RegExpMatch begin;
  final RegExpMatch end;
  final String body;
}

_MarkedBlock _markedBlock(String source, String moduleName) {
  final escaped = RegExp.escape(moduleName);
  final beginPattern = RegExp(
    '^\\s*--\\s*BEGIN\\s+$escaped\\s*\$',
    multiLine: true,
  );
  final endPattern = RegExp(
    '^\\s*--\\s*END\\s+$escaped\\s*\$',
    multiLine: true,
  );
  final begins = beginPattern.allMatches(source).toList();
  final ends = endPattern.allMatches(source).toList();
  if (begins.length != 1 || ends.length != 1) {
    throw StateError(
      'Expected one BEGIN/END marker pair for $moduleName; found '
      '${begins.length}/${ends.length}.',
    );
  }
  final begin = begins.single;
  final end = ends.single;
  if (end.start < begin.end) {
    throw StateError('END marker appears before BEGIN marker for $moduleName.');
  }
  return _MarkedBlock(
    beginMatches: begins,
    endMatches: ends,
    begin: begin,
    end: end,
    body: source.substring(begin.end, end.start),
  );
}

String _normaliseSql(String source) {
  final unix = source
      .replaceFirst('\uFEFF', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  return unix
      .split('\n')
      .map((line) => line.replaceFirst(RegExp(r'[ \t]+$'), ''))
      .join('\n')
      .trim();
}

List<String> _publicTableNames(String config) {
  final tables =
      RegExp(
          r'^\s*create\s+table\s+if\s+not\s+exists\s+public\.([a-z_][a-z0-9_]*)\s*\(',
          multiLine: true,
          caseSensitive: false,
        ).allMatches(config).map((match) => match.group(1)!.toLowerCase()).toSet()
        ..removeWhere((name) => name.isEmpty);
  return tables.toList();
}

bool _hasFixtureEvidence(String module, String table) {
  final tableName = RegExp.escape(table);
  final explicitInsert = RegExp(
    '\\binsert\\s+into\\s+public\\.$tableName\\b',
    caseSensitive: false,
  );
  final indirectManifest = RegExp(
    '^\\s*--\\s*fixture-table\\s*:\\s*$tableName\\s*\$',
    multiLine: true,
    caseSensitive: false,
  );
  return explicitInsert.hasMatch(module) || indirectManifest.hasMatch(module);
}

bool _containsLegacySeedTuple(String source, _LegacyAccount account) {
  final id = RegExp.escape(account.id);
  final email = RegExp.escape(account.email);
  return RegExp(
    "'$id'\\s*::\\s*uuid\\s*,\\s*'[^']+'\\s*::\\s*uuid\\s*,"
    "\\s*'[^']+'\\s*::\\s*uuid\\s*,\\s*'$email'",
    caseSensitive: false,
    dotAll: true,
  ).hasMatch(source);
}

List<String> _devAccountEmails(String source) {
  final emails =
      RegExp(
            r'\bdev(?:\.fixture)?[a-z0-9._-]*@nanobio\.local\b',
            caseSensitive: false,
          )
          .allMatches(source)
          .map((match) => match.group(0)!.toLowerCase())
          .toSet()
        ..removeWhere((email) => email.isEmpty);
  return emails.toList()..sort();
}

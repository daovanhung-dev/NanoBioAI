import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _configPath = 'docs/supabase/config.sql';
const _modulePath = 'docs/supabase/19-dev-sandbox-comprehensive-seed.sql';
const _accountsPath = 'docs/supabase/19-dev-sandbox-accounts.md';
const _demoProfilePath = 'docs/supabase/20-dev-sandbox-demo-profile.sql';
const _smokeFixturePath =
    'test/docs/fixtures/supabase_comprehensive_seed_smoke.sql';
const _moduleName = '19-dev-sandbox-comprehensive-seed.sql';
const _fixtureMarker = 'dev-sandbox-comprehensive-v1';

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
    late String module;

    setUpAll(() {
      config = File(_configPath).readAsStringSync();
      module = File(_modulePath).readAsStringSync();
    });

    test(
      'mirrors module 19 exactly once immediately before the final commit',
      () {
        final block = _markedBlock(config, _moduleName);

        expect(block.beginMatches, hasLength(1));
        expect(block.endMatches, hasLength(1));
        expect(
          _normaliseSql(block.body),
          _normaliseSql(module),
          reason:
              'The canonical module and the config.sql rebuild copy must stay '
              'byte-equivalent apart from line endings/trailing whitespace.',
        );

        final commits = RegExp(
          r'^\s*commit\s*;\s*$',
          multiLine: true,
          caseSensitive: false,
        ).allMatches(config).toList();
        expect(commits, isNotEmpty);
        expect(
          block.end.end,
          lessThan(commits.last.start),
          reason: 'Module 19 must run before config.sql commits the rebuild.',
        );
      },
    );

    test(
      'covers every public table plus Auth through explicit fixture evidence',
      () {
        final publicTables = _publicTableNames(config);
        expect(
          publicTables,
          hasLength(64),
          reason:
              'The comprehensive fixture is the coverage contract for all '
              'public tables in the rebuild schema.',
        );

        final missingTables =
            publicTables
                .where((table) => !_hasFixtureEvidence(module, table))
                .toList()
              ..sort();
        expect(
          missingTables,
          isEmpty,
          reason:
              'Use INSERT INTO public.<table> or a -- fixture-table: <table> '
              'manifest entry for rows that are created indirectly.',
        );

        for (final table in ['auth.users', 'auth.identities']) {
          expect(
            RegExp(
              '\\binsert\\s+into\\s+${RegExp.escape(table)}\\b',
              caseSensitive: false,
            ).hasMatch(module),
            isTrue,
            reason: table,
          );
        }
        expect(module, contains(_fixtureMarker));
        expect(module, contains('dev.fixture.'));
        expect(module, contains('Asia/Ho_Chi_Minh'));
      },
    );

    test('preserves the four legacy account UUID/email bindings', () {
      final legacySeed = File(
        'docs/supabase/09-dev-seed-membership-test-accounts.sql',
      ).readAsStringSync();

      for (final account in _legacyAccounts) {
        expect(
          _containsLegacySeedTuple(config, account),
          isTrue,
          reason: 'config.sql: ${account.email}',
        );
        expect(
          _containsLegacySeedTuple(legacySeed, account),
          isTrue,
          reason: 'legacy seed: ${account.email}',
        );
      }
    });

    test('keeps the account matrix synchronized with configured dev users', () {
      final accounts = File(_accountsPath).readAsStringSync();
      final configuredEmails = _devAccountEmails(config);

      expect(
        configuredEmails,
        containsAll(_legacyAccounts.map((e) => e.email)),
      );
      expect(
        configuredEmails.any((email) => email.startsWith('dev.fixture.')),
        isTrue,
      );
      for (final email in configuredEmails) {
        expect(accounts, contains(email), reason: email);
      }

      final normalizedAccounts = accounts.toLowerCase();
      expect(accounts, contains('NanoBio@123456'));
      expect(normalizedAccounts, contains('local'));
      expect(normalizedAccounts, contains('sandbox'));
      expect(normalizedAccounts, contains('production'));
      expect(
        RegExp(
          r'(không|khong|not).{0,40}production',
          dotAll: true,
        ).hasMatch(normalizedAccounts),
        isTrue,
        reason: 'The account document must prohibit production use.',
      );
      for (final token in ['free', 'plus', 'sale', 'admin', 'family']) {
        expect(normalizedAccounts, contains(token), reason: token);
      }
      expect(RegExp(r'family\s*plus').hasMatch(normalizedAccounts), isTrue);
    });

    test('keeps the opt-in demo profile separate from the base rebuild', () {
      final profile = File(_demoProfilePath).readAsStringSync();

      for (final token in [
        'begin;',
        'commit;',
        'wellness_rewards_rollout',
        'sale_point_conversion',
        'nabi_companion_notifications_rollout',
      ]) {
        expect(profile, contains(token), reason: token);
      }
      expect(profile.toLowerCase(), contains('local'));
      expect(profile.toLowerCase(), contains('sandbox'));
      expect(
        config,
        isNot(contains('-- BEGIN 20-dev-sandbox-demo-profile.sql')),
        reason: 'The base rebuild must retain its rollout-default state.',
      );
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
        final acceptance = File(
          'docs/supabase/08-acceptance-checks.md',
        ).readAsStringSync();
        final smoke = File(_smokeFixturePath).readAsStringSync();

        for (final token in [
          '19-dev-sandbox-comprehensive-seed.sql',
          '19-dev-sandbox-accounts.md',
          '20-dev-sandbox-demo-profile.sql',
        ]) {
          expect(readme, contains(token), reason: token);
        }
        expect(acceptance, contains('supabase_comprehensive_seed_smoke.sql'));

        for (final table in _publicTableNames(config)) {
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

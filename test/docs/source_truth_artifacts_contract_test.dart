import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes the source-truth entrypoint, audit, and manifest contract', () {
    final docsReadme = File('docs/README.md').readAsStringSync();
    final audit = File(
      'docs/audit/SOURCE_TRUTH_AUDIT.md',
    ).readAsStringSync();
    final manifest = jsonDecode(
      File('docs/audit/source_truth_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    for (final token in [
      'Code reachable từ `lib/main.dart`',
      '`Source-only`',
      '`Runtime-unverified`',
      '`Sandbox-unverified`',
      'docs/supabase/config.sql',
    ]) {
      expect(docsReadme, contains(token), reason: token);
    }
    for (final token in [
      '100% static traceability',
      '`Runtime-unverified`',
      '`Sandbox-unverified`',
      'SQL `01`–`06`',
    ]) {
      expect(audit, contains(token), reason: token);
    }

    expect(manifest['schema_version'], 1);
    expect(
      manifest['baseline_commit'],
      matches(RegExp(r'^[0-9a-f]{40}$')),
    );

    const lifecycleStates = {
      'Current',
      'Historical',
      'Generated',
      'Reference',
      'Source',
      'Binary',
    };
    const implementationStates = {
      'Implemented',
      'Partial',
      'Placeholder',
      'Source-only',
      'Absent',
      'N/A',
    };
    const verificationStates = {
      'Static-verified',
      'Runtime-unverified',
      'Sandbox-unverified',
      'Historical',
    };
    final records = (manifest['records'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(records, isNotEmpty);
    for (final record in records) {
      expect(lifecycleStates, contains(record['lifecycle']));
      expect(implementationStates, contains(record['implementation']));
      expect(verificationStates, contains(record['verification']));
    }
  });

  test('keeps one entrypoint and the documented core constants', () {
    final entrypoints = Directory('lib')
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.path.replaceAll('\\', '/'))
        .where((path) => RegExp(r'^lib/main(?:_[^/]*)?\.dart$').hasMatch(path))
        .toList()
      ..sort();
    expect(entrypoints, ['lib/main.dart']);

    final databaseVersion = File(
      'lib/core/storage/localdb/database_version.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/app_versions/v1/features/onboarding/presentation/constants/'
      'onboarding_constants.dart',
    ).readAsStringSync();
    final router = File(
      'lib/app_versions/v2/router/v2_router.dart',
    ).readAsStringSync();

    expect(databaseVersion, contains('currentVersion = 20'));
    expect(onboarding, contains('totalSteps = 9'));
    for (final token in ['...v1Routes', '...v2Routes', '...v3Routes']) {
      expect(router, contains(token), reason: token);
    }
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agent SQLite version snapshots match runtime source', () async {
    final runtime = await File(
      'lib/core/storage/localdb/database_version.dart',
    ).readAsString();
    final match = RegExp(r'currentVersion\s*=\s*(\d+)').firstMatch(runtime);
    expect(match, isNotNull);
    final version = match!.group(1)!;

    for (final path in const [
      '.codex/AGENTS.md',
      '.codex/README.md',
      '.codex/domains/sqlite.md',
    ]) {
      final content = await File(path).readAsString();
      expect(
        content,
        contains('DatabaseVersion.currentVersion = $version'),
        reason: '$path must track the runtime database version',
      );
    }
  });
}

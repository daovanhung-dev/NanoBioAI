import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime launcher validates and forwards auth plus AI config', () {
    final script = File('tools/run_v2.ps1').readAsStringSync();

    expect(script, contains('SUPABASE_URL'));
    expect(script, contains('SUPABASE_ANON_KEY'));
    expect(script, contains('AUTH_EMAIL_REDIRECT_URL'));
    expect(script, contains('GEMINI_API_KEY'));
    expect(script, contains('Get-DartDefineArguments'));
    expect(script, contains(r'--dart-define=$key='));
    expect(script, contains(r'Settings[$key]'));
    expect(script, isNot(contains('--dart-define-from-file=')));
    expect(script, contains('lib/main.dart'));
    expect(script, isNot(contains('assets/.env')));
  });

  test('VS Code entrypoints prepare and forward runtime defines', () {
    final launch =
        jsonDecode(File('.vscode/launch.json').readAsStringSync())
            as Map<String, dynamic>;
    final configurations = launch['configurations'] as List<dynamic>;
    const entrypoints = [
      'lib/main.dart',
      'lib/main_v2.dart',
      'lib/main_admin.dart',
    ];

    for (final entrypoint in entrypoints) {
      final matches = configurations
          .whereType<Map<String, dynamic>>()
          .where((config) => config['program'] == entrypoint)
          .toList(growable: false);

      expect(matches, hasLength(1), reason: entrypoint);
      final config = matches.single;

      expect(config['templateFor'], entrypoint, reason: entrypoint);
      expect(
        config['preLaunchTask'],
        'NanoBio: prepare runtime defines',
        reason: entrypoint,
      );
      expect(
        config['toolArgs'],
        contains('--dart-define-from-file=.dart_tool/nanobio_defines.json'),
        reason: entrypoint,
      );
    }
  });
}

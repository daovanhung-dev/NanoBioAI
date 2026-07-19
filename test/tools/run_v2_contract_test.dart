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
    expect(script, contains('prepare_dart_defines.ps1'));
    expect(script, contains('--dart-define-from-file='));
    expect(script, isNot(contains(r'--dart-define=$key=')));
    expect(script, contains('lib/main.dart'));
    expect(script, isNot(contains('assets/.env')));
  });

  test('VS Code entrypoints prepare and forward runtime defines', () {
    final launch =
        jsonDecode(File('.vscode/launch.json').readAsStringSync())
            as Map<String, dynamic>;
    final configurations = launch['configurations'] as List<dynamic>;
    const entrypoints = ['lib/main.dart'];

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

  test('shared Android Studio profile forwards runtime defines', () {
    final profile = File(
      '.run/NanoBio__Authenticated_App.xml',
    ).readAsStringSync();

    expect(profile, contains('FlutterRunConfigurationType'));
    expect(profile, contains('lib/main.dart'));
    expect(
      profile,
      contains('--dart-define-from-file=.dart_tool/nanobio_defines.json'),
    );
  });

  test('Android debug runs have a local Gemini config fallback', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('rootProject.file("../.env")'));
    expect(gradle, contains('getByName("debug")'));
    expect(gradle, contains('GEMINI_API_KEY'));
    expect(activity, contains('com.example.nano_app/runtime_config'));
    expect(activity, contains('getPrivateRuntimeConfig'));
    expect(activity, contains('BuildConfig.GEMINI_API_KEY'));
  });
}

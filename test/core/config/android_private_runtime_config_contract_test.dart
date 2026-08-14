import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android private runtime config contract', () {
    test('injects Gemini fallback for every Android build type', () {
      final gradleFile = File('android/app/build.gradle.kts');
      expect(gradleFile.existsSync(), isTrue);

      final source = gradleFile.readAsStringSync();

      expect(source, contains('val nativeGeminiApiKey ='));
      expect(
        source,
        contains('providers.gradleProperty("GEMINI_API_KEY")'),
      );
      expect(
        source,
        contains('providers.environmentVariable("GEMINI_API_KEY")'),
      );
      expect(source, contains('localEnvironment["GEMINI_API_KEY"]'));
      expect(source, contains('buildConfigString(nativeGeminiApiKey)'));

      // Regression guard: Gemini fallback must not be scoped to debug only.
      expect(source, isNot(contains('debugGeminiApiKey')));
    });

    test('local dotenv parser accepts export and quoted values', () {
      final source = File('android/app/build.gradle.kts').readAsStringSync();

      expect(source, contains('line.startsWith("export ", ignoreCase = true)'));
      expect(source, contains('rawLine.removePrefix("\\uFEFF")'));
      expect(source, contains('cleanRuntimeValue'));
    });

    test('MainActivity exposes only the private Gemini runtime key', () {
      final activity = File(
        'android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt',
      ).readAsStringSync();

      expect(activity, contains('getPrivateRuntimeConfig'));
      expect(activity, contains('BuildConfig.GEMINI_API_KEY'));
      expect(activity, contains('values["GEMINI_API_KEY"]'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android runtime config contract', () {
    test(
      'does not package a provider credential in any Android build type',
      () {
        final gradleFile = File('android/app/build.gradle.kts');
        expect(gradleFile.existsSync(), isTrue);

        final source = gradleFile.readAsStringSync();

        expect(source, isNot(contains('GEMINI_API_KEY')));
        expect(source, isNot(contains('buildConfigField')));
      },
    );

    test('local dotenv parser accepts export and quoted values', () {
      final source = File('android/app/build.gradle.kts').readAsStringSync();

      expect(source, isNot(contains('GEMINI_API_KEY')));
    });

    test('MainActivity exposes no provider runtime channel', () {
      final activity = File(
        'android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt',
      ).readAsStringSync();

      expect(activity, isNot(contains('getPrivateRuntimeConfig')));
      expect(activity, isNot(contains('GEMINI_API_KEY')));
    });
  });
}

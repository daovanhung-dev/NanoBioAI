import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nabi Kinetic Aura architecture contract', () {
    test('platform feedback APIs remain isolated behind core adapters', () {
      final violations = <String>[];
      for (final file in _dartFiles('lib')) {
        final normalized = file.path.replaceAll('\\', '/');
        final source = file.readAsStringSync();
        if (source.contains('HapticFeedback.') &&
            !normalized.endsWith(
              'lib/core/feedback/app_haptic_adapter.dart',
            )) {
          violations.add('$normalized calls HapticFeedback directly');
        }
        if (source.contains('SystemSound.play') &&
            !normalized.endsWith(
              'lib/core/feedback/app_sound_adapter.dart',
            )) {
          violations.add('$normalized calls SystemSound directly');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Presentation must emit semantic feedback through AppFeedbackService.',
      );
    });

    test('the app theme installs one cross-platform page transition system', () {
      final source = File('lib/core/theme/app_theme.dart').readAsStringSync();

      expect(source, contains('AppPageTransitionsBuilder'));
      expect(source, contains('pageTransitionsTheme'));
      for (final platform in <String>[
        'android',
        'iOS',
        'macOS',
        'windows',
        'linux',
        'fuchsia',
      ]) {
        expect(
          source,
          contains('TargetPlatform.$platform: AppPageTransitionsBuilder()'),
        );
      }
    });

    test('experience preferences expose accessibility and feedback controls', () {
      final preferences = File(
        'lib/core/theme/app_experience_preferences.dart',
      ).readAsStringSync();
      final settings = File(
        'lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart',
      ).readAsStringSync();

      expect(preferences, contains('reduceMotion'));
      expect(preferences, contains('hapticsEnabled'));
      expect(preferences, contains('soundLevel'));
      expect(preferences, contains('performanceTier'));
      expect(settings, contains('Giảm chuyển động'));
      expect(settings, contains('Phản hồi rung'));
      expect(settings, contains('Âm thanh tương tác'));
    });

    test('membership plan selector has a single constructor declaration', () {
      final source = File(
        'lib/app_versions/v2/features/payments/presentation/pages/'
        'membership_payment_page.dart',
      ).readAsStringSync();

      expect(
        RegExp(r'const\s+_PlanSelector\s*\(').allMatches(source),
        hasLength(1),
      );
    });
  });
}

Iterable<File> _dartFiles(String root) sync* {
  final directory = Directory(root);
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Version boundaries', () {
    test('core does not import app version code', () {
      final violations = _dartFiles('lib/core')
          .where(
            (file) =>
                _read(file).contains('app_versions/v1') ||
                _read(file).contains('app_versions/v2') ||
                _read(file).contains('app_versions/v3') ||
                _read(file).contains('sale_referral'),
          )
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'core must stay shared and cannot depend on app versions or sale modules',
      );
    });

    test('v1 does not import later version or sale code', () {
      final violations = _dartFiles('lib/app_versions/v1')
          .where(
            (file) =>
                _read(file).contains('app_versions/v2') ||
                _read(file).contains('app_versions/v3') ||
                _read(file).contains('sale_referral'),
          )
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'v1 is the guest/basic baseline and must not depend on later layers',
      );
    });

    test('v2 features do not import v1 presentation or controllers', () {
      final forbiddenPatterns = [
        RegExp(r'app_versions/v1/features/.*/presentation/'),
        RegExp(r'app_versions/v1/features/.*/controllers/'),
      ];

      final violations = _dartFiles('lib/app_versions/v2/features')
          .where(
            (file) => forbiddenPatterns.any(
              (pattern) => pattern.hasMatch(_read(file)),
            ),
          )
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'v2 feature data should go through shared repositories/services, not v1 UI/controllers',
      );
    });

    test('v2 features do not import v3 or sale modules', () {
      final violations = _dartFiles('lib/app_versions/v2/features')
          .where(
            (file) =>
                _read(file).contains('app_versions/v3') ||
                _read(file).contains('sale_referral'),
          )
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'v2 is the authenticated Free layer and must not depend on v3 or Sale',
      );
    });

    test(
      'v3 features do not import lower-version presentation or controllers',
      () {
        final forbiddenPatterns = [
          RegExp(r'app_versions/v1/features/.*/presentation/'),
          RegExp(r'app_versions/v1/features/.*/controllers/'),
          RegExp(r'app_versions/v2/features/.*/presentation/'),
          RegExp(r'app_versions/v2/features/.*/controllers/'),
        ];

        final violations = _dartFiles('lib/app_versions/v3/features')
            .where(
              (file) => forbiddenPatterns.any(
                (pattern) => pattern.hasMatch(_read(file)),
              ),
            )
            .map((file) => file.path)
            .toList();

        expect(
          violations,
          isEmpty,
          reason:
              'v3 features may inherit contracts but must not depend on lower-version UI/controllers',
        );
      },
    );

    test('sale referral stays independent from app version code', () {
      final violations = _dartFiles('lib/sale_referral')
          .where((file) => _read(file).contains('app_versions/'))
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'Sale/referral is an independent product axis, not a v1/v2/v3 layer',
      );
    });

    test('entrypoints select the expected app version', () {
      final mainV1 = _read(File('lib/main.dart'));
      final mainV2 = _read(File('lib/main_v2.dart'));

      expect(mainV1.contains('BioAIV2App'), isTrue);
      expect(mainV1.contains('BioAIV1App'), isFalse);
      expect(mainV2.contains('BioAIV2App'), isTrue);
    });
  });
}

List<File> _dartFiles(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) return [];

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

String _read(File file) => file.readAsStringSync();

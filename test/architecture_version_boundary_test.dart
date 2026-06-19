import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Version boundaries', () {
    test('core does not import app version code', () {
      final violations = _dartFiles('lib/core')
          .where(
            (file) =>
                _read(file).contains('app_versions/v1') ||
                _read(file).contains('app_versions/v2'),
          )
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason: 'core must stay shared and cannot depend on v1 or v2',
      );
    });

    test('v1 does not import v2 code', () {
      final violations = _dartFiles('lib/app_versions/v1')
          .where((file) => _read(file).contains('app_versions/v2'))
          .map((file) => file.path)
          .toList();

      expect(
        violations,
        isEmpty,
        reason: 'v1 is the stable baseline and must not depend on v2',
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

    test('entrypoints select the expected app version', () {
      final mainV1 = _read(File('lib/main.dart'));
      final mainV2 = _read(File('lib/main_v2.dart'));

      expect(mainV1.contains('BioAIV1App'), isTrue);
      expect(mainV1.contains('BioAIV2App'), isFalse);
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

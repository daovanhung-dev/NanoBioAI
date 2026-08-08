import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Roboto 400-700 is bundled with deterministic files and license', () {
    const expected = <String, String>{
      '400': 'b9c9dc635f41fa6205f93468a13c4241bed19f87d06f131b90935365e94e1bc6',
      '500': '91c41ee1669769db70b6c2fbb91ab10505c9ee7c59a331c2f0466d62eb77083b',
      '600': '26492d402f622c15e8211aa20f214a4d6b15fb9765402e861c36f1e7eb7ba3a9',
      '700': '4a37dcee2d10237786f862cdb44d573c58debdf1ce23dba82c26e6d5781ed0c1',
    };
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final entry in expected.entries) {
      final path = 'assets/fonts/roboto/Roboto-${entry.key}.ttf';
      final file = File(path);
      expect(pubspec, contains('- asset: $path'));
      expect(pubspec, contains('weight: ${entry.key}'));
      expect(file.existsSync(), isTrue, reason: '$path must be bundled.');
      expect(sha256.convert(file.readAsBytesSync()).toString(), entry.value);
    }

    final license = File('assets/fonts/roboto/OFL.txt').readAsStringSync();
    expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });
}

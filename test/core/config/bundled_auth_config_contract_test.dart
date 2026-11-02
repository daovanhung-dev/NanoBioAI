import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled auth config contains only public client settings', () {
    final file = File('assets/config/auth.env');
    expect(file.existsSync(), isTrue);

    final settings = <String, String>{};
    for (final line
        in file
            .readAsLinesSync()
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty && !line.startsWith('#'))) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      settings[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }

    expect(settings.keys, equals({'API_BASE_URL'}));
    expect(settings.keys, isNot(contains('GEMINI_API_KEY')));
    final uri = Uri.parse(settings['API_BASE_URL']!);
    expect(uri.origin, 'https://nanobio.s2w.click');
    expect(uri.path, isEmpty);
  });
}

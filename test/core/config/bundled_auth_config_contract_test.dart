import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled auth config contains only public client settings', () {
    final file = File('assets/config/auth.env');
    expect(file.existsSync(), isTrue);

    final keys = file
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .map((line) => line.split('=').first.trim())
        .toSet();

    expect(keys, equals({'API_BASE_URL'}));
    expect(keys, isNot(contains('GEMINI_API_KEY')));
  });
}

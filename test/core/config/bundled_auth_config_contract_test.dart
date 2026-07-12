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

    expect(
      keys,
      equals({
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'AUTH_EMAIL_REDIRECT_URL',
        'AUTH_CONFIRM_EMAIL_REQUIRED',
      }),
    );
    expect(keys, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(keys, isNot(contains('GEMINI_API_KEY')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authenticated build helper validates and forwards auth config', () {
    final script = File('tools/build_authenticated.ps1').readAsStringSync();

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
}

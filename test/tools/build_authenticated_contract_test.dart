import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authenticated build helper validates and forwards backend config', () {
    final script = File('tools/build_authenticated.ps1').readAsStringSync();

    expect(script, contains('API_BASE_URL'));
    expect(script, isNot(contains('SUPABASE_')));
    expect(script, isNot(contains('GEMINI_API_KEY')));
    expect(script, contains('trusted backend'));
    expect(script, contains('prepare_dart_defines.ps1'));
    expect(script, contains('--dart-define-from-file='));
    expect(script, isNot(contains(r'--dart-define=$key=')));
    expect(script, contains('lib/main.dart'));
    expect(script, isNot(contains('assets/.env')));
  });
}

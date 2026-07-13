import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gemini preflight uses header auth and never prints the key', () {
    final script = File('tools/test_gemini_connection.ps1').readAsStringSync();

    expect(script, contains('GEMINI_API_KEY'));
    expect(script, contains('x-goog-api-key'));
    expect(script, contains(':generateContent'));
    expect(script, contains('GEMINI_MODEL'));
    expect(script, contains('Get-GeminiText'));
    expect(script, contains('maxOutputTokens = 512'));
    expect(script, isNot(contains(r'Write-Host $settings["GEMINI_API_KEY"]')));
  });
}

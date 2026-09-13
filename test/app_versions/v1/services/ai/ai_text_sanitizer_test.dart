import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_sanitizer.dart';

void main() {
  test('keeps Vietnamese text, punctuation, spaces and line breaks', () {
    expect(
      AITextSanitizer.sanitize(
        'Xin chào, bạn!\n\n\nHôm nay thế nào? 123 kcal.',
      ),
      'Xin chào, bạn!\n\nHôm nay thế nào? 123 kcal.',
    );
  });

  test('removes markdown, markup, emoji, control and special characters', () {
    expect(
      AITextSanitizer.sanitize('**<b>Xin chào</b>** 😊 & ^\u0000'),
      'Xin chào',
    );
  });
}

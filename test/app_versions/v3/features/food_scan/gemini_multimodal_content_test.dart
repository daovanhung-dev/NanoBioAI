import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  test('multimodal content keeps inline image and text parts', () {
    final content = GeminiContent.userWithInlineData(
      text: 'Phân tích món ăn',
      mimeType: 'image/jpeg',
      base64Data: 'YWJj',
    );

    final json = content.toJson();
    expect(json['role'], 'user');
    final parts = json['parts']! as List<Object?>;
    expect(parts, hasLength(2));
    expect(
      parts.first,
      {
        'inlineData': {'mimeType': 'image/jpeg', 'data': 'YWJj'},
      },
    );
    expect(parts.last, {'text': 'Phân tích món ăn'});
  });

  test('legacy text content remains text only', () {
    expect(GeminiContent.user('xin chào').toJson(), {
      'role': 'user',
      'parts': [
        {'text': 'xin chào'},
      ],
    });
  });
}

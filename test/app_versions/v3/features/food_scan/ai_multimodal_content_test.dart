import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';

void main() {
  test(
    'provider-neutral multimodal message keeps local image bytes and text',
    () {
      final message = AiMessage.user(
        'Phân tích món ăn',
        images: [
          AiImageAttachment(
            bytes: Uint8List.fromList([97, 98, 99]),
            mimeType: 'image/jpeg',
          ),
        ],
      );

      expect(message.role, AiMessageRole.user);
      expect(message.text, 'Phân tích món ăn');
      expect(message.images, hasLength(1));
      expect(message.images.single.mimeType, 'image/jpeg');
      expect(message.images.single.bytes, [97, 98, 99]);
    },
  );

  test('text-only message has no image attachment', () {
    final message = const AiMessage.user('xin chào');

    expect(message.role, AiMessageRole.user);
    expect(message.text, 'xin chào');
    expect(message.images, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/services/ai/ai_exceptions.dart';

void main() {
  group('AIOverloadedException', () {
    test('matches Gemini overload and capacity errors', () {
      expect(
        AIOverloadedException.matches(
          GenerativeAIException(
            'Server Error [503]: The model is overloaded. Try again later.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          ServerException(
            'Resource has been exhausted, check quota or rate limit.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          ServerException('Too many requests. Please retry later.'),
        ),
        isTrue,
      );
    });

    test('does not match unrelated validation errors', () {
      expect(
        AIOverloadedException.matches(
          const FormatException('AI response is not List'),
        ),
        isFalse,
      );
      expect(
        AIOverloadedException.matches(
          StateError('Expected 35 meal plan records, got 0'),
        ),
        isFalse,
      );
    });

    test('has user-facing Vietnamese message', () {
      expect(
        const AIOverloadedException().toString(),
        'AI bị quá tải. Bạn thử lại sau nhé.',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiExpressionResolver', () {
    test('form cần chú ý giữ đúng fallback context ở runtime', () {
      final presentation = NabiExpressionResolver.fromEvent(
        NabiEvent.formNeedsAttention,
        fallbackContext: NabiContext.onboarding,
      );

      expect(presentation.context, NabiContext.onboarding);
      expect(presentation.emotion, NabiEmotion.concerned);
    });
  });
}

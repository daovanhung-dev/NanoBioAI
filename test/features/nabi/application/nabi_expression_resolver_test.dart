import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/features/Nabi/application/Nabi_expression_resolver.dart';
import '../../../../lib/features/Nabi/domain/entities/Nabi_expression.dart';

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

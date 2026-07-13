import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

void main() {
  group('vietnameseSystemUiText', () {
    test('maps stable backend codes without exposing the code', () {
      expect(
        vietnameseSystemUiText('AUTH_REQUIRED'),
        'Vui lòng đăng nhập để tiếp tục.',
      );
    });

    test('replaces raw English and technical exceptions with safe copy', () {
      const fallback = 'Nabi đang bận. Bạn thử lại sau nhé.';

      expect(
        vietnameseSystemUiText(
          'Failed to query SQLite table: StateError',
          fallback: fallback,
        ),
        fallback,
      );
      expect(
        vietnameseSystemUiText('SOME_NEW_CODE', fallback: fallback),
        fallback,
      );
      expect(
        vietnameseSystemUiText(
          'Daily health reminder: take a walk today',
          fallback: fallback,
        ),
        fallback,
      );
    });

    test('replaces mojibake and unknown unaccented Vietnamese', () {
      const fallback = 'Nội dung chưa sẵn sàng.';

      expect(
        vietnameseSystemUiText(
          'Nabi chÆ°a thá»ƒ lÆ°u áº£nh.',
          fallback: fallback,
        ),
        fallback,
      );
      expect(
        vietnameseSystemUiText('Vui long thu lai sau.', fallback: fallback),
        fallback,
      );
    });

    test('keeps valid uppercase Vietnamese containing Â and Ã', () {
      expect(
        vietnameseSystemUiText('ĐÃ SẴN SÀNG CHĂM SÓC'),
        'ĐÃ SẴN SÀNG CHĂM SÓC',
      );
    });
  });
}

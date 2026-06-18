import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/foundation/motion.dart';

void main() {
  group('MotionFoundation', () {
    group('durations', () {
      test('fast duration should be 150ms', () {
        expect(MotionFoundation.fast, const Duration(milliseconds: 150));
      });

      test('normal duration should be 250ms', () {
        expect(MotionFoundation.normal, const Duration(milliseconds: 250));
      });

      test('slow duration should be 350ms', () {
        expect(MotionFoundation.slow, const Duration(milliseconds: 350));
      });
    });

    group('curves', () {
      test('easeIn curve should be Curves.easeIn', () {
        expect(MotionFoundation.easeIn, Curves.easeIn);
      });

      test('easeOut curve should be Curves.easeOut', () {
        expect(MotionFoundation.easeOut, Curves.easeOut);
      });

      test('easeInOut curve should be Curves.easeInOut', () {
        expect(MotionFoundation.easeInOut, Curves.easeInOut);
      });
    });

    group('requirement validation', () {
      test(
        'all duration values should match requirement 1.6 specification',
        () {
          // Requirement 1.6: fast: 150ms, normal: 250ms, slow: 350ms
          expect(MotionFoundation.fast.inMilliseconds, 150);
          expect(MotionFoundation.normal.inMilliseconds, 250);
          expect(MotionFoundation.slow.inMilliseconds, 350);
        },
      );

      test('all required curves should be defined', () {
        // Requirement 1.6: ease-in, ease-out, ease-in-out
        expect(MotionFoundation.easeIn, isNotNull);
        expect(MotionFoundation.easeOut, isNotNull);
        expect(MotionFoundation.easeInOut, isNotNull);
      });
    });
  });
}

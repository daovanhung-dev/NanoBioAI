import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/foundation/motion.dart';

void main() {
  group('MotionFoundation — Nabi Kinetic Aura', () {
    test('durations follow the canonical micro/component/spatial ladder', () {
      expect(MotionFoundation.press, const Duration(milliseconds: 90));
      expect(MotionFoundation.xFast, const Duration(milliseconds: 120));
      expect(MotionFoundation.fast, const Duration(milliseconds: 180));
      expect(MotionFoundation.normal, const Duration(milliseconds: 260));
      expect(MotionFoundation.emphasized, const Duration(milliseconds: 360));
      expect(MotionFoundation.slow, const Duration(milliseconds: 480));
      expect(MotionFoundation.xSlow, const Duration(milliseconds: 680));
    });

    test('durations increase monotonically', () {
      final values = <Duration>[
        MotionFoundation.press,
        MotionFoundation.xFast,
        MotionFoundation.fast,
        MotionFoundation.normal,
        MotionFoundation.emphasized,
        MotionFoundation.slow,
        MotionFoundation.xSlow,
      ];
      for (var index = 1; index < values.length; index++) {
        expect(values[index], greaterThan(values[index - 1]));
      }
    });

    test('canonical curves remain cubic and deterministic', () {
      expect(MotionFoundation.standard, isA<Cubic>());
      expect(MotionFoundation.emphasizedCurve, isA<Cubic>());
      expect(MotionFoundation.decelerate, isA<Cubic>());
      expect(MotionFoundation.accelerate, isA<Cubic>());
    });

    test('tactile scales are subtle and never exceed the resting scale', () {
      expect(MotionFoundation.buttonPressedScale, inInclusiveRange(.95, 1));
      expect(MotionFoundation.cardPressedScale, inInclusiveRange(.97, 1));
      expect(MotionFoundation.chipPressedScale, inInclusiveRange(.95, 1));
      expect(MotionFoundation.incomingPageScale, inInclusiveRange(.98, 1));
    });
  });
}

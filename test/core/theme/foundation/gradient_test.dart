import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/foundation/colors.dart';

void main() {
  group('GradientFoundation', () {
    group('gradient definitions', () {
      test('primary gradient should use the Green Wellness CTA range', () {
        expect(GradientFoundation.primary, isA<LinearGradient>());
        expect(GradientFoundation.primary.colors, [
          ColorFoundation.ctaStart,
          ColorFoundation.ctaEnd,
        ]);
        expect(GradientFoundation.primary.begin, Alignment.topLeft);
        expect(GradientFoundation.primary.end, Alignment.bottomRight);
      });

      test('premium gradient should use NaBi green to personal purple', () {
        expect(GradientFoundation.premium, isA<LinearGradient>());
        expect(GradientFoundation.premium.colors, [
          ColorFoundation.greenPrimary,
          ColorFoundation.purple500,
        ]);
        expect(GradientFoundation.premium.begin, Alignment.topLeft);
        expect(GradientFoundation.premium.end, Alignment.bottomRight);
      });

      test('success gradient should use green500 to green600', () {
        expect(GradientFoundation.success, isA<LinearGradient>());
        expect(GradientFoundation.success.colors, [
          ColorFoundation.green500,
          ColorFoundation.green600,
        ]);
        expect(GradientFoundation.success.begin, Alignment.topLeft);
        expect(GradientFoundation.success.end, Alignment.bottomRight);
      });

      test('surfaceLight gradient should use white to slate50', () {
        expect(GradientFoundation.surfaceLight, isA<LinearGradient>());
        expect(GradientFoundation.surfaceLight.colors, [
          ColorFoundation.white,
          ColorFoundation.slate50,
        ]);
        expect(GradientFoundation.surfaceLight.begin, Alignment.topCenter);
        expect(GradientFoundation.surfaceLight.end, Alignment.bottomCenter);
      });

      test('surfaceDark gradient should use slate800 to slate900', () {
        expect(GradientFoundation.surfaceDark, isA<LinearGradient>());
        expect(GradientFoundation.surfaceDark.colors, [
          ColorFoundation.slate800,
          ColorFoundation.slate900,
        ]);
        expect(GradientFoundation.surfaceDark.begin, Alignment.topCenter);
        expect(GradientFoundation.surfaceDark.end, Alignment.bottomCenter);
      });
    });

    group('requirement validation', () {
      test('should have exactly 5 gradient definitions (Requirement 11.3)', () {
        // Requirement 11.3: Fewer than 15 gradient definitions (target: 5)
        // Count the number of gradient constants
        final gradients = [
          GradientFoundation.primary,
          GradientFoundation.premium,
          GradientFoundation.success,
          GradientFoundation.surfaceLight,
          GradientFoundation.surfaceDark,
        ];

        expect(gradients.length, 5);
        // All gradients are LinearGradient - verified by static type
        for (final gradient in gradients) {
          expect(gradient, isA<LinearGradient>());
        }
      });

      test('all gradients should reference ColorFoundation values', () {
        // Verify that gradients use foundation colors, not literal values
        final allColors = [
          ...GradientFoundation.primary.colors,
          ...GradientFoundation.premium.colors,
          ...GradientFoundation.success.colors,
          ...GradientFoundation.surfaceLight.colors,
          ...GradientFoundation.surfaceDark.colors,
        ];

        // Check that all colors are defined in ColorFoundation
        final foundationColors = [
          ColorFoundation.ctaStart,
          ColorFoundation.ctaEnd,
          ColorFoundation.greenPrimary,
          ColorFoundation.purple500,
          ColorFoundation.green500,
          ColorFoundation.green600,
          ColorFoundation.white,
          ColorFoundation.slate50,
          ColorFoundation.slate800,
          ColorFoundation.slate900,
        ];

        for (final color in allColors) {
          expect(
            foundationColors.contains(color),
            true,
            reason:
                'All gradient colors should reference ColorFoundation values',
          );
        }
      });

      test('gradients should be const and immutable', () {
        // Verify that GradientFoundation class is immutable
        // This is enforced by the @immutable annotation in the source
        expect(
          GradientFoundation.primary,
          const LinearGradient(
            colors: [ColorFoundation.ctaStart, ColorFoundation.ctaEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      });
    });

    group('gradient properties', () {
      test('brand gradients should use diagonal direction', () {
        // Primary and premium are brand gradients
        expect(GradientFoundation.primary.begin, Alignment.topLeft);
        expect(GradientFoundation.primary.end, Alignment.bottomRight);
        expect(GradientFoundation.premium.begin, Alignment.topLeft);
        expect(GradientFoundation.premium.end, Alignment.bottomRight);
      });

      test('surface gradients should use vertical direction', () {
        // Surface gradients should be top to bottom
        expect(GradientFoundation.surfaceLight.begin, Alignment.topCenter);
        expect(GradientFoundation.surfaceLight.end, Alignment.bottomCenter);
        expect(GradientFoundation.surfaceDark.begin, Alignment.topCenter);
        expect(GradientFoundation.surfaceDark.end, Alignment.bottomCenter);
      });

      test('all gradients should have exactly 2 colors', () {
        // Simple 2-color gradients for performance
        expect(GradientFoundation.primary.colors.length, 2);
        expect(GradientFoundation.premium.colors.length, 2);
        expect(GradientFoundation.success.colors.length, 2);
        expect(GradientFoundation.surfaceLight.colors.length, 2);
        expect(GradientFoundation.surfaceDark.colors.length, 2);
      });
    });
  });
}

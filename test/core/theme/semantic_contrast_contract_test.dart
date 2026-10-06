import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_gradients.dart';
import 'package:nano_app/core/theme/app_semantic_colors.dart';

void main() {
  group('semantic contrast contract', () {
    test('Blue and Green frozen dark mappings keep brand content readable', () {
      final mappings = [
        (
          name: 'Blue',
          colors: AppSemanticColors.blueDark,
          hero: const [Color(0xFF1C478F), Color(0xFF285CC5)],
          brandAccent: const Color(0xFF16845C),
        ),
        (
          name: 'Green rollback',
          colors: AppSemanticColors.greenDark,
          hero: const [Color(0xFF075E45), Color(0xFF006A46)],
          brandAccent: const Color(0xFF14A36F),
        ),
      ];

      for (final mapping in mappings) {
        expect(
          mapping.colors.onBrand,
          const Color(0xFFFFFFFF),
          reason: '${mapping.name} fixed brand foreground must stay white.',
        );
        expect(mapping.colors.brandAccent, mapping.brandAccent);
        for (final background in mapping.hero) {
          expect(
            _contrast(mapping.colors.onBrand, background),
            greaterThanOrEqualTo(4.5),
            reason: '${mapping.name} hero endpoint must meet WCAG AA.',
          );
        }
        expect(
          _contrast(mapping.colors.primary, mapping.colors.textInverse),
          greaterThanOrEqualTo(4.5),
          reason: '${mapping.name} scheme primary pairing must stay valid.',
        );
      }
    });

    test('health accent and success remain readable in both themes', () {
      final green = AppSemanticColors.greenDark;
      final blue = AppSemanticColors.blueDark;

      expect(green.success, const Color(0xFF82D8AB));
      expect(blue.success, const Color(0xFF82D8AB));
      expect(blue.brandAccent, const Color(0xFF16845C));
      expect(
        _contrast(green.success, green.successSoft),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(blue.success, blue.successSoft),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('brand hero endpoints keep white content readable', () {
      for (final gradient in [AppGradients.hero, AppGradients.dashboard]) {
        for (final background in gradient.colors) {
          expect(
            _contrast(AppSemanticColors.dark.onBrand, background),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

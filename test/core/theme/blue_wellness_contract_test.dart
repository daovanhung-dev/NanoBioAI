import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_gradients.dart';
import 'package:nano_app/core/theme/app_radius.dart';
import 'package:nano_app/core/theme/app_semantic_colors.dart';
import 'package:nano_app/core/theme/app_spacing.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/primitives/chip.dart';
import 'package:nano_app/core/theme/primitives/states/loading_state.dart';

void main() {
  group('Nabi Blue Wellness tokens', () {
    test('canonical palette matches the approved design source', () {
      expect(AppColors.primary, const Color(0xFF2F6FED));
      expect(AppColors.primaryDark, const Color(0xFF1746A2));
      expect(AppColors.primaryLight, const Color(0xFF6EA8FE));
      expect(AppColors.primarySoft, const Color(0xFFE8F1FF));
      expect(AppColors.primarySubtle, const Color(0xFFF4F8FF));
      expect(AppColors.brandAccent, const Color(0xFF14A36F));
      expect(AppColors.secondary, const Color(0xFF14A36F));
      expect(AppColors.wellnessGreen, const Color(0xFF14A36F));
      expect(AppColors.background, const Color(0xFFF7FAFF));
      expect(AppColors.textPrimary, const Color(0xFF15253D));
      expect(AppColors.textSecondary, const Color(0xFF5B6B82));
      expect(AppColors.border, const Color(0xFFDCE6F4));
      expect(AppColors.focusRing, const Color(0xFF7DB2FF));
      expect(AppGradients.primary.colors, const [
        Color(0xFF245CC5),
        Color(0xFF4D8DF7),
      ]);
    });

    test('light and dark themes expose context-aware semantic colors', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;
      final lightSemantic = light.extension<AppSemanticColors>();
      final darkSemantic = dark.extension<AppSemanticColors>();

      expect(light.brightness, Brightness.light);
      expect(lightSemantic, isNotNull);
      expect(lightSemantic!.primary, AppColors.primary);
      expect(lightSemantic.brandAccent, AppColors.brandAccent);
      expect(lightSemantic.surfaceSoft, AppColors.primarySubtle);
      expect(dark.brightness, Brightness.dark);
      expect(darkSemantic, isNotNull);
      expect(darkSemantic!.primary, dark.colorScheme.primary);
      expect(darkSemantic.surface, dark.colorScheme.surface);
      expect(dark.scaffoldBackgroundColor, darkSemantic.background);
      expect(light.textTheme.bodyMedium!.fontFamily, 'Roboto');
      expect(dark.textTheme.bodyMedium!.fontFamily, 'Roboto');
    });

    test('dark scheme is a deterministic Material 3 fidelity snapshot', () {
      final expected = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F6FED),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      );
      final actual = AppTheme.darkTheme.colorScheme;

      expect(actual.primary, expected.primary);
      expect(actual.onPrimary, expected.onPrimary);
      expect(actual.primaryContainer, expected.primaryContainer);
      expect(actual.surface, expected.surface);
      expect(actual.onSurface, expected.onSurface);
      expect(
        _contrast(actual.primary, actual.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(actual.surface, actual.onSurface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('layout tokens meet the Blue Wellness geometry contract', () {
      expect(AppSpacing.pagePadding, 16);
      expect(AppSpacing.sectionSpacing, 24);
      expect(AppSpacing.touchTargetMin, 48);
      expect(AppRadius.input, 14);
      expect(AppRadius.card, 20);
      expect(AppRadius.bottomSheet, 28);
    });
  });

  testWidgets('selected chip exposes state and meets minimum touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AppChip(
            variant: ChipVariant.selectable,
            label: 'Uống đủ nước',
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AppChip));
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(
      tester.getSize(find.byType(AppChip)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('loading variants are real visual states, not placeholders', (
    tester,
  ) async {
    for (final variant in LoadingVariant.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingState(variant: variant, message: 'Đang chuẩn bị'),
        ),
      );
      expect(find.textContaining('placeholder'), findsNothing);
      expect(find.text('Đang chuẩn bị'), findsOneWidget);
    }
  });

  test(
    'feature UI does not reintroduce opaque raw colors or numeric radii',
    () {
      const roots = [
        'lib/app_versions/v1',
        'lib/app_versions/v2',
        'lib/app_versions/v3',
        'lib/features',
        'lib/shared',
        'lib/sale_referral',
      ];
      final violations = <String>[];
      final rawColor = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
      final numericRadius = RegExp(r'BorderRadius\.circular\([0-9]');

      for (final root in roots) {
        final directory = Directory(root);
        if (!directory.existsSync()) continue;
        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = entity.readAsStringSync();
          if (rawColor.hasMatch(source) || numericRadius.hasMatch(source)) {
            violations.add(entity.path);
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Feature UI must consume semantic Blue Wellness tokens.',
      );
    },
  );
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

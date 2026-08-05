import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_radius.dart';
import 'package:nano_app/core/theme/app_spacing.dart';
import 'package:nano_app/core/theme/primitives/chip.dart';
import 'package:nano_app/core/theme/primitives/states/loading_state.dart';

void main() {
  group('NaBi Green Wellness tokens', () {
    test('canonical palette matches the approved design source', () {
      expect(AppColors.primary, const Color(0xFF14A36F));
      expect(AppColors.primaryDark, const Color(0xFF075E45));
      expect(AppColors.primaryLight, const Color(0xFF42D392));
      expect(AppColors.primarySoft, const Color(0xFFDDF6E9));
      expect(AppColors.primarySubtle, const Color(0xFFEAF9F1));
      expect(AppColors.background, const Color(0xFFF6FBF8));
      expect(AppColors.textPrimary, const Color(0xFF12352A));
      expect(AppColors.textSecondary, const Color(0xFF60766E));
      expect(AppColors.border, const Color(0xFFD9E9E1));
      expect(AppColors.focusRing, const Color(0xFF68D9A5));
    });

    test('layout tokens meet the Green Wellness geometry contract', () {
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
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(tester.getSize(find.byType(AppChip)).height, greaterThanOrEqualTo(48));
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

  test('feature UI does not reintroduce opaque raw colors or numeric radii', () {
    const roots = [
      'lib/app_versions',
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
      reason: 'Feature UI must consume semantic Green Wellness tokens.',
    );
  });
}

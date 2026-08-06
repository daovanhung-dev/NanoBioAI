import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_radius.dart';
import 'package:nano_app/core/theme/app_spacing.dart';
import 'package:nano_app/core/theme/primitives/chip.dart';
import 'package:nano_app/core/theme/primitives/states/loading_state.dart';

void main() {
  group('NaBi Blue Wellness tokens', () {
    test('canonical palette matches the approved design source', () {
      expect(AppColors.primary, const Color(0xFF2F6FED));
      expect(AppColors.primaryDark, const Color(0xFF1746A2));
      expect(AppColors.primaryLight, const Color(0xFF6EA8FE));
      expect(AppColors.primarySoft, const Color(0xFFE8F1FF));
      expect(AppColors.primarySubtle, const Color(0xFFF4F8FF));
      expect(AppColors.background, const Color(0xFFF7FAFF));
      expect(AppColors.textPrimary, const Color(0xFF15253D));
      expect(AppColors.textSecondary, const Color(0xFF5B6B82));
      expect(AppColors.border, const Color(0xFFDCE6F4));
      expect(AppColors.focusRing, const Color(0xFF7DB2FF));
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
    expect(semantics.flagsCollection.isSelected.toBoolOrNull(), isTrue);
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
      reason: 'Feature UI must consume semantic Blue Wellness tokens.',
    );
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_gradients.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/tokens/color_tokens.dart';

void main() {
  test('release cutover is explicit while development defaults to Green', () {
    final source = File(
      'lib/core/theme/app_theme_flags.dart',
    ).readAsStringSync();
    expect(source, contains('defaultValue: !kReleaseMode'));
    expect(source, contains('STITCH_GREEN_UI_ENABLED=true'));
  });

  test('compile-time cutover selects one internally consistent palette', () {
    final expectedPrimary = AppTheme.stitchGreenUiEnabled
        ? const Color(0xFF006A46)
        : const Color(0xFF2F6FED);
    final expectedCtaStart = AppTheme.stitchGreenUiEnabled
        ? const Color(0xFF0F8E62)
        : const Color(0xFF245CC5);
    final expectedCtaEnd = AppTheme.stitchGreenUiEnabled
        ? const Color(0xFF32C789)
        : const Color(0xFF4D8DF7);

    expect(AppColors.primary, expectedPrimary);
    expect(AppColorTokens.primary, expectedPrimary);
    expect(AppGradients.primary.colors, [expectedCtaStart, expectedCtaEnd]);
    expect(AppTheme.lightTheme.colorScheme.primary, expectedPrimary);

    final expectedDark = ColorScheme.fromSeed(
      seedColor: expectedPrimary,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    expect(AppTheme.darkTheme.colorScheme.primary, expectedDark.primary);
  });
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prints a literal Material 3 fidelity [ColorScheme] snapshot for review.
///
/// Usage:
/// `flutter test --dart-define=DARK_SCHEME_SEED=006A46 tools/theme/print_material3_dark_scheme.dart`.
void main() {
  test('prints the requested fidelity snapshot', () {
    const input = String.fromEnvironment(
      'DARK_SCHEME_SEED',
      defaultValue: '006A46',
    );
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(input)) {
      throw ArgumentError('Expected a six-digit DARK_SCHEME_SEED.');
    }
    final seed = Color(int.parse('ff$input', radix: 16));
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    print('const ColorScheme(');
    print('  brightness: Brightness.dark,');
    _printColor('primary', scheme.primary);
    _printColor('onPrimary', scheme.onPrimary);
    _printColor('primaryContainer', scheme.primaryContainer);
    _printColor('onPrimaryContainer', scheme.onPrimaryContainer);
    _printColor('primaryFixed', scheme.primaryFixed);
    _printColor('primaryFixedDim', scheme.primaryFixedDim);
    _printColor('onPrimaryFixed', scheme.onPrimaryFixed);
    _printColor('onPrimaryFixedVariant', scheme.onPrimaryFixedVariant);
    _printColor('secondary', scheme.secondary);
    _printColor('onSecondary', scheme.onSecondary);
    _printColor('secondaryContainer', scheme.secondaryContainer);
    _printColor('onSecondaryContainer', scheme.onSecondaryContainer);
    _printColor('secondaryFixed', scheme.secondaryFixed);
    _printColor('secondaryFixedDim', scheme.secondaryFixedDim);
    _printColor('onSecondaryFixed', scheme.onSecondaryFixed);
    _printColor('onSecondaryFixedVariant', scheme.onSecondaryFixedVariant);
    _printColor('tertiary', scheme.tertiary);
    _printColor('onTertiary', scheme.onTertiary);
    _printColor('tertiaryContainer', scheme.tertiaryContainer);
    _printColor('onTertiaryContainer', scheme.onTertiaryContainer);
    _printColor('tertiaryFixed', scheme.tertiaryFixed);
    _printColor('tertiaryFixedDim', scheme.tertiaryFixedDim);
    _printColor('onTertiaryFixed', scheme.onTertiaryFixed);
    _printColor('onTertiaryFixedVariant', scheme.onTertiaryFixedVariant);
    _printColor('error', scheme.error);
    _printColor('onError', scheme.onError);
    _printColor('errorContainer', scheme.errorContainer);
    _printColor('onErrorContainer', scheme.onErrorContainer);
    _printColor('surface', scheme.surface);
    _printColor('onSurface', scheme.onSurface);
    _printColor('surfaceDim', scheme.surfaceDim);
    _printColor('surfaceBright', scheme.surfaceBright);
    _printColor('surfaceContainerLowest', scheme.surfaceContainerLowest);
    _printColor('surfaceContainerLow', scheme.surfaceContainerLow);
    _printColor('surfaceContainer', scheme.surfaceContainer);
    _printColor('surfaceContainerHigh', scheme.surfaceContainerHigh);
    _printColor('surfaceContainerHighest', scheme.surfaceContainerHighest);
    _printColor('onSurfaceVariant', scheme.onSurfaceVariant);
    _printColor('outline', scheme.outline);
    _printColor('outlineVariant', scheme.outlineVariant);
    _printColor('shadow', scheme.shadow);
    _printColor('scrim', scheme.scrim);
    _printColor('inverseSurface', scheme.inverseSurface);
    _printColor('onInverseSurface', scheme.onInverseSurface);
    _printColor('inversePrimary', scheme.inversePrimary);
    _printColor('surfaceTint', scheme.surfaceTint);
    print(');');
  });
}

void _printColor(String name, Color color) {
  final value = color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase();
  print('  $name: Color(0x$value),');
}

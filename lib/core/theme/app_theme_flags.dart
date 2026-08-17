import 'package:flutter/foundation.dart';

@immutable
final class AppThemeFlags {
  const AppThemeFlags._();

  /// Compile-time compatibility switch for the former Green Wellness theme.
  ///
  /// Every build defaults to Blue Wellness. Passing
  /// `--dart-define=STITCH_GREEN_UI_ENABLED=true` enables the retained Green
  /// Wellness rollback palette without changing product behavior.
  static const bool stitchGreenUiEnabled = bool.fromEnvironment(
    'STITCH_GREEN_UI_ENABLED',
    defaultValue: false,
  );
}

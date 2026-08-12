import 'package:flutter/foundation.dart';

@immutable
final class AppThemeFlags {
  const AppThemeFlags._();

  /// Compile-time rollback switch for the Green Wellness cutover.
  ///
  /// Every build defaults to the Green Wellness palette. Passing
  /// `--dart-define=STITCH_GREEN_UI_ENABLED=false` remains the one-release
  /// rollback path to the previous Blue Wellness palette.
  static const bool stitchGreenUiEnabled = bool.fromEnvironment(
    'STITCH_GREEN_UI_ENABLED',
    defaultValue: true,
  );
}

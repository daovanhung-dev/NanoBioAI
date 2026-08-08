import 'package:flutter/foundation.dart';

@immutable
final class AppThemeFlags {
  const AppThemeFlags._();

  /// Compile-time rollback switch for the Green Wellness cutover.
  ///
  /// Debug/profile builds default to Green for visual QA. Release builds stay
  /// on the previous Blue Wellness palette until the acceptance gate passes;
  /// then release automation must opt in with
  /// `--dart-define=STITCH_GREEN_UI_ENABLED=true`. Passing `false` remains the
  /// one-release rollback path.
  static const bool stitchGreenUiEnabled = bool.fromEnvironment(
    'STITCH_GREEN_UI_ENABLED',
    // Green is the default for development and visual QA. Release builds stay
    // on the rollback palette until the 76-surface acceptance gate explicitly
    // passes `--dart-define=STITCH_GREEN_UI_ENABLED=true`.
    defaultValue: !kReleaseMode,
  );
}

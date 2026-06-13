import 'package:flutter/foundation.dart';

/// Foundation spacing scale based on base-8 system.
///
/// This class provides the primitive spacing values that form the foundation
/// of the design system. These values should not be used directly in components;
/// instead, use semantic spacing tokens from [AppSpacingTokens] that reference
/// these foundation values.
///
/// The base-8 scale ensures consistent spacing throughout the application and
/// makes it easier to maintain visual rhythm and alignment.
///
/// Example:
/// ```dart
/// // DON'T use foundation tokens directly in components
/// Padding(padding: EdgeInsets.all(SpacingFoundation.space16))
///
/// // DO use semantic tokens that reference foundation values
/// Padding(padding: EdgeInsets.all(AppSpacingTokens.pagePadding))
/// ```
@immutable
class SpacingFoundation {
  const SpacingFoundation._();

  /// No spacing (0px)
  ///
  /// Used when no spacing is needed, typically for tightly grouped elements
  /// or when spacing is controlled by parent container.
  static const double space0 = 0;

  /// Extra small spacing (4px)
  ///
  /// Used for minimal spacing between closely related elements,
  /// such as icon and text in a button.
  static const double space4 = 4;

  /// Small spacing (8px)
  ///
  /// Used for spacing between related items within a component,
  /// such as list items or form fields.
  static const double space8 = 8;

  /// Medium-small spacing (12px)
  ///
  /// Used for compact component padding, such as chips or small buttons.
  static const double space12 = 12;

  /// Medium spacing (16px)
  ///
  /// The most commonly used spacing value. Used for standard padding
  /// in cards, page margins, and spacing between component groups.
  static const double space16 = 16;

  /// Medium-large spacing (24px)
  ///
  /// Used for creating clear separation between sections or
  /// for larger component padding.
  static const double space24 = 24;

  /// Large spacing (32px)
  ///
  /// Used for major section separations and breathing room
  /// in larger layouts.
  static const double space32 = 32;

  /// Extra large spacing (48px)
  ///
  /// Used for very prominent section breaks and in spacious layouts.
  static const double space48 = 48;

  /// 2XL spacing (64px)
  ///
  /// Used for major visual breaks and generous padding in
  /// landing pages or showcase sections.
  static const double space64 = 64;

  /// 3XL spacing (96px)
  ///
  /// Used for maximum separation between major sections,
  /// typically in marketing or presentation layouts.
  static const double space96 = 96;
}

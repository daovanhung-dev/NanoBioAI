import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/foundation/radius.dart';
import 'package:nano_app/core/theme/foundation/shadows.dart';
import 'package:nano_app/core/theme/foundation/motion.dart';
import 'package:nano_app/core/theme/foundation/typography.dart';

/// Component-specific semantic tokens that map foundation values to specific component uses.
///
/// This is Layer 2 of the token architecture:
/// - Foundation tokens (Layer 1) define primitive values
/// - Component tokens (Layer 2) map foundation values to component-specific uses
/// - Components (Layer 3) consume these semantic mappings
///
/// **Validates: Requirements 2.3, 2.4, 2.5**

// ============================================================
// RADIUS TOKENS
// ============================================================

/// Component radius mappings that define border radius for specific UI components.
///
/// Each component radius references a foundation radius value and conveys
/// the appropriate rounding level for that component type.
///
/// **Usage:**
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppRadiusTokens.button),
///   ),
/// );
/// ```
///
/// **Validates: Requirements 2.3**
@immutable
class AppRadiusTokens {
  const AppRadiusTokens._();

  /// Border radius for buttons (12px).
  ///
  /// Medium rounding provides balanced appearance for interactive elements.
  static const double button = RadiusFoundation.radius12;

  /// Border radius for cards (16px).
  ///
  /// Larger rounding creates softer, more approachable containers.
  static const double card = RadiusFoundation.radius16;

  /// Border radius for input fields (12px).
  ///
  /// Consistent with buttons for unified form element appearance.
  static const double input = RadiusFoundation.radius12;

  /// Border radius for chips (8px).
  ///
  /// Subtle rounding for compact, inline elements.
  static const double chip = RadiusFoundation.radius8;

  /// Border radius for badges (9999px).
  ///
  /// Full radius creates circular or pill-shaped badges.
  static const double badge = RadiusFoundation.radiusFull;

  /// Border radius for dialogs and modals (24px).
  ///
  /// Extra large rounding for prominent overlay surfaces.
  static const double dialog = RadiusFoundation.radius24;

  /// Border radius for avatars (9999px).
  ///
  /// Full radius creates circular avatar shapes.
  static const double avatar = RadiusFoundation.radiusFull;
}

// ============================================================
// SHADOW TOKENS
// ============================================================

/// Component shadow mappings that define elevation for specific UI components.
///
/// Each component shadow references a foundation shadow value and conveys
/// the appropriate elevation level for that component type.
///
/// **Light vs Dark Mode:**
/// Shadows automatically adapt based on theme brightness. Use
/// `Theme.of(context).brightness` to select appropriate shadow variant.
///
/// **Usage:**
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadowTokens.card,
///   ),
/// );
/// ```
///
/// **Validates: Requirements 2.4**
@immutable
class AppShadowTokens {
  const AppShadowTokens._();

  /// Shadow for default cards (small elevation).
  ///
  /// Subtle elevation for standard card containers.
  static const List<BoxShadow> card = ShadowFoundation.shadowSm;

  /// Shadow for default cards in dark mode (small elevation).
  ///
  /// Higher opacity shadow for dark mode visibility.
  static const List<BoxShadow> cardDark = ShadowFoundation.shadowSmDark;

  /// Shadow for elevated cards (medium elevation).
  ///
  /// Moderate elevation for emphasized or interactive cards.
  static const List<BoxShadow> cardElevated = ShadowFoundation.shadowMd;

  /// Shadow for elevated cards in dark mode (medium elevation).
  ///
  /// Higher opacity shadow for dark mode visibility.
  static const List<BoxShadow> cardElevatedDark = ShadowFoundation.shadowMdDark;

  /// Shadow for dialogs and modals (large elevation).
  ///
  /// Prominent elevation for overlay surfaces that float above content.
  static const List<BoxShadow> dialog = ShadowFoundation.shadowLg;

  /// Shadow for buttons (small elevation).
  ///
  /// Subtle elevation for interactive button elements.
  static const List<BoxShadow> button = ShadowFoundation.shadowSm;
}

// ============================================================
// MOTION TOKENS
// ============================================================

/// Component animation mappings that define motion characteristics for specific UI components.
///
/// Each component motion token references foundation duration and curve values
/// to provide consistent, appropriate animation timing for that component type.
///
/// **Usage:**
/// ```dart
/// AnimatedContainer(
///   duration: AppMotionTokens.button,
///   curve: AppMotionTokens.defaultCurve,
///   // ...
/// );
/// ```
///
/// **Validates: Requirements 2.5**
@immutable
class AppMotionTokens {
  const AppMotionTokens._();

  /// Animation duration for button interactions (150ms).
  ///
  /// Fast feedback for immediate user interactions like presses and hovers.
  static const Duration button = MotionFoundation.fast;

  /// Animation duration for card transitions (250ms).
  ///
  /// Standard timing for card state changes and transitions.
  static const Duration card = MotionFoundation.normal;

  /// Animation duration for dialog appearances (250ms).
  ///
  /// Standard timing for modal and dialog entry/exit animations.
  static const Duration dialog = MotionFoundation.normal;

  /// Animation duration for page transitions (350ms).
  ///
  /// Slower timing for full-screen page navigation animations.
  static const Duration page = MotionFoundation.slow;

  /// Default animation curve for most component animations.
  ///
  /// Smooth ease-in-out provides natural motion for bidirectional transitions.
  static const Curve defaultCurve = MotionFoundation.easeInOut;
}

// ============================================================
// TEXT STYLE TOKENS
// ============================================================

/// Text style presets that define typography for specific use cases.
///
/// Each text style combines foundation typography tokens (font size, weight, height)
/// into semantic presets for different content types and hierarchy levels.
///
/// **Usage:**
/// ```dart
/// Text(
///   'Welcome',
///   style: AppTextStyles.heading1,
/// );
/// ```
///
/// **Color Application:**
/// These styles define size, weight, and spacing only. Apply color through
/// the `style` parameter or by using `copyWith`:
/// ```dart
/// Text(
///   'Welcome',
///   style: AppTextStyles.heading1.copyWith(color: AppColorTokens.textPrimary),
/// );
/// ```
///
/// **Validates: Requirements 2.3**
@immutable
class AppTextStyles {
  const AppTextStyles._();

  /// Display large text style (32px, bold, tight line height).
  ///
  /// Use for:
  /// - Hero headlines
  /// - Landing page titles
  /// - Splash screen text
  /// - Large promotional content
  static const TextStyle displayLarge = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size32,
    fontWeight: TypographyFoundation.bold,
    height: TypographyFoundation.lineHeightTight,
  );

  /// Heading 1 text style (24px, bold, normal line height).
  ///
  /// Use for:
  /// - Page titles
  /// - Section headers
  /// - Primary headings
  /// - Feature titles
  static const TextStyle heading1 = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size24,
    fontWeight: TypographyFoundation.bold,
    height: TypographyFoundation.lineHeightNormal,
  );

  /// Heading 2 text style (20px, semibold, normal line height).
  ///
  /// Use for:
  /// - Subsection headers
  /// - Card titles
  /// - Secondary headings
  /// - Group labels
  static const TextStyle heading2 = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size20,
    fontWeight: TypographyFoundation.semibold,
    height: TypographyFoundation.lineHeightNormal,
  );

  /// Body large text style (16px, regular, relaxed line height).
  ///
  /// Use for:
  /// - Primary body text
  /// - Article content
  /// - Long-form descriptions
  /// - Default paragraph text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size16,
    fontWeight: TypographyFoundation.regular,
    height: TypographyFoundation.lineHeightRelaxed,
  );

  /// Body medium text style (14px, regular, relaxed line height).
  ///
  /// Use for:
  /// - Secondary body text
  /// - List item text
  /// - Card descriptions
  /// - Form helper text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size14,
    fontWeight: TypographyFoundation.regular,
    height: TypographyFoundation.lineHeightRelaxed,
  );

  /// Label large text style (14px, semibold, tight line height).
  ///
  /// Use for:
  /// - Button labels
  /// - Tab labels
  /// - Form field labels
  /// - Navigation items
  static const TextStyle labelLarge = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size14,
    fontWeight: TypographyFoundation.semibold,
    height: TypographyFoundation.lineHeightTight,
  );

  /// Label medium text style (12px, semibold, tight line height).
  ///
  /// Use for:
  /// - Chip labels
  /// - Small button labels
  /// - Badge labels
  /// - Compact navigation items
  static const TextStyle labelMedium = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size12,
    fontWeight: TypographyFoundation.semibold,
    height: TypographyFoundation.lineHeightTight,
  );

  /// Caption text style (12px, regular, normal line height).
  ///
  /// Use for:
  /// - Supplementary information
  /// - Timestamps
  /// - Metadata labels
  /// - Fine print
  /// - Helper text
  static const TextStyle caption = TextStyle(
    fontFamily: TypographyFoundation.fontFamily,
    fontSize: TypographyFoundation.size12,
    fontWeight: TypographyFoundation.regular,
    height: TypographyFoundation.lineHeightNormal,
  );
}

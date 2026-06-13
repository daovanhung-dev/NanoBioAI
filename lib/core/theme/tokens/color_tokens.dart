import 'package:flutter/material.dart';
import '../foundation/colors.dart';

/// Semantic color tokens for the BioAI application design system.
///
/// This class provides meaningful, context-aware color names that reference
/// foundation color values. Semantic tokens convey **purpose and intent**
/// rather than visual properties (e.g., "primary" instead of "blue500").
///
/// ## Usage
///
/// Always use semantic tokens in components instead of foundation colors:
///
/// ```dart
/// // Good ✓
/// color: AppColorTokens.primary
///
/// // Bad ✗
/// color: ColorFoundation.blue500
/// ```
///
/// ## Light and Dark Mode
///
/// This class provides separate token sets for light and dark modes. Use
/// `Theme.of(context).brightness` to determine which set to apply:
///
/// ```dart
/// final isDark = Theme.of(context).brightness == Brightness.dark;
/// final surface = isDark ? AppColorTokens.darkSurface : AppColorTokens.surface;
/// ```
///
/// Total: 24 semantic color mappings (light mode + dark mode)
@immutable
class AppColorTokens {
  const AppColorTokens._();

  // ============================================================================
  // LIGHT MODE TOKENS
  // ============================================================================

  // Brand Colors
  // ----------------------------------------------------------------------------

  /// Primary brand color - use for main CTAs, primary buttons, and key UI elements
  static const Color primary = ColorFoundation.blue500;

  /// Primary brand color hover state - darker shade for interactive states
  static const Color primaryHover = ColorFoundation.blue600;

  /// Secondary brand color - use for secondary actions and accents
  static const Color secondary = ColorFoundation.cyan500;

  /// Tertiary brand color - use for special features and premium content
  static const Color tertiary = ColorFoundation.purple500;

  // Surface Colors
  // ----------------------------------------------------------------------------

  /// Background color - main app background surface
  static const Color background = ColorFoundation.slate50;

  /// Surface color - cards, sheets, and elevated content surfaces
  static const Color surface = ColorFoundation.white;

  /// Elevated surface color - surfaces that appear above other surfaces
  static const Color surfaceElevated = ColorFoundation.white;

  // Text Colors
  // ----------------------------------------------------------------------------

  /// Primary text color - main content text, headings
  static const Color textPrimary = ColorFoundation.slate900;

  /// Secondary text color - supporting text, descriptions
  static const Color textSecondary = ColorFoundation.slate600;

  /// Muted text color - captions, hints, disabled text
  static const Color textMuted = ColorFoundation.slate500;

  /// Inverse text color - text on dark or colored backgrounds
  static const Color textInverse = ColorFoundation.white;

  // Border Colors
  // ----------------------------------------------------------------------------

  /// Standard border color - default borders, dividers
  static const Color border = ColorFoundation.slate200;

  /// Strong border color - emphasized borders, active states
  static const Color borderStrong = ColorFoundation.slate300;

  // Status Colors
  // ----------------------------------------------------------------------------

  /// Success color - success states, positive confirmations
  static const Color success = ColorFoundation.green500;

  /// Warning color - warning states, caution indicators
  static const Color warning = ColorFoundation.amber500;

  /// Error color - error states, destructive actions
  static const Color error = ColorFoundation.red500;

  /// Info color - informational states, helpful tips
  static const Color info = ColorFoundation.sky500;

  // Light Background Colors for Status
  // ----------------------------------------------------------------------------

  /// Light success background color - for success badges and status indicators
  static const Color successLight = Color(0xFFD1FAE5);

  /// Light warning background color - for warning badges and status indicators
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Light error background color - for error badges and status indicators
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Light info background color - for info badges and status indicators
  static const Color infoLight = Color(0xFFE0F2FE);

  /// Light primary background color - for selected chips and primary status indicators
  static const Color primaryLight = Color(0xFFDBEAFE);

  // ============================================================================
  // DARK MODE TOKENS
  // ============================================================================

  // Surface Colors (Dark)
  // ----------------------------------------------------------------------------

  /// Dark mode background color - main app background in dark mode
  static const Color darkBackground = ColorFoundation.slate900;

  /// Dark mode surface color - cards, sheets, and elevated content in dark mode
  static const Color darkSurface = ColorFoundation.slate800;

  /// Dark mode elevated surface color - surfaces above other surfaces in dark mode
  static const Color darkSurfaceElevated = ColorFoundation.slate700;

  // Text Colors (Dark)
  // ----------------------------------------------------------------------------

  /// Dark mode primary text color - main content text, headings in dark mode
  static const Color darkTextPrimary = ColorFoundation.white;

  /// Dark mode secondary text color - supporting text, descriptions in dark mode
  static const Color darkTextSecondary = ColorFoundation.slate300;

  /// Dark mode muted text color - captions, hints, disabled text in dark mode
  static const Color darkTextMuted = ColorFoundation.slate400;

  // Border Colors (Dark)
  // ----------------------------------------------------------------------------

  /// Dark mode standard border color - default borders, dividers in dark mode
  static const Color darkBorder = ColorFoundation.slate700;

  /// Dark mode strong border color - emphasized borders, active states in dark mode
  static const Color darkBorderStrong = ColorFoundation.slate600;
}

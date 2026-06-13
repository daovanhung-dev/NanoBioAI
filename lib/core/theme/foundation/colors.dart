import 'package:flutter/material.dart';

/// Foundation color palette for the BioAI application design system.
///
/// This class defines the primitive, immutable color values that form the
/// visual vocabulary of the design system. These colors should **never be used
/// directly** in components - instead, reference semantic color tokens from
/// [AppColorTokens] which provide meaningful, context-aware names.
///
/// The palette includes:
/// - Brand colors (blue, cyan, purple)
/// - Status colors (green, amber, red, sky)
/// - Neutral slate scale (slate50-slate900)
/// - Pure colors (white, black)
///
/// Total: 28 color values (reduced from 80+ in the previous system)
@immutable
class ColorFoundation {
  const ColorFoundation._();

  // Brand Colors - Blue
  /// Brand blue 400 - Lighter brand accent
  static const Color blue400 = Color(0xFF60A5FA);

  /// Brand blue 500 - Primary brand color
  static const Color blue500 = Color(0xFF3B82F6);

  /// Brand blue 600 - Darker brand color for hover states
  static const Color blue600 = Color(0xFF2563EB);

  /// Brand blue 700 - Darkest brand color
  static const Color blue700 = Color(0xFF1D4ED8);

  // Brand Colors - Cyan
  /// Brand cyan 400 - Lighter cyan accent
  static const Color cyan400 = Color(0xFF22D3EE);

  /// Brand cyan 500 - Secondary brand color
  static const Color cyan500 = Color(0xFF06B6D4);

  /// Brand cyan 600 - Darker cyan
  static const Color cyan600 = Color(0xFF0891B2);

  // Brand Colors - Purple
  /// Brand purple 500 - Tertiary brand color
  static const Color purple500 = Color(0xFF8B5CF6);

  /// Brand purple 600 - Darker purple
  static const Color purple600 = Color(0xFF7C3AED);

  // Status Colors - Success
  /// Success green 500 - Primary success color
  static const Color green500 = Color(0xFF22C55E);

  /// Success green 600 - Darker success color
  static const Color green600 = Color(0xFF16A34A);

  // Status Colors - Warning
  /// Warning amber 500 - Primary warning color
  static const Color amber500 = Color(0xFFF59E0B);

  /// Warning amber 600 - Darker warning color
  static const Color amber600 = Color(0xFFD97706);

  // Status Colors - Error
  /// Error red 500 - Primary error color
  static const Color red500 = Color(0xFFEF4444);

  /// Error red 600 - Darker error color
  static const Color red600 = Color(0xFFDC2626);

  // Status Colors - Info
  /// Info sky 500 - Primary info color
  static const Color sky500 = Color(0xFF0EA5E9);

  /// Info sky 600 - Darker info color
  static const Color sky600 = Color(0xFF0284C7);

  // Neutral Colors - Slate Scale (Light Mode)
  /// Slate 50 - Lightest neutral background
  static const Color slate50 = Color(0xFFF8FAFC);

  /// Slate 100 - Very light neutral background
  static const Color slate100 = Color(0xFFF1F5F9);

  /// Slate 200 - Light neutral border and divider
  static const Color slate200 = Color(0xFFE2E8F0);

  /// Slate 300 - Neutral border
  static const Color slate300 = Color(0xFFCBD5E1);

  /// Slate 400 - Muted neutral for disabled states
  static const Color slate400 = Color(0xFF94A3B8);

  /// Slate 500 - Mid neutral for muted text
  static const Color slate500 = Color(0xFF64748B);

  /// Slate 600 - Darker neutral for secondary text
  static const Color slate600 = Color(0xFF475569);

  /// Slate 700 - Dark neutral for elevated dark surfaces
  static const Color slate700 = Color(0xFF334155);

  /// Slate 800 - Very dark neutral for dark mode surfaces
  static const Color slate800 = Color(0xFF1E293B);

  /// Slate 900 - Darkest neutral for primary text and dark backgrounds
  static const Color slate900 = Color(0xFF0F172A);

  // Pure Colors
  /// Pure white
  static const Color white = Colors.white;

  /// Pure black
  static const Color black = Colors.black;
}

/// Foundation gradient definitions for the BioAI application design system.
///
/// This class provides a minimal set of gradient definitions for brand moments
/// and premium features. Most UI elements should use solid colors from
/// [ColorFoundation] instead of gradients for better performance.
///
/// Total: 5 gradient definitions (reduced from 25+ in the previous system)
@immutable
class GradientFoundation {
  const GradientFoundation._();

  /// Primary gradient for brand elements
  ///
  /// Uses blue to cyan gradient for main brand moments
  static const LinearGradient primary = LinearGradient(
    colors: [ColorFoundation.blue500, ColorFoundation.cyan500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium gradient for special features
  ///
  /// Uses blue to purple gradient for premium/pro features
  static const LinearGradient premium = LinearGradient(
    colors: [ColorFoundation.blue500, ColorFoundation.purple500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient for positive status indicators
  ///
  /// Uses green gradient for success states
  static const LinearGradient success = LinearGradient(
    colors: [ColorFoundation.green500, ColorFoundation.green600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light surface gradient for subtle backgrounds
  ///
  /// Uses white to light slate for subtle background gradients
  static const LinearGradient surfaceLight = LinearGradient(
    colors: [ColorFoundation.white, ColorFoundation.slate50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark surface gradient for dark mode backgrounds
  ///
  /// Uses slate 800 to slate 900 for dark mode subtle backgrounds
  static const LinearGradient surfaceDark = LinearGradient(
    colors: [ColorFoundation.slate800, ColorFoundation.slate900],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

import 'package:flutter/material.dart';

/// ============================================================
/// App Colors
/// ------------------------------------------------------------
/// - Clean Architecture Friendly
/// - Scalable Design System
/// - Ready for Light/Dark Theme
/// - Semantic Naming
/// - UI/UX Modern Style
/// ============================================================
class AppColors {
  AppColors._();

  // ============================================================
  // BRAND COLORS
  // ============================================================

  /// Main brand color
  static const Color primary = Color(0xFF3B82F6);

  /// Hover / active / stronger state
  static const Color primaryDark = Color(0xFF2563EB);

  /// Soft background / light state
  static const Color primaryLight = Color(0xFF93C5FD);

  /// Extra soft primary background
  static const Color primarySoft = Color(0xFFEFF6FF);

  /// Secondary accent
  static const Color secondary = Color(0xFF06B6D4);

  // ============================================================
  // BACKGROUND & SURFACE
  // ============================================================

  /// App background
  static const Color background = Color(0xFFF8FAFC);

  /// Scaffold background
  static const Color scaffold = Color(0xFFF1F5F9);

  /// Card / container surface
  static const Color surface = Colors.white;

  /// Elevated surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Modal / dialog background
  static const Color modalBackground = Colors.white;

  // ============================================================
  // TEXT COLORS
  // ============================================================

  /// Main text
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary text
  static const Color textSecondary = Color(0xFF475569);

  /// Hint / disabled text
  static const Color textHint = Color(0xFF94A3B8);

  /// Text on dark backgrounds
  static const Color textWhite = Colors.white;

  // ============================================================
  // STATUS COLORS
  // ============================================================

  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ============================================================
  // BORDER & DIVIDER
  // ============================================================

  /// Default border
  static const Color border = Color(0xFFE2E8F0);

  /// Light border
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Divider color
  static const Color divider = Color(0xFFE5E7EB);

  // ============================================================
  // COMPONENT COLORS
  // ============================================================

  /// Card color
  static const Color card = Colors.white;

  /// Input background
  static const Color inputBackground = Color(0xFFF8FAFC);

  /// Disabled component
  static const Color disabled = Color(0xFFCBD5E1);

  /// Shadow overlay
  static const Color overlay = Color(0x55000000);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF60A5FA),
      Color(0xFF2563EB),
    ],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF38BDF8),
      Color(0xFF2563EB),
    ],
  );

  // ============================================================
  // DARK MODE READY
  // ============================================================

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);

  static const Color darkCard = Color(0xFF1E293B);

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static const Color darkBorder = Color(0xFF334155);
}
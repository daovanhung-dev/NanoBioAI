import 'package:flutter/material.dart';

/// ============================================================
/// App Colors
/// ------------------------------------------------------------
/// Scalable semantic color system for Flutter themes.
/// - Backward compatible with existing code
/// - Light/Dark ready
/// - Semantic naming
/// - Reusable across product types
/// ============================================================
class AppColors {
  AppColors._();

  // ============================================================
  // BRAND
  // ============================================================

  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primarySoft = Color(0xFFEFF6FF);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color secondarySoft = Color(0xFFE0F7FA);

  static const Color tertiary = Color(0xFF8B5CF6);

  // ============================================================
  // SEMANTIC STATUS
  // ============================================================

  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);

  static const Color danger = error;
  static const Color dangerSoft = errorSoft;

  // ============================================================
  // LIGHT SURFACES
  // ============================================================

  static const Color background = Color(0xFFF8FAFC);
  static const Color scaffold = Color(0xFFF1F5F9);

  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color modalBackground = Colors.white;

  static const Color card = Colors.white;
  static const Color cardAlt = Color(0xFFF8FAFC);
  static const Color inputBackground = Color(0xFFF8FAFC);

  // ============================================================
  // DARK SURFACES
  // ============================================================

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkScaffold = Color(0xFF0B1220);

  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkModalBackground = Color(0xFF111827);

  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardAlt = Color(0xFF162033);
  static const Color darkInputBackground = Color(0xFF0F172A);

  // ============================================================
  // TEXT
  // ============================================================

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textInverse = Colors.white;
  static const Color textWhite = Colors.white;

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);
  static const Color darkTextDisabled = Color(0xFF475569);
  static const Color darkTextInverse = Color(0xFF0F172A);

  // ============================================================
  // BORDERS / DIVIDERS / OUTLINES
  // ============================================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color outline = Color(0xFFD8E0EA);

  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderLight = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkOutline = Color(0xFF475569);

  // ============================================================
  // STATES / OVERLAYS
  // ============================================================

  static const Color overlay = Color(0x55000000);
  static const Color overlayStrong = Color(0x88000000);
  static const Color scrim = Color(0x66000000);

  static const Color hover = Color(0x0F3B82F6);
  static const Color pressed = Color(0x1A3B82F6);
  static const Color focused = Color(0x223B82F6);
  static const Color selected = Color(0x143B82F6);
  static const Color disabled = Color(0xFFCBD5E1);

  static const Color darkOverlay = Color(0x99000000);
  static const Color darkHover = Color(0x203B82F6);
  static const Color darkPressed = Color(0x2A3B82F6);
  static const Color darkFocused = Color(0x333B82F6);
  static const Color darkSelected = Color(0x263B82F6);
  static const Color darkDisabled = Color(0xFF475569);

  // ============================================================
  // NAV / ICON
  // ============================================================

  static const Color icon = Color(0xFF64748B);
  static const Color iconSecondary = Color(0xFF94A3B8);
  static const Color iconDisabled = Color(0xFFCBD5E1);

  static const Color darkIcon = Color(0xFFCBD5E1);
  static const Color darkIconSecondary = Color(0xFF94A3B8);
  static const Color darkIconDisabled = Color(0xFF475569);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  // ============================================================
  // ALIASES FOR BACKWARD COMPATIBILITY
  // ============================================================

  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color cardColor = card;
  static const Color modalColor = modalBackground;
  static const Color borderColor = border;
  static const Color dividerColor = divider;
  static const Color overlayColor = overlay;

  // Existing names already used in the theme file
  static const Color scaffoldBackground = scaffold;
  static const Color cardSurface = card;
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;
  static const Color textHintColor = textHint;

  // ============================================================
  // DARK THEME SET
  // ============================================================

  static const Color darkPrimary = primaryLight;
  static const Color darkSecondary = secondaryLight;
  static const Color darkSurfaceCard = darkCard;
  static const Color darkSurfaceInput = darkInputBackground;
}

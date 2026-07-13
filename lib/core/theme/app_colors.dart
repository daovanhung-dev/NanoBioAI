import 'package:flutter/material.dart';

/// Semantic palette for NanoBio/Nabi.
///
/// The palette intentionally combines a trustworthy medical blue with a calm
/// wellness teal. Feature code should use semantic names from this class rather
/// than introducing new color literals.
@immutable
class AppColors {
  const AppColors._();

  // Brand and clinical accents.
  static const Color primary = Color(0xFF1769E0);
  static const Color primaryDark = Color(0xFF0D4EA6);
  static const Color primaryLight = Color(0xFF7CB7FF);
  static const Color primarySoft = Color(0xFFEAF3FF);
  static const Color primarySubtle = Color(0xFFF4F8FF);

  static const Color secondary = Color(0xFF0F766E);
  static const Color secondaryDark = Color(0xFF0B5B55);
  static const Color secondaryLight = Color(0xFF5FD2C7);
  static const Color secondarySoft = Color(0xFFE8F7F5);

  static const Color tertiary = Color(0xFF6750A4);
  static const Color tertiarySoft = Color(0xFFF1ECFB);
  static const Color clinicalNavy = Color(0xFF12304A);
  static const Color wellnessMint = Color(0xFF2AA981);

  // Semantic status.
  static const Color success = Color(0xFF16825D);
  static const Color successSoft = Color(0xFFE7F6EF);
  static const Color warning = Color(0xFF9A6200);
  static const Color warningDark = Color(0xFF7A4D00);
  static const Color warningSoft = Color(0xFFFFF4D6);
  static const Color error = Color(0xFFC4314B);
  static const Color errorSoft = Color(0xFFFCECEF);
  static const Color info = Color(0xFF1261A0);
  static const Color infoSoft = Color(0xFFEAF4FC);
  static const Color danger = error;
  static const Color dangerSoft = errorSoft;

  // Light surfaces.
  static const Color background = Color(0xFFF4F8FB);
  static const Color scaffold = Color(0xFFF1F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF7FAFC);
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFF7FAFC);
  static const Color inputBackground = Color(0xFFF5F8FB);

  // Dark surfaces retained for dark-aware components and future theme work.
  static const Color darkBackground = Color(0xFF081723);
  static const Color darkScaffold = Color(0xFF07131E);
  static const Color darkSurface = Color(0xFF102433);
  static const Color darkSurfaceElevated = Color(0xFF173244);
  static const Color darkModalBackground = Color(0xFF102433);
  static const Color darkCard = Color(0xFF173244);
  static const Color darkCardAlt = Color(0xFF122A3A);
  static const Color darkInputBackground = Color(0xFF0D2130);

  // Text hierarchy.
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF486581);
  static const Color textMuted = Color(0xFF627D98);
  static const Color textHint = Color(0xFF829AB1);
  static const Color textDisabled = Color(0xFFBCCCDC);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF7FAFC);
  static const Color darkTextSecondary = Color(0xFFD9E2EC);
  static const Color darkTextMuted = Color(0xFF9FB3C8);
  static const Color darkTextHint = Color(0xFF829AB1);
  static const Color darkTextDisabled = Color(0xFF627D98);
  static const Color darkTextInverse = textPrimary;

  // Borders, dividers and focus.
  static const Color border = Color(0xFFD9E2EC);
  static const Color borderLight = Color(0xFFE8EEF4);
  static const Color divider = Color(0xFFE3EAF1);
  static const Color outline = Color(0xFFC6D4E1);
  static const Color focusRing = Color(0xFF84B8FF);

  static const Color darkBorder = Color(0xFF36566C);
  static const Color darkBorderLight = Color(0xFF24465B);
  static const Color darkDivider = Color(0xFF2B4D62);
  static const Color darkOutline = Color(0xFF54768C);

  // States and overlays.
  static const Color overlay = Color(0x52081723);
  static const Color overlayStrong = Color(0x80081723);
  static const Color scrim = Color(0x66081723);
  static const Color hover = Color(0x101769E0);
  static const Color pressed = Color(0x1F1769E0);
  static const Color focused = Color(0x291769E0);
  static const Color selected = Color(0x141769E0);
  static const Color disabled = Color(0xFFD9E2EC);

  static const Color darkOverlay = Color(0x99000000);
  static const Color darkHover = Color(0x221769E0);
  static const Color darkPressed = Color(0x331769E0);
  static const Color darkFocused = Color(0x441769E0);
  static const Color darkSelected = Color(0x2B1769E0);
  static const Color darkDisabled = Color(0xFF36566C);

  // Navigation and icon colors.
  static const Color icon = Color(0xFF486581);
  static const Color iconSecondary = Color(0xFF829AB1);
  static const Color iconDisabled = Color(0xFFBCCCDC);
  static const Color darkIcon = Color(0xFFD9E2EC);
  static const Color darkIconSecondary = Color(0xFF9FB3C8);
  static const Color darkIconDisabled = Color(0xFF627D98);

  // Backward-compatible gradients.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B7BEA), Color(0xFF0D4EA6)],
  );
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4C96F4), Color(0xFF1769E0)],
  );
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1769E0), Color(0xFF6750A4)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2AA981), Color(0xFF0F766E)],
  );

  // Backward-compatible aliases.
  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color cardColor = card;
  static const Color modalColor = modalBackground;
  static const Color borderColor = border;
  static const Color dividerColor = divider;
  static const Color overlayColor = overlay;
  static const Color scaffoldBackground = scaffold;
  static const Color cardSurface = card;
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;
  static const Color textHintColor = textHint;

  static const Color darkPrimary = primaryLight;
  static const Color darkSecondary = secondaryLight;
  static const Color darkSurfaceCard = darkCard;
  static const Color darkSurfaceInput = darkInputBackground;
}

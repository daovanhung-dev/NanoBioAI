import 'package:flutter/material.dart';

/// Canonical semantic palette for NaBi Blue Wellness.
///
/// Consumer features must use these semantic roles instead of raw color
/// literals. Admin and Sale surfaces share the same foundation while retaining
/// their operational status semantics.
@immutable
class AppColors {
  const AppColors._();

  // NaBi Blue Wellness brand.
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1746A2);
  static const Color primaryLight = Color(0xFF6EA8FE);
  static const Color primarySoft = Color(0xFFE8F1FF);
  static const Color primarySubtle = Color(0xFFF4F8FF);

  // Supporting accents. They never compete with the dominant blue.
  static const Color secondary = Color(0xFF38A9E8);
  static const Color secondaryDark = Color(0xFF1977A8);
  static const Color secondaryLight = Color(0xFF9DDCF5);
  static const Color secondarySoft = Color(0xFFE7F6FD);
  static const Color tertiary = Color(0xFF8174E8);
  static const Color tertiarySoft = Color(0xFFF0EDFF);
  static const Color clinicalNavy = Color(0xFF102A43);
  static const Color wellnessMint = primary;

  static const Color energyYellow = Color(0xFFFFC857);
  static const Color calmBlue = secondary;
  static const Color careCoral = Color(0xFFFF7D75);
  static const Color personalPurple = tertiary;

  // Semantic status. Success intentionally remains green.
  static const Color success = Color(0xFF14885F);
  static const Color successSoft = Color(0xFFE0F6EB);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningDark = Color(0xFF8D5A17);
  static const Color warningSoft = Color(0xFFFFF3D6);
  static const Color error = Color(0xFFC64A4A);
  static const Color errorSoft = Color(0xFFFDE8E7);
  static const Color info = Color(0xFF247CA8);
  static const Color infoSoft = Color(0xFFE3F3FB);
  static const Color danger = error;
  static const Color dangerSoft = errorSoft;

  // Calm category surfaces.
  static const Color pastelBlue = Color(0xFFE8F1FF);
  static const Color pastelSky = Color(0xFFEDF7FF);
  static const Color pastelMint = Color(0xFFE8F7F4);
  static const Color pastelLavender = Color(0xFFF0EDFF);
  static const Color pastelRose = Color(0xFFFDEDEC);
  static const Color pastelAmber = Color(0xFFFFF3D6);
  static const Color pastelPeach = Color(0xFFFFEEE8);

  // Light surfaces.
  static const Color background = Color(0xFFF7FAFF);
  static const Color scaffold = background;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F8FF);
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFFBFDFF);
  static const Color inputBackground = Color(0xFFFCFDFF);

  // Dark-capable tokens. Dark mode is not enabled globally by this refactor.
  static const Color darkBackground = Color(0xFF07172B);
  static const Color darkScaffold = Color(0xFF061326);
  static const Color darkSurface = Color(0xFF0D223D);
  static const Color darkSurfaceElevated = Color(0xFF123052);
  static const Color darkModalBackground = darkSurface;
  static const Color darkCard = darkSurfaceElevated;
  static const Color darkCardAlt = Color(0xFF102945);
  static const Color darkInputBackground = Color(0xFF0B1D34);

  // Text hierarchy.
  static const Color textPrimary = Color(0xFF15253D);
  static const Color textSecondary = Color(0xFF5B6B82);
  static const Color textMuted = Color(0xFF8796AA);
  static const Color textHint = Color(0xFFA4B0C0);
  static const Color textDisabled = Color(0xFFB7C1CE);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textWhite = textInverse;

  static const Color darkTextPrimary = Color(0xFFF4F8FF);
  static const Color darkTextSecondary = Color(0xFFC7D4E5);
  static const Color darkTextMuted = Color(0xFF91A4BC);
  static const Color darkTextHint = Color(0xFF7890AC);
  static const Color darkTextDisabled = Color(0xFF56708E);
  static const Color darkTextInverse = textPrimary;

  // Borders, dividers and focus.
  static const Color border = Color(0xFFDCE6F4);
  static const Color borderLight = Color(0xFFEBF1F8);
  static const Color divider = Color(0xFFE4ECF6);
  static const Color outline = Color(0xFFB8C8DC);
  static const Color focusRing = Color(0xFF7DB2FF);

  static const Color darkBorder = Color(0xFF315678);
  static const Color darkBorderLight = Color(0xFF244766);
  static const Color darkDivider = Color(0xFF294D6C);
  static const Color darkOutline = Color(0xFF4D7193);

  // States and overlays.
  static const Color overlay = Color(0x52102A43);
  static const Color overlayStrong = Color(0x80102A43);
  static const Color scrim = Color(0x66102A43);
  static const Color hover = Color(0x122F6FED);
  static const Color pressed = Color(0x242F6FED);
  static const Color focused = Color(0x2E2F6FED);
  static const Color selected = Color(0x1A2F6FED);
  static const Color disabled = Color(0xFFDDE5EF);

  static const Color darkOverlay = Color(0x99000000);
  static const Color darkHover = Color(0x246EA8FE);
  static const Color darkPressed = Color(0x336EA8FE);
  static const Color darkFocused = Color(0x446EA8FE);
  static const Color darkSelected = Color(0x2B6EA8FE);
  static const Color darkDisabled = Color(0xFF315678);

  // Navigation and icon colors.
  static const Color icon = Color(0xFF5B6B82);
  static const Color iconSecondary = Color(0xFF8796AA);
  static const Color iconDisabled = textDisabled;
  static const Color darkIcon = darkTextSecondary;
  static const Color darkIconSecondary = darkTextMuted;
  static const Color darkIconDisabled = darkTextDisabled;

  // Backward-compatible gradients.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF245CC5), Color(0xFF4D8DF7)],
  );
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6EA8FE), Color(0xFF2F6FED)],
  );
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6FED), Color(0xFF8174E8)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14885F), Color(0xFF42C98A)],
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

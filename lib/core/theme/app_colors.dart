import 'package:flutter/material.dart';

import 'app_theme_flags.dart';

/// Backward-compatible static facade for Nabi Blue Wellness.
///
/// New presentation code should prefer `AppSemanticColors` from the active
/// theme. These constants remain available while existing consumers migrate.
@immutable
class AppColors {
  const AppColors._();

  static const bool stitchGreenUiEnabled = AppThemeFlags.stitchGreenUiEnabled;

  // Nabi Blue Wellness brand. Green remains a wellness/success accent.
  static const Color primary = stitchGreenUiEnabled
      ? Color(0xFF006A46)
      : Color(0xFF2F6FED);
  static const Color primaryDark = stitchGreenUiEnabled
      ? Color(0xFF075E45)
      : Color(0xFF1746A2);
  static const Color primaryLight = stitchGreenUiEnabled
      ? Color(0xFF62DDA3)
      : Color(0xFF6EA8FE);
  static const Color primarySoft = stitchGreenUiEnabled
      ? Color(0xFFDDF6E9)
      : Color(0xFFE8F1FF);
  static const Color primarySubtle = stitchGreenUiEnabled
      ? Color(0xFFEAF9F1)
      : Color(0xFFF4F8FF);
  static const Color brandAccent = stitchGreenUiEnabled
      ? Color(0xFF14A36F)
      : Color(0xFF14A36F);
  static const Color ctaStart = stitchGreenUiEnabled
      ? Color(0xFF0F8E62)
      : Color(0xFF245CC5);
  static const Color ctaEnd = stitchGreenUiEnabled
      ? Color(0xFF32C789)
      : Color(0xFF4D8DF7);

  // Supporting accents. Green is the health/leaf accent under Blue Wellness.
  static const Color secondary = stitchGreenUiEnabled
      ? Color(0xFF58B9E8)
      : Color(0xFF14A36F);
  static const Color secondaryDark = stitchGreenUiEnabled
      ? Color(0xFF247CA8)
      : Color(0xFF0F6F4D);
  static const Color secondaryLight = stitchGreenUiEnabled
      ? Color(0xFF9DDCF5)
      : Color(0xFF62DDA3);
  static const Color secondarySoft = stitchGreenUiEnabled
      ? Color(0xFFE7F6FD)
      : Color(0xFFE0F6EB);
  static const Color tertiary = stitchGreenUiEnabled
      ? Color(0xFF8B7CF6)
      : Color(0xFF8174E8);
  static const Color tertiarySoft = Color(0xFFF0EDFF);
  static const Color clinicalNavy = stitchGreenUiEnabled
      ? Color(0xFF12352A)
      : Color(0xFF102A43);
  static const Color wellnessGreen = Color(0xFF14A36F);
  static const Color wellnessGreenDark = Color(0xFF0F6F4D);
  static const Color wellnessGreenLight = Color(0xFF62DDA3);
  static const Color wellnessGreenSoft = Color(0xFFE0F6EB);
  static const Color wellnessMint = wellnessGreen;

  static const Color energyYellow = Color(0xFFFFC857);
  static const Color calmBlue = Color(0xFF38A9E8);
  static const Color careCoral = Color(0xFFFF7D75);
  static const Color personalPurple = tertiary;
  static const Color nabiSkinTint = Color(0xFFFDE8E7);
  static const Color nabiHighlight = Color(0xFFFFFFFF);

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
  static const Color pastelBlue = stitchGreenUiEnabled
      ? Color(0xFFE7F6FD)
      : Color(0xFFE8F1FF);
  static const Color pastelSky = Color(0xFFEDF7FF);
  static const Color pastelMint = stitchGreenUiEnabled
      ? Color(0xFFEAF9F1)
      : Color(0xFFE8F7F4);
  static const Color pastelLavender = Color(0xFFF0EDFF);
  static const Color pastelRose = Color(0xFFFDEDEC);
  static const Color pastelAmber = Color(0xFFFFF3D6);
  static const Color pastelPeach = Color(0xFFFFEEE8);

  // Light surfaces.
  static const Color background = stitchGreenUiEnabled
      ? Color(0xFFF5FAF7)
      : Color(0xFFF7FAFF);
  static const Color scaffold = background;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSoft = stitchGreenUiEnabled
      ? Color(0xFFEAF9F1)
      : Color(0xFFF4F8FF);
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = stitchGreenUiEnabled
      ? Color(0xFFF0F5F2)
      : Color(0xFFFBFDFF);
  static const Color inputBackground = stitchGreenUiEnabled
      ? Color(0xFFFFFFFF)
      : Color(0xFFFCFDFF);

  // Frozen Blue Wellness dark defaults with a retained Green rollback branch.
  static const Color darkBackground = stitchGreenUiEnabled
      ? Color(0xFF0E1512)
      : Color(0xFF07172B);
  static const Color darkScaffold = darkBackground;
  static const Color darkSurface = stitchGreenUiEnabled
      ? Color(0xFF171D1B)
      : Color(0xFF0D223D);
  static const Color darkSurfaceElevated = stitchGreenUiEnabled
      ? Color(0xFF202724)
      : Color(0xFF123052);
  static const Color darkModalBackground = darkSurface;
  static const Color darkCard = darkSurfaceElevated;
  static const Color darkCardAlt = stitchGreenUiEnabled
      ? Color(0xFF252C29)
      : Color(0xFF102945);
  static const Color darkInputBackground = stitchGreenUiEnabled
      ? Color(0xFF171D1B)
      : Color(0xFF0B1D34);

  // Text hierarchy.
  static const Color textPrimary = stitchGreenUiEnabled
      ? Color(0xFF12352A)
      : Color(0xFF15253D);
  static const Color textSecondary = stitchGreenUiEnabled
      ? Color(0xFF60766E)
      : Color(0xFF5B6B82);
  static const Color textMuted = stitchGreenUiEnabled
      ? Color(0xFF8A9B94)
      : Color(0xFF8796AA);
  static const Color textHint = stitchGreenUiEnabled
      ? Color(0xFF8A9B94)
      : Color(0xFFA4B0C0);
  static const Color textDisabled = stitchGreenUiEnabled
      ? Color(0xFFA8B5AF)
      : Color(0xFFB7C1CE);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textWhite = textInverse;

  static const Color darkTextPrimary = stitchGreenUiEnabled
      ? Color(0xFFDEE4E1)
      : Color(0xFFF4F8FF);
  static const Color darkTextSecondary = stitchGreenUiEnabled
      ? Color(0xFFBCCABF)
      : Color(0xFFC7D4E5);
  static const Color darkTextMuted = stitchGreenUiEnabled
      ? Color(0xFF8F9D95)
      : Color(0xFF91A4BC);
  static const Color darkTextHint = darkTextMuted;
  static const Color darkTextDisabled = stitchGreenUiEnabled
      ? Color(0xFF66736C)
      : Color(0xFF56708E);
  static const Color darkTextInverse = textPrimary;

  // Borders, dividers and focus.
  static const Color border = stitchGreenUiEnabled
      ? Color(0xFFD9E9E1)
      : Color(0xFFDCE6F4);
  static const Color borderLight = stitchGreenUiEnabled
      ? Color(0xFFE4E9E6)
      : Color(0xFFEBF1F8);
  static const Color divider = stitchGreenUiEnabled
      ? Color(0xFFDEE4E1)
      : Color(0xFFE4ECF6);
  static const Color outline = stitchGreenUiEnabled
      ? Color(0xFF6D7A71)
      : Color(0xFFB8C8DC);
  static const Color focusRing = stitchGreenUiEnabled
      ? Color(0xFF68D9A5)
      : Color(0xFF7DB2FF);

  static const Color darkBorder = stitchGreenUiEnabled
      ? Color(0xFF89978F)
      : Color(0xFF315678);
  static const Color darkBorderLight = stitchGreenUiEnabled
      ? Color(0xFF3F4A44)
      : Color(0xFF244766);
  static const Color darkDivider = stitchGreenUiEnabled
      ? Color(0xFF3F4A44)
      : Color(0xFF294D6C);
  static const Color darkOutline = stitchGreenUiEnabled
      ? Color(0xFF89978F)
      : Color(0xFF4D7193);

  // States and overlays.
  static const Color overlay = stitchGreenUiEnabled
      ? Color(0x5212352A)
      : Color(0x52102A43);
  static const Color overlayGradient = stitchGreenUiEnabled
      ? Color(0x9912352A)
      : Color(0x99102A43);
  static const Color overlayTransparent = stitchGreenUiEnabled
      ? Color(0x0012352A)
      : Color(0x00102A43);
  static const Color overlayStrong = stitchGreenUiEnabled
      ? Color(0x8012352A)
      : Color(0x80102A43);
  static const Color shadow = stitchGreenUiEnabled
      ? Color(0x2412352A)
      : Color(0x24102A43);
  static const Color scrim = stitchGreenUiEnabled
      ? Color(0x6612352A)
      : Color(0x66102A43);
  static const Color hover = stitchGreenUiEnabled
      ? Color(0x12006A46)
      : Color(0x122F6FED);
  static const Color pressed = stitchGreenUiEnabled
      ? Color(0x24006A46)
      : Color(0x242F6FED);
  static const Color focused = stitchGreenUiEnabled
      ? Color(0x2E006A46)
      : Color(0x2E2F6FED);
  static const Color selected = stitchGreenUiEnabled
      ? Color(0x1A006A46)
      : Color(0x1A2F6FED);
  static const Color disabled = stitchGreenUiEnabled
      ? Color(0xFFDDE7E2)
      : Color(0xFFDDE5EF);

  static const Color darkOverlay = Color(0x99000000);
  static const Color darkHover = stitchGreenUiEnabled
      ? Color(0x2462DDA3)
      : Color(0x246EA8FE);
  static const Color darkPressed = stitchGreenUiEnabled
      ? Color(0x3362DDA3)
      : Color(0x336EA8FE);
  static const Color darkFocused = stitchGreenUiEnabled
      ? Color(0x4462DDA3)
      : Color(0x446EA8FE);
  static const Color darkSelected = stitchGreenUiEnabled
      ? Color(0x2B62DDA3)
      : Color(0x2B6EA8FE);
  static const Color darkDisabled = stitchGreenUiEnabled
      ? Color(0xFF3F4A44)
      : Color(0xFF315678);

  // Navigation and icon colors.
  static const Color icon = textSecondary;
  static const Color iconSecondary = textMuted;
  static const Color iconDisabled = textDisabled;
  static const Color darkIcon = darkTextSecondary;
  static const Color darkIconSecondary = darkTextMuted;
  static const Color darkIconDisabled = darkTextDisabled;

  // Backward-compatible gradients.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ctaStart, ctaEnd],
  );
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primary],
  );
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, tertiary],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, wellnessGreen],
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

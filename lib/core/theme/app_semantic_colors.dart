import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_flags.dart';

/// Context-aware Blue Wellness colors used by presentation code.
///
/// [AppColors] remains the compatibility facade for legacy consumers. New UI
/// should read this extension from `Theme.of(context)` so light and dark modes
/// resolve the same semantic role to the correct value.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySoft,
    required this.primarySubtle,
    required this.brandAccent,
    required this.ctaStart,
    required this.ctaEnd,
    required this.secondary,
    required this.secondaryDark,
    required this.secondaryLight,
    required this.secondarySoft,
    required this.tertiary,
    required this.tertiarySoft,
    required this.clinicalNavy,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.info,
    required this.infoSoft,
    required this.background,
    required this.surface,
    required this.card,
    required this.cardAlt,
    required this.surfaceSoft,
    required this.inputBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textHint,
    required this.textInverse,
    required this.onBrand,
    required this.border,
    required this.borderLight,
    required this.divider,
    required this.outline,
    required this.focusRing,
    required this.hover,
    required this.pressed,
    required this.focused,
    required this.disabled,
    required this.icon,
    required this.scrim,
  });

  static const Color seed = AppColors.primary;

  /// Active compile-time light palette. Blue Wellness is the default.
  static const AppSemanticColors light = AppSemanticColors(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    primarySoft: AppColors.primarySoft,
    primarySubtle: AppColors.primarySubtle,
    brandAccent: AppColors.brandAccent,
    ctaStart: AppColors.ctaStart,
    ctaEnd: AppColors.ctaEnd,
    secondary: AppColors.secondary,
    secondaryDark: AppColors.secondaryDark,
    secondaryLight: AppColors.secondaryLight,
    secondarySoft: AppColors.secondarySoft,
    tertiary: AppColors.tertiary,
    tertiarySoft: AppColors.tertiarySoft,
    clinicalNavy: AppColors.clinicalNavy,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    error: AppColors.error,
    errorSoft: AppColors.errorSoft,
    info: AppColors.info,
    infoSoft: AppColors.infoSoft,
    background: AppColors.background,
    surface: AppColors.surface,
    card: AppColors.card,
    cardAlt: AppColors.cardAlt,
    surfaceSoft: AppColors.surfaceSoft,
    inputBackground: AppColors.inputBackground,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textHint: AppColors.textHint,
    textInverse: AppColors.textInverse,
    onBrand: AppColors.textInverse,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    divider: AppColors.divider,
    outline: AppColors.outline,
    focusRing: AppColors.focusRing,
    hover: AppColors.hover,
    pressed: AppColors.pressed,
    focused: AppColors.focused,
    disabled: AppColors.disabled,
    icon: AppColors.icon,
    scrim: AppColors.scrim,
  );

  /// Literal Material 3 fidelity snapshots generated from the Blue default
  /// and retained Green compatibility seeds.
  ///
  /// Keeping the generated values in source prevents an SDK algorithm update
  /// from silently changing production colors or golden screenshots.
  static const ColorScheme darkColorScheme = AppThemeFlags.stitchGreenUiEnabled
      ? _greenDarkColorScheme
      : _blueDarkColorScheme;

  static const ColorScheme _greenDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF82D8AB),
    onPrimary: Color(0xFF003823),
    primaryContainer: Color(0xFF006A46),
    onPrimaryContainer: Color(0xFFFFFFFF),
    primaryFixed: Color(0xFF9EF4C6),
    primaryFixedDim: Color(0xFF82D8AB),
    onPrimaryFixed: Color(0xFF002113),
    onPrimaryFixedVariant: Color(0xFF005235),
    secondary: Color(0xFFACCEB9),
    onSecondary: Color(0xFF183627),
    secondaryContainer: Color(0xFF314F3F),
    onSecondaryContainer: Color(0xFFC9ECD6),
    secondaryFixed: Color(0xFFC8EBD4),
    secondaryFixedDim: Color(0xFFACCEB9),
    onSecondaryFixed: Color(0xFF022113),
    onSecondaryFixedVariant: Color(0xFF2F4D3D),
    tertiary: Color(0xFFFFB3AF),
    onTertiary: Color(0xFF5B191A),
    tertiaryContainer: Color(0xFF934442),
    onTertiaryContainer: Color(0xFFFFFFFF),
    tertiaryFixed: Color(0xFFFFDAD7),
    tertiaryFixedDim: Color(0xFFFFB3AF),
    onTertiaryFixed: Color(0xFF3E0408),
    onTertiaryFixedVariant: Color(0xFF782F2E),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF101411),
    onSurface: Color(0xFFDFE4DE),
    surfaceDim: Color(0xFF101411),
    surfaceBright: Color(0xFF363A37),
    surfaceContainerLowest: Color(0xFF0B0F0C),
    surfaceContainerLow: Color(0xFF181D1A),
    surfaceContainer: Color(0xFF1C211D),
    surfaceContainerHigh: Color(0xFF262B28),
    surfaceContainerHighest: Color(0xFF313632),
    onSurfaceVariant: Color(0xFFBEC9C0),
    outline: Color(0xFF88938B),
    outlineVariant: Color(0xFF3F4942),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFDFE4DE),
    onInverseSurface: Color(0xFF2D312E),
    inversePrimary: Color(0xFF056C48),
    surfaceTint: Color(0xFF82D8AB),
  );

  static const ColorScheme _blueDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB1C5FF),
    onPrimary: Color(0xFF002C72),
    primaryContainer: Color(0xFF2F6FED),
    onPrimaryContainer: Color(0xFFFFFFFF),
    primaryFixed: Color(0xFFDAE2FF),
    primaryFixedDim: Color(0xFFB1C5FF),
    onPrimaryFixed: Color(0xFF001847),
    onPrimaryFixedVariant: Color(0xFF0040A0),
    secondary: Color(0xFFB2C5FF),
    onSecondary: Color(0xFF192E5E),
    secondaryContainer: Color(0xFF344779),
    onSecondaryContainer: Color(0xFFDCE3FF),
    secondaryFixed: Color(0xFFDAE2FF),
    secondaryFixedDim: Color(0xFFB2C5FF),
    onSecondaryFixed: Color(0xFF001847),
    onSecondaryFixedVariant: Color(0xFF314576),
    tertiary: Color(0xFFFFB691),
    onTertiary: Color(0xFF552000),
    tertiaryContainer: Color(0xFFC45400),
    onTertiaryContainer: Color(0xFFFFFFFF),
    tertiaryFixed: Color(0xFFFFDBCB),
    tertiaryFixedDim: Color(0xFFFFB691),
    onTertiaryFixed: Color(0xFF341100),
    onTertiaryFixedVariant: Color(0xFF793100),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF11131B),
    onSurface: Color(0xFFE1E2ED),
    surfaceDim: Color(0xFF11131B),
    surfaceBright: Color(0xFF373941),
    surfaceContainerLowest: Color(0xFF0C0E15),
    surfaceContainerLow: Color(0xFF191B23),
    surfaceContainer: Color(0xFF1D1F27),
    surfaceContainerHigh: Color(0xFF272A32),
    surfaceContainerHighest: Color(0xFF32343D),
    onSurfaceVariant: Color(0xFFC2C6D7),
    outline: Color(0xFF8C90A0),
    outlineVariant: Color(0xFF424654),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E2ED),
    onInverseSurface: Color(0xFF2E3038),
    inversePrimary: Color(0xFF0056D0),
    surfaceTint: Color(0xFFB1C5FF),
  );

  static final AppSemanticColors greenDark = _fromDarkScheme(
    _greenDarkColorScheme,
    brandAccent: const Color(0xFF14A36F),
    ctaStart: const Color(0xFF0F8E62),
    ctaEnd: const Color(0xFF32C789),
  );

  static final AppSemanticColors blueDark = _fromDarkScheme(
    _blueDarkColorScheme,
    brandAccent: const Color(0xFF14A36F),
    ctaStart: const Color(0xFF245CC5),
    ctaEnd: const Color(0xFF4D8DF7),
  );

  @Deprecated('Use blueDark; Blue Wellness is no longer a rollback palette.')
  static final AppSemanticColors legacyBlueDark = blueDark;

  static final AppSemanticColors dark = AppThemeFlags.stitchGreenUiEnabled
      ? greenDark
      : blueDark;

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySoft;
  final Color primarySubtle;
  final Color brandAccent;
  final Color ctaStart;
  final Color ctaEnd;
  final Color secondary;
  final Color secondaryDark;
  final Color secondaryLight;
  final Color secondarySoft;
  final Color tertiary;
  final Color tertiarySoft;
  final Color clinicalNavy;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color info;
  final Color infoSoft;
  final Color background;
  final Color surface;
  final Color card;
  final Color cardAlt;
  final Color surfaceSoft;
  final Color inputBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textHint;

  /// Foreground for a theme-derived primary fill.
  final Color textInverse;

  /// Deterministic foreground for fixed, dark brand artwork and gradients.
  /// It must not inherit Material's dark [ColorScheme.onPrimary], which is a
  /// dark color intended for the scheme's light primary tone.
  final Color onBrand;
  final Color border;
  final Color borderLight;
  final Color divider;
  final Color outline;
  final Color focusRing;
  final Color hover;
  final Color pressed;
  final Color focused;
  final Color disabled;
  final Color icon;
  final Color scrim;

  static AppSemanticColors _fromDarkScheme(
    ColorScheme scheme, {
    required Color brandAccent,
    required Color ctaStart,
    required Color ctaEnd,
  }) {
    return AppSemanticColors(
      primary: scheme.primary,
      primaryDark: scheme.onPrimaryContainer,
      primaryLight: scheme.primaryFixedDim,
      primarySoft: scheme.primaryContainer,
      primarySubtle: scheme.surfaceContainerHigh,
      brandAccent: brandAccent,
      ctaStart: ctaStart,
      ctaEnd: ctaEnd,
      secondary: scheme.secondary,
      secondaryDark: scheme.onSecondaryContainer,
      secondaryLight: scheme.secondaryFixedDim,
      secondarySoft: scheme.secondaryContainer,
      tertiary: scheme.tertiary,
      tertiarySoft: scheme.tertiaryContainer,
      clinicalNavy: scheme.inverseSurface,
      // Success remains green under both the Blue default and Green rollback.
      success: const Color(0xFF82D8AB),
      successSoft: const Color(0xFF164C37),
      warning: const Color(0xFFF4C77A),
      warningSoft: const Color(0xFF554519),
      error: scheme.error,
      errorSoft: scheme.errorContainer,
      info: const Color(0xFF8DD5F5),
      infoSoft: const Color(0xFF123D50),
      background: scheme.surface,
      surface: scheme.surface,
      card: scheme.surfaceContainerLow,
      cardAlt: scheme.surfaceContainer,
      surfaceSoft: scheme.surfaceContainerHigh,
      inputBackground: scheme.surfaceContainerLowest,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      textMuted: scheme.onSurfaceVariant.withValues(alpha: .78),
      textHint: scheme.onSurfaceVariant.withValues(alpha: .68),
      textInverse: scheme.onPrimary,
      onBrand: AppColors.textInverse,
      border: scheme.outlineVariant,
      borderLight: scheme.outlineVariant.withValues(alpha: .72),
      divider: scheme.outlineVariant.withValues(alpha: .62),
      outline: scheme.outline,
      focusRing: scheme.primary,
      hover: scheme.primary.withValues(alpha: .10),
      pressed: scheme.primary.withValues(alpha: .18),
      focused: scheme.primary.withValues(alpha: .22),
      disabled: scheme.onSurface.withValues(alpha: .12),
      icon: scheme.onSurfaceVariant,
      scrim: scheme.scrim,
    );
  }

  @override
  AppSemanticColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primarySoft,
    Color? primarySubtle,
    Color? brandAccent,
    Color? ctaStart,
    Color? ctaEnd,
    Color? secondary,
    Color? secondaryDark,
    Color? secondaryLight,
    Color? secondarySoft,
    Color? tertiary,
    Color? tertiarySoft,
    Color? clinicalNavy,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? info,
    Color? infoSoft,
    Color? background,
    Color? surface,
    Color? card,
    Color? cardAlt,
    Color? surfaceSoft,
    Color? inputBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textHint,
    Color? textInverse,
    Color? onBrand,
    Color? border,
    Color? borderLight,
    Color? divider,
    Color? outline,
    Color? focusRing,
    Color? hover,
    Color? pressed,
    Color? focused,
    Color? disabled,
    Color? icon,
    Color? scrim,
  }) {
    return AppSemanticColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySoft: primarySoft ?? this.primarySoft,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      brandAccent: brandAccent ?? this.brandAccent,
      ctaStart: ctaStart ?? this.ctaStart,
      ctaEnd: ctaEnd ?? this.ctaEnd,
      secondary: secondary ?? this.secondary,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      tertiary: tertiary ?? this.tertiary,
      tertiarySoft: tertiarySoft ?? this.tertiarySoft,
      clinicalNavy: clinicalNavy ?? this.clinicalNavy,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      inputBackground: inputBackground ?? this.inputBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      textInverse: textInverse ?? this.textInverse,
      onBrand: onBrand ?? this.onBrand,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      divider: divider ?? this.divider,
      outline: outline ?? this.outline,
      focusRing: focusRing ?? this.focusRing,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      focused: focused ?? this.focused,
      disabled: disabled ?? this.disabled,
      icon: icon ?? this.icon,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      ctaStart: Color.lerp(ctaStart, other.ctaStart, t)!,
      ctaEnd: Color.lerp(ctaEnd, other.ctaEnd, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryDark: Color.lerp(secondaryDark, other.secondaryDark, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiarySoft: Color.lerp(tertiarySoft, other.tertiarySoft, t)!,
      clinicalNavy: Color.lerp(clinicalNavy, other.clinicalNavy, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
      focused: Color.lerp(focused, other.focused, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
  }
}

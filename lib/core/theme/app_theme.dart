import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_duration.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'app_theme_flags.dart';

class AppTheme {
  const AppTheme._();

  static const bool stitchGreenUiEnabled = AppThemeFlags.stitchGreenUiEnabled;

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textInverse,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textInverse,
      secondaryContainer: AppColors.secondarySoft,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.textInverse,
      tertiaryContainer: AppColors.tertiarySoft,
      onTertiaryContainer: AppColors.tertiary,
      error: AppColors.error,
      onError: AppColors.textInverse,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.cardAlt,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.borderLight,
      shadow: Color(0x2412352A),
      scrim: AppColors.scrim,
      inverseSurface: AppColors.primaryDark,
      onInverseSurface: AppColors.textInverse,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      focusColor: AppColors.focused,
      hoverColor: AppColors.hover,
      highlightColor: AppColors.pressed,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: const VisualDensity(horizontal: -0.5, vertical: -0.5),
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      headlineSmall: AppTextStyles.heading3,
      titleLarge: AppTextStyles.heading4,
      titleMedium: AppTextStyles.heading5,
      titleSmall: AppTextStyles.labelLarge,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );

    final defaultShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    final interactiveShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.light],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: colorScheme,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: AppColors.borderLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        titleTextStyle: AppTextStyles.appBarTitle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x1212352A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        titleTextStyle: AppTextStyles.heading3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        modalBackgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.xl),
          ),
          side: BorderSide(color: AppColors.borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.icon, size: 22),
      primaryIconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 22,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          iconSize: const WidgetStatePropertyAll(20),
          foregroundColor: const WidgetStatePropertyAll(AppColors.icon),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.pressed;
            if (states.contains(WidgetState.hovered)) return AppColors.hover;
            if (states.contains(WidgetState.focused)) return AppColors.focused;
            return Colors.transparent;
          }),
          shape: WidgetStatePropertyAll(interactiveShape),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minLeadingWidth: 32,
        minTileHeight: 48,
        iconColor: AppColors.icon,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        titleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.listTilePaddingHorizontal,
          vertical: AppSpacing.listTilePaddingVertical,
        ),
        shape: defaultShape,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: .18),
        selectionHandleColor: AppColors.primary,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textInverse,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
        circularTrackColor: AppColors.primarySoft,
        linearMinHeight: 5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingHorizontal,
          vertical: AppSpacing.inputPaddingVertical,
        ),
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: AppTextStyles.helper,
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.icon,
        suffixIconColor: AppColors.icon,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.8),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.8),
        disabledBorder: _inputBorder(AppColors.borderLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.primary,
          foreground: AppColors.textInverse,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          background: AppColors.primary,
          foreground: AppColors.textInverse,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingHorizontal,
              vertical: AppSpacing.buttonPaddingVertical,
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryDark),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.pressed;
            if (states.contains(WidgetState.hovered)) return AppColors.hover;
            return AppColors.surface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? AppColors.border
                : AppColors.primary.withValues(alpha: .46);
            return BorderSide(color: color, width: 1.2);
          }),
          textStyle: WidgetStatePropertyAll(AppTextStyles.buttonText),
          shape: WidgetStatePropertyAll(interactiveShape),
          overlayColor: const WidgetStatePropertyAll(AppColors.pressed),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryDark),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(interactiveShape),
          overlayColor: const WidgetStatePropertyAll(AppColors.pressed),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.clinicalNavy,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textInverse,
        ),
        actionTextColor: AppColors.primaryLight,
        closeIconColor: AppColors.textInverse,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.sm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryDark : AppColors.icon,
            size: selected ? 23 : 21,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.primaryDark : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.icon,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.icon),
        selectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primaryDark,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        overlayColor: const WidgetStatePropertyAll(AppColors.hover),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.surfaceSoft,
        checkmarkColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelStyle: AppTextStyles.chipLabel,
        secondaryLabelStyle: AppTextStyles.chipLabel.copyWith(
          color: AppColors.primaryDark,
        ),
        shape: const StadiumBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        side: const BorderSide(color: AppColors.outline, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.textInverse),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textInverse;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.outline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primarySoft,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.focused,
        valueIndicatorColor: AppColors.primaryDark,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textInverse,
        ),
        trackHeight: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primarySoft,
        headerForegroundColor: AppColors.primaryDark,
        dayForegroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        todayForegroundColor: const WidgetStatePropertyAll(
          AppColors.primaryDark,
        ),
        todayBorder: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteColor: AppColors.primarySoft,
        hourMinuteTextColor: AppColors.primaryDark,
        dialBackgroundColor: AppColors.cardAlt,
        dialHandColor: AppColors.primary,
        entryModeIconColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textHint.withValues(alpha: .55),
        ),
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(AppRadius.circular),
        crossAxisMargin: 3,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final colors = AppSemanticColors.dark;
    final colorScheme = AppSemanticColors.darkColorScheme.copyWith(
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      cardColor: colors.card,
      dividerColor: colors.divider,
      focusColor: colors.focused,
      hoverColor: colors.hover,
      highlightColor: colors.pressed,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: const VisualDensity(horizontal: -0.5, vertical: -0.5),
    );
    final textTheme = base.textTheme
        .copyWith(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          displaySmall: AppTextStyles.displaySmall,
          headlineLarge: AppTextStyles.heading1,
          headlineMedium: AppTextStyles.heading2,
          headlineSmall: AppTextStyles.heading3,
          titleLarge: AppTextStyles.heading4,
          titleMedium: AppTextStyles.heading5,
          titleSmall: AppTextStyles.labelLarge,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        )
        .apply(
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
          decorationColor: colors.textPrimary,
        );
    final interactiveShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: colorScheme,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: colors.surface,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: colors.borderLight,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: .26),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.borderLight),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: BorderSide(color: colors.borderLight),
        ),
        titleTextStyle: AppTextStyles.heading3.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        modalBackgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(AppRadius.xl),
          ),
          side: BorderSide(color: colors.borderLight),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.icon, size: 22),
      primaryIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          iconSize: const WidgetStatePropertyAll(20),
          foregroundColor: WidgetStatePropertyAll(colors.icon),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return colors.pressed;
            if (states.contains(WidgetState.hovered)) return colors.hover;
            if (states.contains(WidgetState.focused)) return colors.focused;
            return Colors.transparent;
          }),
          shape: WidgetStatePropertyAll(interactiveShape),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minLeadingWidth: 32,
        minTileHeight: 48,
        iconColor: colors.icon,
        textColor: colors.textPrimary,
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: colors.textSecondary,
        ),
        titleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.listTilePaddingHorizontal,
          vertical: AppSpacing.listTilePaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: .24),
        selectionHandleColor: colors.primary,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.primarySoft,
        circularTrackColor: colors.primarySoft,
        linearMinHeight: 5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingHorizontal,
          vertical: AppSpacing.inputPaddingVertical,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(color: colors.textHint),
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: colors.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: AppTextStyles.helper.copyWith(color: colors.textSecondary),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: colors.error),
        prefixIconColor: colors.icon,
        suffixIconColor: colors.icon,
        border: _inputBorder(colors.border),
        enabledBorder: _inputBorder(colors.border),
        focusedBorder: _inputBorder(colors.primary, width: 1.8),
        errorBorder: _inputBorder(colors.error),
        focusedErrorBorder: _inputBorder(colors.error, width: 1.8),
        disabledBorder: _inputBorder(colors.borderLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _darkFilledButtonStyle(colors),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _darkFilledButtonStyle(colors),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingHorizontal,
              vertical: AppSpacing.buttonPaddingVertical,
            ),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.primary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return colors.pressed;
            if (states.contains(WidgetState.hovered)) return colors.hover;
            return colors.surface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? colors.border
                  : colors.primary.withValues(alpha: .60),
              width: 1.2,
            );
          }),
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.buttonText.copyWith(color: colors.primary),
          ),
          shape: WidgetStatePropertyAll(interactiveShape),
          overlayColor: WidgetStatePropertyAll(colors.pressed),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppDuration.button,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStatePropertyAll(colors.primary),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(interactiveShape),
          overlayColor: WidgetStatePropertyAll(colors.pressed),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.textInverse,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        closeIconColor: colorScheme.onInverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.sm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.icon,
            size: selected ? 23 : 21,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.labelSmall.copyWith(
            color: selected ? colors.primary : colors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySoft,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.icon),
        selectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.primary,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.textMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        overlayColor: WidgetStatePropertyAll(colors.hover),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSoft,
        selectedColor: colors.primarySoft,
        disabledColor: colors.surfaceSoft,
        checkmarkColor: colors.primary,
        side: BorderSide(color: colors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelStyle: AppTextStyles.chipLabel.copyWith(color: colors.textPrimary),
        secondaryLabelStyle: AppTextStyles.chipLabel.copyWith(
          color: colors.primary,
        ),
        shape: const StadiumBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        side: BorderSide(color: colors.outline, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colors.textInverse),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textInverse;
          return colors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.outline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.primarySoft,
        thumbColor: colors.primary,
        overlayColor: colors.focused,
        valueIndicatorColor: colors.primarySoft,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.primaryDark,
        ),
        trackHeight: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.borderLight),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colors.primarySoft,
        headerForegroundColor: colors.primaryDark,
        dayForegroundColor: WidgetStatePropertyAll(colors.textPrimary),
        todayForegroundColor: WidgetStatePropertyAll(colors.primary),
        todayBorder: BorderSide(color: colors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: BorderSide(color: colors.borderLight),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.card,
        hourMinuteColor: colors.primarySoft,
        hourMinuteTextColor: colors.primaryDark,
        dialBackgroundColor: colors.cardAlt,
        dialHandColor: colors.primary,
        entryModeIconColor: colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: BorderSide(color: colors.borderLight),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          colors.textHint.withValues(alpha: .70),
        ),
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(AppRadius.circular),
        crossAxisMargin: 3,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ButtonStyle _darkFilledButtonStyle(AppSemanticColors colors) {
    return ButtonStyle(
      animationDuration: AppDuration.button,
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabled;
        if (states.contains(WidgetState.pressed)) return colors.primaryLight;
        return colors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.textMuted;
        return colors.textInverse;
      }),
      overlayColor: WidgetStatePropertyAll(colors.pressed),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(AppTextStyles.button),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }

  static ButtonStyle _filledButtonStyle({
    required Color background,
    required Color foreground,
  }) {
    return ButtonStyle(
      animationDuration: AppDuration.button,
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.disabled;
        if (states.contains(WidgetState.pressed)) return AppColors.primaryDark;
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
        return foreground;
      }),
      overlayColor: const WidgetStatePropertyAll(AppColors.pressed),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(AppTextStyles.button),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

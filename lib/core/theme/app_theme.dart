

import 'package:flutter/material.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';
import 'package:nano_app/core/constants/app/app_spacing.dart';
import 'package:nano_app/core/theme/app_colors.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final baseTheme = ThemeData.light();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      outline: AppColors.divider,
      surfaceTint: Colors.transparent,
    );

    return baseTheme.copyWith(
      useMaterial3: true,

      brightness: Brightness.light,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      indicatorColor: AppColors.primary,

      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,

      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,

        headlineLarge: AppTextStyles.heading1,
        headlineMedium: AppTextStyles.heading2,
        headlineSmall: AppTextStyles.heading3,

        titleLarge: AppTextStyles.heading4,
        titleMedium: AppTextStyles.heading5,

        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,

        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,

        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),

        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),

        titleTextStyle: AppTextStyles.heading3,
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),

        titleTextStyle: AppTextStyles.heading3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      primaryIconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withOpacity(0.18),
        selectionHandleColor: AppColors.primary,
      ),

      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),

        margin: const EdgeInsets.all(AppSpacing.sm),

        textStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
        ),

        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.divider,
        circularTrackColor: AppColors.divider,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),

        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),

        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),

        helperStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),

        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),

        border: _inputBorder(AppColors.divider),

        enabledBorder: _inputBorder(AppColors.divider),

        focusedBorder: _inputBorder(
          AppColors.primary,
          width: 1.5,
        ),

        errorBorder: _inputBorder(AppColors.error),

        focusedErrorBorder: _inputBorder(
          AppColors.error,
          width: 1.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),

          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),

          backgroundColor: const WidgetStatePropertyAll(
            AppColors.primary,
          ),

          foregroundColor: const WidgetStatePropertyAll(
            Colors.white,
          ),

          elevation: const WidgetStatePropertyAll(0),

          textStyle: WidgetStatePropertyAll(
            AppTextStyles.button,
          ),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppRadius.md,
              ),
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),

          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),

          foregroundColor: const WidgetStatePropertyAll(
            AppColors.primary,
          ),

          side: const WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.primary,
              width: 1.2,
            ),
          ),

          textStyle: WidgetStatePropertyAll(
            AppTextStyles.buttonText,
          ),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppRadius.md,
              ),
            ),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 44),
          ),

          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),

          foregroundColor: const WidgetStatePropertyAll(
            AppColors.primary,
          ),

          textStyle: WidgetStatePropertyAll(
            AppTextStyles.labelLarge,
          ),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppRadius.md,
              ),
            ),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,

        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.md,
          ),
        ),

        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android:
              FadeUpwardsPageTransitionsBuilder(),

          TargetPlatform.iOS:
              CupertinoPageTransitionsBuilder(),

          TargetPlatform.macOS:
              CupertinoPageTransitionsBuilder(),

          TargetPlatform.windows:
              ZoomPageTransitionsBuilder(),

          TargetPlatform.linux:
              ZoomPageTransitionsBuilder(),

          TargetPlatform.fuchsia:
              ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppRadius.md,
      ),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Theme dành riêng cho khu vực quản trị.
///
/// Phong cách lấy cảm hứng từ workspace của macOS: nền sáng, đường viền mảnh,
/// chiều sâu thấp, điều hướng rõ và mật độ thông tin cao. Theme này chỉ thay
/// đổi presentation; không ảnh hưởng quyền, dữ liệu hoặc nghiệp vụ.
abstract final class AdminWorkspaceTheme {
  static const Color canvas = Color(0xFFF3F6FA);
  static const Color sidebar = Color(0xFFF8FAFC);
  static const Color toolbar = Color(0xFFFDFEFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelMuted = Color(0xFFF7F9FC);
  static const Color selected = Color(0xFFE8F1FF);
  static const Color hover = Color(0xFFF0F5FC);
  static const Color divider = Color(0xFFDDE5EF);
  static const Color border = Color(0xFFD7E0EA);
  static const Color navy = Color(0xFF17324D);
  static const Color blue = Color(0xFF3478D4);
  static const Color blueDark = Color(0xFF245B9E);
  static const Color cyan = Color(0xFF2E9EB5);
  static const Color mint = Color(0xFF2F9E77);
  static const Color warning = Color(0xFFC47A19);
  static const Color danger = Color(0xFFC8464D);
  static const Color text = Color(0xFF1C2B3A);
  static const Color textSecondary = Color(0xFF5F7183);
  static const Color textMuted = Color(0xFF8796A5);

  static const double sidebarWidth = 248;
  static const double compactSidebarWidth = 76;
  static const double contentMaxWidth = 1240;
  static const double panelRadius = 14;
  static const double controlRadius = 10;

  static ThemeData light(ThemeData base) {
    const scheme = ColorScheme.light(
      primary: blue,
      onPrimary: Colors.white,
      primaryContainer: selected,
      onPrimaryContainer: navy,
      secondary: cyan,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE3F5F8),
      onSecondaryContainer: navy,
      tertiary: mint,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE5F6EF),
      onTertiaryContainer: Color(0xFF185B45),
      error: danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFBEAEC),
      onErrorContainer: Color(0xFF8E2830),
      surface: panel,
      onSurface: text,
      surfaceContainerHighest: panelMuted,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: divider,
      shadow: Color(0x1A17324D),
      scrim: Color(0x66132435),
      inverseSurface: navy,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFFAECDF4),
      surfaceTint: Colors.transparent,
    );

    final compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(panelRadius),
      side: const BorderSide(color: border),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: panel,
      dividerColor: divider,
      hoverColor: hover,
      focusColor: selected,
      highlightColor: selected,
      splashFactory: InkRipple.splashFactory,
      visualDensity: const VisualDensity(horizontal: -0.8, vertical: -0.8),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: toolbar,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 58,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1217324D),
        shape: panelShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x2417324D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: AppTextStyles.heading3.copyWith(color: text),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
          side: BorderSide(color: divider),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: sidebar,
        indicatorColor: selected,
        elevation: 0,
        selectedIconTheme: const IconThemeData(color: blueDark, size: 22),
        unselectedIconTheme: const IconThemeData(color: textSecondary, size: 21),
        selectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: textSecondary,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: panel,
        isDense: true,
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(blue, width: 1.6),
        errorBorder: _inputBorder(danger),
        focusedErrorBorder: _inputBorder(danger, width: 1.6),
        disabledBorder: _inputBorder(divider),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textMuted),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: blueDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          minimumSize: const WidgetStatePropertyAll(Size(48, 42)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return divider;
            }
            if (states.contains(WidgetState.pressed)) {
              return blueDark;
            }
            return blue;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(compactShape),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          minimumSize: const WidgetStatePropertyAll(Size(48, 42)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          ),
          foregroundColor: const WidgetStatePropertyAll(navy),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return hover;
            }
            return panel;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(compactShape),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 120),
          minimumSize: const WidgetStatePropertyAll(Size(42, 42)),
          foregroundColor: const WidgetStatePropertyAll(textSecondary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return hover;
            }
            return Colors.transparent;
          }),
          shape: WidgetStatePropertyAll(compactShape),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFFB9D7FF),
        closeIconColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        waitDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

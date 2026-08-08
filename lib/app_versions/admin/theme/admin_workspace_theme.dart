import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Semantic palette for the independent Admin workspace.
///
/// Admin deliberately keeps its blue/cyan/mint operational identity instead
/// of inheriting the consumer Green Wellness palette. Presentation code reads
/// these roles from [BuildContext] so the same workspace remains legible in
/// light and dark modes.
@immutable
final class AdminWorkspaceColors extends ThemeExtension<AdminWorkspaceColors> {
  const AdminWorkspaceColors({
    required this.canvas,
    required this.sidebar,
    required this.toolbar,
    required this.panel,
    required this.panelMuted,
    required this.selected,
    required this.hover,
    required this.divider,
    required this.border,
    required this.borderStrong,
    required this.brandSurface,
    required this.blue,
    required this.blueStrong,
    required this.cyan,
    required this.mint,
    required this.warning,
    required this.danger,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.onAccent,
    required this.onBrandSecondary,
    required this.brandHighlight,
    required this.dangerContainer,
    required this.dangerBorder,
    required this.onDangerContainer,
    required this.warningContainer,
    required this.warningBorder,
    required this.onWarningContainer,
    required this.successContainer,
    required this.successBorder,
    required this.onSuccessContainer,
    required this.infoContainer,
    required this.neutralContainer,
    required this.shadow,
    required this.scrim,
  });

  static const AdminWorkspaceColors light = AdminWorkspaceColors(
    canvas: Color(0xFFF3F6FA),
    sidebar: Color(0xFFF8FAFC),
    toolbar: Color(0xFFFDFEFF),
    panel: Color(0xFFFFFFFF),
    panelMuted: Color(0xFFF7F9FC),
    selected: Color(0xFFE8F1FF),
    hover: Color(0xFFF0F5FC),
    divider: Color(0xFFDDE5EF),
    border: Color(0xFFD7E0EA),
    borderStrong: Color(0xFFB7CBE2),
    brandSurface: Color(0xFF17324D),
    blue: Color(0xFF3478D4),
    blueStrong: Color(0xFF245B9E),
    cyan: Color(0xFF2E9EB5),
    mint: Color(0xFF2F9E77),
    warning: Color(0xFFC47A19),
    danger: Color(0xFFC8464D),
    text: Color(0xFF1C2B3A),
    textSecondary: Color(0xFF5F7183),
    textMuted: Color(0xFF8796A5),
    onAccent: Color(0xFFFFFFFF),
    onBrandSecondary: Color(0xFFC7D4E1),
    brandHighlight: Color(0xFFB9D7FF),
    dangerContainer: Color(0xFFFBEAEC),
    dangerBorder: Color(0xFFE7B7BB),
    onDangerContainer: Color(0xFF8E2830),
    warningContainer: Color(0xFFFFF7E8),
    warningBorder: Color(0xFFEACB96),
    onWarningContainer: Color(0xFF6E430E),
    successContainer: Color(0xFFEAF7F1),
    successBorder: Color(0xFFBEE4D3),
    onSuccessContainer: Color(0xFF185B45),
    infoContainer: Color(0xFFE8F6F8),
    neutralContainer: Color(0xFFF0F3F6),
    shadow: Color(0x1417324D),
    scrim: Color(0x66132435),
  );

  static const AdminWorkspaceColors dark = AdminWorkspaceColors(
    canvas: Color(0xFF0D1621),
    sidebar: Color(0xFF111D29),
    toolbar: Color(0xFF142130),
    panel: Color(0xFF182635),
    panelMuted: Color(0xFF1D2D3D),
    selected: Color(0xFF1E3B5B),
    hover: Color(0xFF213447),
    divider: Color(0xFF2A3D50),
    border: Color(0xFF354A60),
    borderStrong: Color(0xFF53708D),
    brandSurface: Color(0xFF17324D),
    blue: Color(0xFF82B7F4),
    blueStrong: Color(0xFFA9CEFA),
    cyan: Color(0xFF72CEE0),
    mint: Color(0xFF69D6AB),
    warning: Color(0xFFF1BE72),
    danger: Color(0xFFFFB3B8),
    text: Color(0xFFE6EEF6),
    textSecondary: Color(0xFFBCC9D6),
    textMuted: Color(0xFF91A2B3),
    onAccent: Color(0xFF07131E),
    onBrandSecondary: Color(0xFFC7D4E1),
    brandHighlight: Color(0xFFB9D7FF),
    dangerContainer: Color(0xFF4A2229),
    dangerBorder: Color(0xFF754049),
    onDangerContainer: Color(0xFFFFDADD),
    warningContainer: Color(0xFF44351D),
    warningBorder: Color(0xFF6C5530),
    onWarningContainer: Color(0xFFFFDDA8),
    successContainer: Color(0xFF173D31),
    successBorder: Color(0xFF2F6653),
    onSuccessContainer: Color(0xFFB5F2D6),
    infoContainer: Color(0xFF153B46),
    neutralContainer: Color(0xFF273543),
    shadow: Color(0x66000000),
    scrim: Color(0xB3000000),
  );

  final Color canvas;
  final Color sidebar;
  final Color toolbar;
  final Color panel;
  final Color panelMuted;
  final Color selected;
  final Color hover;
  final Color divider;
  final Color border;
  final Color borderStrong;
  final Color brandSurface;
  final Color blue;
  final Color blueStrong;
  final Color cyan;
  final Color mint;
  final Color warning;
  final Color danger;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color onAccent;
  final Color onBrandSecondary;
  final Color brandHighlight;
  final Color dangerContainer;
  final Color dangerBorder;
  final Color onDangerContainer;
  final Color warningContainer;
  final Color warningBorder;
  final Color onWarningContainer;
  final Color successContainer;
  final Color successBorder;
  final Color onSuccessContainer;
  final Color infoContainer;
  final Color neutralContainer;
  final Color shadow;
  final Color scrim;

  @override
  AdminWorkspaceColors copyWith({
    Color? canvas,
    Color? sidebar,
    Color? toolbar,
    Color? panel,
    Color? panelMuted,
    Color? selected,
    Color? hover,
    Color? divider,
    Color? border,
    Color? borderStrong,
    Color? brandSurface,
    Color? blue,
    Color? blueStrong,
    Color? cyan,
    Color? mint,
    Color? warning,
    Color? danger,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? onAccent,
    Color? onBrandSecondary,
    Color? brandHighlight,
    Color? dangerContainer,
    Color? dangerBorder,
    Color? onDangerContainer,
    Color? warningContainer,
    Color? warningBorder,
    Color? onWarningContainer,
    Color? successContainer,
    Color? successBorder,
    Color? onSuccessContainer,
    Color? infoContainer,
    Color? neutralContainer,
    Color? shadow,
    Color? scrim,
  }) {
    return AdminWorkspaceColors(
      canvas: canvas ?? this.canvas,
      sidebar: sidebar ?? this.sidebar,
      toolbar: toolbar ?? this.toolbar,
      panel: panel ?? this.panel,
      panelMuted: panelMuted ?? this.panelMuted,
      selected: selected ?? this.selected,
      hover: hover ?? this.hover,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      brandSurface: brandSurface ?? this.brandSurface,
      blue: blue ?? this.blue,
      blueStrong: blueStrong ?? this.blueStrong,
      cyan: cyan ?? this.cyan,
      mint: mint ?? this.mint,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onAccent: onAccent ?? this.onAccent,
      onBrandSecondary: onBrandSecondary ?? this.onBrandSecondary,
      brandHighlight: brandHighlight ?? this.brandHighlight,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      warningBorder: warningBorder ?? this.warningBorder,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      successContainer: successContainer ?? this.successContainer,
      successBorder: successBorder ?? this.successBorder,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AdminWorkspaceColors lerp(covariant AdminWorkspaceColors? other, double t) {
    if (other == null) return this;
    return AdminWorkspaceColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      toolbar: Color.lerp(toolbar, other.toolbar, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelMuted: Color.lerp(panelMuted, other.panelMuted, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      brandSurface: Color.lerp(brandSurface, other.brandSurface, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueStrong: Color.lerp(blueStrong, other.blueStrong, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onBrandSecondary: Color.lerp(
        onBrandSecondary,
        other.onBrandSecondary,
        t,
      )!,
      brandHighlight: Color.lerp(brandHighlight, other.brandHighlight, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      neutralContainer: Color.lerp(
        neutralContainer,
        other.neutralContainer,
        t,
      )!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension AdminWorkspaceColorsContext on BuildContext {
  AdminWorkspaceColors get adminColors {
    final theme = Theme.of(this);
    return theme.extension<AdminWorkspaceColors>() ??
        (theme.brightness == Brightness.dark
            ? AdminWorkspaceColors.dark
            : AdminWorkspaceColors.light);
  }
}

/// Theme dành riêng cho khu vực quản trị.
///
/// Theme này chỉ thay đổi presentation; không ảnh hưởng quyền, dữ liệu
/// hoặc nghiệp vụ.
abstract final class AdminWorkspaceTheme {
  static const double sidebarWidth = 248;
  static const double compactSidebarWidth = 76;
  static const double contentMaxWidth = 1240;
  static const double panelRadius = 14;
  static const double controlRadius = 10;

  static ThemeData light(ThemeData base) =>
      _build(base, AdminWorkspaceColors.light, Brightness.light);

  static ThemeData dark(ThemeData base) =>
      _build(base, AdminWorkspaceColors.dark, Brightness.dark);

  static ThemeData _build(
    ThemeData base,
    AdminWorkspaceColors colors,
    Brightness brightness,
  ) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.blue,
      onPrimary: colors.onAccent,
      primaryContainer: colors.selected,
      onPrimaryContainer: colors.text,
      secondary: colors.cyan,
      onSecondary: colors.onAccent,
      secondaryContainer: colors.infoContainer,
      onSecondaryContainer: colors.text,
      tertiary: colors.mint,
      onTertiary: colors.onAccent,
      tertiaryContainer: colors.successContainer,
      onTertiaryContainer: colors.onSuccessContainer,
      error: colors.danger,
      onError: colors.onAccent,
      errorContainer: colors.dangerContainer,
      onErrorContainer: colors.onDangerContainer,
      surface: colors.panel,
      onSurface: colors.text,
      surfaceContainerHighest: colors.panelMuted,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.divider,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.brandSurface,
      onInverseSurface: const Color(0xFFFFFFFF),
      inversePrimary: colors.brandHighlight,
      surfaceTint: Colors.transparent,
    );

    final compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(panelRadius),
      side: BorderSide(color: colors.border),
    );
    final textTheme = base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    );
    final appSemanticColors = base.extension<AppSemanticColors>();

    return base.copyWith(
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[
        if (appSemanticColors != null) appSemanticColors,
        colors,
      ],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      cardColor: colors.panel,
      dividerColor: colors.divider,
      hoverColor: colors.hover,
      focusColor: colors.selected,
      highlightColor: colors.selected,
      splashFactory: InkRipple.splashFactory,
      visualDensity: const VisualDensity(horizontal: -0.8, vertical: -0.8),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.toolbar,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 58,
      ),
      cardTheme: CardThemeData(
        color: colors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.shadow,
        shape: panelShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: AppTextStyles.heading3.copyWith(color: colors.text),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.sidebar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(18),
          ),
          side: BorderSide(color: colors.divider),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.sidebar,
        indicatorColor: colors.selected,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: colors.blueStrong, size: 22),
        unselectedIconTheme: IconThemeData(
          color: colors.textSecondary,
          size: 21,
        ),
        selectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 21),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.text,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colors.panel,
        isDense: true,
        border: _inputBorder(colors.border),
        enabledBorder: _inputBorder(colors.border),
        focusedBorder: _inputBorder(colors.blue, width: 1.6),
        errorBorder: _inputBorder(colors.danger),
        focusedErrorBorder: _inputBorder(colors.danger, width: 1.6),
        disabledBorder: _inputBorder(colors.divider),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textMuted),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.blueStrong,
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
            if (states.contains(WidgetState.disabled)) return colors.divider;
            if (states.contains(WidgetState.pressed)) {
              return colors.blueStrong;
            }
            return colors.blue;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted;
            }
            return colors.onAccent;
          }),
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
          foregroundColor: WidgetStatePropertyAll(colors.text),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return colors.hover;
            }
            return colors.panel;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(compactShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.blueStrong),
          overlayColor: WidgetStatePropertyAll(colors.hover),
          shape: WidgetStatePropertyAll(compactShape),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 120),
          minimumSize: const WidgetStatePropertyAll(Size(42, 42)),
          foregroundColor: WidgetStatePropertyAll(colors.textSecondary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return colors.hover;
            }
            return Colors.transparent;
          }),
          shape: WidgetStatePropertyAll(compactShape),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.blue,
        circularTrackColor: colors.selected,
        linearTrackColor: colors.selected,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.blue,
        selectionColor: colors.blue.withValues(alpha: .24),
        selectionHandleColor: colors.blue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.brandSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        actionTextColor: colors.brandHighlight,
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
          color: colors.brandSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        waitDuration: const Duration(milliseconds: 350),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.panel,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTextStyles.bodyMedium.copyWith(color: colors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          side: BorderSide(color: colors.border),
        ),
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

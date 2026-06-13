import 'package:flutter/material.dart';

/// Foundation shadow definitions providing elevation levels for light and dark modes.
///
/// This class defines 5 foundation shadows (reduced from 30+) with three elevation
/// levels for light mode and two dark mode variants. Shadows should be referenced
/// through semantic tokens rather than used directly.
///
/// **Shadow Levels:**
/// - `shadowSm`: Small shadow for subtle elevation (cards, chips)
/// - `shadowMd`: Medium shadow for moderate elevation (elevated cards, dropdowns)
/// - `shadowLg`: Large shadow for prominent elevation (dialogs, modals)
/// - `shadowSmDark`: Small shadow variant for dark mode
/// - `shadowMdDark`: Medium shadow variant for dark mode
///
/// **Usage:**
/// ```dart
/// // Use through semantic tokens (recommended)
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadowTokens.card, // References ShadowFoundation.shadowSm
///   ),
/// );
///
/// // Direct usage (not recommended)
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: ShadowFoundation.shadowSm,
///   ),
/// );
/// ```
///
/// **Dark Mode:**
/// Dark mode shadows use higher opacity for visibility on dark surfaces.
/// Use `Theme.of(context).brightness` to determine which shadow set to apply.
///
/// **Validates: Requirements 1.5, 11.4**
@immutable
class ShadowFoundation {
  const ShadowFoundation._();

  /// Small shadow for subtle elevation.
  ///
  /// **Elevation:** 2dp
  /// **Blur:** 6px
  /// **Opacity:** 8%
  ///
  /// **Use cases:** Default cards, chips, small floating elements
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium shadow for moderate elevation.
  ///
  /// **Elevation:** 4dp
  /// **Blur:** 12px
  /// **Opacity:** 10%
  ///
  /// **Use cases:** Elevated cards, dropdown menus, floating action buttons
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Large shadow for prominent elevation.
  ///
  /// **Elevation:** 8dp
  /// **Blur:** 20px
  /// **Opacity:** 15%
  ///
  /// **Use cases:** Dialogs, modals, bottom sheets, prominent overlays
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Small shadow variant for dark mode.
  ///
  /// **Elevation:** 2dp
  /// **Blur:** 6px
  /// **Opacity:** 20%
  ///
  /// Dark mode uses higher opacity shadows for visibility on dark surfaces.
  ///
  /// **Use cases:** Default cards, chips in dark mode
  static const List<BoxShadow> shadowSmDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium shadow variant for dark mode.
  ///
  /// **Elevation:** 4dp
  /// **Blur:** 12px
  /// **Opacity:** 27%
  ///
  /// Dark mode uses higher opacity shadows for visibility on dark surfaces.
  ///
  /// **Use cases:** Elevated cards, dropdown menus in dark mode
  static const List<BoxShadow> shadowMdDark = [
    BoxShadow(
      color: Color(0x44000000), // 27% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

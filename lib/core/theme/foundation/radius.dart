import 'package:flutter/material.dart';

/// Foundation radius scale for the design system.
/// 
/// Provides consistent border radius values following a progressive scale.
/// These are primitive values that should be referenced by semantic tokens.
/// 
/// Scale levels:
/// - `radius0`: No radius (sharp corners)
/// - `radius4`: Subtle rounding for small elements
/// - `radius8`: Standard rounding for chips and small cards
/// - `radius12`: Medium rounding for buttons and inputs
/// - `radius16`: Large rounding for cards
/// - `radius24`: Extra large rounding for dialogs
/// - `radiusFull`: Circular elements (pills, avatars, badges)
/// 
/// **Validates: Requirements 1.4**
@immutable
class RadiusFoundation {
  const RadiusFoundation._();

  /// No radius - sharp corners (0px)
  static const double radius0 = 0;

  /// Subtle radius for small elements (4px)
  static const double radius4 = 4;

  /// Standard radius for chips and small cards (8px)
  static const double radius8 = 8;

  /// Medium radius for buttons and inputs (12px)
  static const double radius12 = 12;

  /// Large radius for cards (16px)
  static const double radius16 = 16;

  /// Extra large radius for dialogs and modals (24px)
  static const double radius24 = 24;

  /// Full radius for circular elements like pills, avatars, and badges (9999px)
  static const double radiusFull = 9999;
}

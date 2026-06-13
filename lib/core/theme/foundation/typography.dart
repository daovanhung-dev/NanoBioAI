import 'package:flutter/material.dart';

/// Foundation typography tokens defining primitive font sizes, weights, and line heights.
///
/// These are raw typographic values that serve as the foundation for semantic text styles.
/// Do not use these directly in components - use [AppTextStyles] semantic tokens instead.
///
/// **Validates: Requirements 1.2**
@immutable
class TypographyFoundation {
  const TypographyFoundation._();

  /// Primary font family for the application
  static const String fontFamily = 'Roboto';

  // Font Sizes
  /// Font size for captions and minimal text (12px)
  static const double size12 = 12;

  /// Font size for body text and labels (14px)
  static const double size14 = 14;

  /// Font size for body text and small headings (16px)
  static const double size16 = 16;

  /// Font size for titles and medium headings (18px)
  static const double size18 = 18;

  /// Font size for headings (20px)
  static const double size20 = 20;

  /// Font size for large headings (24px)
  static const double size24 = 24;

  /// Font size for display text (28px)
  static const double size28 = 28;

  /// Font size for large display text (32px)
  static const double size32 = 32;

  // Font Weights
  /// Regular font weight (400)
  static const FontWeight regular = FontWeight.w400;

  /// Medium font weight (500)
  static const FontWeight medium = FontWeight.w500;

  /// Semibold font weight (600)
  static const FontWeight semibold = FontWeight.w600;

  /// Bold font weight (700)
  static const FontWeight bold = FontWeight.w700;

  // Line Heights
  /// Tight line height for headings (1.2)
  static const double lineHeightTight = 1.2;

  /// Normal line height for most text (1.4)
  static const double lineHeightNormal = 1.4;

  /// Relaxed line height for body text (1.5)
  static const double lineHeightRelaxed = 1.5;
}

import 'package:flutter/material.dart';

import 'app_theme_flags.dart';

/// Soft brand-tinted depth system. Heavy black drop shadows are intentionally
/// avoided so cards remain calm and lightweight in either compatibility mode.
@immutable
class AppShadows {
  const AppShadows._();

  static const Color _xsTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x0F12352A)
      : Color(0x0F102A43);
  static const Color _smTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x1212352A)
      : Color(0x12102A43);
  static const Color _mdTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x1712352A)
      : Color(0x17102A43);
  static const Color _lgTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x1C12352A)
      : Color(0x1C102A43);
  static const Color _xlTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x2412352A)
      : Color(0x24102A43);
  static const Color _glassTint = AppThemeFlags.stitchGreenUiEnabled
      ? Color(0x1412352A)
      : Color(0x14102A43);

  static const List<BoxShadow> xs = [
    BoxShadow(color: _xsTint, blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: _smTint, blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: _mdTint, blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: _lgTint, blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: _xlTint, blurRadius: 40, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> card = sm;
  static const List<BoxShadow> cardRaised = md;
  static const List<BoxShadow> dialog = lg;
  static const List<BoxShadow> bottomSheet = lg;
  static const List<BoxShadow> dropdown = md;
  static const List<BoxShadow> popup = md;
  static const List<BoxShadow> appBar = xs;
  static const List<BoxShadow> input = xs;

  static const List<BoxShadow> button = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x3314A36F)
          : Color(0x332F6FED),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x3D14A36F)
          : Color(0x3D2F6FED),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> floating = [
    BoxShadow(color: _xlTint, blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> focus = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x5268D9A5)
          : Color(0x527DB2FF),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];
  static const List<BoxShadow> divider = [
    BoxShadow(color: _xsTint, blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> primary = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x3D14A36F)
          : Color(0x3D2F6FED),
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];
  static const List<BoxShadow> secondary = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x3358B9E8)
          : Color(0x3314A36F),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> success = [
    BoxShadow(color: Color(0x3314885F), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> warning = [
    BoxShadow(color: Color(0x33FFC857), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> danger = [
    BoxShadow(color: Color(0x33FF7D75), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> info = [
    BoxShadow(color: Color(0x3338A9E8), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> glass = [
    BoxShadow(color: _glassTint, blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> neumorphismLight = [
    BoxShadow(color: Color(0x12FFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    BoxShadow(color: _glassTint, blurRadius: 12, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> neumorphismDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(5, 5)),
  ];
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x0F14A36F)
          : Color(0x0F2F6FED),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> darkXs = [
    BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> darkSm = [
    BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> darkLg = [
    BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> darkXl = [
    BoxShadow(color: Color(0x77000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
  static const List<BoxShadow> darkCard = darkSm;
  static const List<BoxShadow> darkDialog = darkLg;
  static const List<BoxShadow> darkBottomSheet = darkLg;
  static const List<BoxShadow> darkButton = [
    BoxShadow(
      color: AppThemeFlags.stitchGreenUiEnabled
          ? Color(0x3362DDA3)
          : Color(0x336EA8FE),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

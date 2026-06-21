import 'package:flutter/material.dart';

@immutable
class AppShadows {
  const AppShadows._();

  // =========================================================
  // BASE ELEVATION SHADOWS
  // =========================================================

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 32,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];

  // =========================================================
  // SEMANTIC SHADOWS
  // =========================================================

  static const List<BoxShadow> card = sm;
  static const List<BoxShadow> cardRaised = md;
  static const List<BoxShadow> dialog = lg;
  static const List<BoxShadow> bottomSheet = lg;
  static const List<BoxShadow> dropdown = md;
  static const List<BoxShadow> popup = md;
  static const List<BoxShadow> appBar = xs;
  static const List<BoxShadow> input = xs;

  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x24000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 24,
      spreadRadius: 1,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> focus = [
    BoxShadow(
      color: Color(0x1A3B82F6),
      blurRadius: 0,
      spreadRadius: 4,
      offset: Offset.zero,
    ),
  ];

  static const List<BoxShadow> divider = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 1, offset: Offset(0, 1)),
  ];

  // =========================================================
  // COLORED SHADOWS
  // =========================================================

  static const List<BoxShadow> primary = [
    BoxShadow(color: Color(0x334DA8FF), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> secondary = [
    BoxShadow(color: Color(0x336EE7F9), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> success = [
    BoxShadow(color: Color(0x3334D399), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> warning = [
    BoxShadow(color: Color(0x33F59E0B), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> danger = [
    BoxShadow(color: Color(0x33EF4444), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> info = [
    BoxShadow(color: Color(0x330EA5E9), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // =========================================================
  // MODERN UI STYLES
  // =========================================================

  static const List<BoxShadow> glass = [
    BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 10, offset: Offset(-2, -2)),
    BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(2, 2)),
  ];

  static const List<BoxShadow> neumorphismLight = [
    BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(4, 4)),
  ];

  static const List<BoxShadow> neumorphismDark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(4, 4)),
    BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 24,
      spreadRadius: 4,
      offset: Offset(0, 8),
    ),
  ];

  // =========================================================
  // DARK MODE PRESETS
  // =========================================================

  static const List<BoxShadow> darkXs = [
    BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> darkSm = [
    BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> darkLg = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> darkXl = [
    BoxShadow(color: Color(0x77000000), blurRadius: 36, offset: Offset(0, 14)),
  ];

  static const List<BoxShadow> darkCard = darkSm;
  static const List<BoxShadow> darkDialog = darkLg;
  static const List<BoxShadow> darkBottomSheet = darkLg;
  static const List<BoxShadow> darkButton = [
    BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  // =========================================================
  // HELPERS
  // =========================================================

  static List<BoxShadow> custom({
    required Color color,
    double blurRadius = 12,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> opacity({
    required Color color,
    double opacity = 0.15,
    double blurRadius = 12,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> elevation(
    int level, {
    required bool darkMode,
    Color? color,
  }) {
    final shadowColor = color ?? Colors.black;

    switch (level) {
      case 0:
        return const [];
      case 1:
        return darkMode
            ? opacity(
                color: shadowColor,
                opacity: 0.20,
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            : xs;
      case 2:
        return darkMode
            ? opacity(
                color: shadowColor,
                opacity: 0.26,
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            : sm;
      case 3:
        return darkMode
            ? opacity(
                color: shadowColor,
                opacity: 0.32,
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            : md;
      case 4:
        return darkMode
            ? opacity(
                color: shadowColor,
                opacity: 0.40,
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            : lg;
      default:
        return darkMode ? darkXl : xl;
    }
  }

  static List<BoxShadow> surface({
    required bool elevated,
    required bool darkMode,
  }) {
    if (!elevated) {
      return const [];
    }
    return darkMode ? darkCard : card;
  }
}

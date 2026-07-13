import 'package:flutter/material.dart';

@immutable
class AppShadows {
  const AppShadows._();

  // Restrained blue-grey shadows keep health information calm and readable.
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0F102A43), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x12102A43), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x17102A43), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1C102A43), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x24102A43),
      blurRadius: 42,
      spreadRadius: 1,
      offset: Offset(0, 16),
    ),
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
    BoxShadow(color: Color(0x2B1769E0), blurRadius: 16, offset: Offset(0, 7)),
  ];
  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x301769E0), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x25102A43),
      blurRadius: 32,
      spreadRadius: 1,
      offset: Offset(0, 12),
    ),
  ];
  static const List<BoxShadow> focus = [
    BoxShadow(
      color: Color(0x401769E0),
      blurRadius: 0,
      spreadRadius: 3,
      offset: Offset.zero,
    ),
  ];
  static const List<BoxShadow> divider = [
    BoxShadow(color: Color(0x08102A43), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> primary = [
    BoxShadow(color: Color(0x331769E0), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> secondary = [
    BoxShadow(color: Color(0x2B0F766E), blurRadius: 20, offset: Offset(0, 7)),
  ];
  static const List<BoxShadow> success = [
    BoxShadow(color: Color(0x2B16825D), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> warning = [
    BoxShadow(color: Color(0x269A6200), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> danger = [
    BoxShadow(color: Color(0x26C4314B), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> info = [
    BoxShadow(color: Color(0x261261A0), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> glass = [
    BoxShadow(color: Color(0x14FFFFFF), blurRadius: 12, offset: Offset(-2, -2)),
    BoxShadow(color: Color(0x15102A43), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> neumorphismLight = [
    BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    BoxShadow(color: Color(0x14102A43), blurRadius: 12, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> neumorphismDark = [
    BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(4, 4)),
    BoxShadow(color: Color(0x12FFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
  ];
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14102A43),
      blurRadius: 32,
      spreadRadius: 1,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> darkXs = [
    BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
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
    BoxShadow(color: Color(0x77000000), blurRadius: 42, offset: Offset(0, 16)),
  ];
  static const List<BoxShadow> darkCard = darkSm;
  static const List<BoxShadow> darkDialog = darkLg;
  static const List<BoxShadow> darkBottomSheet = darkLg;
  static const List<BoxShadow> darkButton = [
    BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 7)),
  ];

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
            ? opacity(color: shadowColor, opacity: .20, blurRadius: 3, offset: const Offset(0, 1))
            : xs;
      case 2:
        return darkMode
            ? opacity(color: shadowColor, opacity: .26, blurRadius: 10, offset: const Offset(0, 3))
            : sm;
      case 3:
        return darkMode
            ? opacity(color: shadowColor, opacity: .32, blurRadius: 18, offset: const Offset(0, 6))
            : md;
      case 4:
        return darkMode
            ? opacity(color: shadowColor, opacity: .40, blurRadius: 28, offset: const Offset(0, 10))
            : lg;
      default:
        return darkMode ? darkXl : xl;
    }
  }

  static List<BoxShadow> surface({
    required bool elevated,
    required bool darkMode,
  }) {
    if (!elevated) return const [];
    return darkMode ? darkCard : card;
  }
}

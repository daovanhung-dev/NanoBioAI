import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class AppShadows {
  const AppShadows._();

  // =========================================================
  // Basic Shadows
  // =========================================================

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
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
  // Colored Shadows
  // =========================================================

  static const List<BoxShadow> primary = [
    BoxShadow(
      color: Color(0x334DA8FF),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> secondary = [
    BoxShadow(
      color: Color(0x336EE7F9),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> success = [
    BoxShadow(
      color: Color(0x3334D399),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> danger = [
    BoxShadow(
      color: Color(0x33EF4444),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // =========================================================
  // Glassmorphism / Modern UI
  // =========================================================

  static const List<BoxShadow> glass = [
    BoxShadow(
      color: Color(0x1FFFFFFF),
      blurRadius: 10,
      offset: Offset(-2, -2),
    ),
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(2, 2),
    ),
  ];

  static const List<BoxShadow> neumorphismLight = [
    BoxShadow(
      color: Color(0xFFFFFFFF),
      blurRadius: 12,
      offset: Offset(-4, -4),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(4, 4),
    ),
  ];

  static const List<BoxShadow> neumorphismDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(4, 4),
    ),
    BoxShadow(
      color: Color(0x1FFFFFFF),
      blurRadius: 12,
      offset: Offset(-4, -4),
    ),
  ];

  // =========================================================
  // Inner / Soft UI Simulation
  // =========================================================

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 24,
      spreadRadius: 4,
      offset: Offset(0, 8),
    ),
  ];

  // =========================================================
  // Helpers
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
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
}
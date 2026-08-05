import 'package:flutter/material.dart';

/// Soft, blue-tinted depth system. Heavy black drop shadows are intentionally
/// avoided so cards remain calm and lightweight.
@immutable
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0F102A43), blurRadius: 4, offset: Offset(0, 1)),
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
    BoxShadow(color: Color(0x24102A43), blurRadius: 40, offset: Offset(0, 16)),
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
    BoxShadow(color: Color(0x332F6FED), blurRadius: 14, offset: Offset(0, 5)),
  ];
  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x3D2F6FED), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x24102A43), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> focus = [
    BoxShadow(color: Color(0x527DB2FF), blurRadius: 0, spreadRadius: 3),
  ];
  static const List<BoxShadow> divider = [
    BoxShadow(color: Color(0x0F102A43), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> primary = [
    BoxShadow(color: Color(0x3D2F6FED), blurRadius: 26, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> secondary = [
    BoxShadow(color: Color(0x3338A9E8), blurRadius: 22, offset: Offset(0, 8)),
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
  static const List<BoxShadow> info = secondary;
  static const List<BoxShadow> glass = [
    BoxShadow(color: Color(0x14102A43), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> neumorphismLight = [
    BoxShadow(color: Color(0x12FFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    BoxShadow(color: Color(0x14102A43), blurRadius: 12, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> neumorphismDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(5, 5)),
  ];
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F2F6FED), blurRadius: 20, offset: Offset(0, 6)),
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
    BoxShadow(color: Color(0x336EA8FE), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

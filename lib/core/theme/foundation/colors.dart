import 'package:flutter/material.dart';

/// Layer-1 immutable color values for Nabi Blue Wellness.
@immutable
class ColorFoundation {
  const ColorFoundation._();

  static const Color greenBright = Color(0xFF62DDA3);
  static const Color greenPrimary = Color(0xFF006A46);
  static const Color greenDeep = Color(0xFF075E45);
  static const Color greenAccent = Color(0xFF14A36F);
  static const Color greenSoft = Color(0xFFDDF6E9);
  static const Color mintSurface = Color(0xFFEAF9F1);

  static const Color blueBright = Color(0xFF6EA8FE);
  static const Color bluePrimary = Color(0xFF2F6FED);
  static const Color blueDeep = Color(0xFF1746A2);
  static const Color blueSoft = Color(0xFFE8F1FF);
  static const Color blueSurface = Color(0xFFF4F8FF);
  static const Color ctaStart = Color(0xFF245CC5);
  static const Color ctaEnd = Color(0xFF4D8DF7);

  static const Color blue400 = blueBright;
  static const Color blue500 = bluePrimary;
  static const Color blue600 = blueDeep;
  static const Color blue700 = Color(0xFF10377D);
  static const Color cyan400 = Color(0xFF9DDCF5);
  static const Color cyan500 = Color(0xFF58B9E8);
  static const Color cyan600 = Color(0xFF247CA8);
  static const Color purple500 = Color(0xFF8B7CF6);
  static const Color purple600 = Color(0xFF6F60DA);

  // Semantic status colors are independent from the brand scale.
  static const Color green500 = Color(0xFF14885F);
  static const Color green600 = Color(0xFF0F6F4D);
  static const Color successSoft = Color(0xFFE0F6EB);
  static const Color amber500 = Color(0xFFFFC857);
  static const Color amber600 = Color(0xFFB7791F);
  static const Color amberSoft = Color(0xFFFFF3D6);
  static const Color red500 = Color(0xFFC64A4A);
  static const Color red600 = Color(0xFFA93B3B);
  static const Color redSoft = Color(0xFFFDE8E7);
  static const Color sky500 = Color(0xFF38A9E8);
  static const Color sky600 = Color(0xFF247CA8);
  static const Color skySoft = Color(0xFFE7F6FD);

  static const Color slate50 = Color(0xFFF7FAFF);
  static const Color slate100 = Color(0xFFFBFDFF);
  static const Color slate200 = Color(0xFFDCE6F4);
  static const Color slate300 = Color(0xFFC7D4E5);
  static const Color slate400 = Color(0xFFB7C1CE);
  static const Color slate500 = Color(0xFF8796AA);
  static const Color slate600 = Color(0xFF5B6B82);
  static const Color slate700 = Color(0xFF3D4F66);
  static const Color slate800 = Color(0xFF25364D);
  static const Color slate900 = Color(0xFF102A43);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

@immutable
class GradientFoundation {
  const GradientFoundation._();

  static const LinearGradient primary = LinearGradient(
    colors: [ColorFoundation.ctaStart, ColorFoundation.ctaEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [ColorFoundation.bluePrimary, ColorFoundation.purple500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [ColorFoundation.green500, ColorFoundation.green600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceLight = LinearGradient(
    colors: [ColorFoundation.white, ColorFoundation.slate50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceDark = LinearGradient(
    colors: [ColorFoundation.slate800, ColorFoundation.slate900],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

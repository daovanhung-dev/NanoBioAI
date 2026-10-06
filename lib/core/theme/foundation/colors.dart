import 'package:flutter/material.dart';

/// Layer-1 immutable color values for Nabi Blue Wellness.
@immutable
class ColorFoundation {
  const ColorFoundation._();

  static const Color greenBright = Color(0xFF62DDA3);
  static const Color greenPrimary = Color(0xFF006A46);
  static const Color greenDeep = Color(0xFF075E45);
  static const Color greenAccent = Color(0xFF16845C);
  static const Color greenSoft = Color(0xFFE5F3EB);
  static const Color mintSurface = Color(0xFFEAF5EE);

  static const Color blueBright = Color(0xFF9BB9F2);
  static const Color bluePrimary = Color(0xFF285CC5);
  static const Color blueDeep = Color(0xFF1C478F);
  static const Color blueSoft = Color(0xFFE7EEFC);
  static const Color blueSurface = Color(0xFFF2F6FC);
  static const Color ctaStart = Color(0xFF234FA8);
  static const Color ctaEnd = Color(0xFF3971D3);

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
  static const Color green500 = Color(0xFF167754);
  static const Color green600 = Color(0xFF0F6648);
  static const Color successSoft = Color(0xFFE5F3EB);
  static const Color amber500 = Color(0xFFE2AD4E);
  static const Color amber600 = Color(0xFF94600F);
  static const Color amberSoft = Color(0xFFFFF4DB);
  static const Color red500 = Color(0xFFB74343);
  static const Color red600 = Color(0xFF963838);
  static const Color redSoft = Color(0xFFFCEBE9);
  static const Color sky500 = Color(0xFF6BA9D0);
  static const Color sky600 = Color(0xFF286A92);
  static const Color skySoft = Color(0xFFE9F2F8);

  static const Color slate50 = Color(0xFFF4F7FB);
  static const Color slate100 = Color(0xFFF8FAFD);
  static const Color slate200 = Color(0xFFD8E1EC);
  static const Color slate300 = Color(0xFFC2CDDD);
  static const Color slate400 = Color(0xFF9AA7B8);
  static const Color slate500 = Color(0xFF748399);
  static const Color slate600 = Color(0xFF53657B);
  static const Color slate700 = Color(0xFF3E5068);
  static const Color slate800 = Color(0xFF24364F);
  static const Color slate900 = Color(0xFF14243A);

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

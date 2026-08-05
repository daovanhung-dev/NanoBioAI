import 'package:flutter/material.dart';

/// Named gradients for the NaBi Blue Wellness visual language.
///
/// Gradients are reserved for hero, primary CTA, celebration and focused
/// progress. Routine data cards should remain solid surfaces.
@immutable
class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF245CC5), Color(0xFF4D8DF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryReverse = LinearGradient(
    colors: [Color(0xFF4D8DF7), Color(0xFF245CC5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [Color(0xFF2F6FED), Color(0xFF8174E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumDark = LinearGradient(
    colors: [Color(0xFF1746A2), Color(0xFF6557C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFBFDFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceAlt = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurface = LinearGradient(
    colors: [Color(0xFF123052), Color(0xFF07172B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurfaceElevated = LinearGradient(
    colors: [Color(0xFF19436F), Color(0xFF0D223D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF14885F), Color(0xFF42C98A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFFC857), Color(0xFFB7791F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFFF7D75), Color(0xFFC64A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF6AC5F0), Color(0xFF247CA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient health = success;

  static const LinearGradient energy = LinearGradient(
    colors: [Color(0xFFFFD982), Color(0xFFFFC857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sleep = LinearGradient(
    colors: [Color(0xFF9FD8F6), Color(0xFF38A9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meditation = LinearGradient(
    colors: [Color(0xFFB6AEFF), Color(0xFF8174E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ai = LinearGradient(
    colors: [Color(0xFF2F6FED), Color(0xFF38A9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient futuristic = LinearGradient(
    colors: [Color(0xFF1746A2), Color(0xFF8174E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overlayTop = LinearGradient(
    colors: [Color(0x99102A43), Color(0x00102A43)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayBottom = LinearGradient(
    colors: [Color(0x00102A43), Color(0xB3102A43)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient overlayLeft = LinearGradient(
    colors: [Color(0x99102A43), Color(0x00102A43)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient overlayRight = LinearGradient(
    colors: [Color(0x00102A43), Color(0x99102A43)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF1746A2), Color(0xFF2F6FED), Color(0xFF6EA8FE)],
    stops: [0, .56, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboard = LinearGradient(
    colors: [Color(0xFF1746A2), Color(0xFF2F6FED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onboarding = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient medicalBackground = LinearGradient(
    colors: [Color(0xFFF7FAFF), Color(0xFFFBFDFF), Color(0xFFF4F8FF)],
    stops: [0, .58, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [Color(0xEFFFFFFF), Color(0xBFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassDark = LinearGradient(
    colors: [Color(0xCC123052), Color(0x99102A43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/foundation.dart';

/// Rendering budget used by the Kinetic Aura motion system.
enum AppPerformanceTier { economical, balanced, rich }

@immutable
class AppMotionPolicy {
  const AppMotionPolicy({
    this.reduceMotion = false,
    this.performanceTier = AppPerformanceTier.balanced,
  });

  final bool reduceMotion;
  final AppPerformanceTier performanceTier;

  AppMotionPolicy copyWith({
    bool? reduceMotion,
    AppPerformanceTier? performanceTier,
  }) {
    return AppMotionPolicy(
      reduceMotion: reduceMotion ?? this.reduceMotion,
      performanceTier: performanceTier ?? this.performanceTier,
    );
  }

  double get distanceFactor => switch (performanceTier) {
        AppPerformanceTier.economical => 0.55,
        AppPerformanceTier.balanced => 1,
        AppPerformanceTier.rich => 1.12,
      };

  double get scaleFactor => switch (performanceTier) {
        AppPerformanceTier.economical => 0.7,
        AppPerformanceTier.balanced => 1,
        AppPerformanceTier.rich => 1.05,
      };
}

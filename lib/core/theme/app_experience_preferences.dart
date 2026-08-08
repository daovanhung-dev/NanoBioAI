import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feedback/app_feedback_policy.dart';
import '../motion/app_motion_policy.dart';

@immutable
class AppExperiencePreferences {
  const AppExperiencePreferences({
    this.reduceMotion = false,
    this.hapticsEnabled = true,
    this.soundLevel = AppSoundFeedbackLevel.subtle,
    this.performanceTier = AppPerformanceTier.balanced,
  });

  final bool reduceMotion;
  final bool hapticsEnabled;
  final AppSoundFeedbackLevel soundLevel;
  final AppPerformanceTier performanceTier;

  static const defaults = AppExperiencePreferences();

  AppFeedbackPolicy get feedbackPolicy =>
      AppFeedbackPolicy(hapticsEnabled: hapticsEnabled, soundLevel: soundLevel);

  AppMotionPolicy motionPolicy({required bool systemReduceMotion}) {
    return AppMotionPolicy(
      reduceMotion: reduceMotion || systemReduceMotion,
      performanceTier: performanceTier,
    );
  }

  AppExperiencePreferences copyWith({
    bool? reduceMotion,
    bool? hapticsEnabled,
    AppSoundFeedbackLevel? soundLevel,
    AppPerformanceTier? performanceTier,
  }) {
    return AppExperiencePreferences(
      reduceMotion: reduceMotion ?? this.reduceMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundLevel: soundLevel ?? this.soundLevel,
      performanceTier: performanceTier ?? this.performanceTier,
    );
  }
}

final appExperiencePreferencesProvider =
    AsyncNotifierProvider<
      AppExperiencePreferencesController,
      AppExperiencePreferences
    >(AppExperiencePreferencesController.new);

class AppExperiencePreferencesController
    extends AsyncNotifier<AppExperiencePreferences> {
  static const _reduceMotionKey = 'nanobio_reduce_motion';
  static const _hapticsEnabledKey = 'nanobio_haptics_enabled';
  static const _soundLevelKey = 'nanobio_sound_feedback_level';
  static const _performanceTierKey = 'nanobio_motion_performance_tier';

  @override
  Future<AppExperiencePreferences> build() async {
    final preferences = await SharedPreferences.getInstance();
    return AppExperiencePreferences(
      reduceMotion: preferences.getBool(_reduceMotionKey) ?? false,
      hapticsEnabled: preferences.getBool(_hapticsEnabledKey) ?? true,
      soundLevel: _soundLevelFromStorage(preferences.getString(_soundLevelKey)),
      performanceTier: _performanceTierFromStorage(
        preferences.getString(_performanceTierKey),
      ),
    );
  }

  Future<void> setReduceMotion(bool value) async {
    await _update((current) => current.copyWith(reduceMotion: value));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_reduceMotionKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _update((current) => current.copyWith(hapticsEnabled: value));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hapticsEnabledKey, value);
  }

  Future<void> setSoundLevel(AppSoundFeedbackLevel value) async {
    await _update((current) => current.copyWith(soundLevel: value));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_soundLevelKey, value.name);
  }

  Future<void> setPerformanceTier(AppPerformanceTier value) async {
    await _update((current) => current.copyWith(performanceTier: value));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_performanceTierKey, value.name);
  }

  Future<void> _update(
    AppExperiencePreferences Function(AppExperiencePreferences current)
    transform,
  ) async {
    final current = state.value ?? AppExperiencePreferences.defaults;
    state = AsyncData(transform(current));
  }

  AppSoundFeedbackLevel _soundLevelFromStorage(String? value) {
    return AppSoundFeedbackLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AppSoundFeedbackLevel.subtle,
    );
  }

  AppPerformanceTier _performanceTierFromStorage(String? value) {
    return AppPerformanceTier.values.firstWhere(
      (tier) => tier.name == value,
      orElse: () => AppPerformanceTier.balanced,
    );
  }
}

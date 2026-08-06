import 'dart:async';

import 'app_feedback_policy.dart';
import 'app_feedback_type.dart';
import 'app_haptic_adapter.dart';
import 'app_sound_adapter.dart';

/// Central feedback orchestrator for visual companions, haptic and sound cues.
///
/// Presentation and controllers emit semantic events only. Platform APIs live
/// behind adapters so tests can use fakes and sound assets can be replaced later.
class AppFeedbackService {
  AppFeedbackService({
    AppHapticAdapter hapticAdapter = const SystemAppHapticAdapter(),
    AppSoundAdapter soundAdapter = const SystemAppSoundAdapter(),
    AppFeedbackPolicy policy = const AppFeedbackPolicy(),
  })  : _hapticAdapter = hapticAdapter,
        _soundAdapter = soundAdapter,
        _policy = policy;

  static final AppFeedbackService instance = AppFeedbackService();

  final AppHapticAdapter _hapticAdapter;
  final AppSoundAdapter _soundAdapter;
  final Map<AppFeedbackType, DateTime> _lastEmission = {};

  AppFeedbackPolicy _policy;

  AppFeedbackPolicy get policy => _policy;

  void configure(AppFeedbackPolicy policy) {
    _policy = policy;
  }

  void emit(
    AppFeedbackType type, {
    Duration? cooldown,
    AppFeedbackPolicy? policyOverride,
  }) {
    final effectiveCooldown = cooldown ?? _defaultCooldown(type);
    final now = DateTime.now();
    final previous = _lastEmission[type];
    if (previous != null && now.difference(previous) < effectiveCooldown) {
      return;
    }
    _lastEmission[type] = now;
    unawaited(_emit(type, policyOverride ?? _policy));
  }

  Future<void> _emit(AppFeedbackType type, AppFeedbackPolicy policy) async {
    final haptic = _hapticFor(type);
    final sound = _soundFor(type);

    if (policy.hapticsEnabled && haptic != AppHapticPattern.none) {
      try {
        await _hapticAdapter.emit(haptic);
      } catch (_) {
        // Feedback is best-effort and must never break a product flow.
      }
    }

    if (policy.allowsSound(type) && sound != AppSoundCue.none) {
      try {
        await _soundAdapter.play(sound);
      } catch (_) {
        // Platform sound support differs; product behavior remains unchanged.
      }
    }
  }

  Duration _defaultCooldown(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.tap || AppFeedbackType.selection =>
        const Duration(milliseconds: 70),
      AppFeedbackType.primaryAction ||
      AppFeedbackType.voiceStart ||
      AppFeedbackType.voiceStop => const Duration(milliseconds: 140),
      _ => const Duration(milliseconds: 320),
    };
  }

  AppHapticPattern _hapticFor(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.tap => AppHapticPattern.selection,
      AppFeedbackType.selection => AppHapticPattern.selection,
      AppFeedbackType.primaryAction => AppHapticPattern.light,
      AppFeedbackType.success => AppHapticPattern.medium,
      AppFeedbackType.warning => AppHapticPattern.medium,
      AppFeedbackType.error => AppHapticPattern.heavy,
      AppFeedbackType.voiceStart => AppHapticPattern.light,
      AppFeedbackType.voiceStop => AppHapticPattern.selection,
      AppFeedbackType.answerReady => AppHapticPattern.light,
      AppFeedbackType.milestone => AppHapticPattern.heavy,
    };
  }

  AppSoundCue _soundFor(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.tap => AppSoundCue.softTap,
      AppFeedbackType.selection => AppSoundCue.selection,
      AppFeedbackType.primaryAction => AppSoundCue.softTap,
      AppFeedbackType.success => AppSoundCue.success,
      AppFeedbackType.warning => AppSoundCue.warning,
      AppFeedbackType.error => AppSoundCue.error,
      AppFeedbackType.voiceStart || AppFeedbackType.voiceStop =>
        AppSoundCue.voice,
      AppFeedbackType.answerReady => AppSoundCue.answer,
      AppFeedbackType.milestone => AppSoundCue.milestone,
    };
  }
}

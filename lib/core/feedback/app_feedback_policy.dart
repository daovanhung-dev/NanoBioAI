import 'package:flutter/foundation.dart';

import 'app_feedback_type.dart';

enum AppSoundFeedbackLevel { off, subtle, full }

@immutable
class AppFeedbackPolicy {
  const AppFeedbackPolicy({
    this.hapticsEnabled = true,
    this.soundLevel = AppSoundFeedbackLevel.subtle,
  });

  final bool hapticsEnabled;
  final AppSoundFeedbackLevel soundLevel;

  bool allowsSound(AppFeedbackType type) {
    return switch (soundLevel) {
      AppSoundFeedbackLevel.off => false,
      AppSoundFeedbackLevel.subtle => switch (type) {
          AppFeedbackType.success ||
          AppFeedbackType.warning ||
          AppFeedbackType.error ||
          AppFeedbackType.voiceStart ||
          AppFeedbackType.voiceStop ||
          AppFeedbackType.answerReady ||
          AppFeedbackType.milestone => true,
          _ => false,
        },
      AppSoundFeedbackLevel.full => type != AppFeedbackType.tap,
    };
  }
}

/// Semantic feedback events shared by every NanoBio surface.
enum AppFeedbackType {
  tap,
  selection,
  primaryAction,
  success,
  warning,
  error,
  voiceStart,
  voiceStop,
  answerReady,
  milestone,
}

enum AppHapticPattern { none, selection, light, medium, heavy }

enum AppSoundCue { none, softTap, selection, success, warning, error, voice, answer, milestone }

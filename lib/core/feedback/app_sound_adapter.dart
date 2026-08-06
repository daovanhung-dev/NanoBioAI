import 'package:flutter/services.dart';

import 'app_feedback_type.dart';

abstract interface class AppSoundAdapter {
  Future<void> play(AppSoundCue cue);
}

/// Uses platform system sounds until licensed physical Nabi SFX are restored.
///
/// Widgets never depend on this implementation. A future asset-backed adapter
/// can replace it without changing presentation code.
class SystemAppSoundAdapter implements AppSoundAdapter {
  const SystemAppSoundAdapter();

  @override
  Future<void> play(AppSoundCue cue) async {
    switch (cue) {
      case AppSoundCue.none:
        return;
      case AppSoundCue.warning:
      case AppSoundCue.error:
      case AppSoundCue.milestone:
        await SystemSound.play(SystemSoundType.alert);
        return;
      case AppSoundCue.softTap:
      case AppSoundCue.selection:
      case AppSoundCue.success:
      case AppSoundCue.voice:
      case AppSoundCue.answer:
        await SystemSound.play(SystemSoundType.click);
        return;
    }
  }
}

class NoOpAppSoundAdapter implements AppSoundAdapter {
  const NoOpAppSoundAdapter();

  @override
  Future<void> play(AppSoundCue cue) async {}
}

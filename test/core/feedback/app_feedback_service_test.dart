import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/feedback/app_feedback_policy.dart';
import 'package:nano_app/core/feedback/app_feedback_service.dart';
import 'package:nano_app/core/feedback/app_feedback_type.dart';
import 'package:nano_app/core/feedback/app_haptic_adapter.dart';
import 'package:nano_app/core/feedback/app_sound_adapter.dart';

class _RecordingHapticAdapter implements AppHapticAdapter {
  final emitted = <AppHapticPattern>[];

  @override
  Future<void> emit(AppHapticPattern pattern) async {
    emitted.add(pattern);
  }
}

class _RecordingSoundAdapter implements AppSoundAdapter {
  final played = <AppSoundCue>[];

  @override
  Future<void> play(AppSoundCue cue) async {
    played.add(cue);
  }
}

Future<void> _flushFeedback() => Future<void>.delayed(Duration.zero);

void main() {
  test('subtle policy keeps selection haptic but suppresses selection sound', () async {
    final haptic = _RecordingHapticAdapter();
    final sound = _RecordingSoundAdapter();
    final service = AppFeedbackService(
      hapticAdapter: haptic,
      soundAdapter: sound,
      policy: const AppFeedbackPolicy(
        soundLevel: AppSoundFeedbackLevel.subtle,
      ),
    );

    service.emit(AppFeedbackType.selection);
    await _flushFeedback();

    expect(haptic.emitted, [AppHapticPattern.selection]);
    expect(sound.played, isEmpty);
  });

  test('meaningful success emits both haptic and subtle sound', () async {
    final haptic = _RecordingHapticAdapter();
    final sound = _RecordingSoundAdapter();
    final service = AppFeedbackService(
      hapticAdapter: haptic,
      soundAdapter: sound,
    );

    service.emit(AppFeedbackType.success);
    await _flushFeedback();

    expect(haptic.emitted, [AppHapticPattern.medium]);
    expect(sound.played, [AppSoundCue.success]);
  });

  test('disabled feedback policy performs no platform work', () async {
    final haptic = _RecordingHapticAdapter();
    final sound = _RecordingSoundAdapter();
    final service = AppFeedbackService(
      hapticAdapter: haptic,
      soundAdapter: sound,
      policy: const AppFeedbackPolicy(
        hapticsEnabled: false,
        soundLevel: AppSoundFeedbackLevel.off,
      ),
    );

    service.emit(AppFeedbackType.milestone);
    await _flushFeedback();

    expect(haptic.emitted, isEmpty);
    expect(sound.played, isEmpty);
  });

  test('cooldown prevents repeated sound and haptic spam', () async {
    final haptic = _RecordingHapticAdapter();
    final sound = _RecordingSoundAdapter();
    final service = AppFeedbackService(
      hapticAdapter: haptic,
      soundAdapter: sound,
    );

    service.emit(
      AppFeedbackType.success,
      cooldown: const Duration(minutes: 1),
    );
    service.emit(
      AppFeedbackType.success,
      cooldown: const Duration(minutes: 1),
    );
    await _flushFeedback();

    expect(haptic.emitted, hasLength(1));
    expect(sound.played, hasLength(1));
  });
}

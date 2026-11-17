import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_gateways.dart';
import 'package:nano_app/app_versions/v1/features/splash/domain/services/startup_greeting_service.dart';

void main() {
  test('speaks the Vietnamese greeting once per cold app launch', () async {
    final tts = _FakeTextToSpeechGateway();
    final service = StartupGreetingService(tts);

    await service.speakOnce();
    await service.speakOnce();

    expect(tts.spoken, [StartupGreetingService.greeting]);
  });

  test(
    'continues silently when Vietnamese device TTS is unavailable',
    () async {
      final tts = _FakeTextToSpeechGateway()
        ..speakError = StateError('Vietnamese TTS unavailable');
      final service = StartupGreetingService(tts);

      await expectLater(service.speakOnce(), completes);
      expect(tts.spoken, [StartupGreetingService.greeting]);
      expect(tts.stopCalls, 1);
    },
  );

  test('does not speak when the platform has no native TTS support', () async {
    final tts = _FakeTextToSpeechGateway();
    final service = StartupGreetingService(tts, enabled: false);

    await service.speakOnce();

    expect(tts.spoken, isEmpty);
  });
}

class _FakeTextToSpeechGateway implements TextToSpeechGateway {
  final List<String> spoken = [];
  Object? speakError;
  int stopCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (speakError case final error?) throw error;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

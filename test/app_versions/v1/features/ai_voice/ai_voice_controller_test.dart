import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_live_event.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/ai_voice_copy.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_live_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';

void main() {
  test(
    'does not open microphone or consume a Live turn before explicit start',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();

      expect(live.startCalls, 0);
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.idle,
      );
    },
  );

  test(
    'opens one Live session immediately after the explicit start action',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      expect(live.startCalls, 1);
      expect(container.read(aiVoiceControllerProvider).isSessionActive, isTrue);
    },
  );

  test(
    'transitions from listening to user speech, Nabi speech and listening',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      live.emit(const VoiceLiveEvent.inputTranscript('Tôi nên ăn gì?'));
      await _drainEvents();
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.userSpeaking,
      );
      expect(
        container.read(aiVoiceControllerProvider).transcript,
        'Tôi nên ăn gì?',
      );

      live.emit(
        const VoiceLiveEvent.outputTranscript('Bạn hãy ăn đủ bữa nhé.'),
      );
      live.emit(VoiceLiveEvent.outputAudio(Uint8List.fromList(<int>[1, 2])));
      await _drainEvents();
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.speaking,
      );
      expect(
        container.read(aiVoiceControllerProvider).responseDraft,
        'Bạn hãy ăn đủ bữa nhé.',
      );

      live.emit(const VoiceLiveEvent.turnCompleted());
      await _drainEvents();
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.listening,
      );
    },
  );

  test(
    'interruption clears Nabi response while microphone session remains open',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      live.emit(const VoiceLiveEvent.outputTranscript('Câu Nabi đang nói'));
      live.emit(const VoiceLiveEvent.interrupted());
      await _drainEvents();

      final state = container.read(aiVoiceControllerProvider);
      expect(state.phase, AiVoicePhase.interrupted);
      expect(state.responseDraft, isEmpty);
      expect(state.isSessionActive, isTrue);
      expect(live.stopCalls, 0);
    },
  );

  test(
    'pauses and resumes only microphone input in the active session',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      await controller.pauseListening();
      expect(live.pauseCalls, 1);
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.paused,
      );

      await controller.resumeListening();
      expect(live.resumeCalls, 1);
      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.listening,
      );
    },
  );

  test('stops and releases Live audio when app leaves foreground', () async {
    final live = _FakeLiveGateway();
    final container = _container(live: live);
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    await controller.initialize();
    await controller.startConversation();
    await controller.handleAppLifecycleState(AppLifecycleState.paused);

    expect(live.stopCalls, 1);
    expect(
      container.read(aiVoiceControllerProvider).sessionState,
      AiVoiceSessionState.stopped,
    );
  });

  test('cancels a pending startup when the app leaves foreground', () async {
    final live = _FakeLiveGateway(startCompleter: Completer());
    final container = _container(live: live);
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    await controller.initialize();
    final start = controller.startConversation();
    await _drainEvents();
    expect(
      container.read(aiVoiceControllerProvider).sessionState,
      AiVoiceSessionState.starting,
    );

    await controller.handleAppLifecycleState(AppLifecycleState.paused);
    live.completeStart();
    await start;

    expect(
      container.read(aiVoiceControllerProvider).sessionState,
      AiVoiceSessionState.stopped,
    );
    expect(container.read(aiVoiceControllerProvider).isSessionActive, isFalse);
    expect(live.stopCalls, greaterThanOrEqualTo(1));
  });

  test(
    'does not open a second Live session while startup is pending',
    () async {
      final live = _FakeLiveGateway(startCompleter: Completer());
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      final firstStart = controller.startConversation();
      await _drainEvents();
      await controller.startConversation();

      expect(live.startCalls, 1);
      live.completeStart();
      await firstStart;
      expect(container.read(aiVoiceControllerProvider).isSessionActive, isTrue);
    },
  );

  test(
    'terminal Live error stops session without retaining playback resources',
    () async {
      final live = _FakeLiveGateway();
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      live.emit(VoiceLiveEvent.failure(StateError('network')));
      await _drainEvents();

      expect(
        container.read(aiVoiceControllerProvider).phase,
        AiVoicePhase.error,
      );
      expect(live.stopCalls, 1);
    },
  );

  test(
    'shows a safe local configuration error without opening a session',
    () async {
      final live = _FakeLiveGateway(
        startError: const VoiceLiveConfigurationException(),
      );
      final container = _container(live: live);
      addTearDown(container.dispose);
      final controller = container.read(aiVoiceControllerProvider.notifier);

      await controller.initialize();
      await controller.startConversation();
      await _drainEvents();

      final state = container.read(aiVoiceControllerProvider);
      expect(state.phase, AiVoicePhase.error);
      expect(state.errorMessage, AiVoiceCopy.voiceConfigurationMissing);
      expect(live.startCalls, 1);
      expect(live.stopCalls, 1);
    },
  );
}

ProviderContainer _container({required _FakeLiveGateway live}) {
  return ProviderContainer(
    overrides: [voiceLiveGatewayProvider.overrideWithValue(live)],
  );
}

Future<void> _drainEvents() => Future<void>.delayed(Duration.zero);

class _FakeLiveGateway implements VoiceLiveGateway {
  final _events = StreamController<VoiceLiveEvent>();
  final Completer<Stream<VoiceLiveEvent>>? _startCompleter;
  final Object? _startError;
  int startCalls = 0;
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;

  _FakeLiveGateway({
    Completer<Stream<VoiceLiveEvent>>? startCompleter,
    Object? startError,
  }) : _startCompleter = startCompleter,
       _startError = startError;

  @override
  Future<Stream<VoiceLiveEvent>> startSession() async {
    startCalls++;
    final error = _startError;
    if (error != null) throw error;
    final completer = _startCompleter;
    if (completer != null) return completer.future;
    return _events.stream;
  }

  void completeStart() {
    final completer = _startCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_events.stream);
    }
  }

  void emit(VoiceLiveEvent event) => _events.add(event);

  @override
  Future<void> pauseInput() async {
    pauseCalls++;
  }

  @override
  Future<void> resumeInput() async {
    resumeCalls++;
  }

  @override
  Future<void> setOutputMuted(bool muted) async {}

  @override
  Future<void> stopOutputImmediately() async {}

  @override
  Future<void> stopSession() async {
    stopCalls++;
  }
}

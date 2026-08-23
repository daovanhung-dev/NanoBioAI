import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/ai_voice_copy.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_gateways.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/repositories/ai_voice_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/voice_chat_exception.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';

void main() {
  group('AiVoiceController sequential loop', () {
    test('reaction speed values map to the requested silence windows', () {
      expect(AiVoiceReactionSpeed.values.map((speed) => speed.label), [
        'Siêu nhanh 0,2 giây',
        'Nhanh 0,5 giây',
        'Bình thường 1 giây',
        'Chậm 2 giây',
      ]);
      expect(AiVoiceReactionSpeed.values.map((speed) => speed.pauseFor), [
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);
      expect(const AiVoiceState().reactionSpeed, AiVoiceReactionSpeed.normal);
    });

    test('passes selected reaction speed to every STT turn', () async {
      final harness = _Harness(repositoryResults: ['Nabi trả lời']);
      addTearDown(harness.dispose);

      harness.controller.setReactionSpeed(AiVoiceReactionSpeed.ultraFast);
      await harness.controller.startConversation();
      expect(harness.speech.pauseDurations, [
        const Duration(milliseconds: 200),
      ]);

      harness.speech.completeCurrent('Xin chào');
      await _flush();
      harness.tts.completeCurrent();
      await _flush();

      expect(harness.speech.pauseDurations, [
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 200),
      ]);
      await harness.controller.stopConversation();
    });

    test('allows every STT turn to listen for up to three minutes', () async {
      final harness = _Harness(repositoryResults: ['Nabi trả lời']);
      addTearDown(harness.dispose);

      await harness.controller.startConversation();
      expect(harness.speech.listenDurations, [const Duration(minutes: 3)]);

      harness.speech.completeCurrent('Xin chào');
      await _flush();
      harness.tts.completeCurrent();
      await _flush();

      expect(harness.speech.listenDurations, [
        const Duration(minutes: 3),
        const Duration(minutes: 3),
      ]);
      await harness.controller.stopConversation();
    });

    test(
      'cannot change reaction speed while a session is in progress',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);

        harness.controller.setReactionSpeed(AiVoiceReactionSpeed.fast);
        await harness.controller.startConversation();
        harness.controller.setReactionSpeed(AiVoiceReactionSpeed.slow);

        expect(
          harness.controllerState.reactionSpeed,
          AiVoiceReactionSpeed.fast,
        );
        expect(harness.speech.pauseDurations, [
          const Duration(milliseconds: 500),
        ]);
        await harness.controller.stopConversation();
      },
    );

    test(
      'keeps reaction speed through Stop and Start on the same page',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);

        harness.controller.setReactionSpeed(AiVoiceReactionSpeed.slow);
        await harness.controller.startConversation();
        await harness.controller.stopConversation();

        expect(
          harness.controllerState.reactionSpeed,
          AiVoiceReactionSpeed.slow,
        );

        await harness.controller.startConversation();
        expect(harness.speech.pauseDurations, [
          const Duration(seconds: 2),
          const Duration(seconds: 2),
        ]);
        await harness.controller.stopConversation();
      },
    );

    test('runs two turns in strict STT -> repository -> TTS order', () async {
      final harness = _Harness(
        repositoryResults: ['Nabi trả lời một', 'Nabi trả lời hai'],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      expect(harness.speech.listenCount, 0);
      await harness.controller.startConversation();
      expect(harness.speech.listenCount, 1);

      harness.speech.completeCurrent('Câu một');
      await _flush();
      expect(harness.tts.speakCount, 1);
      harness.tts.completeCurrent();
      await _flush();
      expect(harness.speech.listenCount, 2);

      harness.speech.completeCurrent('Câu hai');
      await _flush();
      expect(harness.tts.speakCount, 2);
      harness.tts.completeCurrent();
      await harness.controller.stopConversation();
      await _flush();

      expect(harness.guard.overlaps, isEmpty);
      expect(harness.guard.events.where(_isTurnEvent), [
        'stt:start:1',
        'stt:end:1',
        'repo:start:Câu một',
        'repo:end:Câu một',
        'tts:start:Nabi trả lời một',
        'tts:end:Nabi trả lời một',
        'stt:start:2',
        'stt:end:2',
        'repo:start:Câu hai',
        'repo:end:Câu hai',
        'tts:start:Nabi trả lời hai',
        'tts:end:Nabi trả lời hai',
      ]);
      expect(harness.controllerState.phase, AiVoicePhase.idle);
    });

    test('empty transcript skips backend and listens again', () async {
      final harness = _Harness(repositoryResults: ['unused']);
      addTearDown(harness.dispose);

      await harness.controller.startConversation();
      harness.speech.completeCurrent('   ');
      await _flush();

      expect(harness.repository.messages, isEmpty);
      expect(harness.speech.listenCount, 2);
      await harness.controller.stopConversation();
    });

    for (final lifecycleAction in ['stop', 'background']) {
      for (final phase in ['listening', 'thinking', 'speaking']) {
        test('$lifecycleAction during $phase never restarts STT', () async {
          final pendingRepository = Completer<String>();
          final harness = _Harness(
            repositoryResults: [
              if (phase == 'thinking') pendingRepository else 'Nabi trả lời',
            ],
          );
          addTearDown(harness.dispose);

          await harness.controller.startConversation();
          if (phase != 'listening') {
            harness.speech.completeCurrent('Xin chào');
            await _flush();
          }
          if (phase == 'speaking') {
            expect(harness.tts.speakCount, 1);
          }

          if (lifecycleAction == 'stop') {
            await harness.controller.stopConversation();
          } else {
            await harness.controller.handleAppLifecycleState(
              AppLifecycleState.paused,
            );
          }
          pendingRepository.complete('Response đến muộn');
          await _flush();

          expect(harness.speech.listenCount, 1);
          expect(harness.controllerState.phase, AiVoicePhase.idle);
          expect(harness.controllerState.isSessionInProgress, isFalse);
        });
      }
    }

    test('permission denial stops safely', () async {
      final harness = _Harness(
        speechInitializeError:
            const SpeechRecognitionPermissionDeniedException(),
      );
      addTearDown(harness.dispose);

      await harness.controller.startConversation();

      expect(harness.controllerState.phase, AiVoicePhase.permissionDenied);
      expect(
        harness.controllerState.errorMessage,
        AiVoiceCopy.permissionDenied,
      );
      expect(harness.speech.listenCount, 0);
      expect(harness.repository.messages, isEmpty);
    });

    final failureMessages = <VoiceChatFailure, String>{
      VoiceChatFailure.invalidRequest: AiVoiceCopy.temporarilyUnavailable,
      VoiceChatFailure.temporarilyUnavailable:
          AiVoiceCopy.temporarilyUnavailable,
      VoiceChatFailure.unavailable: AiVoiceCopy.unavailable,
      VoiceChatFailure.invalidResponse: AiVoiceCopy.invalidResponse,
    };
    for (final entry in failureMessages.entries) {
      test('Gemini ${entry.key.name} stops safely without TTS', () async {
        final harness = _Harness(
          repositoryResults: [VoiceChatException(entry.key)],
        );
        addTearDown(harness.dispose);

        await harness.controller.startConversation();
        harness.speech.completeCurrent('Kiểm tra lỗi');
        await _flush();

        expect(harness.controllerState.phase, AiVoicePhase.error);
        expect(harness.controllerState.errorMessage, entry.value);
        expect(harness.tts.speakCount, 0);
        expect(harness.speech.listenCount, 1);
      });
    }

    test('empty backend response stops safely', () async {
      final harness = _Harness(repositoryResults: ['   ']);
      addTearDown(harness.dispose);

      await harness.controller.startConversation();
      harness.speech.completeCurrent('Câu hỏi');
      await _flush();

      expect(harness.controllerState.phase, AiVoicePhase.error);
      expect(harness.controllerState.errorMessage, AiVoiceCopy.invalidResponse);
      expect(harness.tts.speakCount, 0);
    });

    test('TTS failure stops and does not reopen microphone', () async {
      final harness = _Harness(
        repositoryResults: ['Câu trả lời'],
        ttsError: StateError('speaker failed'),
      );
      addTearDown(harness.dispose);

      await harness.controller.startConversation();
      harness.speech.completeCurrent('Câu hỏi');
      await _flush();

      expect(harness.controllerState.phase, AiVoicePhase.error);
      expect(harness.controllerState.errorMessage, AiVoiceCopy.ttsUnavailable);
      expect(harness.speech.listenCount, 1);
    });
  });
}

bool _isTurnEvent(String event) =>
    event.startsWith('stt:start') ||
    event.startsWith('stt:end') ||
    event.startsWith('repo:start') ||
    event.startsWith('repo:end') ||
    event.startsWith('tts:start') ||
    event.startsWith('tts:end');

Future<void> _flush([int cycles = 12]) async {
  for (var i = 0; i < cycles; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  final _ActivityGuard guard = _ActivityGuard();
  late final _FakeSpeech speech;
  late final _FakeRepository repository;
  late final _FakeTts tts;
  late final ProviderContainer container;

  _Harness({
    List<Object> repositoryResults = const [],
    Object? speechInitializeError,
    Object? ttsError,
  }) {
    speech = _FakeSpeech(guard, initializeError: speechInitializeError);
    repository = _FakeRepository(guard, results: repositoryResults);
    tts = _FakeTts(guard, speakError: ttsError);
    container = ProviderContainer(
      overrides: [
        speechRecognitionGatewayProvider.overrideWithValue(speech),
        textToSpeechGatewayProvider.overrideWithValue(tts),
        aiVoiceRepositoryProvider.overrideWithValue(repository),
        aiVoiceTurnDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
  }

  AiVoiceController get controller =>
      container.read(aiVoiceControllerProvider.notifier);

  AiVoiceState get controllerState => container.read(aiVoiceControllerProvider);

  void dispose() => container.dispose();
}

class _ActivityGuard {
  bool listening = false;
  bool thinking = false;
  bool speaking = false;
  final List<String> overlaps = [];
  final List<String> events = [];

  void assertOnly(String stage) {
    final active = <String>[
      if (listening) 'STT',
      if (thinking) 'backend',
      if (speaking) 'TTS',
    ];
    if (active.isNotEmpty) {
      overlaps.add('$stage overlapped ${active.join(',')}');
    }
  }
}

class _FakeSpeech implements SpeechRecognitionGateway {
  final _ActivityGuard guard;
  final Object? initializeError;
  Completer<String>? _current;
  int listenCount = 0;
  final List<Duration> listenDurations = [];
  final List<Duration> pauseDurations = [];

  _FakeSpeech(this.guard, {this.initializeError});

  @override
  Future<bool> initialize() async {
    if (initializeError != null) throw initializeError!;
    return true;
  }

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(minutes: 3),
    Duration pauseFor = const Duration(seconds: 1),
  }) async {
    guard.assertOnly('STT');
    guard.listening = true;
    listenCount++;
    listenDurations.add(listenFor);
    pauseDurations.add(pauseFor);
    guard.events.add('stt:start:$listenCount');
    final completer = Completer<String>();
    _current = completer;
    try {
      return await completer.future;
    } finally {
      guard.listening = false;
      guard.events.add('stt:end:$listenCount');
      if (identical(_current, completer)) _current = null;
    }
  }

  void completeCurrent(String transcript) {
    final completer = _current;
    if (completer == null || completer.isCompleted) {
      throw StateError('No active speech listen');
    }
    completer.complete(transcript);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {
    final completer = _current;
    if (completer != null && !completer.isCompleted) completer.complete('');
  }
}

class _FakeRepository implements AiVoiceRepository {
  final _ActivityGuard guard;
  final List<Object> results;
  final List<String> messages = [];
  int resetCount = 0;

  _FakeRepository(this.guard, {required List<Object> results})
    : results = List<Object>.from(results);

  @override
  Future<String> sendTurn(String message) async {
    guard.assertOnly('backend');
    guard.thinking = true;
    guard.events.add('repo:start:$message');
    messages.add(message);
    try {
      final result = results.isEmpty ? 'Nabi trả lời' : results.removeAt(0);
      if (result is Completer<String>) return await result.future;
      if (result is Exception) throw result;
      if (result is Error) throw result;
      return result as String;
    } finally {
      guard.thinking = false;
      guard.events.add('repo:end:$message');
    }
  }

  @override
  void resetSession() {
    resetCount++;
  }
}

class _FakeTts implements TextToSpeechGateway {
  final _ActivityGuard guard;
  final Object? speakError;
  Completer<void>? _current;
  int speakCount = 0;

  _FakeTts(this.guard, {this.speakError});

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {
    guard.assertOnly('TTS');
    guard.speaking = true;
    speakCount++;
    guard.events.add('tts:start:$text');
    try {
      if (speakError != null) throw speakError!;
      final completer = Completer<void>();
      _current = completer;
      await completer.future;
    } finally {
      guard.speaking = false;
      guard.events.add('tts:end:$text');
      _current = null;
    }
  }

  void completeCurrent() {
    final completer = _current;
    if (completer == null || completer.isCompleted) {
      throw StateError('No active TTS');
    }
    completer.complete();
  }

  @override
  Future<void> stop() async {
    final completer = _current;
    if (completer != null && !completer.isCompleted) completer.complete();
  }
}

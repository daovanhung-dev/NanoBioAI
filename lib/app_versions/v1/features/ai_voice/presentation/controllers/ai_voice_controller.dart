import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai_voice_copy.dart';
import '../../domain/entities/ai_voice_state.dart';
import '../../domain/gateways/voice_gateways.dart';
import '../../domain/repositories/ai_voice_repository.dart';
import '../../domain/voice_chat_exception.dart';
import '../../providers/voice_dependencies.dart';

class AiVoiceController extends Notifier<AiVoiceState> {
  late final SpeechRecognitionGateway _speech;
  late final TextToSpeechGateway _tts;
  late final AiVoiceRepository _repository;
  late final Duration _turnDelay;

  bool _isDisposed = false;
  int _generation = 0;

  @override
  AiVoiceState build() {
    _speech = ref.read(speechRecognitionGatewayProvider);
    _tts = ref.read(textToSpeechGatewayProvider);
    _repository = ref.read(aiVoiceRepositoryProvider);
    _turnDelay = ref.read(aiVoiceTurnDelayProvider);
    ref.onDispose(() {
      _isDisposed = true;
      _generation++;
      _repository.resetSession();
      unawaited(_cancelDevices());
    });
    return const AiVoiceState();
  }

  /// Prepares presentation state only. Device permission and microphone access
  /// are deferred until the user explicitly presses Start.
  Future<void> initialize() async {
    if (_isDisposed || state.isInitialized) return;
    state = state.copyWith(
      phase: AiVoicePhase.idle,
      sessionState: AiVoiceSessionState.stopped,
      isInitialized: true,
      clearError: true,
    );
  }

  Future<void> startConversation() async {
    if (_isDisposed || state.isSessionInProgress) return;

    final generation = ++_generation;
    _repository.resetSession();
    state = state.copyWith(
      phase: AiVoicePhase.initializing,
      sessionState: AiVoiceSessionState.starting,
      transcript: '',
      response: '',
      isInitialized: true,
      clearError: true,
    );

    try {
      final speechAvailable = await _speech.initialize();
      if (!speechAvailable) {
        throw const SpeechRecognitionUnavailableException();
      }
      await _tts.initialize();
      if (!_isCurrent(generation)) return;

      state = state.copyWith(
        phase: AiVoicePhase.listening,
        sessionState: AiVoiceSessionState.active,
        clearError: true,
      );
      unawaited(_runConversation(generation));
    } on SpeechRecognitionPermissionDeniedException {
      if (_isCurrent(generation)) {
        await _stopWithFailure(
          phase: AiVoicePhase.permissionDenied,
          message: AiVoiceCopy.permissionDenied,
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        await _stopWithFailure(
          phase: AiVoicePhase.error,
          message: AiVoiceCopy.unavailable,
        );
      }
    }
  }

  Future<void> listenAndRespond() => startConversation();

  void setReactionSpeed(AiVoiceReactionSpeed speed) {
    if (_isDisposed || state.isSessionInProgress) return;
    state = state.copyWith(reactionSpeed: speed);
  }

  Future<void> _runConversation(int generation) async {
    while (_isCurrent(generation) && state.isSessionActive) {
      state = state.copyWith(phase: AiVoicePhase.listening, clearError: true);

      final String transcript;
      try {
        transcript = (await _speech.listenOnce(
          localeId: 'vi_VN',
          listenFor: const Duration(minutes: 3),
          pauseFor: state.reactionSpeed.pauseFor,
        )).trim();
        await _speech.stop();
      } on SpeechRecognitionPermissionDeniedException {
        if (_isCurrent(generation)) {
          await _stopWithFailure(
            phase: AiVoicePhase.permissionDenied,
            message: AiVoiceCopy.permissionDenied,
          );
        }
        return;
      } catch (_) {
        if (_isCurrent(generation)) {
          await _stopWithFailure(
            phase: AiVoicePhase.error,
            message: AiVoiceCopy.unavailable,
          );
        }
        return;
      }

      if (!_isCurrent(generation) || !state.isSessionActive) return;
      if (transcript.isEmpty) {
        await _waitBeforeNextTurn(generation);
        continue;
      }

      state = state.copyWith(
        phase: AiVoicePhase.thinking,
        transcript: transcript,
      );

      final String response;
      try {
        response = (await _repository.sendTurn(transcript)).trim();
      } on VoiceChatException catch (error) {
        if (_isCurrent(generation)) {
          await _stopWithFailure(
            phase: AiVoicePhase.error,
            message: _messageForVoiceFailure(error.failure),
          );
        }
        return;
      } catch (_) {
        if (_isCurrent(generation)) {
          await _stopWithFailure(
            phase: AiVoicePhase.error,
            message: AiVoiceCopy.temporarilyUnavailable,
          );
        }
        return;
      }

      if (!_isCurrent(generation) || !state.isSessionActive) return;
      if (response.isEmpty) {
        await _stopWithFailure(
          phase: AiVoicePhase.error,
          message: AiVoiceCopy.invalidResponse,
        );
        return;
      }

      state = state.copyWith(phase: AiVoicePhase.speaking, response: response);
      try {
        await _tts.speak(response);
      } catch (_) {
        if (_isCurrent(generation)) {
          await _stopWithFailure(
            phase: AiVoicePhase.error,
            message: AiVoiceCopy.ttsUnavailable,
          );
        }
        return;
      }

      if (!_isCurrent(generation) || !state.isSessionActive) return;
      await _waitBeforeNextTurn(generation);
    }
  }

  Future<void> _waitBeforeNextTurn(int generation) async {
    if (_turnDelay > Duration.zero) await Future<void>.delayed(_turnDelay);
    if (!_isCurrent(generation)) return;
  }

  Future<void> stopConversation() async {
    if (_isDisposed) return;
    _generation++;
    _repository.resetSession();
    if (state.isSessionInProgress) {
      state = state.copyWith(sessionState: AiVoiceSessionState.stopping);
    }
    await _cancelDevices();
    if (_isDisposed) return;
    state = state.copyWith(
      phase: AiVoicePhase.idle,
      sessionState: AiVoiceSessionState.stopped,
      clearError: true,
      isInitialized: true,
    );
  }

  /// Route disposal cannot publish synchronously while Flutter is unmounting
  /// the listening widget. Cleanup starts immediately; idle is published only
  /// after the device cancellation future yields.
  Future<void> leavePage() async {
    if (_isDisposed) return;
    _generation++;
    _repository.resetSession();
    await _cancelDevices();
    if (_isDisposed) return;
    state = state.copyWith(
      phase: AiVoicePhase.idle,
      sessionState: AiVoiceSessionState.stopped,
      clearError: true,
      isInitialized: true,
    );
  }

  Future<void> handleAppLifecycleState(AppLifecycleState lifecycleState) async {
    if (lifecycleState != AppLifecycleState.resumed &&
        state.isSessionInProgress) {
      await stopConversation();
    }
  }

  Future<void> _stopWithFailure({
    required AiVoicePhase phase,
    required String message,
  }) async {
    _generation++;
    _repository.resetSession();
    await _cancelDevices();
    if (_isDisposed) return;
    state = state.copyWith(
      phase: phase,
      sessionState: AiVoiceSessionState.stopped,
      errorMessage: message,
      isInitialized: true,
    );
  }

  Future<void> _cancelDevices() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Best-effort cleanup; the generation token already blocks late work.
    }
    try {
      await _tts.stop();
    } catch (_) {
      // Best-effort cleanup; the user-facing failure was set by the caller.
    }
  }

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  String _messageForVoiceFailure(VoiceChatFailure failure) {
    return switch (failure) {
      VoiceChatFailure.temporarilyUnavailable =>
        AiVoiceCopy.temporarilyUnavailable,
      VoiceChatFailure.invalidResponse => AiVoiceCopy.invalidResponse,
      VoiceChatFailure.invalidRequest => AiVoiceCopy.temporarilyUnavailable,
      VoiceChatFailure.unavailable => AiVoiceCopy.unavailable,
    };
  }
}

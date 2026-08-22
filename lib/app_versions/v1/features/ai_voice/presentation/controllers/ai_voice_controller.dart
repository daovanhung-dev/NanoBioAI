import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai_voice_copy.dart';
import '../../domain/entities/ai_voice_state.dart';
import '../../domain/entities/voice_live_event.dart';
import '../../domain/gateways/voice_live_gateway.dart';
import '../../domain/speech_transcript_merger.dart';
import '../../providers/voice_live_dependencies.dart';

class AiVoiceController extends Notifier<AiVoiceState> {
  StreamSubscription<VoiceLiveEvent>? _sessionSubscription;
  bool _isDisposed = false;
  int _sessionGeneration = 0;
  late final VoiceLiveGateway _liveGateway;

  @override
  AiVoiceState build() {
    _liveGateway = ref.read(voiceLiveGatewayProvider);
    ref.onDispose(() {
      _isDisposed = true;
      _sessionGeneration++;
      unawaited(_disposeSession());
    });
    return const AiVoiceState();
  }

  Future<void> initialize() {
    if (_isDisposed || state.isInitialized) return Future<void>.value();
    state = state.copyWith(
      phase: AiVoicePhase.idle,
      isInitialized: true,
      clearError: true,
    );
    return Future<void>.value();
  }

  /// Opens a single Gemini Live voice session. This method is intentionally
  /// called only from the user's explicit start action.
  Future<void> startConversation() async {
    if (_isDisposed || state.isSessionInProgress) return;

    final generation = ++_sessionGeneration;
    state = state.copyWith(
      phase: AiVoicePhase.connecting,
      sessionState: AiVoiceSessionState.starting,
      isListeningPaused: false,
      isMuted: false,
      isBargeInArmed: true,
      hasSpeechStarted: false,
      partialTranscript: '',
      finalTranscript: '',
      responseDraft: '',
      spokenResponse: '',
      clearError: true,
      clearSessionStartedAt: true,
      clearCurrentTurnStartedAt: true,
    );

    try {
      final events = await _liveGateway.startSession();
      if (!_isCurrentGeneration(generation)) {
        await _liveGateway.stopSession();
        return;
      }
      await _sessionSubscription?.cancel();
      if (!_isCurrentGeneration(generation)) {
        await _liveGateway.stopSession();
        return;
      }
      _sessionSubscription = events.listen(
        (event) => _handleLiveEvent(event, generation),
        onError: (Object error, StackTrace stackTrace) =>
            _handleUnhandledEventError(error, stackTrace, generation),
      );
      if (!_isCurrentGeneration(generation)) {
        await _disposeSession();
        return;
      }
      state = state.copyWith(
        phase: AiVoicePhase.listening,
        sessionState: AiVoiceSessionState.active,
        sessionStartedAt: DateTime.now(),
        isBargeInArmed: true,
      );
    } catch (error) {
      _handleFailure(
        AiVoiceCopy.responseUnavailable,
        generation: generation,
        error: error,
      );
    }
  }

  /// Kept as a small compatibility surface for callers of the prior
  /// one-shot voice controller.
  Future<void> listenAndRespond() => startConversation();

  Future<void> toggleListening() async {
    if (!state.isSessionActive || _isDisposed) return;
    if (state.isListeningPaused) {
      await resumeListening();
      return;
    }
    await pauseListening();
  }

  Future<void> pauseListening() async {
    if (!state.isSessionActive || state.isListeningPaused || _isDisposed) {
      return;
    }
    final generation = _sessionGeneration;
    try {
      await _liveGateway.pauseInput();
      if (!_isCurrentGeneration(generation) || !state.isSessionActive) return;
      state = state.copyWith(
        phase: AiVoicePhase.paused,
        isListeningPaused: true,
        hasSpeechStarted: false,
        clearCurrentTurnStartedAt: true,
      );
    } catch (error) {
      _handleFailure(
        AiVoiceCopy.responseUnavailable,
        generation: generation,
        error: error,
      );
    }
  }

  Future<void> resumeListening() async {
    if (!state.isSessionActive || !state.isListeningPaused || _isDisposed) {
      return;
    }
    final generation = _sessionGeneration;
    try {
      await _liveGateway.resumeInput();
      if (!_isCurrentGeneration(generation) || !state.isSessionActive) return;
      state = state.copyWith(
        phase: AiVoicePhase.listening,
        isListeningPaused: false,
        hasSpeechStarted: false,
        isBargeInArmed: true,
        clearCurrentTurnStartedAt: true,
      );
    } catch (error) {
      _handleFailure(
        AiVoiceCopy.responseUnavailable,
        generation: generation,
        error: error,
      );
    }
  }

  Future<void> setMuted(bool muted) async {
    if (!state.isSessionActive || _isDisposed) return;
    final generation = _sessionGeneration;
    try {
      await _liveGateway.setOutputMuted(muted);
      if (!_isCurrentGeneration(generation) || !state.isSessionActive) return;
      state = state.copyWith(isMuted: muted);
    } catch (error) {
      _handleFailure(
        AiVoiceCopy.responseUnavailable,
        generation: generation,
        error: error,
      );
    }
  }

  Future<void> stopConversation() async {
    if (_isDisposed || !state.isSessionInProgress) {
      return;
    }
    _sessionGeneration++;
    state = state.copyWith(sessionState: AiVoiceSessionState.stopping);
    await _disposeSession();
    if (_isDisposed) return;
    state = const AiVoiceState(phase: AiVoicePhase.idle, isInitialized: true);
  }

  Future<void> handleAppLifecycleState(AppLifecycleState lifecycleState) async {
    if (lifecycleState == AppLifecycleState.resumed ||
        !state.isSessionInProgress) {
      return;
    }
    await stopConversation();
  }

  Future<void> _disposeSession() async {
    final subscription = _sessionSubscription;
    _sessionSubscription = null;
    await subscription?.cancel();
    await _liveGateway.stopSession();
  }

  void _handleLiveEvent(VoiceLiveEvent event, int generation) {
    if (!_isCurrentGeneration(generation)) return;
    switch (event.type) {
      case VoiceLiveEventType.connected:
      case VoiceLiveEventType.reconnected:
        state = state.copyWith(
          phase: AiVoicePhase.listening,
          sessionState: AiVoiceSessionState.active,
          isListeningPaused: false,
          isBargeInArmed: true,
          clearError: true,
        );
        break;
      case VoiceLiveEventType.listening:
        if (!state.isListeningPaused) {
          state = state.copyWith(
            phase: AiVoicePhase.listening,
            sessionState: AiVoiceSessionState.active,
            isBargeInArmed: true,
          );
        }
        break;
      case VoiceLiveEventType.inputTranscript:
        final merged = SpeechTranscriptMerger.merge(
          state.finalTranscript,
          event.transcript,
        );
        state = state.copyWith(
          phase: state.isListeningPaused
              ? AiVoicePhase.paused
              : AiVoicePhase.userSpeaking,
          partialTranscript: event.transcript,
          finalTranscript: merged,
          hasSpeechStarted: event.transcript.trim().isNotEmpty,
          currentTurnStartedAt: state.hasSpeechStarted ? null : DateTime.now(),
        );
        break;
      case VoiceLiveEventType.outputTranscript:
        final response = SpeechTranscriptMerger.merge(
          state.responseDraft,
          event.transcript,
        );
        state = state.copyWith(
          phase: AiVoicePhase.speaking,
          responseDraft: response,
          spokenResponse: response,
          hasSpeechStarted: false,
          isBargeInArmed: true,
          clearCurrentTurnStartedAt: true,
        );
        break;
      case VoiceLiveEventType.outputAudio:
        if (!state.isMuted && !state.isListeningPaused) {
          state = state.copyWith(
            phase: AiVoicePhase.speaking,
            hasSpeechStarted: false,
            isBargeInArmed: true,
          );
        }
        break;
      case VoiceLiveEventType.interrupted:
        state = state.copyWith(
          phase: state.isListeningPaused
              ? AiVoicePhase.paused
              : AiVoicePhase.interrupted,
          responseDraft: '',
          spokenResponse: '',
          isBargeInArmed: true,
          hasSpeechStarted: false,
          clearCurrentTurnStartedAt: true,
        );
        break;
      case VoiceLiveEventType.turnCompleted:
        state = state.copyWith(
          phase: state.isListeningPaused
              ? AiVoicePhase.paused
              : AiVoicePhase.listening,
          partialTranscript: '',
          responseDraft: '',
          hasSpeechStarted: false,
          isBargeInArmed: true,
          clearCurrentTurnStartedAt: true,
        );
        break;
      case VoiceLiveEventType.paused:
        state = state.copyWith(
          phase: AiVoicePhase.paused,
          isListeningPaused: true,
          hasSpeechStarted: false,
          clearCurrentTurnStartedAt: true,
        );
        break;
      case VoiceLiveEventType.reconnecting:
        state = state.copyWith(phase: AiVoicePhase.reconnecting);
        break;
      case VoiceLiveEventType.permissionDenied:
        _sessionGeneration++;
        state = state.copyWith(
          phase: AiVoicePhase.permissionDenied,
          sessionState: AiVoiceSessionState.permissionDenied,
          errorMessage: AiVoiceCopy.permissionDenied,
        );
        unawaited(_disposeSession());
        break;
      case VoiceLiveEventType.failure:
        _handleFailure(
          AiVoiceCopy.responseUnavailable,
          generation: generation,
          error: event.error,
        );
        break;
      case VoiceLiveEventType.closed:
        if (state.sessionState == AiVoiceSessionState.active) {
          state = state.copyWith(
            phase: AiVoicePhase.idle,
            sessionState: AiVoiceSessionState.stopped,
            isListeningPaused: false,
            isBargeInArmed: false,
          );
        }
        break;
    }
  }

  void _handleUnhandledEventError(
    Object error,
    StackTrace stackTrace,
    int generation,
  ) {
    _handleFailure(
      AiVoiceCopy.responseUnavailable,
      generation: generation,
      error: error,
    );
  }

  bool _isCurrentGeneration(int generation) =>
      !_isDisposed && generation == _sessionGeneration;

  void _handleFailure(
    String message, {
    required int generation,
    Object? error,
  }) {
    if (!_isCurrentGeneration(generation)) return;
    _debugFailure(error);
    _sessionGeneration++;
    state = state.copyWith(
      phase: AiVoicePhase.error,
      sessionState: AiVoiceSessionState.error,
      errorMessage: _failureMessage(message, error),
      isListeningPaused: false,
      isBargeInArmed: false,
      hasSpeechStarted: false,
      clearCurrentTurnStartedAt: true,
    );
    unawaited(_disposeSession());
  }

  String _failureMessage(String fallback, Object? error) {
    return error is VoiceLiveConfigurationException
        ? AiVoiceCopy.voiceConfigurationMissing
        : fallback;
  }

  void _debugFailure(Object? error) {
    assert(() {
      debugPrint(
        '[ai_voice] session failure errorType=${error?.runtimeType ?? 'unknown'}',
      );
      return true;
    }());
  }
}

enum AiVoicePhase {
  initializing,
  idle,
  connecting,
  listening,
  userSpeaking,
  speaking,
  paused,
  reconnecting,
  interrupted,
  error,
  permissionDenied,

  // Retained while callers migrate from the pre-Live implementation.
  greeting,
  transcribing,
  finalizingInput,
  thinking,
  waitingFirstToken,
  streamingResponse,
  recoveringRecognizer,
}

enum AiVoiceSessionState {
  stopped,
  starting,
  active,
  stopping,
  permissionDenied,
  error,
}

class AiVoiceState {
  final AiVoicePhase phase;
  final AiVoiceSessionState sessionState;
  final String partialTranscript;
  final String finalTranscript;
  final String responseDraft;
  final String spokenResponse;
  final String? errorMessage;
  final bool isMuted;
  final bool isInitialized;
  final bool isListeningPaused;
  final bool isBargeInArmed;
  final bool hasSpeechStarted;
  final bool isContinuousListeningEnabled;
  final double voiceActivityLevel;
  final String conversationSessionId;
  final int turnId;
  final DateTime? sessionStartedAt;
  final DateTime? currentTurnStartedAt;

  const AiVoiceState({
    this.phase = AiVoicePhase.initializing,
    this.sessionState = AiVoiceSessionState.stopped,
    this.partialTranscript = '',
    this.finalTranscript = '',
    this.responseDraft = '',
    this.spokenResponse = '',
    this.errorMessage,
    this.isMuted = false,
    this.isInitialized = false,
    this.isListeningPaused = false,
    this.isBargeInArmed = false,
    this.hasSpeechStarted = false,
    this.isContinuousListeningEnabled = true,
    this.voiceActivityLevel = 0,
    this.conversationSessionId = '',
    this.turnId = 0,
    this.sessionStartedAt,
    this.currentTurnStartedAt,
  });

  String get transcript =>
      finalTranscript.isNotEmpty ? finalTranscript : partialTranscript;
  String get response => responseDraft;
  bool get isSessionActive => sessionState == AiVoiceSessionState.active;
  bool get isSessionInProgress =>
      sessionState == AiVoiceSessionState.starting ||
      sessionState == AiVoiceSessionState.active ||
      sessionState == AiVoiceSessionState.stopping;
  bool get isListening =>
      phase == AiVoicePhase.listening || phase == AiVoicePhase.userSpeaking;
  bool get isBusy =>
      phase == AiVoicePhase.connecting ||
      phase == AiVoicePhase.userSpeaking ||
      phase == AiVoicePhase.speaking ||
      phase == AiVoicePhase.reconnecting;

  AiVoiceState copyWith({
    AiVoicePhase? phase,
    AiVoiceSessionState? sessionState,
    String? partialTranscript,
    String? finalTranscript,
    String? responseDraft,
    String? spokenResponse,
    String? errorMessage,
    bool clearError = false,
    bool? isMuted,
    bool? isInitialized,
    bool? isListeningPaused,
    bool? isBargeInArmed,
    bool? hasSpeechStarted,
    bool? isContinuousListeningEnabled,
    double? voiceActivityLevel,
    String? conversationSessionId,
    int? turnId,
    DateTime? sessionStartedAt,
    DateTime? currentTurnStartedAt,
    bool clearSessionStartedAt = false,
    bool clearCurrentTurnStartedAt = false,
  }) {
    return AiVoiceState(
      phase: phase ?? this.phase,
      sessionState: sessionState ?? this.sessionState,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      finalTranscript: finalTranscript ?? this.finalTranscript,
      responseDraft: responseDraft ?? this.responseDraft,
      spokenResponse: spokenResponse ?? this.spokenResponse,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isMuted: isMuted ?? this.isMuted,
      isInitialized: isInitialized ?? this.isInitialized,
      isListeningPaused: isListeningPaused ?? this.isListeningPaused,
      isBargeInArmed: isBargeInArmed ?? this.isBargeInArmed,
      hasSpeechStarted: hasSpeechStarted ?? this.hasSpeechStarted,
      isContinuousListeningEnabled:
          isContinuousListeningEnabled ?? this.isContinuousListeningEnabled,
      voiceActivityLevel: voiceActivityLevel ?? this.voiceActivityLevel,
      conversationSessionId:
          conversationSessionId ?? this.conversationSessionId,
      turnId: turnId ?? this.turnId,
      sessionStartedAt: clearSessionStartedAt
          ? null
          : sessionStartedAt ?? this.sessionStartedAt,
      currentTurnStartedAt: clearCurrentTurnStartedAt
          ? null
          : currentTurnStartedAt ?? this.currentTurnStartedAt,
    );
  }
}

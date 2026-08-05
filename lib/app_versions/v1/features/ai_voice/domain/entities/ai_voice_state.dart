enum AiVoicePhase {
  initializing,
  idle,
  greeting,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
  permissionDenied,
}

class AiVoiceState {
  final AiVoicePhase phase;
  final String transcript;
  final String response;
  final String? errorMessage;
  final bool isMuted;
  final bool isInitialized;

  const AiVoiceState({
    this.phase = AiVoicePhase.initializing,
    this.transcript = '',
    this.response = '',
    this.errorMessage,
    this.isMuted = false,
    this.isInitialized = false,
  });

  bool get isBusy =>
      phase == AiVoicePhase.initializing ||
      phase == AiVoicePhase.greeting ||
      phase == AiVoicePhase.listening ||
      phase == AiVoicePhase.transcribing ||
      phase == AiVoicePhase.thinking ||
      phase == AiVoicePhase.speaking;

  AiVoiceState copyWith({
    AiVoicePhase? phase,
    String? transcript,
    String? response,
    String? errorMessage,
    bool clearError = false,
    bool? isMuted,
    bool? isInitialized,
  }) {
    return AiVoiceState(
      phase: phase ?? this.phase,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isMuted: isMuted ?? this.isMuted,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

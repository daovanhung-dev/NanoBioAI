enum AiVoicePhase {
  initializing,
  idle,
  listening,
  thinking,
  speaking,
  error,
  permissionDenied,
}

enum AiVoiceSessionState { stopped, starting, active, stopping }

enum AiVoiceReactionSpeed {
  ultraFast(
    label: 'Siêu nhanh 0,2 giây',
    pauseFor: Duration(milliseconds: 200),
  ),
  fast(label: 'Nhanh 0,5 giây', pauseFor: Duration(milliseconds: 500)),
  normal(label: 'Bình thường 1 giây', pauseFor: Duration(seconds: 1)),
  slow(label: 'Chậm 2 giây', pauseFor: Duration(seconds: 2));

  const AiVoiceReactionSpeed({required this.label, required this.pauseFor});

  final String label;
  final Duration pauseFor;
}

class AiVoiceState {
  final AiVoicePhase phase;
  final AiVoiceSessionState sessionState;
  final String transcript;
  final String response;
  final String? errorMessage;
  final bool isInitialized;
  final AiVoiceReactionSpeed reactionSpeed;

  const AiVoiceState({
    this.phase = AiVoicePhase.initializing,
    this.sessionState = AiVoiceSessionState.stopped,
    this.transcript = '',
    this.response = '',
    this.errorMessage,
    this.isInitialized = false,
    this.reactionSpeed = AiVoiceReactionSpeed.normal,
  });

  bool get isSessionActive => sessionState == AiVoiceSessionState.active;

  bool get isSessionInProgress =>
      sessionState == AiVoiceSessionState.starting ||
      sessionState == AiVoiceSessionState.active ||
      sessionState == AiVoiceSessionState.stopping;

  bool get isListening => phase == AiVoicePhase.listening;

  AiVoiceState copyWith({
    AiVoicePhase? phase,
    AiVoiceSessionState? sessionState,
    String? transcript,
    String? response,
    String? errorMessage,
    bool clearError = false,
    bool? isInitialized,
    AiVoiceReactionSpeed? reactionSpeed,
  }) {
    return AiVoiceState(
      phase: phase ?? this.phase,
      sessionState: sessionState ?? this.sessionState,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      reactionSpeed: reactionSpeed ?? this.reactionSpeed,
    );
  }
}

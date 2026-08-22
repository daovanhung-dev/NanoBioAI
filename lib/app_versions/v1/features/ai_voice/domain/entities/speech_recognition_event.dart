enum SpeechRecognitionEventType {
  started,
  soundLevel,
  partial,
  finalSegment,
  restarting,
  completed,
  error,
}

class SpeechRecognitionEvent {
  final SpeechRecognitionEventType type;
  final String transcript;
  final double soundLevel;
  final Object? error;
  final int generation;

  const SpeechRecognitionEvent._({
    required this.type,
    this.transcript = '',
    this.soundLevel = 0,
    this.error,
    required this.generation,
  });

  const SpeechRecognitionEvent.started({required int generation})
      : this._(
          type: SpeechRecognitionEventType.started,
          generation: generation,
        );

  const SpeechRecognitionEvent.soundLevel({
    required double level,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.soundLevel,
          soundLevel: level,
          generation: generation,
        );

  const SpeechRecognitionEvent.partial({
    required String transcript,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.partial,
          transcript: transcript,
          generation: generation,
        );

  const SpeechRecognitionEvent.finalSegment({
    required String transcript,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.finalSegment,
          transcript: transcript,
          generation: generation,
        );

  const SpeechRecognitionEvent.restarting({
    required String transcript,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.restarting,
          transcript: transcript,
          generation: generation,
        );

  const SpeechRecognitionEvent.completed({
    required String transcript,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.completed,
          transcript: transcript,
          generation: generation,
        );

  const SpeechRecognitionEvent.failure({
    required Object error,
    required int generation,
  }) : this._(
          type: SpeechRecognitionEventType.error,
          error: error,
          generation: generation,
        );
}

enum AIChatStreamEventType { delta, completed }

class AIChatStreamEvent {
  final AIChatStreamEventType type;
  final String delta;
  final String fullText;

  const AIChatStreamEvent._({
    required this.type,
    required this.delta,
    required this.fullText,
  });

  const AIChatStreamEvent.delta({
    required String delta,
    required String fullText,
  }) : this._(
         type: AIChatStreamEventType.delta,
         delta: delta,
         fullText: fullText,
       );

  const AIChatStreamEvent.completed({required String fullText})
    : this._(
        type: AIChatStreamEventType.completed,
        delta: '',
        fullText: fullText,
      );
}

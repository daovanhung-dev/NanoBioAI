import '../domain/entities/Nabi_expression.dart';

/// State duy nhất điều khiển biểu cảm, lời gợi ý và hiển thị của Nabi.
class NabiState {
  const NabiState({
    required this.context,
    required this.emotion,
    required this.bubbleText,
    this.isVisible = true,
    this.isMinimized = false,
    this.isChatOpen = false,
  });

  factory NabiState.initial() => const NabiState(
    context: NabiContext.app,
    emotion: NabiEmotion.greeting,
    bubbleText: 'Nabi ở đây, mình cùng chăm sóc hôm nay nhé.',
  );

  final NabiContext context;
  final NabiEmotion emotion;

  /// Lời nhắn ngắn, không lộ thuật ngữ kỹ thuật.
  final String bubbleText;
  final bool isVisible;
  final bool isMinimized;
  final bool isChatOpen;

  NabiState copyWith({
    NabiContext? context,
    NabiEmotion? emotion,
    String? bubbleText,
    bool? isVisible,
    bool? isMinimized,
    bool? isChatOpen,
  }) {
    return NabiState(
      context: context ?? this.context,
      emotion: emotion ?? this.emotion,
      bubbleText: bubbleText ?? this.bubbleText,
      isVisible: isVisible ?? this.isVisible,
      isMinimized: isMinimized ?? this.isMinimized,
      isChatOpen: isChatOpen ?? this.isChatOpen,
    );
  }
}

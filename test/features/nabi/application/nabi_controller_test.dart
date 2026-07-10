import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiController', () {
    test('task hoàn thành phải chuyển sang biểu cảm chúc mừng', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(nabiControllerProvider.notifier)
          .dispatch(NabiEvent.taskCompleted);

      final state = container.read(nabiControllerProvider);
      expect(state.context, NabiContext.dailyTasks);
      expect(state.emotion, NabiEmotion.celebrating);
      expect(state.bubbleText, contains('làm tốt'));
    });

    test('AI đang xử lý phải là thinking và vẫn nhận diện AI Chat đang mở', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(nabiControllerProvider.notifier).setChatThinking();

      final state = container.read(nabiControllerProvider);
      expect(state.context, NabiContext.aiChat);
      expect(state.emotion, NabiEmotion.thinking);
      expect(state.isChatOpen, isTrue);
    });

    test('route context không được làm Nabi biến mất', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(nabiControllerProvider.notifier)
          .setContext(NabiContext.healthCalculation);

      final state = container.read(nabiControllerProvider);
      expect(state.isVisible, isTrue);
      expect(state.emotion, NabiEmotion.thinking);
    });
  });
}

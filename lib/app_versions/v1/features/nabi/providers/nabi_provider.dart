import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nabi_context.dart';
import '../domain/nabi_state_resolver.dart';
import '../domain/nabi_visual_state.dart';

/// Provider quản lý [NabiContext] toàn cục.
///
/// Bất kỳ trang nào cũng có thể cập nhật context thông qua:
///   ```dart
///   ref.read(NabiContextProvider.notifier).update((ctx) => ctx.copyWith(...));
///   ```
final NabiContextProvider = NotifierProvider<NabiContextNotifier, NabiContext>(
  NabiContextNotifier.new,
);

/// Provider tiện ích – trả về [NabiVisualState] đã được resolve.
/// Widget chỉ cần watch provider này.
final NabiVisualStateProvider = Provider<NabiVisualState>((ref) {
  final ctx = ref.watch(NabiContextProvider);
  return NabiStateResolver.resolve(ctx);
});

class NabiContextNotifier extends Notifier<NabiContext> {
  int _chatPulseToken = 0;

  @override
  NabiContext build() => const NabiContext();

  /// Cập nhật context theo dạng diff – chỉ thay trường cần thay.
  void update(NabiContext Function(NabiContext current) updater) {
    state = updater(state);
  }

  /// Đặt route hiện tại (gọi khi chuyển trang/tab).
  void setRoute(String routePath) {
    if (state.routePath == routePath) return;
    // Reset một số trạng thái tạm thời khi chuyển route
    state = state.copyWith(
      routePath: routePath,
      clearForceState: true,
      justCompletedTask: false,
      justSkippedTask: false,
      isPlanJustReady: false,
      syncJustSucceeded: false,
      isChatOpen: routePath.contains('/ai-chat'),
      isChatTyping: false,
      isChatAnswerReady: false,
    );
  }

  /// Chat bắt đầu hoặc dừng gõ.
  void setChatTyping({required bool typing}) {
    if (typing) _chatPulseToken++;
    state = state.copyWith(
      isChatTyping: typing,
      isChatAnswerReady: typing ? false : state.isChatAnswerReady,
      clearForceState: typing,
    );
  }

  /// Chat đã có câu trả lời.
  void setChatAnswerReady() {
    final token = ++_chatPulseToken;
    state = state.copyWith(isChatTyping: false, isChatAnswerReady: true);

    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (token != _chatPulseToken ||
          state.isChatTyping ||
          !state.isChatAnswerReady) {
        return;
      }

      state = state.copyWith(
        isChatAnswerReady: false,
        forceState: NabiVisualState.taskComplete,
      );

      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (token == _chatPulseToken &&
            state.forceState == NabiVisualState.taskComplete) {
          clearTransientState();
        }
      });
    });
  }

  void setChatFailed() {
    final token = ++_chatPulseToken;
    state = state.copyWith(
      isChatTyping: false,
      isChatAnswerReady: false,
      forceState: NabiVisualState.syncRetry,
    );

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (token == _chatPulseToken &&
          state.forceState == NabiVisualState.syncRetry) {
        clearTransientState();
      }
    });
  }

  /// Người dùng vừa hoàn thành task.
  void notifyTaskCompleted({double? newProgress}) {
    state = state.copyWith(
      justCompletedTask: true,
      justSkippedTask: false,
      dailyProgress: newProgress ?? state.dailyProgress,
    );
  }

  /// Người dùng vừa bỏ qua task.
  void notifyTaskSkipped() {
    state = state.copyWith(justSkippedTask: true, justCompletedTask: false);
  }

  /// Sau khi animation hoàn thành, reset về trạng thái bình thường.
  void clearTransientState() {
    state = state.copyWith(
      justCompletedTask: false,
      justSkippedTask: false,
      isPlanJustReady: false,
      syncJustSucceeded: false,
      isChatAnswerReady: false,
      clearForceState: true,
    );
  }

  /// Cập nhật trạng thái onboarding.
  void setOnboardingStep(int step) {
    state = state.copyWith(isOnboarding: true, onboardingStep: step);
  }

  void completeOnboarding() {
    state = state.copyWith(isOnboarding: false, onboardingStep: null);
  }

  /// Cập nhật tiến độ hàng ngày (0.0 – 1.0).
  void setDailyProgress(double progress) {
    state = state.copyWith(dailyProgress: progress);
  }

  /// Cập nhật chuỗi streak (số ngày).
  void setStreak(int days) {
    state = state.copyWith(streakDays: days);
  }
}

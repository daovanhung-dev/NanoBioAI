import '../domain/entities/Nabi_expression.dart';

/// Quy tắc tập trung: event/ngữ cảnh nào thì Nabi biểu cảm và nói gì.
///
/// Các câu nói giữ tone Nami/Nabi: ấm áp, ngắn gọn, không phán xét.
class NabiExpressionResolver {
  const NabiExpressionResolver._();

  static NabiResolvedPresentation fromEvent(
    NabiEvent event, {
    NabiContext fallbackContext = NabiContext.app,
    String? detail,
  }) {
    final defaultPresentation = switch (event) {
      NabiEvent.appOpened => const NabiResolvedPresentation(
          context: NabiContext.app,
          emotion: NabiEmotion.greeting,
          bubbleText: 'Nabi ở đây, mình cùng chăm sóc hôm nay nhé.',
        ),
      NabiEvent.onboardingStarted => const NabiResolvedPresentation(
          context: NabiContext.onboarding,
          emotion: NabiEmotion.greeting,
          bubbleText: 'Mình bắt đầu thật nhẹ nhàng nhé.',
        ),
      NabiEvent.onboardingStepCompleted => const NabiResolvedPresentation(
          context: NabiContext.onboarding,
          emotion: NabiEmotion.happy,
          bubbleText: 'Tốt lắm, Nabi đã hiểu bạn hơn một chút rồi.',
        ),
      NabiEvent.onboardingCompleted => const NabiResolvedPresentation(
          context: NabiContext.dashboard,
          emotion: NabiEmotion.celebrating,
          bubbleText: 'Tuyệt vời! Mình đã sẵn sàng cho hành trình mới.',
        ),
      NabiEvent.dashboardOpened => const NabiResolvedPresentation(
          context: NabiContext.dashboard,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Hôm nay mình tiến một bước nhỏ nhé.',
        ),
      NabiEvent.healthCalculationStarted => const NabiResolvedPresentation(
          context: NabiContext.healthCalculation,
          emotion: NabiEmotion.thinking,
          bubbleText: 'Nabi đang xem các chỉ số của bạn.',
        ),
      NabiEvent.healthCalculationCompleted => const NabiResolvedPresentation(
          context: NabiContext.healthCalculation,
          emotion: NabiEmotion.happy,
          bubbleText: 'Xong rồi, mình cùng xem kết quả nhé.',
        ),
      NabiEvent.mealPlanReady => const NabiResolvedPresentation(
          context: NabiContext.mealPlan,
          emotion: NabiEmotion.happy,
          bubbleText: 'Thực đơn của bạn đã sẵn sàng rồi.',
        ),
      NabiEvent.exercisePlanReady => const NabiResolvedPresentation(
          context: NabiContext.exercisePlan,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Mình vận động vừa sức thôi nhé.',
        ),
      NabiEvent.taskCompleted => const NabiResolvedPresentation(
          context: NabiContext.dailyTasks,
          emotion: NabiEmotion.celebrating,
          bubbleText: 'Bạn làm tốt lắm, Nabi vui cùng bạn!',
        ),
      NabiEvent.taskSkipped => const NabiResolvedPresentation(
          context: NabiContext.dailyTasks,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Không sao đâu, mình quay lại khi bạn sẵn sàng nhé.',
        ),
      NabiEvent.notificationOpened => const NabiResolvedPresentation(
          context: NabiContext.dailyTasks,
          emotion: NabiEmotion.listening,
          bubbleText: 'Nabi nhắc bạn một việc nhỏ thôi nè.',
        ),
      NabiEvent.aiChatOpened => const NabiResolvedPresentation(
          context: NabiContext.aiChat,
          emotion: NabiEmotion.listening,
          bubbleText: 'Nabi đang lắng nghe bạn đây.',
        ),
      NabiEvent.aiThinking => const NabiResolvedPresentation(
          context: NabiContext.aiChat,
          emotion: NabiEmotion.thinking,
          bubbleText: 'Để Nabi suy nghĩ một chút nhé.',
        ),
      NabiEvent.aiResponded => const NabiResolvedPresentation(
          context: NabiContext.aiChat,
          emotion: NabiEmotion.happy,
          bubbleText: 'Nabi đã tìm được điều phù hợp cho bạn.',
        ),
      NabiEvent.aiFailed => const NabiResolvedPresentation(
          context: NabiContext.aiChat,
          emotion: NabiEmotion.concerned,
          bubbleText: 'Nabi chưa trả lời được lúc này. Mình thử lại sau nhé.',
        ),
      NabiEvent.authenticationRequired => const NabiResolvedPresentation(
          context: NabiContext.authentication,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Đăng nhập để Nabi đồng hành cùng bạn lâu dài hơn nhé.',
        ),
      NabiEvent.synchronizationStarted => const NabiResolvedPresentation(
          context: NabiContext.synchronizing,
          emotion: NabiEmotion.thinking,
          bubbleText: 'Nabi đang cất giữ hành trình của bạn thật cẩn thận.',
        ),
      NabiEvent.synchronizationSucceeded => const NabiResolvedPresentation(
          context: NabiContext.dashboard,
          emotion: NabiEmotion.happy,
          bubbleText: 'Mọi thứ đã được cập nhật rồi.',
        ),
      NabiEvent.synchronizationFailed => const NabiResolvedPresentation(
          context: NabiContext.error,
          emotion: NabiEmotion.concerned,
          bubbleText: 'Nabi chưa cập nhật được. Dữ liệu của bạn vẫn an toàn nhé.',
        ),
      NabiEvent.formNeedsAttention => NabiResolvedPresentation(
          context: fallbackContext,
          emotion: NabiEmotion.concerned,
          bubbleText: 'Mình xem lại một chút để kết quả chính xác hơn nhé.',
        ),
      NabiEvent.noData => const NabiResolvedPresentation(
          context: NabiContext.empty,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Mình bắt đầu từ một điều nhỏ thôi nhé.',
        ),
      NabiEvent.networkUnavailable => const NabiResolvedPresentation(
          context: NabiContext.error,
          emotion: NabiEmotion.concerned,
          bubbleText: 'Nabi chưa kết nối được. Mình thử lại khi mạng ổn định nhé.',
        ),
    };

    return detail == null || detail.trim().isEmpty
        ? defaultPresentation
        : defaultPresentation.copyWith(bubbleText: detail.trim());
  }

  static NabiResolvedPresentation fromContext(NabiContext context) {
    return switch (context) {
      NabiContext.app => const NabiResolvedPresentation(
          context: NabiContext.app,
          emotion: NabiEmotion.idle,
          bubbleText: 'Chạm vào Nabi khi bạn cần một người đồng hành nhé.',
        ),
      NabiContext.onboarding => const NabiResolvedPresentation(
          context: NabiContext.onboarding,
          emotion: NabiEmotion.greeting,
          bubbleText: 'Mình đi từng bước thật nhẹ nhàng nhé.',
        ),
      NabiContext.dashboard => const NabiResolvedPresentation(
          context: NabiContext.dashboard,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Hôm nay bạn muốn bắt đầu từ đâu?',
        ),
      NabiContext.healthCalculation => const NabiResolvedPresentation(
          context: NabiContext.healthCalculation,
          emotion: NabiEmotion.thinking,
          bubbleText: 'Nabi đang cùng bạn nhìn các chỉ số.',
        ),
      NabiContext.mealPlan => const NabiResolvedPresentation(
          context: NabiContext.mealPlan,
          emotion: NabiEmotion.happy,
          bubbleText: 'Mình chọn điều phù hợp với cơ thể bạn nhé.',
        ),
      NabiContext.exercisePlan => const NabiResolvedPresentation(
          context: NabiContext.exercisePlan,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Nhẹ nhàng và đều đặn là đủ rồi.',
        ),
      NabiContext.dailyTasks => const NabiResolvedPresentation(
          context: NabiContext.dailyTasks,
          emotion: NabiEmotion.listening,
          bubbleText: 'Nabi cùng bạn hoàn thành từng việc nhỏ.',
        ),
      NabiContext.aiChat => const NabiResolvedPresentation(
          context: NabiContext.aiChat,
          emotion: NabiEmotion.listening,
          bubbleText: 'Nabi đang lắng nghe bạn đây.',
        ),
      NabiContext.authentication => const NabiResolvedPresentation(
          context: NabiContext.authentication,
          emotion: NabiEmotion.greeting,
          bubbleText: 'Rất vui được gặp bạn ở đây.',
        ),
      NabiContext.synchronizing => const NabiResolvedPresentation(
          context: NabiContext.synchronizing,
          emotion: NabiEmotion.thinking,
          bubbleText: 'Nabi đang cập nhật hành trình của bạn.',
        ),
      NabiContext.empty => const NabiResolvedPresentation(
          context: NabiContext.empty,
          emotion: NabiEmotion.encouraging,
          bubbleText: 'Mình bắt đầu bằng một điều nhỏ nhé.',
        ),
      NabiContext.error => const NabiResolvedPresentation(
          context: NabiContext.error,
          emotion: NabiEmotion.concerned,
          bubbleText: 'Không sao đâu, Nabi ở đây cùng bạn.',
        ),
    };
  }
}

class NabiResolvedPresentation {
  const NabiResolvedPresentation({
    required this.context,
    required this.emotion,
    required this.bubbleText,
  });

  final NabiContext context;
  final NabiEmotion emotion;
  final String bubbleText;

  NabiResolvedPresentation copyWith({
    NabiContext? context,
    NabiEmotion? emotion,
    String? bubbleText,
  }) {
    return NabiResolvedPresentation(
      context: context ?? this.context,
      emotion: emotion ?? this.emotion,
      bubbleText: bubbleText ?? this.bubbleText,
    );
  }
}

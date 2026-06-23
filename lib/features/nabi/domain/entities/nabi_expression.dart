/// Các trạng thái cảm xúc hiển thị của nhân vật Nabi.
///
/// Không gắn với route hay UI cụ thể để Presentation có thể biểu diễn bằng
/// Canvas, ảnh sprite hoặc Rive trong tương lai mà không đổi flow nghiệp vụ.
enum NabiEmotion {
  idle,
  greeting,
  listening,
  thinking,
  encouraging,
  happy,
  celebrating,
  concerned,
  sleepy,
}

/// Ngữ cảnh nghiệp vụ Nabi đang đồng hành cùng người dùng.
enum NabiContext {
  app,
  onboarding,
  dashboard,
  healthCalculation,
  mealPlan,
  exercisePlan,
  dailyTasks,
  aiChat,
  authentication,
  synchronizing,
  empty,
  error,
}

/// Sự kiện UI/nghiệp vụ để các feature thông báo cho Nabi đổi biểu cảm.
///
/// Mỗi feature chỉ gửi event; luật chọn biểu cảm và lời nhắn nằm tập trung
/// trong [NabiExpressionResolver] tại application layer.
enum NabiEvent {
  appOpened,
  onboardingStarted,
  onboardingStepCompleted,
  onboardingCompleted,
  dashboardOpened,
  healthCalculationStarted,
  healthCalculationCompleted,
  mealPlanReady,
  exercisePlanReady,
  taskCompleted,
  taskSkipped,
  notificationOpened,
  aiChatOpened,
  aiThinking,
  aiResponded,
  aiFailed,
  authenticationRequired,
  synchronizationStarted,
  synchronizationSucceeded,
  synchronizationFailed,
  formNeedsAttention,
  noData,
  networkUnavailable,
}

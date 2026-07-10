import 'nabi_visual_state.dart';

/// Mô tả ngữ cảnh hiện tại để [NabiStateResolver] chọn trạng thái phù hợp.
///
/// Tất cả trường là optional; resolver sẽ dùng những gì có sẵn.
/// UI không tự tính toán state – chỉ cung cấp facts, resolver quyết định.
class NabiContext {
  /// Route/trang hiện tại (dùng hằng số từ V1RoutePaths).
  final String? routePath;

  /// Người dùng có đang trong quá trình onboarding không.
  final bool isOnboarding;

  /// Bước onboarding hiện tại (0-based).
  final int? onboardingStep;

  /// AI đang sinh kế hoạch.
  final bool isGeneratingPlan;

  /// Kế hoạch vừa được tạo xong.
  final bool isPlanJustReady;

  /// Chat đang hoạt động.
  final bool isChatOpen;

  /// AI đang gõ phản hồi trong chat.
  final bool isChatTyping;

  /// AI vừa hoàn thành câu trả lời.
  final bool isChatAnswerReady;

  /// Có lịch trình hôm nay không.
  final bool hasScheduleToday;

  /// Tiến độ hôm nay (0.0 – 1.0).
  final double? dailyProgress;

  /// Streak hiện tại (số ngày liên tiếp).
  final int? streakDays;

  /// Người dùng vừa hoàn thành một task.
  final bool justCompletedTask;

  /// Người dùng vừa bỏ qua một task.
  final bool justSkippedTask;

  /// Lần cuối dùng app (để tính away state).
  final DateTime? lastActiveDate;

  /// Người dùng là guest (chưa đăng nhập).
  final bool isGuest;

  /// Đang tải dữ liệu.
  final bool isLoading;

  /// Đang đồng bộ cloud.
  final bool isSyncing;

  /// Đồng bộ vừa thành công.
  final bool syncJustSucceeded;

  /// Đang offline.
  final bool isOffline;

  /// Tính năng bị khoá (cần nâng cấp).
  final bool isFeatureLocked;

  /// Override thủ công – UI có thể ép trạng thái khi cần.
  final NabiVisualState? forceState;

  const NabiContext({
    this.routePath,
    this.isOnboarding = false,
    this.onboardingStep,
    this.isGeneratingPlan = false,
    this.isPlanJustReady = false,
    this.isChatOpen = false,
    this.isChatTyping = false,
    this.isChatAnswerReady = false,
    this.hasScheduleToday = false,
    this.dailyProgress,
    this.streakDays,
    this.justCompletedTask = false,
    this.justSkippedTask = false,
    this.lastActiveDate,
    this.isGuest = false,
    this.isLoading = false,
    this.isSyncing = false,
    this.syncJustSucceeded = false,
    this.isOffline = false,
    this.isFeatureLocked = false,
    this.forceState,
  });

  NabiContext copyWith({
    String? routePath,
    bool? isOnboarding,
    int? onboardingStep,
    bool? isGeneratingPlan,
    bool? isPlanJustReady,
    bool? isChatOpen,
    bool? isChatTyping,
    bool? isChatAnswerReady,
    bool? hasScheduleToday,
    double? dailyProgress,
    int? streakDays,
    bool? justCompletedTask,
    bool? justSkippedTask,
    DateTime? lastActiveDate,
    bool? isGuest,
    bool? isLoading,
    bool? isSyncing,
    bool? syncJustSucceeded,
    bool? isOffline,
    bool? isFeatureLocked,
    NabiVisualState? forceState,
    bool clearForceState = false,
  }) {
    return NabiContext(
      routePath: routePath ?? this.routePath,
      isOnboarding: isOnboarding ?? this.isOnboarding,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isGeneratingPlan: isGeneratingPlan ?? this.isGeneratingPlan,
      isPlanJustReady: isPlanJustReady ?? this.isPlanJustReady,
      isChatOpen: isChatOpen ?? this.isChatOpen,
      isChatTyping: isChatTyping ?? this.isChatTyping,
      isChatAnswerReady: isChatAnswerReady ?? this.isChatAnswerReady,
      hasScheduleToday: hasScheduleToday ?? this.hasScheduleToday,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      streakDays: streakDays ?? this.streakDays,
      justCompletedTask: justCompletedTask ?? this.justCompletedTask,
      justSkippedTask: justSkippedTask ?? this.justSkippedTask,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      syncJustSucceeded: syncJustSucceeded ?? this.syncJustSucceeded,
      isOffline: isOffline ?? this.isOffline,
      isFeatureLocked: isFeatureLocked ?? this.isFeatureLocked,
      forceState: clearForceState ? null : forceState ?? this.forceState,
    );
  }
}

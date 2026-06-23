/// Tất cả trạng thái biểu cảm của nhân vật Nabi.
///
/// Mỗi state ánh xạ đến một file PNG trong `assets/images/Nabi/`.
/// Chỉ [NabiAssetResolver] được phép map state → đường dẫn asset.
enum NabiVisualState {
  // ── core ──────────────────────────────────────────────────────────────────
  /// Nabi đang chờ, vui vẻ – trạng thái mặc định khi không có gì đặc biệt.
  idleHappy,

  /// Nabi đang chờ, trung tính – không có hoạt động nào của người dùng.
  idleNeutral,

  /// Nabi đang lắng nghe người dùng nói.
  listen,

  /// Nabi đang suy nghĩ / phân tích.
  think,

  /// Nabi đang nói / trả lời.
  speak,

  /// Nabi đang phân tích dữ liệu.
  analyze,

  /// Nabi chỉ dẫn / hướng dẫn người dùng.
  pointGuide,

  /// Nabi vẫy tay chào hoặc mừng.
  wave,

  // ── onboarding ────────────────────────────────────────────────────────────
  /// Màn hình giới thiệu onboarding.
  onboardingIntro,

  /// Nhập thông tin cơ bản.
  onboardingBasicInfo,

  /// Nhập chỉ số cơ thể.
  onboardingBodyProfile,

  /// Chọn mục tiêu sức khỏe.
  onboardingGoal,

  /// Kiểm tra sức khoẻ ban đầu.
  onboardingHealthCheck,

  /// Nhập thói quen lối sống.
  onboardingLifestyle,

  /// Xem lại thông tin trước khi xác nhận.
  onboardingReview,

  /// AI đang sinh kế hoạch cá nhân.
  aiGeneratingPlan,

  /// Kế hoạch đã sẵn sàng.
  planReady,

  // ── daily ─────────────────────────────────────────────────────────────────
  /// Nhắc bữa sáng.
  breakfast,

  /// Nhắc bữa trưa.
  lunch,

  /// Nhắc bữa tối.
  dinner,

  /// Nhắc uống nước.
  drinkWater,

  /// Nhắc tập thể dục.
  exercise,

  /// Nhắc đi bộ.
  walk,

  /// Nhắc giãn cơ.
  stretch,

  /// Nhắc ăn nhẹ lành mạnh.
  healthySnack,

  /// Nhắc đi ngủ / nghỉ ngơi.
  sleep,

  /// Check-in buổi sáng.
  morningCheckin,

  /// Check-in tâm trạng.
  moodCheckin,

  /// Đo chỉ số cơ thể.
  bodyMeasure,

  /// Xem lịch trình.
  viewSchedule,

  /// Có thông báo nhắc nhở.
  notificationReminder,

  // ── chat ──────────────────────────────────────────────────────────────────
  /// Nabi chào khi mở chat.
  chatGreet,

  /// Nabi đang gõ / đang xử lý.
  chatTyping,

  /// Nabi đang lắng nghe tin nhắn.
  chatListen,

  /// Nabi đang suy luận câu trả lời.
  chatReasoning,

  /// Câu trả lời đã sẵn sàng.
  chatAnswerReady,

  /// Nabi cần làm rõ câu hỏi.
  chatClarify,

  /// Nabi đang gợi ý về bữa ăn.
  chatMealTip,

  /// Nabi đang gợi ý về tập luyện.
  chatExerciseTip,

  /// Nabi đang gợi ý về nghỉ ngơi.
  chatRestTip,

  /// Nabi đang gợi ý về nước.
  chatWaterTip,

  // ── progress ──────────────────────────────────────────────────────────────
  /// Hoàn thành một nhiệm vụ.
  taskComplete,

  /// Nhiệm vụ đang chờ.
  taskPending,

  /// Bỏ qua nhẹ nhàng.
  taskSkipGentle,

  /// Nhắc nhở nhiệm vụ bị bỏ lỡ.
  missedTaskRemind,

  /// Khuyến khích khi tiến độ thấp.
  lowProgressEncourage,

  /// Hoàn thành cả ngày.
  dayComplete,

  /// Bắt đầu chuỗi streak.
  streakStart,

  /// Chuỗi 7 ngày liên tiếp.
  streak7Days,

  /// Kỷ lục cá nhân mới.
  personalBest,

  /// Nabi tự hào về người dùng.
  proudOfYou,

  /// Cảm ơn người dùng.
  thankYou,

  /// Đạt mốc / huy hiệu.
  milestoneBadge,

  // ── engagement ────────────────────────────────────────────────────────────
  /// Người dùng mới.
  newUser,

  /// Người dùng mới quay lại sau nghỉ.
  freshRestart,

  /// Chào mừng trở lại.
  welcomeBack,

  /// Người dùng thường xuyên.
  regularUser,

  /// Người dùng hàng ngày.
  dailyUser,

  /// Người dùng không thường xuyên.
  occasionalUser,

  /// Vắng 1 ngày.
  away1Day,

  /// Vắng 3 ngày.
  away3Days,

  /// Vắng 7 ngày.
  away7Days,

  /// Vắng 14 ngày.
  away14Days,

  // ── system ────────────────────────────────────────────────────────────────
  /// Dashboard trống (chưa có dữ liệu).
  emptyDashboard,

  /// Chưa có lịch trình.
  noSchedule,

  /// Đang tải.
  loading,

  /// Đang đồng bộ.
  syncing,

  /// Đồng bộ thành công.
  syncSuccess,

  /// Đồng bộ thất bại – cần thử lại.
  syncRetry,

  /// Ngoại tuyến.
  offline,

  /// Xin quyền thông báo.
  notificationPermission,

  /// Màn hình đăng nhập.
  login,

  /// Tài khoản đã kết nối thành công.
  accountConnected,

  /// Tính năng bị khoá (cần nâng cấp).
  accessLocked,

  // ── future ────────────────────────────────────────────────────────────────
  /// Mời thành viên gia đình.
  familyInvite,

  /// Thành viên gia đình vừa tham gia.
  familyMemberJoined,

  /// Kế hoạch gia đình.
  familyPlan,

  /// Chia sẻ tiến độ gia đình.
  familySharedProgress,

  /// Mời bạn bè (referral).
  referralInvite,

  /// Referral thành công.
  referralSuccess,

  /// Mở khoá tính năng premium.
  premiumUnlocked,

  /// Bảng xếp hạng Sale.
  salesLeaderboard,

  /// Phần thưởng Sale.
  salesReward,

  /// Hoa hồng thành công.
  commissionSuccess,
}

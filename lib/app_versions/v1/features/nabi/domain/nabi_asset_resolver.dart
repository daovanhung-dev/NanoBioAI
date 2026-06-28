import 'nabi_visual_state.dart';

/// Ánh xạ [NabiVisualState] → đường dẫn asset PNG.
///
/// Đây là nơi DUY NHẤT được phép biết cấu trúc thư mục assets/images/Nabi/.
/// UI nhận vào [NabiVisualState] và chỉ hỏi resolver để lấy path.
abstract final class NabiAssetResolver {
  NabiAssetResolver._();

  static const String _base = 'assets/images/Nabi';

  /// Trả về đường dẫn asset tương ứng với [state].
  static String pathFor(NabiVisualState state) {
    return switch (state) {
      // ── core ────────────────────────────────────────────────
      NabiVisualState.idleHappy => '$_base/core/Nabi_idle_happy.png',
      NabiVisualState.idleNeutral => '$_base/core/Nabi_idle_neutral.png',
      NabiVisualState.listen => '$_base/core/Nabi_listen.png',
      NabiVisualState.think => '$_base/core/Nabi_think.png',
      NabiVisualState.speak => '$_base/core/Nabi_speak.png',
      NabiVisualState.analyze => '$_base/core/Nabi_analyze.png',
      NabiVisualState.pointGuide => '$_base/core/Nabi_point_guide.png',
      NabiVisualState.wave => '$_base/core/Nabi_wave.png',

      // ── onboarding ──────────────────────────────────────────
      NabiVisualState.onboardingIntro =>
        '$_base/onboarding/Nabi_onboarding_intro.png',
      NabiVisualState.onboardingBasicInfo =>
        '$_base/onboarding/Nabi_onboarding_basic_info.png',
      NabiVisualState.onboardingBodyProfile =>
        '$_base/onboarding/Nabi_onboarding_body_profile.png',
      NabiVisualState.onboardingGoal =>
        '$_base/onboarding/Nabi_onboarding_goal.png',
      NabiVisualState.onboardingHealthCheck =>
        '$_base/onboarding/Nabi_onboarding_health_check.png',
      NabiVisualState.onboardingLifestyle =>
        '$_base/onboarding/Nabi_onboarding_lifestyle.png',
      NabiVisualState.onboardingReview =>
        '$_base/onboarding/Nabi_onboarding_review.png',
      NabiVisualState.aiGeneratingPlan =>
        '$_base/onboarding/Nabi_ai_generating_plan.png',
      NabiVisualState.planReady => '$_base/onboarding/Nabi_plan_ready.png',

      // ── daily ───────────────────────────────────────────────
      NabiVisualState.breakfast => '$_base/daily/Nabi_breakfast.png',
      NabiVisualState.lunch => '$_base/daily/Nabi_lunch.png',
      NabiVisualState.dinner => '$_base/daily/Nabi_dinner.png',
      NabiVisualState.drinkWater => '$_base/daily/Nabi_drink_water.png',
      NabiVisualState.exercise => '$_base/daily/Nabi_exercise.png',
      NabiVisualState.walk => '$_base/daily/Nabi_walk.png',
      NabiVisualState.stretch => '$_base/daily/Nabi_stretch.png',
      NabiVisualState.healthySnack => '$_base/daily/Nabi_healthy_snack.png',
      NabiVisualState.sleep => '$_base/daily/Nabi_sleep.png',
      NabiVisualState.morningCheckin => '$_base/daily/Nabi_morning_checkin.png',
      NabiVisualState.moodCheckin => '$_base/daily/Nabi_mood_checkin.png',
      NabiVisualState.bodyMeasure => '$_base/daily/Nabi_body_measure.png',
      NabiVisualState.viewSchedule => '$_base/daily/Nabi_view_schedule.png',
      NabiVisualState.notificationReminder =>
        '$_base/daily/Nabi_notification_reminder.png',

      // ── chat ────────────────────────────────────────────────
      NabiVisualState.chatGreet => '$_base/chat/Nabi_chat_greet.png',
      NabiVisualState.chatTyping => '$_base/chat/Nabi_chat_typing.png',
      NabiVisualState.chatListen => '$_base/chat/Nabi_chat_listen.png',
      NabiVisualState.chatReasoning => '$_base/chat/Nabi_chat_reasoning.png',
      NabiVisualState.chatAnswerReady =>
        '$_base/chat/Nabi_chat_answer_ready.png',
      NabiVisualState.chatClarify => '$_base/chat/Nabi_chat_clarify.png',
      NabiVisualState.chatMealTip => '$_base/chat/Nabi_chat_meal_tip.png',
      NabiVisualState.chatExerciseTip =>
        '$_base/chat/Nabi_chat_exercise_tip.png',
      NabiVisualState.chatRestTip => '$_base/chat/Nabi_chat_rest_tip.png',
      NabiVisualState.chatWaterTip => '$_base/chat/Nabi_chat_water_tip.png',

      // ── progress ────────────────────────────────────────────
      NabiVisualState.taskComplete => '$_base/progress/Nabi_task_complete.png',
      NabiVisualState.taskPending => '$_base/progress/Nabi_task_pending.png',
      NabiVisualState.taskSkipGentle =>
        '$_base/progress/Nabi_task_skip_gentle.png',
      NabiVisualState.missedTaskRemind =>
        '$_base/progress/Nabi_missed_task_remind.png',
      NabiVisualState.lowProgressEncourage =>
        '$_base/progress/Nabi_low_progress_encourage.png',
      NabiVisualState.dayComplete => '$_base/progress/Nabi_day_complete.png',
      NabiVisualState.streakStart => '$_base/progress/Nabi_streak_start.png',
      NabiVisualState.streak7Days => '$_base/progress/Nabi_streak_7days.png',
      NabiVisualState.personalBest => '$_base/progress/Nabi_personal_best.png',
      NabiVisualState.proudOfYou => '$_base/progress/Nabi_proud_of_you.png',
      NabiVisualState.thankYou => '$_base/progress/Nabi_thank_you.png',
      NabiVisualState.milestoneBadge =>
        '$_base/progress/Nabi_milestone_badge.png',

      // ── engagement ──────────────────────────────────────────
      NabiVisualState.newUser => '$_base/engagement/Nabi_new_user.png',
      NabiVisualState.freshRestart =>
        '$_base/engagement/Nabi_fresh_restart.png',
      NabiVisualState.welcomeBack => '$_base/engagement/Nabi_welcome_back.png',
      NabiVisualState.regularUser => '$_base/engagement/Nabi_regular_user.png',
      NabiVisualState.dailyUser => '$_base/engagement/Nabi_daily_user.png',
      NabiVisualState.occasionalUser =>
        '$_base/engagement/Nabi_occasional_user.png',
      NabiVisualState.away1Day => '$_base/engagement/Nabi_away_1day.png',
      NabiVisualState.away3Days => '$_base/engagement/Nabi_away_3days.png',
      NabiVisualState.away7Days => '$_base/engagement/Nabi_away_7days.png',
      NabiVisualState.away14Days => '$_base/engagement/Nabi_away_14days.png',

      // ── system ──────────────────────────────────────────────
      NabiVisualState.emptyDashboard =>
        '$_base/system/Nabi_empty_dashboard.png',
      NabiVisualState.noSchedule => '$_base/system/Nabi_no_schedule.png',
      NabiVisualState.loading => '$_base/system/Nabi_loading.png',
      NabiVisualState.syncing => '$_base/system/Nabi_syncing.png',
      NabiVisualState.syncSuccess => '$_base/system/Nabi_sync_success.png',
      NabiVisualState.syncRetry => '$_base/system/Nabi_sync_retry.png',
      NabiVisualState.offline => '$_base/system/Nabi_offline.png',
      NabiVisualState.notificationPermission =>
        '$_base/system/Nabi_notification_permission.png',
      NabiVisualState.login => '$_base/system/Nabi_login.png',
      NabiVisualState.accountConnected =>
        '$_base/system/Nabi_account_connected.png',
      NabiVisualState.accessLocked => '$_base/system/Nabi_access_locked.png',

      // ── future ──────────────────────────────────────────────
      NabiVisualState.familyInvite => '$_base/future/Nabi_family_invite.png',
      NabiVisualState.familyMemberJoined =>
        '$_base/future/Nabi_family_member_joined.png',
      NabiVisualState.familyPlan => '$_base/future/Nabi_family_plan.png',
      NabiVisualState.familySharedProgress =>
        '$_base/future/Nabi_family_shared_progress.png',
      NabiVisualState.referralInvite =>
        '$_base/future/Nabi_referral_invite.png',
      NabiVisualState.referralSuccess =>
        '$_base/future/Nabi_referral_success.png',
      NabiVisualState.premiumUnlocked =>
        '$_base/future/Nabi_premium_unlocked.png',
      NabiVisualState.salesLeaderboard =>
        '$_base/future/Nabi_sales_leaderboard.png',
      NabiVisualState.salesReward => '$_base/future/Nabi_sales_reward.png',
      NabiVisualState.commissionSuccess =>
        '$_base/future/Nabi_commission_success.png',
    };
  }
}

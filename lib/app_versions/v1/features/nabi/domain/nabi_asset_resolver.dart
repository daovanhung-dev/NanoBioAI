import 'package:nano_app/features/nabi/data/nabi_asset_catalog.dart';

import 'nabi_visual_state.dart';

/// Ánh xạ [NabiVisualState] → đường dẫn asset PNG.
///
/// The shared catalog owns the active lowercase static asset root; this
/// resolver only maps V1 visual states to their relative asset paths.
abstract final class NabiAssetResolver {
  NabiAssetResolver._();

  static const String _base = NabiAssetCatalog.staticRoot;

  /// Trả về đường dẫn asset tương ứng với [state].
  static String pathFor(NabiVisualState state) {
    return switch (state) {
      // ── core ────────────────────────────────────────────────
      NabiVisualState.idleHappy => '$_base/core/nabi_idle_happy.png',
      NabiVisualState.idleNeutral => '$_base/core/nabi_idle_neutral.png',
      NabiVisualState.listen => '$_base/core/nabi_listen.png',
      NabiVisualState.think => '$_base/core/nabi_think.png',
      NabiVisualState.speak => '$_base/core/nabi_speak.png',
      NabiVisualState.analyze => '$_base/core/nabi_analyze.png',
      NabiVisualState.pointGuide => '$_base/core/nabi_point_guide.png',
      NabiVisualState.wave => '$_base/core/nabi_wave.png',

      // ── onboarding ──────────────────────────────────────────
      NabiVisualState.onboardingIntro =>
        '$_base/onboarding/nabi_onboarding_intro.png',
      NabiVisualState.onboardingBasicInfo =>
        '$_base/onboarding/nabi_onboarding_basic_info.png',
      NabiVisualState.onboardingBodyProfile =>
        '$_base/onboarding/nabi_onboarding_body_profile.png',
      NabiVisualState.onboardingGoal =>
        '$_base/onboarding/nabi_onboarding_goal.png',
      NabiVisualState.onboardingHealthCheck =>
        '$_base/onboarding/nabi_onboarding_health_check.png',
      NabiVisualState.onboardingLifestyle =>
        '$_base/onboarding/nabi_onboarding_lifestyle.png',
      NabiVisualState.onboardingReview =>
        '$_base/onboarding/nabi_onboarding_review.png',
      NabiVisualState.aiGeneratingPlan =>
        '$_base/onboarding/nabi_ai_generating_plan.png',
      NabiVisualState.planReady => '$_base/onboarding/nabi_plan_ready.png',

      // ── daily ───────────────────────────────────────────────
      NabiVisualState.breakfast => '$_base/daily/nabi_breakfast.png',
      NabiVisualState.lunch => '$_base/daily/nabi_lunch.png',
      NabiVisualState.dinner => '$_base/daily/nabi_dinner.png',
      NabiVisualState.drinkWater => '$_base/daily/nabi_drink_water.png',
      NabiVisualState.exercise => '$_base/daily/nabi_exercise.png',
      NabiVisualState.walk => '$_base/daily/nabi_walk.png',
      NabiVisualState.stretch => '$_base/daily/nabi_stretch.png',
      NabiVisualState.healthySnack => '$_base/daily/nabi_healthy_snack.png',
      NabiVisualState.sleep => '$_base/daily/nabi_sleep.png',
      NabiVisualState.morningCheckin => '$_base/daily/nabi_morning_checkin.png',
      NabiVisualState.moodCheckin => '$_base/daily/nabi_mood_checkin.png',
      NabiVisualState.bodyMeasure => '$_base/daily/nabi_body_measure.png',
      NabiVisualState.viewSchedule => '$_base/daily/nabi_view_schedule.png',
      NabiVisualState.notificationReminder =>
        '$_base/daily/nabi_notification_reminder.png',

      // ── chat ────────────────────────────────────────────────
      NabiVisualState.chatGreet => '$_base/chat/nabi_chat_greet.png',
      NabiVisualState.chatTyping => '$_base/chat/nabi_chat_typing.png',
      NabiVisualState.chatListen => '$_base/chat/nabi_chat_listen.png',
      NabiVisualState.chatReasoning => '$_base/chat/nabi_chat_reasoning.png',
      NabiVisualState.chatAnswerReady =>
        '$_base/chat/nabi_chat_answer_ready.png',
      NabiVisualState.chatClarify => '$_base/chat/nabi_chat_clarify.png',
      NabiVisualState.chatMealTip => '$_base/chat/nabi_chat_meal_tip.png',
      NabiVisualState.chatExerciseTip =>
        '$_base/chat/nabi_chat_exercise_tip.png',
      NabiVisualState.chatRestTip => '$_base/chat/nabi_chat_rest_tip.png',
      NabiVisualState.chatWaterTip => '$_base/chat/nabi_chat_water_tip.png',

      // ── progress ────────────────────────────────────────────
      NabiVisualState.taskComplete => '$_base/progress/nabi_task_complete.png',
      NabiVisualState.taskPending => '$_base/progress/nabi_task_pending.png',
      NabiVisualState.taskSkipGentle =>
        '$_base/progress/nabi_task_skip_gentle.png',
      NabiVisualState.missedTaskRemind =>
        '$_base/progress/nabi_missed_task_remind.png',
      NabiVisualState.lowProgressEncourage =>
        '$_base/progress/nabi_low_progress_encourage.png',
      NabiVisualState.dayComplete => '$_base/progress/nabi_day_complete.png',
      NabiVisualState.streakStart => '$_base/progress/nabi_streak_start.png',
      NabiVisualState.streak7Days => '$_base/progress/nabi_streak_7days.png',
      NabiVisualState.personalBest => '$_base/progress/nabi_personal_best.png',
      NabiVisualState.proudOfYou => '$_base/progress/nabi_proud_of_you.png',
      NabiVisualState.thankYou => '$_base/progress/nabi_thank_you.png',
      NabiVisualState.milestoneBadge =>
        '$_base/progress/nabi_milestone_badge.png',

      // ── engagement ──────────────────────────────────────────
      NabiVisualState.newUser => '$_base/engagement/nabi_new_user.png',
      NabiVisualState.freshRestart =>
        '$_base/engagement/nabi_fresh_restart.png',
      NabiVisualState.welcomeBack => '$_base/engagement/nabi_welcome_back.png',
      NabiVisualState.regularUser => '$_base/engagement/nabi_regular_user.png',
      NabiVisualState.dailyUser => '$_base/engagement/nabi_daily_user.png',
      NabiVisualState.occasionalUser =>
        '$_base/engagement/nabi_occasional_user.png',
      NabiVisualState.away1Day => '$_base/engagement/nabi_away_1day.png',
      NabiVisualState.away3Days => '$_base/engagement/nabi_away_3days.png',
      NabiVisualState.away7Days => '$_base/engagement/nabi_away_7days.png',
      NabiVisualState.away14Days => '$_base/engagement/nabi_away_14days.png',

      // ── system ──────────────────────────────────────────────
      NabiVisualState.emptyDashboard =>
        '$_base/system/nabi_empty_dashboard.png',
      NabiVisualState.noSchedule => '$_base/system/nabi_no_schedule.png',
      NabiVisualState.loading => '$_base/system/nabi_loading.png',
      NabiVisualState.syncing => '$_base/system/nabi_syncing.png',
      NabiVisualState.syncSuccess => '$_base/system/nabi_sync_success.png',
      NabiVisualState.syncRetry => '$_base/system/nabi_sync_retry.png',
      NabiVisualState.offline => '$_base/system/nabi_offline.png',
      NabiVisualState.notificationPermission =>
        '$_base/system/nabi_notification_permission.png',
      NabiVisualState.login => '$_base/system/nabi_login.png',
      NabiVisualState.accountConnected =>
        '$_base/system/nabi_account_connected.png',
      NabiVisualState.accessLocked => '$_base/system/nabi_access_locked.png',

      // ── future ──────────────────────────────────────────────
      NabiVisualState.familyInvite => '$_base/future/nabi_family_invite.png',
      NabiVisualState.familyMemberJoined =>
        '$_base/future/nabi_family_member_joined.png',
      NabiVisualState.familyPlan => '$_base/future/nabi_family_plan.png',
      NabiVisualState.familySharedProgress =>
        '$_base/future/nabi_family_shared_progress.png',
      NabiVisualState.referralInvite =>
        '$_base/future/nabi_referral_invite.png',
      NabiVisualState.referralSuccess =>
        '$_base/future/nabi_referral_success.png',
      NabiVisualState.premiumUnlocked =>
        '$_base/future/nabi_premium_unlocked.png',
      NabiVisualState.salesLeaderboard =>
        '$_base/future/nabi_sales_leaderboard.png',
      NabiVisualState.salesReward => '$_base/future/nabi_sales_reward.png',
      NabiVisualState.commissionSuccess =>
        '$_base/future/nabi_commission_success.png',
    };
  }
}

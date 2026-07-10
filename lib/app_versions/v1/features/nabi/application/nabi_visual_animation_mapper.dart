import 'package:nano_app/features/nabi/nabi.dart';

import '../domain/nabi_visual_state.dart';

abstract final class NabiVisualAnimationMapper {
  const NabiVisualAnimationMapper._();

  static NabiAnimationType fromVisualState(NabiVisualState state) {
    return switch (state) {
      NabiVisualState.aiGeneratingPlan ||
      NabiVisualState.chatTyping ||
      NabiVisualState.loading ||
      NabiVisualState.syncing => NabiAnimationType.loading,

      NabiVisualState.analyze ||
      NabiVisualState.bodyMeasure ||
      NabiVisualState.chatClarify ||
      NabiVisualState.chatMealTip ||
      NabiVisualState.chatReasoning ||
      NabiVisualState.chatRestTip ||
      NabiVisualState.chatWaterTip ||
      NabiVisualState.think => NabiAnimationType.thinking,

      NabiVisualState.chatExerciseTip ||
      NabiVisualState.exercise ||
      NabiVisualState.stretch ||
      NabiVisualState.walk => NabiAnimationType.cheering,

      NabiVisualState.chatAnswerReady ||
      NabiVisualState.speak => NabiAnimationType.talking,

      NabiVisualState.chatGreet ||
      NabiVisualState.chatListen ||
      NabiVisualState.listen => NabiAnimationType.listening,

      NabiVisualState.newUser ||
      NabiVisualState.onboardingBasicInfo ||
      NabiVisualState.onboardingBodyProfile ||
      NabiVisualState.onboardingGoal ||
      NabiVisualState.onboardingHealthCheck ||
      NabiVisualState.onboardingIntro ||
      NabiVisualState.onboardingLifestyle ||
      NabiVisualState.onboardingReview ||
      NabiVisualState.pointGuide ||
      NabiVisualState.wave ||
      NabiVisualState.welcomeBack => NabiAnimationType.greeting,

      NabiVisualState.accountConnected ||
      NabiVisualState.dailyUser ||
      NabiVisualState.dayComplete ||
      NabiVisualState.freshRestart ||
      NabiVisualState.milestoneBadge ||
      NabiVisualState.personalBest ||
      NabiVisualState.planReady ||
      NabiVisualState.proudOfYou ||
      NabiVisualState.regularUser ||
      NabiVisualState.streak7Days ||
      NabiVisualState.streakStart ||
      NabiVisualState.syncSuccess ||
      NabiVisualState.taskComplete ||
      NabiVisualState.thankYou => NabiAnimationType.happy,

      NabiVisualState.breakfast ||
      NabiVisualState.dinner ||
      NabiVisualState.drinkWater ||
      NabiVisualState.healthySnack ||
      NabiVisualState.lunch ||
      NabiVisualState.missedTaskRemind ||
      NabiVisualState.moodCheckin ||
      NabiVisualState.morningCheckin ||
      NabiVisualState.notificationPermission ||
      NabiVisualState.notificationReminder ||
      NabiVisualState.sleep ||
      NabiVisualState.taskPending ||
      NabiVisualState.viewSchedule => NabiAnimationType.reminder,

      NabiVisualState.commissionSuccess ||
      NabiVisualState.familyInvite ||
      NabiVisualState.familyMemberJoined ||
      NabiVisualState.familyPlan ||
      NabiVisualState.familySharedProgress ||
      NabiVisualState.premiumUnlocked ||
      NabiVisualState.referralInvite ||
      NabiVisualState.referralSuccess ||
      NabiVisualState.salesLeaderboard ||
      NabiVisualState.salesReward => NabiAnimationType.membership,

      NabiVisualState.accessLocked ||
      NabiVisualState.offline ||
      NabiVisualState.syncRetry => NabiAnimationType.error,

      NabiVisualState.away14Days ||
      NabiVisualState.away1Day ||
      NabiVisualState.away3Days ||
      NabiVisualState.away7Days ||
      NabiVisualState.emptyDashboard ||
      NabiVisualState.lowProgressEncourage ||
      NabiVisualState.noSchedule ||
      NabiVisualState.occasionalUser ||
      NabiVisualState.taskSkipGentle => NabiAnimationType.sad,

      NabiVisualState.idleHappy => NabiAnimationType.idle,
      NabiVisualState.idleNeutral ||
      NabiVisualState.login => NabiAnimationType.idle,
    };
  }
}

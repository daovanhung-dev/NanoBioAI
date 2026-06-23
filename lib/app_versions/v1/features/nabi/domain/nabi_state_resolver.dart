import 'nabi_context.dart';
import 'nabi_visual_state.dart';

/// Chọn [NabiVisualState] phù hợp nhất từ một [NabiContext].
///
/// Thứ tự ưu tiên (cao → thấp):
///   1. forceState (override thủ công)
///   2. System states (offline, loading, syncing, locked)
///   3. Onboarding flow
///   4. AI generating / plan ready
///   5. Chat flow
///   6. Task interactions (complete, skip)
///   7. Progress milestones (streak, day complete)
///   8. Engagement (away, new user, welcome back)
///   9. Route-based default
///  10. Fallback: idleHappy
abstract final class NabiStateResolver {
  NabiStateResolver._();

  static NabiVisualState resolve(NabiContext ctx) {
    // 1. Force override
    if (ctx.forceState != null) return ctx.forceState!;

    // 2. System states
    if (ctx.isOffline) return NabiVisualState.offline;
    if (ctx.isFeatureLocked) return NabiVisualState.accessLocked;
    if (ctx.isSyncing) return NabiVisualState.syncing;
    if (ctx.syncJustSucceeded) return NabiVisualState.syncSuccess;
    if (ctx.isLoading) return NabiVisualState.loading;

    // 3. Onboarding
    if (ctx.isGeneratingPlan) return NabiVisualState.aiGeneratingPlan;
    if (ctx.isPlanJustReady) return NabiVisualState.planReady;
    if (ctx.isOnboarding) return _resolveOnboardingStep(ctx.onboardingStep);

    // 4. Chat
    if (ctx.isChatOpen) {
      if (ctx.isChatTyping) return NabiVisualState.chatTyping;
      if (ctx.isChatAnswerReady) return NabiVisualState.chatAnswerReady;
      return NabiVisualState.chatGreet;
    }

    // 5. Task interactions
    if (ctx.justCompletedTask) return _resolveTaskComplete(ctx);
    if (ctx.justSkippedTask) return NabiVisualState.taskSkipGentle;

    // 6. Progress milestones
    final milestone = _resolveMilestone(ctx);
    if (milestone != null) return milestone;

    // 7. Engagement / away
    final engagement = _resolveEngagement(ctx);
    if (engagement != null) return engagement;

    // 8. Route-based
    return _resolveByRoute(ctx.routePath);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static NabiVisualState _resolveOnboardingStep(int? step) {
    return switch (step) {
      0 => NabiVisualState.onboardingIntro,
      1 => NabiVisualState.onboardingBasicInfo,
      2 => NabiVisualState.onboardingBodyProfile,
      3 => NabiVisualState.onboardingGoal,
      4 => NabiVisualState.onboardingHealthCheck,
      5 => NabiVisualState.onboardingLifestyle,
      6 => NabiVisualState.onboardingReview,
      _ => NabiVisualState.onboardingIntro,
    };
  }

  static NabiVisualState _resolveTaskComplete(NabiContext ctx) {
    final progress = ctx.dailyProgress ?? 0;
    if (progress >= 1.0) return NabiVisualState.dayComplete;
    if (progress >= 0.8) return NabiVisualState.proudOfYou;
    return NabiVisualState.taskComplete;
  }

  static NabiVisualState? _resolveMilestone(NabiContext ctx) {
    final streak = ctx.streakDays ?? 0;
    if (streak >= 7) return NabiVisualState.streak7Days;
    if (streak >= 1) return NabiVisualState.streakStart;

    final progress = ctx.dailyProgress ?? -1;
    if (progress >= 1.0) return NabiVisualState.dayComplete;
    if (progress < 0.3 && progress >= 0) {
      return NabiVisualState.lowProgressEncourage;
    }

    return null;
  }

  static NabiVisualState? _resolveEngagement(NabiContext ctx) {
    final lastActive = ctx.lastActiveDate;
    if (lastActive == null) {
      if (ctx.isGuest) return NabiVisualState.newUser;
      return null;
    }

    final daysSince = DateTime.now().difference(lastActive).inDays;
    if (daysSince >= 14) return NabiVisualState.away14Days;
    if (daysSince >= 7) return NabiVisualState.away7Days;
    if (daysSince >= 3) return NabiVisualState.away3Days;
    if (daysSince >= 1) return NabiVisualState.away1Day;

    return null;
  }

  static NabiVisualState _resolveByRoute(String? route) {
    if (route == null) return NabiVisualState.idleHappy;

    // Route prefixes – match từ specific đến general
    if (route.contains('/ai-chat')) return NabiVisualState.chatGreet;
    if (route.contains('/onboarding')) return NabiVisualState.onboardingIntro;
    if (route.contains('/dashboard')) return NabiVisualState.idleHappy;
    if (route.contains('/lifestyle') || route.contains('/schedule')) {
      return NabiVisualState.viewSchedule;
    }
    if (route.contains('/meal') || route.contains('/nutrition')) {
      return NabiVisualState.chatMealTip;
    }
    if (route.contains('/daily-tracking') || route.contains('/tracking')) {
      return NabiVisualState.morningCheckin;
    }
    if (route.contains('/settings')) return NabiVisualState.idleNeutral;
    if (route.contains('/profile')) return NabiVisualState.pointGuide;
    if (route.contains('/login') || route.contains('/sign-in')) {
      return NabiVisualState.login;
    }
    if (route.contains('/features')) return NabiVisualState.wave;
    if (route.contains('/health-insights')) return NabiVisualState.analyze;

    return NabiVisualState.idleHappy;
  }
}

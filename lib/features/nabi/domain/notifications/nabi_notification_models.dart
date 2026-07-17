enum NabiNotificationCategory {
  contextual,
  milestone,
  subscription,
  retention,
  reward,
  report,
  care,
  profile,
}

enum NabiNotificationChannel { inApp, osLocal }

enum NabiNotificationStatus {
  eligible,
  queued,
  presented,
  collapsed,
  opened,
  deferred,
  actioned,
  converted,
  expired,
  cancelled,
  failed,
}

class NabiNotificationDestination {
  final String actionKey;
  final String? resourceId;
  final String? planCode;
  final String? billingCycle;
  final String? focus;
  final String? returnTo;

  const NabiNotificationDestination({
    required this.actionKey,
    this.resourceId,
    this.planCode,
    this.billingCycle,
    this.focus,
    this.returnTo,
  });
}

class NabiNotificationDefinition {
  final String id;
  final int contentVersion;
  final NabiNotificationCategory category;
  final int priority;
  final String policyKey;
  final String title;
  final String body;
  final String emotionKey;
  final NabiNotificationDestination primaryDestination;
  final NabiNotificationDestination? secondaryDestination;
  final String primaryLabel;
  final String? secondaryLabel;
  final Set<NabiNotificationChannel> channels;
  final Set<String> audiences;
  final Duration cooldown;
  final bool proactive;
  final bool upsell;
  final bool active;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;
  final Set<String> requiredVariables;

  const NabiNotificationDefinition({
    required this.id,
    required this.contentVersion,
    required this.category,
    required this.priority,
    required this.policyKey,
    required this.title,
    required this.body,
    required this.emotionKey,
    required this.primaryDestination,
    required this.primaryLabel,
    required this.channels,
    required this.audiences,
    this.secondaryDestination,
    this.secondaryLabel,
    this.cooldown = const Duration(hours: 72),
    this.proactive = true,
    this.upsell = false,
    this.active = true,
    this.effectiveFrom,
    this.effectiveUntil,
    this.requiredVariables = const {},
  });
}

class NabiBusinessSnapshot {
  final String actorKey;
  final String actorKind;
  final String membershipPlan;
  final String? billingCycle;
  final String sourceEventId;
  final DateTime occurredAt;
  final int successfulChatCount;
  final int attemptedChatNumber;
  final int requestedPlanDays;
  final int subscriptionAgeDays;
  final int? subscriptionDaysRemaining;
  final int streakDays;
  final int awayHours;
  final int profileAgeDays;
  final int remainingRequiredTasks;
  final bool planQuotaExhausted;
  final bool guestHorizonExhausted;
  final bool firstStreakSeven;
  final bool todayCompleted;
  final bool expertLocked;
  final bool map365Locked;
  final bool weeklyReportLocked;
  final bool expertRecommended;
  final bool activityReady;
  final bool streakLost;
  final bool rescueCardAvailable;
  final bool rescueNotificationActive;
  final bool rewardReady;
  final bool reportReady;
  final bool inviteAvailable;
  final bool nearSleep;
  final bool partialDay;
  final bool profileMissing;
  final Map<String, String> variables;

  const NabiBusinessSnapshot({
    required this.actorKey,
    required this.actorKind,
    required this.membershipPlan,
    required this.sourceEventId,
    required this.occurredAt,
    this.billingCycle,
    this.successfulChatCount = 0,
    this.attemptedChatNumber = 0,
    this.requestedPlanDays = 0,
    this.subscriptionAgeDays = 0,
    this.subscriptionDaysRemaining,
    this.streakDays = 0,
    this.awayHours = 0,
    this.profileAgeDays = 0,
    this.remainingRequiredTasks = 0,
    this.planQuotaExhausted = false,
    this.guestHorizonExhausted = false,
    this.firstStreakSeven = false,
    this.todayCompleted = false,
    this.expertLocked = false,
    this.map365Locked = false,
    this.weeklyReportLocked = false,
    this.expertRecommended = false,
    this.activityReady = false,
    this.streakLost = false,
    this.rescueCardAvailable = false,
    this.rescueNotificationActive = false,
    this.rewardReady = false,
    this.reportReady = false,
    this.inviteAvailable = false,
    this.nearSleep = false,
    this.partialDay = false,
    this.profileMissing = false,
    this.variables = const {},
  });
}

class NabiUiContext {
  final String sessionId;
  final String screenKey;
  final String screenInstanceId;
  final bool isForeground;
  final bool onboarding;
  final bool inputActive;
  final bool keyboardWouldCover;
  final bool paymentActive;
  final bool consultationActive;
  final bool criticalError;

  const NabiUiContext({
    required this.sessionId,
    required this.screenKey,
    required this.screenInstanceId,
    this.isForeground = true,
    this.onboarding = false,
    this.inputActive = false,
    this.keyboardWouldCover = false,
    this.paymentActive = false,
    this.consultationActive = false,
    this.criticalError = false,
  });

  bool get suppressesPresentation =>
      onboarding ||
      inputActive ||
      keyboardWouldCover ||
      paymentActive ||
      consultationActive ||
      criticalError;
}

class NabiNotificationPreferences {
  final bool proactiveInAppEnabled;
  final bool pushEnabled;
  final bool analyticsUploadEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;

  const NabiNotificationPreferences({
    this.proactiveInAppEnabled = true,
    this.pushEnabled = false,
    this.analyticsUploadEnabled = false,
    this.quietStartMinutes = 21 * 60,
    this.quietEndMinutes = 7 * 60,
  });
}

class NabiNotificationHistoryEntry {
  final String notificationId;
  final NabiNotificationCategory category;
  final DateTime presentedAt;
  final String sessionId;
  final String screenInstanceId;
  final bool proactive;
  final bool upsell;
  final NabiNotificationStatus status;
  final DateTime? deferredUntil;

  const NabiNotificationHistoryEntry({
    required this.notificationId,
    required this.category,
    required this.presentedAt,
    required this.sessionId,
    required this.screenInstanceId,
    required this.proactive,
    required this.upsell,
    required this.status,
    this.deferredUntil,
  });
}

enum NabiEligibilityBlockedReason {
  inactive,
  outsideEffectiveWindow,
  wrongAudience,
  missingDynamicValue,
  triggerNotMatched,
  uiSuppressed,
  proactiveDisabled,
  sessionCap,
  screenCap,
  recentDismissGuard,
  dailyUpsellCap,
  rollingUpsellCap,
  cooldown,
  deferred,
  quietHours,
}

class NabiEligibilityDecision {
  final NabiNotificationDefinition definition;
  final bool eligible;
  final NabiEligibilityBlockedReason? blockedReason;

  const NabiEligibilityDecision._({
    required this.definition,
    required this.eligible,
    this.blockedReason,
  });

  const NabiEligibilityDecision.allowed(NabiNotificationDefinition definition)
    : this._(definition: definition, eligible: true);

  const NabiEligibilityDecision.blocked(
    NabiNotificationDefinition definition,
    NabiEligibilityBlockedReason reason,
  ) : this._(
        definition: definition,
        eligible: false,
        blockedReason: reason,
      );
}

class NabiNotificationOccurrence {
  final String id;
  final String actorKey;
  final String notificationId;
  final int contentVersion;
  final String sourceEventId;
  final NabiNotificationStatus status;
  final DateTime eligibleAt;
  final DateTime? deferredUntil;

  const NabiNotificationOccurrence({
    required this.id,
    required this.actorKey,
    required this.notificationId,
    required this.contentVersion,
    required this.sourceEventId,
    required this.status,
    required this.eligibleAt,
    this.deferredUntil,
  });
}

import '../../domain/notifications/nabi_notification_catalog.dart';
import '../../domain/notifications/nabi_notification_models.dart';

class NabiNotificationEngine {
  const NabiNotificationEngine();

  List<NabiEligibilityDecision> evaluateAll({
    required Iterable<NabiNotificationDefinition> definitions,
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
    required NabiNotificationPreferences preferences,
    required List<NabiNotificationHistoryEntry> history,
    required DateTime now,
    NabiNotificationChannel channel = NabiNotificationChannel.inApp,
  }) {
    final decisions = definitions
        .map(
          (definition) => evaluate(
            definition: definition,
            snapshot: snapshot,
            uiContext: uiContext,
            preferences: preferences,
            history: history,
            now: now,
            channel: channel,
          ),
        )
        .toList();
    decisions.sort((left, right) {
      if (left.eligible != right.eligible) return left.eligible ? -1 : 1;
      final priority = right.definition.priority.compareTo(
        left.definition.priority,
      );
      if (priority != 0) return priority;
      return left.definition.id.compareTo(right.definition.id);
    });
    return decisions;
  }

  NabiEligibilityDecision evaluate({
    required NabiNotificationDefinition definition,
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
    required NabiNotificationPreferences preferences,
    required List<NabiNotificationHistoryEntry> history,
    required DateTime now,
    NabiNotificationChannel channel = NabiNotificationChannel.inApp,
  }) {
    if (!definition.active || !definition.channels.contains(channel)) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.inactive,
      );
    }
    if ((definition.effectiveFrom != null && now.isBefore(definition.effectiveFrom!)) ||
        (definition.effectiveUntil != null && !now.isBefore(definition.effectiveUntil!))) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.outsideEffectiveWindow,
      );
    }
    if (!definition.audiences.contains(
      NabiNotificationCatalog.audienceKey(snapshot),
    )) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.wrongAudience,
      );
    }
    if (definition.requiredVariables.any(
      (key) => snapshot.variables[key]?.trim().isNotEmpty != true,
    )) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.missingDynamicValue,
      );
    }
    if (!_matchesPolicy(definition.policyKey, snapshot)) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.triggerNotMatched,
      );
    }
    if (uiContext.suppressesPresentation) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.uiSuppressed,
      );
    }
    if (definition.proactive &&
        channel == NabiNotificationChannel.inApp &&
        !preferences.proactiveInAppEnabled) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.proactiveDisabled,
      );
    }
    if (channel == NabiNotificationChannel.osLocal) {
      if (!preferences.pushEnabled) {
        return NabiEligibilityDecision.blocked(
          definition,
          NabiEligibilityBlockedReason.proactiveDisabled,
        );
      }
      if (_isQuietHour(now, preferences)) {
        return NabiEligibilityDecision.blocked(
          definition,
          NabiEligibilityBlockedReason.quietHours,
        );
      }
    }

    final lastThirtySeconds = now.subtract(const Duration(seconds: 30));
    if (history.any((entry) => entry.presentedAt.isAfter(lastThirtySeconds))) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.recentDismissGuard,
      );
    }

    final deferred = history.where(
      (entry) =>
          entry.notificationId == definition.id &&
          entry.deferredUntil != null &&
          entry.deferredUntil!.isAfter(now),
    );
    if (deferred.isNotEmpty) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.deferred,
      );
    }

    if (definition.proactive &&
        history.any(
          (entry) =>
              entry.proactive && entry.sessionId == uiContext.sessionId,
        )) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.sessionCap,
      );
    }
    if (!definition.proactive &&
        history.any(
          (entry) =>
              entry.notificationId == definition.id &&
              entry.screenInstanceId == uiContext.screenInstanceId,
        )) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.screenCap,
      );
    }

    final cooldownStart = now.subtract(definition.cooldown);
    if (history.any(
      (entry) =>
          entry.notificationId == definition.id &&
          entry.presentedAt.isAfter(cooldownStart),
    )) {
      return NabiEligibilityDecision.blocked(
        definition,
        NabiEligibilityBlockedReason.cooldown,
      );
    }

    if (definition.upsell && definition.proactive) {
      final todayStart = DateTime(now.year, now.month, now.day);
      final rollingStart = now.subtract(const Duration(days: 7));
      final dailyCount = history
          .where(
            (entry) => entry.upsell && entry.presentedAt.isAfter(todayStart),
          )
          .length;
      if (dailyCount >= 2) {
        return NabiEligibilityDecision.blocked(
          definition,
          NabiEligibilityBlockedReason.dailyUpsellCap,
        );
      }
      final rollingCount = history
          .where(
            (entry) => entry.upsell && entry.presentedAt.isAfter(rollingStart),
          )
          .length;
      if (rollingCount >= 5) {
        return NabiEligibilityDecision.blocked(
          definition,
          NabiEligibilityBlockedReason.rollingUpsellCap,
        );
      }
    }

    return NabiEligibilityDecision.allowed(definition);
  }

  bool _matchesPolicy(String policy, NabiBusinessSnapshot snapshot) {
    return switch (policy) {
      'free_plan_limit' => snapshot.actorKind == 'guest'
          ? snapshot.guestHorizonExhausted
          : snapshot.planQuotaExhausted || snapshot.requestedPlanDays > 3,
      'free_chat_limit' =>
        snapshot.successfulChatCount == 2 || snapshot.attemptedChatNumber >= 4,
      'first_streak_7' => snapshot.firstStreakSeven,
      'expert_locked' => snapshot.expertLocked,
      'map365_locked' => snapshot.map365Locked,
      'weekly_report_locked' => snapshot.weeklyReportLocked,
      'expert_recommended' => snapshot.expertRecommended,
      'plus_day_7' => snapshot.subscriptionAgeDays == 7,
      'plus_day_15' => snapshot.subscriptionAgeDays == 15 && snapshot.activityReady,
      'plus_expiry_5' => snapshot.subscriptionDaysRemaining == 5,
      'plus_expiry_1' => snapshot.subscriptionDaysRemaining == 1,
      'streak_6' => snapshot.streakDays == 6 && !snapshot.todayCompleted,
      'rescue_card' => snapshot.streakLost && snapshot.rescueCardAvailable,
      'reward_ready' => snapshot.rewardReady,
      'report_ready' => snapshot.reportReady,
      'invite_available' => snapshot.inviteAvailable,
      'care_near_sleep' =>
        snapshot.nearSleep && snapshot.remainingRequiredTasks >= 2,
      'return_72h' => snapshot.awayHours >= 72,
      'partial_day' =>
        (snapshot.partialDay || snapshot.streakLost) &&
            !snapshot.rescueNotificationActive,
      'profile_stale' => snapshot.profileMissing || snapshot.profileAgeDays > 30,
      _ => false,
    };
  }

  bool _isQuietHour(DateTime now, NabiNotificationPreferences preferences) {
    final minute = now.hour * 60 + now.minute;
    final start = preferences.quietStartMinutes;
    final end = preferences.quietEndMinutes;
    if (start == end) return false;
    return start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
  }
}

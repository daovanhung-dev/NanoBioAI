import '../../domain/notifications/nabi_health_reminder_preferences.dart';

class NabiHealthReminderPlanningContext {
  final DateTime now;
  final NabiHealthReminderPreferences preferences;
  final NabiQuietHours quietHours;
  final DateTime? healthProfileUpdatedAt;
  final bool waterCompletedToday;
  final Duration rollingHorizon;

  const NabiHealthReminderPlanningContext({
    required this.now,
    required this.preferences,
    required this.quietHours,
    this.healthProfileUpdatedAt,
    this.waterCompletedToday = false,
    this.rollingHorizon = const Duration(hours: 48),
  });
}

class NabiHealthReminderPlanner {
  const NabiHealthReminderPlanner();

  List<NabiPlannedHealthReminder> plan(
    NabiHealthReminderPlanningContext context,
  ) {
    final preferences = context.preferences;
    if (!preferences.masterEnabled) return const [];

    final result = <NabiPlannedHealthReminder>[];
    if (preferences.healthCheckInEnabled) {
      result.addAll(_planHealthCheckIns(context));
    }
    if (preferences.waterReminderEnabled) {
      result.addAll(_planWater(context));
    }
    if (preferences.goalReviewEnabled) {
      final next = _planGoalReview(context);
      if (next != null) result.add(next);
    }
    if (preferences.profileReviewEnabled) {
      final next = _planProfileReview(context);
      if (next != null) result.add(next);
    }

    result.sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return _deduplicateMinutes(result);
  }

  List<NabiPlannedHealthReminder> _planHealthCheckIns(
    NabiHealthReminderPlanningContext context,
  ) {
    final prefs = context.preferences;
    final interval = Duration(
      minutes: prefs.healthCheckInIntervalMinutes.clamp(60, 240),
    );
    var earliest = context.now.add(const Duration(minutes: 2));
    final last = prefs.lastHealthCheckInAt;
    if (last != null) {
      final afterLast = last.toLocal().add(interval);
      if (afterLast.isAfter(earliest)) earliest = afterLast;
    }
    return _planRepeating(
      category: NabiHealthReminderCategory.healthCheckIn,
      earliest: earliest,
      horizonEnd: context.now.add(context.rollingHorizon),
      startMinutes: prefs.healthCheckInStartMinutes,
      endMinutes: prefs.healthCheckInEndMinutes,
      interval: interval,
      quietHours: context.quietHours,
      skipToday: false,
    );
  }

  List<NabiPlannedHealthReminder> _planWater(
    NabiHealthReminderPlanningContext context,
  ) {
    final prefs = context.preferences;
    return _planRepeating(
      category: NabiHealthReminderCategory.water,
      earliest: context.now.add(const Duration(minutes: 2)),
      horizonEnd: context.now.add(context.rollingHorizon),
      startMinutes: prefs.waterReminderStartMinutes,
      endMinutes: prefs.waterReminderEndMinutes,
      interval: Duration(
        minutes: prefs.waterReminderIntervalMinutes.clamp(60, 360),
      ),
      quietHours: context.quietHours,
      skipToday: context.waterCompletedToday,
    );
  }

  NabiPlannedHealthReminder? _planGoalReview(
    NabiHealthReminderPlanningContext context,
  ) {
    final now = context.now;
    final prefs = context.preferences;
    var candidate = _goalCandidateOnOrAfter(now, prefs.goalReviewMinutes);

    for (var guard = 0; guard < 4; guard++) {
      final period = goalReviewPeriodKey(candidate);
      if (period != prefs.lastGoalReviewPeriod) {
        candidate = _ensureFuture(candidate, now);
        candidate = _moveOutOfQuiet(candidate, context.quietHours);
        if (candidate.isAfter(now)) {
          return NabiPlannedHealthReminder(
            category: NabiHealthReminderCategory.goalReview,
            scheduledAt: candidate,
          );
        }
      }
      candidate = _nextGoalCandidate(candidate, prefs.goalReviewMinutes);
    }
    return null;
  }

  NabiPlannedHealthReminder? _planProfileReview(
    NabiHealthReminderPlanningContext context,
  ) {
    final prefs = context.preferences;
    final now = context.now;
    final candidates = <DateTime>[
      if (context.healthProfileUpdatedAt != null)
        context.healthProfileUpdatedAt!.toLocal(),
      if (prefs.lastProfileReviewedAt != null)
        prefs.lastProfileReviewedAt!.toLocal(),
    ];
    candidates.sort();
    final base = candidates.isEmpty ? now : candidates.last;
    var dueDate = base.add(
      Duration(days: prefs.profileReviewIntervalDays.clamp(7, 365)),
    );
    dueDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      prefs.profileReviewMinutes ~/ 60,
      prefs.profileReviewMinutes % 60,
    );
    dueDate = _ensureFuture(dueDate, now);
    dueDate = _moveOutOfQuiet(dueDate, context.quietHours);
    return NabiPlannedHealthReminder(
      category: NabiHealthReminderCategory.profileReview,
      scheduledAt: dueDate,
    );
  }

  List<NabiPlannedHealthReminder> _planRepeating({
    required NabiHealthReminderCategory category,
    required DateTime earliest,
    required DateTime horizonEnd,
    required int startMinutes,
    required int endMinutes,
    required Duration interval,
    required NabiQuietHours quietHours,
    required bool skipToday,
  }) {
    final result = <NabiPlannedHealthReminder>[];
    final normalizedStart = startMinutes.clamp(0, 1439);
    final normalizedEnd = endMinutes.clamp(0, 1439);
    var day = DateTime(earliest.year, earliest.month, earliest.day);
    final lastDay = DateTime(horizonEnd.year, horizonEnd.month, horizonEnd.day);

    while (!day.isAfter(lastDay)) {
      final isToday = _sameDate(day, earliest);
      if (!(skipToday && isToday)) {
        final windows = _activeWindows(day, normalizedStart, normalizedEnd);
        for (final window in windows) {
          var cursor = window.$1;
          while (cursor.isBefore(window.$2)) {
            if (!cursor.isBefore(earliest) &&
                !cursor.isAfter(horizonEnd) &&
                !quietHours.contains(cursor)) {
              result.add(
                NabiPlannedHealthReminder(
                  category: category,
                  scheduledAt: cursor,
                ),
              );
            }
            cursor = cursor.add(interval);
          }
        }
      }
      day = day.add(const Duration(days: 1));
    }
    return result;
  }

  List<(DateTime, DateTime)> _activeWindows(
    DateTime day,
    int startMinutes,
    int endMinutes,
  ) {
    DateTime at(int minutes, {int dayOffset = 0}) => DateTime(
      day.year,
      day.month,
      day.day + dayOffset,
      minutes ~/ 60,
      minutes % 60,
    );

    if (startMinutes == endMinutes) return const [];
    if (startMinutes < endMinutes) {
      return [(at(startMinutes), at(endMinutes))];
    }
    return [(at(startMinutes), at(endMinutes, dayOffset: 1))];
  }

  List<NabiPlannedHealthReminder> _deduplicateMinutes(
    List<NabiPlannedHealthReminder> reminders,
  ) {
    final seen = <String>{};
    final result = <NabiPlannedHealthReminder>[];
    for (final reminder in reminders) {
      var candidate = reminder;
      var key = _minuteKey(candidate.scheduledAt);
      if (seen.contains(key)) {
        if (candidate.category == NabiHealthReminderCategory.healthCheckIn ||
            candidate.category == NabiHealthReminderCategory.water) {
          final shifted = candidate.scheduledAt.add(const Duration(minutes: 1));
          candidate = NabiPlannedHealthReminder(
            category: candidate.category,
            scheduledAt: shifted,
          );
          key = _minuteKey(shifted);
        }
      }
      if (seen.add(key)) result.add(candidate);
    }
    return result;
  }

  DateTime _goalCandidateOnOrAfter(DateTime now, int minutes) {
    final day = now.day;
    if (day <= 1) return _dateAt(now.year, now.month, 1, minutes);
    if (day <= 15) return _dateAt(now.year, now.month, 15, minutes);
    return _dateAt(now.year, now.month + 1, 1, minutes);
  }

  DateTime _nextGoalCandidate(DateTime current, int minutes) {
    if (current.day == 1) {
      return _dateAt(current.year, current.month, 15, minutes);
    }
    return _dateAt(current.year, current.month + 1, 1, minutes);
  }

  DateTime _dateAt(int year, int month, int day, int minutes) {
    final normalized = minutes.clamp(0, 1439);
    return DateTime(
      year,
      month,
      day,
      normalized ~/ 60,
      normalized % 60,
    );
  }

  DateTime _ensureFuture(DateTime candidate, DateTime now) {
    if (candidate.isAfter(now)) return candidate;
    return now.add(const Duration(minutes: 2));
  }

  DateTime _moveOutOfQuiet(DateTime candidate, NabiQuietHours quietHours) {
    if (!quietHours.contains(candidate)) return candidate;
    final end = quietHours.endMinutes.clamp(0, 1439);
    final candidateMinute = candidate.hour * 60 + candidate.minute;
    final wraps = quietHours.startMinutes > quietHours.endMinutes;
    final dayOffset = wraps && candidateMinute >= quietHours.startMinutes ? 1 : 0;
    return DateTime(
      candidate.year,
      candidate.month,
      candidate.day + dayOffset,
      end ~/ 60,
      end % 60,
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _minuteKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}-${value.hour}-${value.minute}';

  static String goalReviewPeriodKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

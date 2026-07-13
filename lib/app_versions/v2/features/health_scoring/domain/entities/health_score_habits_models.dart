const healthScoreHabitsFormulaVersion = 'm08_wellness_v1_2026_06';
const healthScoreHabitsLocalDraftFormulaVersion =
    healthScoreHabitsFormulaVersion;

class HealthScorePeriod {
  final String startDate;
  final String endDate;

  const HealthScorePeriod({required this.startDate, required this.endDate});

  factory HealthScorePeriod.lastDays({required DateTime now, int days = 7}) {
    final today = HealthScoreDateKey.fromDate(now);
    final start = HealthScoreDateKey.fromDate(
      HealthScoreDateKey.dateOnly(now).subtract(Duration(days: days - 1)),
    );
    return HealthScorePeriod(startDate: start, endDate: today);
  }

  List<String> get dateKeys {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null || end.isBefore(start)) {
      return const [];
    }

    final count = end.difference(start).inDays + 1;
    return List<String>.generate(
      count,
      (index) => HealthScoreDateKey.fromDate(start.add(Duration(days: index))),
      growable: false,
    );
  }
}

class HealthScoreDateKey {
  const HealthScoreDateKey._();

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String fromDate(DateTime value) {
    final date = dateOnly(value);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String? fromValue(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}

class CalculateHealthScoreCommand {
  final String actorId;
  final String? subjectId;
  final bool isFamilyPlus;
  final HealthScorePeriod? period;
  final DateTime? now;

  const CalculateHealthScoreCommand({
    required this.actorId,
    this.subjectId,
    this.isFamilyPlus = false,
    this.period,
    this.now,
  });
}

class LoadHabitProgressCommand {
  final String actorId;
  final String? subjectId;
  final bool isFamilyPlus;
  final HealthScorePeriod? period;
  final DateTime? now;

  const LoadHabitProgressCommand({
    required this.actorId,
    this.subjectId,
    this.isFamilyPlus = false,
    this.period,
    this.now,
  });
}

enum HealthScoreCompletionGroup { tasksHabits, meals }

class HealthScoreCompletionEntry {
  final String id;
  final String date;
  final HealthScoreCompletionGroup group;
  final String category;
  final String title;
  final bool isCompleted;
  final bool isDue;

  const HealthScoreCompletionEntry({
    required this.id,
    required this.date,
    required this.group,
    required this.category,
    required this.title,
    required this.isCompleted,
    required this.isDue,
  });
}

class HealthScoreDailyLogEntry {
  final String date;
  final int waterMl;
  final double sleepHours;

  const HealthScoreDailyLogEntry({
    required this.date,
    this.waterMl = 0,
    this.sleepHours = 0,
  });
}

class HealthScoreInputSnapshot {
  final String userId;
  final HealthScorePeriod period;
  final DateTime now;
  final List<HealthScoreCompletionEntry> completionEntries;
  final List<HealthScoreDailyLogEntry> dailyLogs;

  const HealthScoreInputSnapshot({
    required this.userId,
    required this.period,
    required this.now,
    required this.completionEntries,
    required this.dailyLogs,
  });
}

class HealthScoreBreakdownItem {
  final String code;
  final String label;
  final int weight;
  final int score;
  final int completedCount;
  final int totalCount;

  const HealthScoreBreakdownItem({
    required this.code,
    required this.label,
    required this.weight,
    required this.score,
    required this.completedCount,
    required this.totalCount,
  });

  bool get hasInput => totalCount > 0;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}

class HealthScoreHabitProgressItem {
  final String code;
  final String label;
  final int completedCount;
  final int dueCount;

  const HealthScoreHabitProgressItem({
    required this.code,
    required this.label,
    required this.completedCount,
    required this.dueCount,
  });

  double get progress => dueCount == 0 ? 0 : completedCount / dueCount;
}

class HealthScoreHabitsResult {
  final int score;
  final String formulaVersion;
  final HealthScorePeriod period;
  final bool hasInputs;
  final List<HealthScoreBreakdownItem> breakdown;
  final List<HealthScoreHabitProgressItem> habitProgress;

  const HealthScoreHabitsResult({
    required this.score,
    required this.formulaVersion,
    required this.period,
    required this.hasInputs,
    required this.breakdown,
    required this.habitProgress,
  });

  const HealthScoreHabitsResult.empty({
    required this.period,
    this.formulaVersion = healthScoreHabitsFormulaVersion,
  }) : score = 0,
       hasInputs = false,
       breakdown = const [],
       habitProgress = const [];
}

class HealthScoreHabitsException implements Exception {
  final String code;
  final String safeMessage;

  const HealthScoreHabitsException(this.code, this.safeMessage);

  const HealthScoreHabitsException.authRequired()
    : this('AUTH_REQUIRED', 'Vui lòng đăng nhập để xem điểm sức khỏe.');

  const HealthScoreHabitsException.forbidden()
    : this(
        'FORBIDDEN',
        'Chỉ gói FamilyPlus mới được xem hồ sơ sức khỏe của thành viên khác.',
      );

  const HealthScoreHabitsException.invalidCommand()
    : this('INVALID_COMMAND', 'Yêu cầu xem điểm sức khỏe chưa hợp lệ.');

  @override
  String toString() => '$code: $safeMessage';
}

const advancedTrackingHydrationGoalCode = 'advanced_hydration';
const advancedTrackingHydrationGoalName = 'Uống đủ nước mỗi ngày';
const advancedTrackingHydrationFormulaVersion =
    'm10_hydration_local_v1_2026_06';
const advancedTrackingHydrationTargetMl = 2000;

class AdvancedTrackingActorContext {
  final String actorId;
  final bool hasPaidAccess;
  final bool isFamilyPlus;

  const AdvancedTrackingActorContext({
    required this.actorId,
    required this.hasPaidAccess,
    this.isFamilyPlus = false,
  });

  String resolveSubjectId(String? requestedSubjectId) {
    final actor = actorId.trim();
    if (actor.isEmpty) {
      throw const AdvancedTrackingException.authRequired();
    }
    if (!hasPaidAccess) {
      throw const AdvancedTrackingException.forbidden();
    }

    final requested = requestedSubjectId?.trim();
    final subject = requested == null || requested.isEmpty ? actor : requested;
    if (subject != actor && !isFamilyPlus) {
      throw const AdvancedTrackingException.forbidden();
    }
    return subject;
  }
}

class AdvancedTrackingPeriod {
  final String startDate;
  final String endDate;

  const AdvancedTrackingPeriod({
    required this.startDate,
    required this.endDate,
  });

  factory AdvancedTrackingPeriod.lastDays({
    required DateTime now,
    int days = 7,
  }) {
    final today = AdvancedTrackingDateKey.fromDate(now);
    final start = AdvancedTrackingDateKey.fromDate(
      AdvancedTrackingDateKey.dateOnly(now).subtract(Duration(days: days - 1)),
    );
    return AdvancedTrackingPeriod(startDate: start, endDate: today);
  }

  List<String> get dateKeys {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null || end.isBefore(start)) {
      return const [];
    }

    return List<String>.generate(
      end.difference(start).inDays + 1,
      (index) =>
          AdvancedTrackingDateKey.fromDate(start.add(Duration(days: index))),
      growable: false,
    );
  }
}

class AdvancedTrackingDateKey {
  const AdvancedTrackingDateKey._();

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String fromDate(DateTime value) {
    final date = dateOnly(value);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class CreateAdvancedGoalCommand {
  final AdvancedTrackingActorContext actor;
  final String? subjectUserId;
  final DateTime? now;

  const CreateAdvancedGoalCommand({
    required this.actor,
    this.subjectUserId,
    this.now,
  });
}

class LoadGoalRoadmapCommand {
  final AdvancedTrackingActorContext actor;
  final String? subjectUserId;
  final AdvancedTrackingPeriod? period;
  final DateTime? now;

  const LoadGoalRoadmapCommand({
    required this.actor,
    this.subjectUserId,
    this.period,
    this.now,
  });
}

class AdvancedTrackingGoal {
  final String id;
  final String subjectUserId;
  final String goalCode;
  final String goalName;
  final bool isActive;
  final String createdAt;

  const AdvancedTrackingGoal({
    required this.id,
    required this.subjectUserId,
    required this.goalCode,
    required this.goalName,
    required this.isActive,
    required this.createdAt,
  });
}

class AdvancedTrackingHydrationLog {
  final String date;
  final int waterMl;

  const AdvancedTrackingHydrationLog({
    required this.date,
    required this.waterMl,
  });
}

class AdvancedTrackingRoadmapStep {
  final String date;
  final int waterMl;
  final int targetMl;

  const AdvancedTrackingRoadmapStep({
    required this.date,
    required this.waterMl,
    this.targetMl = advancedTrackingHydrationTargetMl,
  });

  bool get isComplete => waterMl >= targetMl;

  double get progress {
    if (targetMl <= 0) return 0;
    return (waterMl / targetMl).clamp(0, 1).toDouble();
  }
}

class AdvancedTrackingRoadmapResult {
  final String subjectUserId;
  final AdvancedTrackingGoal? goal;
  final AdvancedTrackingPeriod period;
  final String formulaVersion;
  final int targetMl;
  final List<AdvancedTrackingRoadmapStep> steps;

  const AdvancedTrackingRoadmapResult({
    required this.subjectUserId,
    required this.goal,
    required this.period,
    required this.steps,
    this.formulaVersion = advancedTrackingHydrationFormulaVersion,
    this.targetMl = advancedTrackingHydrationTargetMl,
  });

  bool get hasGoal => goal != null;

  int get completedDays => steps.where((step) => step.isComplete).length;

  int get totalDays => steps.length;

  double get progress => totalDays == 0 ? 0 : completedDays / totalDays;

  int get averageWaterMl {
    if (steps.isEmpty) return 0;
    final total = steps.fold<int>(0, (sum, step) => sum + step.waterMl);
    return (total / steps.length).round();
  }
}

class AdvancedTrackingException implements Exception {
  final String code;
  final String safeMessage;

  const AdvancedTrackingException(this.code, this.safeMessage);

  const AdvancedTrackingException.authRequired()
    : this('AUTH_REQUIRED', 'Bạn cần đăng nhập để xem lộ trình này.');

  const AdvancedTrackingException.forbidden()
    : this(
        'FORBIDDEN',
        'Tính năng này dành cho Plus và FamilyPlus. Nabi sẽ mở khi gói của bạn sẵn sàng.',
      );

  const AdvancedTrackingException.invalidCommand()
    : this(
        'INVALID_COMMAND',
        'Nabi chưa thể tạo lộ trình từ thông tin hiện tại.',
      );

  @override
  String toString() => '$code: $safeMessage';
}

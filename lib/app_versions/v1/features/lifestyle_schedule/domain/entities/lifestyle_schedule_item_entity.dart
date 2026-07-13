import '../services/lifestyle_schedule_window_policy.dart';

export '../services/lifestyle_schedule_window_policy.dart'
    show CompletionWindowStatus;

class LifestyleScheduleSourceTypes {
  static const mealPlan = 'meal_plan';
  static const exerciseTask = 'exercise_task';
  static const dailyHealthTask = 'daily_health_task';
  static const aiSchedule = 'ai_schedule';
}

class LifestyleScheduleCategories {
  static const routine = 'routine';
  static const meal = 'meal';
  static const water = 'water';
  static const body = 'body';
  static const mind = 'mind';
  static const brain = 'brain';
  static const sleep = 'sleep';
}

class LifestyleScheduleItemEntity {
  static const completionWindow =
      LifestyleScheduleWindowPolicy.completionWindow;

  final String id;
  final String? userId;
  final String scheduleDate;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String category;
  final String sourceType;
  final String? sourceId;
  final double targetValue;
  final double currentValue;
  final String unit;
  final bool isCompleted;
  final String? completionProofPath;
  final String? completionProofCapturedAt;
  final String? completedAt;
  final int sortOrder;
  final bool aiGenerated;
  final String encouragement;
  final String createdAt;
  final String updatedAt;

  const LifestyleScheduleItemEntity({
    required this.id,
    this.userId,
    required this.scheduleDate,
    required this.startTime,
    this.endTime = '',
    required this.title,
    this.description = '',
    required this.category,
    required this.sourceType,
    this.sourceId,
    this.targetValue = 1,
    this.currentValue = 0,
    this.unit = 'lan',
    this.isCompleted = false,
    this.completionProofPath,
    this.completionProofCapturedAt,
    this.completedAt,
    this.sortOrder = 0,
    this.aiGenerated = true,
    this.encouragement = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isMealLinked =>
      sourceType == LifestyleScheduleSourceTypes.mealPlan &&
      (sourceId?.isNotEmpty ?? false);

  bool get isDailyTaskLinked =>
      sourceType == LifestyleScheduleSourceTypes.dailyHealthTask &&
      (sourceId?.isNotEmpty ?? false);

  bool get isExerciseTask =>
      sourceType == LifestyleScheduleSourceTypes.exerciseTask;

  bool get isQuantitative => targetValue > 1;

  DateTime? get scheduledAt {
    return LifestyleScheduleWindowPolicy.parseScheduledAt(
      scheduleDate: scheduleDate,
      startTime: startTime,
    );
  }

  DateTime? get completionDeadline {
    final scheduled = scheduledAt;
    if (scheduled == null) return null;
    return scheduled.add(completionWindow);
  }

  CompletionWindowStatus completionStatusAt(DateTime now) {
    return LifestyleScheduleWindowPolicy.statusAt(
      scheduleDate: scheduleDate,
      startTime: startTime,
      isCompleted: isCompleted,
      now: now,
    );
  }

  bool isWithinCompletionWindow(DateTime now) {
    return LifestyleScheduleWindowPolicy.isWithinWindow(
      scheduleDate: scheduleDate,
      startTime: startTime,
      now: now,
    );
  }

  bool canCompleteAt(DateTime now) {
    return !isCompleted && isWithinCompletionWindow(now);
  }

  double get progressRatio {
    if (targetValue <= 0) return isCompleted ? 1 : 0;
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  LifestyleScheduleItemEntity copyWith({
    String? id,
    String? userId,
    String? scheduleDate,
    String? startTime,
    String? endTime,
    String? title,
    String? description,
    String? category,
    String? sourceType,
    String? sourceId,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool? isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? completedAt,
    bool clearCompletionProof = false,
    int? sortOrder,
    bool? aiGenerated,
    String? encouragement,
    String? createdAt,
    String? updatedAt,
  }) {
    return LifestyleScheduleItemEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      completionProofPath: clearCompletionProof
          ? null
          : completionProofPath ?? this.completionProofPath,
      completionProofCapturedAt: clearCompletionProof
          ? null
          : completionProofCapturedAt ?? this.completionProofCapturedAt,
      completedAt: clearCompletionProof
          ? null
          : completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      encouragement: encouragement ?? this.encouragement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

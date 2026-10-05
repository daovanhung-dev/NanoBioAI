const fitnessWorkoutTimeOptions = <String>[
  '06:00',
  '07:00',
  '08:00',
  '12:00',
  '16:30',
  '17:30',
  '18:30',
  '19:30',
];

class FitnessWorkoutScheduleSlot {
  const FitnessWorkoutScheduleSlot({
    required this.startAt,
    required this.endAt,
  });

  final DateTime startAt;
  final DateTime endAt;
}

class FitnessWorkoutTimeResolution {
  const FitnessWorkoutTimeResolution({
    required this.requestedTime,
    required this.conflicts,
    this.suggestedTime,
  });

  final String requestedTime;
  final String? suggestedTime;
  final List<FitnessScheduleConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

class FitnessScheduleConflict {
  const FitnessScheduleConflict({
    required this.workoutStartAt,
    required this.workoutEndAt,
    required this.itemTitle,
    required this.itemStartAt,
    required this.itemEndAt,
  });

  final DateTime workoutStartAt;
  final DateTime workoutEndAt;
  final String itemTitle;
  final DateTime itemStartAt;
  final DateTime? itemEndAt;
}

class FitnessScheduleConflictException implements Exception {
  const FitnessScheduleConflictException(this.conflicts);

  final List<FitnessScheduleConflict> conflicts;

  @override
  String toString() => 'Fitness schedule conflicts: ${conflicts.length}';
}

class FitnessWorkoutTimeResolutionRequired implements Exception {
  const FitnessWorkoutTimeResolutionRequired(this.resolution);

  final FitnessWorkoutTimeResolution resolution;

  @override
  String toString() =>
      'Workout time resolution required: ${resolution.requestedTime} '
      'to ${resolution.suggestedTime ?? 'a manually selected time'}';
}

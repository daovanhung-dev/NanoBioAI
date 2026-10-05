class FitnessWorkoutScheduleSlot {
  const FitnessWorkoutScheduleSlot({
    required this.startAt,
    required this.endAt,
  });

  final DateTime startAt;
  final DateTime endAt;
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

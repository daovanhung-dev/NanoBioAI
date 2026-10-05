import '../entities/fitness_training_program.dart';
import '../entities/fitness_training_catalog.dart';
import '../entities/fitness_schedule_conflict.dart';

abstract interface class FitnessTrainingRepository {
  Future<bool> guestInitialPlanAvailable(String userId);

  Future<List<FitnessTrainingProgram>> loadPrograms(String userId);

  Future<FitnessTrainingProgram?> findByRequestId(
    String userId,
    String requestId,
  );

  Future<FitnessTrainingProgram> savePreview(
    FitnessTrainingProgram program, {
    required bool guest,
  });

  Future<void> markQuotaCommitted({
    required String userId,
    required String programId,
  });

  Future<FitnessTrainingProgram> saveCheckIn({
    required String userId,
    required String programId,
    required FitnessWeeklyCheckIn checkIn,
  });

  Future<List<FitnessScheduleConflict>> findScheduleConflicts({
    required String userId,
    required List<FitnessWorkoutScheduleSlot> slots,
    required DateTime now,
  });

  Future<Map<String, List<FitnessScheduleConflict>>>
  findScheduleConflictsByWorkoutTime({
    required String userId,
    required Map<String, List<FitnessWorkoutScheduleSlot>> slotsByTime,
    required DateTime now,
  });

  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
    String? workoutTimeOverride,
  });
}

class FitnessTrainingGuestQuotaExceededException implements Exception {
  const FitnessTrainingGuestQuotaExceededException();

  static const userMessage =
      'Lượt tạo chương trình dành cho khách đã dùng rồi. Đăng nhập để tiếp tục luyện tập cùng Nabi nhé.';
}

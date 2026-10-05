import '../entities/fitness_training_program.dart';
import '../entities/fitness_training_catalog.dart';

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

  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
  });
}

class FitnessTrainingGuestQuotaExceededException implements Exception {
  const FitnessTrainingGuestQuotaExceededException();

  static const userMessage =
      'Lượt tạo chương trình dành cho khách đã dùng rồi. Đăng nhập để tiếp tục luyện tập cùng Nabi nhé.';
}

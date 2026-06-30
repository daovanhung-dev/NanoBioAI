import '../entities/advanced_tracking_models.dart';

abstract class AdvancedTrackingRepository {
  Future<AdvancedTrackingGoal?> loadActiveGoal({
    required String subjectUserId,
    required String goalCode,
  });

  Future<AdvancedTrackingGoal> createHydrationGoal({
    required String subjectUserId,
    required DateTime now,
  });

  Future<List<AdvancedTrackingHydrationLog>> loadHydrationLogs({
    required String subjectUserId,
    required AdvancedTrackingPeriod period,
  });
}

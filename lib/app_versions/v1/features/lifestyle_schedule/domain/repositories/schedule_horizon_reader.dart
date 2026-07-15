import '../entities/schedule_horizon.dart';

abstract class ScheduleHorizonReader {
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  });
}

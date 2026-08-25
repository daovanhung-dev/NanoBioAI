import 'water_tracking_snapshot.dart';

abstract interface class WaterTrackingRepository {
  Future<WaterTrackingSnapshot> load(DateTime localDay);

  Future<void> saveTargetMl(int targetMl);

  Future<void> saveAmountMl(DateTime localDay, int amountMl);
}

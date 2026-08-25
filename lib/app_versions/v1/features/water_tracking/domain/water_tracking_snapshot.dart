class WaterTrackingSnapshot {
  final int? targetMl;
  final int amountMl;

  const WaterTrackingSnapshot({
    required this.targetMl,
    required this.amountMl,
  });

  WaterTrackingSnapshot copyWith({
    int? targetMl,
    int? amountMl,
    bool clearTarget = false,
  }) {
    return WaterTrackingSnapshot(
      targetMl: clearTarget ? null : targetMl ?? this.targetMl,
      amountMl: amountMl ?? this.amountMl,
    );
  }
}

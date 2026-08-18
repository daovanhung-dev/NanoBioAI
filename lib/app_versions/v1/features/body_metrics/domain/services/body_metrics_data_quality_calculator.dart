import '../entities/body_metrics_health_snapshot.dart';

class BodyMetricsDataQualityResult {
  final double completeness;
  final Map<String, DateTime?> freshnessByGroup;
  final List<String> gaps;

  const BodyMetricsDataQualityResult({
    required this.completeness,
    required this.freshnessByGroup,
    required this.gaps,
  });
}

class BodyMetricsDataQualityCalculator {
  const BodyMetricsDataQualityCalculator._();

  static BodyMetricsDataQualityResult calculate(BodyMetricsHealthSnapshot snapshot) {
    final gaps = <String>[];

    final profileParts = <bool>[
      snapshot.heightCm != null,
      snapshot.currentWeightKg != null,
      snapshot.ageYears != null,
      snapshot.sex != null,
      snapshot.activityLevel != null,
    ];
    final profileScore = _fraction(profileParts);
    if (snapshot.heightCm == null) gaps.add('Thiếu chiều cao trong hồ sơ sức khỏe.');
    if (snapshot.currentWeightKg == null) gaps.add('Chưa có cân nặng hợp lệ.');
    if (snapshot.ageYears == null) gaps.add('Thiếu tuổi để tính nhóm chỉ số theo tuổi.');
    if (snapshot.activityLevel == null) gaps.add('Chưa có mức vận động gần đây.');

    final tracking7 = snapshot.trackingWithinDays(7);
    final tracking30 = snapshot.trackingWithinDays(30);
    final trackingParts = <bool>[
      tracking7.length >= 3,
      tracking30.length >= 7,
      tracking30.any((row) => row.weightKg != null),
      tracking30.any((row) => row.sleepHours != null),
      tracking30.any((row) => row.steps != null || row.waterMl != null),
    ];
    final trackingScore = _fraction(trackingParts);
    if (tracking7.length < 3) gaps.add('Chưa đủ dữ liệu tracking để đọc xu hướng bảy ngày.');
    if (tracking30.length < 7) gaps.add('Chưa đủ dữ liệu tracking để đọc xu hướng ba mươi ngày.');

    final nutrition30 = snapshot.nutritionWithinDays(30);
    final nutritionParts = <bool>[
      nutrition30.length >= 3,
      nutrition30.any((row) => row.calories != null),
      nutrition30.any((row) => row.proteinG != null),
      nutrition30.any((row) => row.fiberG != null),
    ];
    final nutritionScore = _fraction(nutritionParts);
    if (nutrition30.length < 3) gaps.add('Chưa đủ ngày thực đơn để phân tích dinh dưỡng ổn định.');

    final lifestyleScore = snapshot.lifestyle == null ? 0.0 : 1.0;
    if (snapshot.lifestyle == null) gaps.add('Chưa có dữ liệu thói quen sống.');

    final scheduleScore = snapshot.schedule.plannedTaskCount == 0 ? 0.0 : 1.0;
    if (snapshot.schedule.plannedTaskCount == 0) gaps.add('Chưa có lịch chăm sóc trong cửa sổ phân tích.');

    final contextScore = snapshot.contextLoaded ? 1.0 : 0.0;
    if (!snapshot.contextLoaded) gaps.add('Chưa tải được bối cảnh mục tiêu và tình trạng đã khai báo.');

    final completeness = profileScore * .20 +
        trackingScore * .20 +
        nutritionScore * .20 +
        lifestyleScore * .15 +
        scheduleScore * .15 +
        contextScore * .10;

    return BodyMetricsDataQualityResult(
      completeness: completeness.clamp(0.0, 1.0).toDouble(),
      freshnessByGroup: {
        'profile': snapshot.profileUpdatedAt,
        'tracking': snapshot.tracking.isEmpty ? null : snapshot.tracking.first.date,
        'nutrition': snapshot.nutrition.isEmpty ? null : snapshot.nutrition.first.date,
        'lifestyle': snapshot.lifestyle?.updatedAt,
        'schedule': snapshot.schedule.latestUpdatedAt,
        'context': snapshot.generatedAt,
      },
      gaps: gaps,
    );
  }

  static double _fraction(List<bool> values) {
    if (values.isEmpty) return 0;
    return values.where((value) => value).length / values.length;
  }
}

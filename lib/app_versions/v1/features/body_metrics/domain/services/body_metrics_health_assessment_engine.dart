import '../entities/body_metrics_health_assessment.dart';
import '../entities/body_metrics_health_metric.dart';
import '../entities/body_metrics_health_report.dart';
import '../entities/body_metrics_health_snapshot.dart';

class BodyMetricsHealthAssessmentEngine {
  const BodyMetricsHealthAssessmentEngine._();

  static BodyMetricsHealthAssessment assess({
    required BodyMetricsHealthSnapshot snapshot,
    required BodyMetricsHealthReport report,
  }) {
    final strengths = <String>[];
    final attentionItems = <String>[];
    final evaluatedGroups = <String>{};
    final attentionGroups = <String>{};
    var evaluatedSignals = 0;

    void evaluated(String group) {
      evaluatedGroups.add(group);
      evaluatedSignals += 1;
    }

    void strength(String group, String message) {
      evaluated(group);
      if (!strengths.contains(message)) strengths.add(message);
    }

    void attention(String group, String message) {
      evaluated(group);
      attentionGroups.add(group);
      if (!attentionItems.contains(message)) attentionItems.add(message);
    }

    void neutral(String group) => evaluated(group);

    final bmi = report.metric(BodyMetricsMetricIds.bmi)?.value;
    final canUseAdultBmi = snapshot.ageYears != null && snapshot.ageYears! >= 18;
    if (bmi != null && canUseAdultBmi) {
      if (bmi >= 18.5 && bmi < 25) {
        strength(
          'body',
          'Cân nặng đang trong khoảng tham khảo so với chiều cao.',
        );
      } else {
        final direction = bmi < 18.5
            ? 'thấp hơn khoảng tham khảo'
            : bmi < 30
                ? 'cao hơn khoảng tham khảo'
                : 'cao đáng kể so với khoảng tham khảo';
        attention(
          'body',
          'Cân nặng đang $direction so với chiều cao — hãy theo dõi xu hướng và ưu tiên thay đổi thói quen từ từ.',
        );
      }
    }

    final sleepAverage = report.metric(BodyMetricsMetricIds.sleepAverage7d)?.value;
    if (sleepAverage != null) {
      if (sleepAverage >= 7 && sleepAverage <= 9) {
        strength(
          'recovery',
          'Thời lượng ngủ gần đây đang trong khoảng tham khảo 7–9 giờ.',
        );
      } else {
        attention(
          'recovery',
          'Thời lượng ngủ gần đây đang ngoài khoảng 7–9 giờ — thử điều chỉnh giờ ngủ đều hơn, từng 15–30 phút.',
        );
      }
    }

    final macroBalance =
        report.metric(BodyMetricsMetricIds.macroBalanceCount)?.value;
    if (macroBalance != null) {
      if (macroBalance >= 3) {
        strength(
          'nutrition',
          'Tỷ lệ đạm, tinh bột và chất béo đang cân đối theo các khoảng tham khảo hiện có.',
        );
      } else if (macroBalance <= 1) {
        attention(
          'nutrition',
          'Tỷ lệ đạm, tinh bột và chất béo còn lệch nhiều — ưu tiên các bữa ăn cân bằng hơn.',
        );
      } else {
        neutral('nutrition');
      }
    }

    final fiberCoverage =
        report.metric(BodyMetricsMetricIds.fiberCoverage)?.value;
    if (fiberCoverage != null) {
      if (fiberCoverage >= 100) {
        strength(
          'nutrition',
          'Lượng chất xơ trung bình đang đạt mốc tham khảo của khẩu phần hiện tại.',
        );
      } else if (fiberCoverage < 70) {
        attention(
          'nutrition',
          'Chất xơ đang thấp hơn khoảng 70% mốc tham khảo — thử thêm rau, đậu, quả hoặc ngũ cốc nguyên hạt.',
        );
      } else {
        neutral('nutrition');
      }
    }

    final sodiumRatio = report.metric(BodyMetricsMetricIds.sodiumRatio)?.value;
    if (sodiumRatio != null) {
      if (sodiumRatio <= 100) {
        strength(
          'nutrition',
          'Natri trung bình đang trong mốc tham khảo 2.300 mg/ngày.',
        );
      } else {
        attention(
          'nutrition',
          'Natri trung bình đang vượt mốc tham khảo 2.300 mg/ngày — nên giảm món quá mặn và thực phẩm chế biến sẵn.',
        );
      }
    }

    final hasEnoughData = report.dataCompleteness >= 0.35 &&
        evaluatedGroups.length >= 2 &&
        evaluatedSignals >= 2;
    final dataConfidenceLabel = _dataConfidenceLabel(report.dataCompleteness);
    final keyMetricIds = _selectKeyMetrics(report);

    if (!hasEnoughData) {
      return BodyMetricsHealthAssessment(
        level: BodyMetricsOverallHealthLevel.insufficientData,
        headline: 'CHƯA ĐỦ DỮ LIỆU',
        summary:
            'Nabi chưa có đủ dữ liệu gần đây để nói sức khỏe của bạn đang tốt hay cần chú ý. Hãy cập nhật thêm các thông tin cơ bản và theo dõi vài ngày nữa.',
        strengths: strengths.take(3).toList(growable: false),
        attentionItems: attentionItems.take(3).toList(growable: false),
        keyMetricIds: keyMetricIds,
        dataConfidenceLabel: dataConfidenceLabel,
        hasEnoughData: false,
      );
    }

    final level = switch (attentionGroups.length) {
      0 => BodyMetricsOverallHealthLevel.good,
      1 => strengths.isEmpty
          ? BodyMetricsOverallHealthLevel.attention
          : BodyMetricsOverallHealthLevel.fair,
      2 => BodyMetricsOverallHealthLevel.attention,
      _ => BodyMetricsOverallHealthLevel.concern,
    };

    return BodyMetricsHealthAssessment(
      level: level,
      headline: _headline(level),
      summary: _summary(level),
      strengths: strengths.take(3).toList(growable: false),
      attentionItems: attentionItems.take(3).toList(growable: false),
      keyMetricIds: keyMetricIds,
      dataConfidenceLabel: dataConfidenceLabel,
      hasEnoughData: true,
    );
  }

  static String _headline(BodyMetricsOverallHealthLevel level) => switch (level) {
        BodyMetricsOverallHealthLevel.good => 'TỐT',
        BodyMetricsOverallHealthLevel.fair => 'KHÁ ỔN',
        BodyMetricsOverallHealthLevel.attention => 'CẦN CHÚ Ý',
        BodyMetricsOverallHealthLevel.concern => 'CẦN QUAN TÂM',
        BodyMetricsOverallHealthLevel.insufficientData => 'CHƯA ĐỦ DỮ LIỆU',
      };

  static String _summary(BodyMetricsOverallHealthLevel level) => switch (level) {
        BodyMetricsOverallHealthLevel.good =>
          'Các nhóm chỉ số đủ dữ liệu hiện đang nằm trong khoảng tham khảo. Hãy tiếp tục duy trì những thói quen đang làm tốt.',
        BodyMetricsOverallHealthLevel.fair =>
          'Nhìn chung sức khỏe của bạn khá ổn, nhưng có một nhóm chỉ số nên được cải thiện thêm.',
        BodyMetricsOverallHealthLevel.attention =>
          'Có một vài nhóm chỉ số đang lệch khỏi khoảng tham khảo. Ưu tiên cải thiện từng việc nhỏ trong những ngày tới.',
        BodyMetricsOverallHealthLevel.concern =>
          'Nhiều nhóm chỉ số đang cùng cần được quan tâm. Hãy theo dõi sát hơn và cân nhắc trao đổi với chuyên gia y tế nếu tình trạng kéo dài hoặc bạn có triệu chứng.',
        BodyMetricsOverallHealthLevel.insufficientData =>
          'Nabi chưa có đủ dữ liệu để đưa ra nhận định tổng quan.',
      };

  static String _dataConfidenceLabel(double completeness) {
    if (completeness >= 0.75) return 'Dữ liệu khá đầy đủ';
    if (completeness >= 0.50) return 'Dữ liệu ở mức vừa';
    return 'Dữ liệu còn hạn chế';
  }

  static List<String> _selectKeyMetrics(BodyMetricsHealthReport report) {
    const priorities = <String>[
      BodyMetricsMetricIds.bmi,
      BodyMetricsMetricIds.sleepAverage7d,
      BodyMetricsMetricIds.waterAverage7d,
      BodyMetricsMetricIds.stepsAverage,
      BodyMetricsMetricIds.energyAlignment,
      BodyMetricsMetricIds.macroBalanceCount,
      BodyMetricsMetricIds.latestHeartRate,
      BodyMetricsMetricIds.latestSpO2,
    ];

    return priorities
        .where((id) => report.metric(id)?.hasValue ?? false)
        .take(6)
        .toList(growable: false);
  }
}

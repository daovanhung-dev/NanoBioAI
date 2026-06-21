import 'dart:math' as math;

import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_health_input.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_health_status.dart';

/// Pure calculation service for dashboard health status.
///
/// This module does not know Flutter widgets, Riverpod, Supabase or SQLite.
/// It only receives normalized health data and returns UI-ready scores.
class DashboardHealthCalculator {
  const DashboardHealthCalculator._();

  static DashboardHealthStatus calculate(DashboardHealthInput input) {
    final bmi = _resolveBmi(input);
    final bmiLabel = _bmiLabel(bmi);
    final bmiScore = _bmiScore(bmi);

    final hydrationLiter = _resolveWaterLiter(
      input.waterPerDay,
      input.latestWaterMl,
    );
    final hydrationScore = _hydrationScore(hydrationLiter);

    final sleepScore = _sleepScore(input.sleepQuality, input.latestSleepHours);
    final activityScore = _activityScore(
      input.activityLevel,
      input.latestStepsCount,
    );
    final stressScore = _stressScore(
      input.latestStressLevel,
      input.conditions,
      input.concernText,
    );
    final conditionScore = _conditionScore(input.conditions);
    final goalFocusScore = _goalFocusScore(input.goals);

    final totalScore = _weightedAverage(<_WeightedScore>[
      _WeightedScore(bmiScore, 0.22),
      _WeightedScore(hydrationScore, 0.16),
      _WeightedScore(sleepScore, 0.18),
      _WeightedScore(activityScore, 0.16),
      _WeightedScore(stressScore, 0.14),
      _WeightedScore(conditionScore, 0.10),
      _WeightedScore(goalFocusScore, 0.04),
    ]).clamp(0, 100).toInt();

    final riskLevel = _riskLevel(totalScore, conditionScore, stressScore);

    final metrics = <DashboardMetricStatus>[
      DashboardMetricStatus(
        code: 'bmi',
        title: 'BMI',
        value: bmi <= 0 ? '--' : bmi.toStringAsFixed(1),
        label: bmiLabel,
        message: _bmiMessage(bmi),
        progress: bmiScore / 100,
      ),
      DashboardMetricStatus(
        code: 'water',
        title: 'Nước uống',
        value: hydrationLiter == null
            ? '--'
            : '${hydrationLiter.toStringAsFixed(1)}L',
        label: _hydrationLabel(hydrationScore),
        message: _hydrationMessage(hydrationScore),
        progress: hydrationScore / 100,
      ),
      DashboardMetricStatus(
        code: 'sleep',
        title: 'Giấc ngủ',
        value: _sleepValue(input.sleepQuality, input.latestSleepHours),
        label: _scoreLabel(sleepScore),
        message: _sleepMessage(sleepScore),
        progress: sleepScore / 100,
      ),
      DashboardMetricStatus(
        code: 'activity',
        title: 'Vận động',
        value: _activityValue(input.activityLevel, input.latestStepsCount),
        label: _scoreLabel(activityScore),
        message: _activityMessage(activityScore),
        progress: activityScore / 100,
      ),
      DashboardMetricStatus(
        code: 'stress',
        title: 'Căng thẳng',
        value: input.latestStressLevel == null
            ? '--'
            : '${input.latestStressLevel}/10',
        label: _scoreLabel(stressScore),
        message: _stressMessage(stressScore),
        progress: stressScore / 100,
      ),
      DashboardMetricStatus(
        code: 'condition',
        title: 'Tình trạng',
        value: input.conditions.isEmpty ? 'Ổn' : '${input.conditions.length}',
        label: _scoreLabel(conditionScore),
        message: _conditionMessage(input.conditions),
        progress: conditionScore / 100,
      ),
    ];

    return DashboardHealthStatus(
      bmi: bmi,
      bmiLabel: bmiLabel,
      bmiMessage: _bmiMessage(bmi),
      healthScore: totalScore,
      riskLevel: riskLevel,
      riskLabel: _riskLabel(riskLevel),
      summaryMessage: _summaryMessage(totalScore, riskLevel, input.goals),
      metrics: metrics,
      insights: _buildInsights(
        bmi: bmi,
        hydrationScore: hydrationScore,
        sleepScore: sleepScore,
        activityScore: activityScore,
        stressScore: stressScore,
        conditionScore: conditionScore,
        conditions: input.conditions,
        goals: input.goals,
      ),
    );
  }

  static double _resolveBmi(DashboardHealthInput input) {
    final existingBmi = input.bmi?.toDouble();
    if (existingBmi != null && existingBmi > 0) return _round1(existingBmi);

    final heightCm = input.heightCm?.toDouble();
    final weightKg = input.weightKg?.toDouble();
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return 0;
    }

    final heightMeter = heightCm / 100;
    return _round1(weightKg / (heightMeter * heightMeter));
  }

  static double _round1(double value) => (value * 10).roundToDouble() / 10;

  static String _bmiLabel(double bmi) {
    if (bmi <= 0) return 'Chưa đủ dữ liệu';
    if (bmi < 18.5) return 'Hơi gầy';
    if (bmi < 23) return 'Cân bằng';
    if (bmi < 25) return 'Cần chú ý';
    if (bmi < 30) return 'Thừa cân';
    return 'Nguy cơ cao';
  }

  static String _bmiMessage(double bmi) {
    if (bmi <= 0) {
      return 'Cần chiều cao và cân nặng để Nami tính BMI chính xác hơn.';
    }
    if (bmi < 18.5) {
      return 'Bạn có thể cần tăng năng lượng và protein một cách nhẹ nhàng.';
    }
    if (bmi < 23) {
      return 'BMI đang ở vùng khá cân bằng, hãy duy trì nhịp sinh hoạt hiện tại.';
    }
    if (bmi < 25) {
      return 'BMI bắt đầu nhích lên, mình nên chú ý bữa tối và vận động nhẹ.';
    }
    if (bmi < 30) {
      return 'Nên ưu tiên kiểm soát calo, đường ngọt và vận động đều hơn.';
    }
    return 'Nên theo dõi sát hơn và cân nhắc tham khảo chuyên gia y tế khi cần.';
  }

  static int _bmiScore(double bmi) {
    if (bmi <= 0) return 55;
    if (bmi >= 18.5 && bmi < 23) return 96;
    if (bmi >= 17.5 && bmi < 18.5) return 78;
    if (bmi >= 23 && bmi < 25) return 78;
    if (bmi >= 25 && bmi < 30) return 62;
    if (bmi >= 30) return 42;
    return 58;
  }

  static double? _resolveWaterLiter(String? waterPerDay, int? waterMl) {
    if (waterMl != null && waterMl > 0) return _round1(waterMl / 1000);
    final raw = _normalize(waterPerDay);
    if (raw.isEmpty) return null;
    if (raw.contains('duoi 1') || raw.contains('duoi mot')) return 0.8;
    if (raw.contains('tren 2') || raw.contains('hon 2')) return 2.2;
    if (raw.contains('1') && raw.contains('1.5')) return 1.25;
    if (raw.contains('1.5') && raw.contains('2')) return 1.75;

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static int _hydrationScore(double? liter) {
    if (liter == null) return 55;
    if (liter >= 1.8 && liter <= 2.7) return 95;
    if (liter >= 1.5) return 82;
    if (liter >= 1.0) return 66;
    return 45;
  }

  static String _hydrationLabel(int score) => _scoreLabel(score);

  static String _hydrationMessage(int score) {
    if (score >= 85) {
      return 'Lượng nước khá ổn, cứ giữ nhịp nhẹ nhàng như vậy nhé.';
    }
    if (score >= 70) {
      return 'Chỉ cần thêm một chút nước vào buổi sáng hoặc chiều.';
    }
    if (score >= 55) {
      return 'Nami nghĩ bạn nên đặt nhắc uống nước để dễ duy trì hơn.';
    }
    return 'Lượng nước hơi thấp, hôm nay mình tăng dần từng cốc nhỏ nhé.';
  }

  static int _sleepScore(String? quality, num? hours) {
    if (hours != null && hours > 0) {
      final value = hours.toDouble();
      if (value >= 7 && value <= 8.5) return 95;
      if (value >= 6 && value < 7) return 76;
      if (value > 8.5 && value <= 9.5) return 82;
      if (value >= 5) return 58;
      return 38;
    }

    final raw = _normalize(quality);
    if (raw.isEmpty) return 55;
    if (raw.contains('ngu ngon')) return 92;
    if (raw.contains('khong sau')) return 62;
    if (raw.contains('kho ngu')) return 55;
    if (raw.contains('thuc khuya')) return 52;
    if (raw.contains('met')) return 50;
    return 60;
  }

  static String _sleepValue(String? quality, num? hours) {
    if (hours != null && hours > 0) {
      return '${hours.toDouble().toStringAsFixed(1)}h';
    }
    if (quality == null || quality.trim().isEmpty) return '--';
    return quality.trim();
  }

  static String _sleepMessage(int score) {
    if (score >= 85) return 'Giấc ngủ đang hỗ trợ tốt cho phục hồi cơ thể.';
    if (score >= 70) {
      return 'Giấc ngủ tương đối ổn, có thể cải thiện thêm giờ đi ngủ.';
    }
    if (score >= 55) return 'Nên giảm màn hình và caffeine trước khi ngủ.';
    return 'Giấc ngủ đang là điểm cần chăm sóc trước tiên.';
  }

  static int _activityScore(String? level, int? steps) {
    if (steps != null && steps > 0) {
      if (steps >= 8000) return 94;
      if (steps >= 6000) return 82;
      if (steps >= 4000) return 68;
      if (steps >= 2500) return 55;
      return 38;
    }

    final raw = _normalize(level);
    if (raw.isEmpty) return 55;
    if (raw.contains('tap thuong xuyen')) return 92;
    if (raw.contains('1') && raw.contains('3')) return 78;
    if (raw.contains('di bo')) return 68;
    if (raw.contains('lao dong nang')) return 80;
    if (raw.contains('it van dong')) return 45;
    return 60;
  }

  static String _activityValue(String? level, int? steps) {
    if (steps != null && steps > 0) return '$steps bước';
    if (level == null || level.trim().isEmpty) return '--';
    return level.trim();
  }

  static String _activityMessage(int score) {
    if (score >= 85) {
      return 'Mức vận động rất tốt, hãy giữ nhịp an toàn và đều đặn.';
    }
    if (score >= 70) {
      return 'Bạn đang có nền vận động ổn, thêm đi bộ nhẹ là rất tốt.';
    }
    if (score >= 55) return 'Nên thêm 10–15 phút vận động nhẹ trong ngày.';
    return 'Cơ thể cần được đánh thức bằng những bước đi nhỏ trước.';
  }

  static int _stressScore(
    int? stressLevel,
    List<String> conditions,
    String? concern,
  ) {
    if (stressLevel != null) {
      return (100 - (stressLevel.clamp(0, 10).toInt() * 8))
          .clamp(20, 100)
          .toInt();
    }

    final haystack = _normalize([...conditions, concern ?? ''].join(' '));
    var score = 82;
    if (haystack.contains('stress') || haystack.contains('cang thang')) {
      score -= 24;
    }
    if (haystack.contains('mat ngu') || haystack.contains('kho ngu')) {
      score -= 12;
    }
    if (haystack.contains('met moi')) score -= 12;
    return score.clamp(35, 92).toInt();
  }

  static String _stressMessage(int score) {
    if (score >= 85) {
      return 'Tín hiệu căng thẳng chưa đáng lo, hãy tiếp tục nghỉ ngơi đều.';
    }
    if (score >= 70) {
      return 'Cơ thể có thể đang hơi mệt, nên có khoảng nghỉ ngắn trong ngày.';
    }
    if (score >= 55) {
      return 'Nami gợi ý thở chậm 3 phút và ngủ sớm hơn một chút.';
    }
    return 'Căng thẳng đang ảnh hưởng rõ, mình nên ưu tiên phục hồi trước.';
  }

  static int _conditionScore(List<String> conditions) {
    if (conditions.isEmpty) return 92;

    const highRiskKeywords = <String>[
      'duong huyet',
      'huyet ap',
      'mo mau',
      'gan nhiem mo',
      'beo phi',
    ];
    const mediumRiskKeywords = <String>[
      'da day',
      'tao bon',
      'day hoi',
      'xuong khop',
      'mat ngu',
      'met moi',
    ];

    var penalty = 0;
    for (final condition in conditions) {
      final raw = _normalize(condition);
      if (highRiskKeywords.any(raw.contains)) {
        penalty += 12;
      } else if (mediumRiskKeywords.any(raw.contains)) {
        penalty += 8;
      } else {
        penalty += 5;
      }
    }

    return math.max(35, 92 - penalty).toInt();
  }

  static String _conditionMessage(List<String> conditions) {
    if (conditions.isEmpty) {
      return 'Chưa ghi nhận vấn đề đặc biệt trong hồ sơ sức khỏe.';
    }
    return 'Có ${conditions.length} điểm cần theo dõi, Nami sẽ ưu tiên gợi ý nhẹ nhàng hơn.';
  }

  static int _goalFocusScore(List<String> goals) {
    if (goals.isEmpty) return 60;
    if (goals.length <= 3) return 90;
    if (goals.length <= 5) return 78;
    return 68;
  }

  static DashboardRiskLevel _riskLevel(
    int totalScore,
    int conditionScore,
    int stressScore,
  ) {
    if (totalScore >= 85 && conditionScore >= 75 && stressScore >= 70) {
      return DashboardRiskLevel.excellent;
    }
    if (totalScore >= 70) return DashboardRiskLevel.good;
    if (totalScore >= 55) return DashboardRiskLevel.attention;
    return DashboardRiskLevel.risk;
  }

  static String _riskLabel(DashboardRiskLevel riskLevel) {
    switch (riskLevel) {
      case DashboardRiskLevel.excellent:
        return 'Rất ổn';
      case DashboardRiskLevel.good:
        return 'Khá tốt';
      case DashboardRiskLevel.attention:
        return 'Cần chú ý';
      case DashboardRiskLevel.risk:
        return 'Nên theo dõi';
    }
  }

  static String _summaryMessage(
    int score,
    DashboardRiskLevel riskLevel,
    List<String> goals,
  ) {
    final goalText = goals.isEmpty
        ? 'sức khỏe tổng thể'
        : goals.take(2).join(', ');

    switch (riskLevel) {
      case DashboardRiskLevel.excellent:
        return 'Hôm nay các chỉ số của bạn khá đẹp. Mình tiếp tục duy trì để tiến gần hơn tới $goalText nhé.';
      case DashboardRiskLevel.good:
        return 'Nền tảng sức khỏe đang ổn. Chỉ cần cải thiện một vài thói quen nhỏ là điểm sẽ tốt hơn.';
      case DashboardRiskLevel.attention:
        return 'Cơ thể đang gửi vài tín hiệu cần được quan tâm. Mình ưu tiên nước, ngủ và vận động nhẹ trước nhé.';
      case DashboardRiskLevel.risk:
        return 'Nami thấy bạn nên chăm sóc bản thân chậm lại một chút và theo dõi các chỉ số đều hơn.';
    }
  }

  static List<DashboardHealthInsight> _buildInsights({
    required double bmi,
    required int hydrationScore,
    required int sleepScore,
    required int activityScore,
    required int stressScore,
    required int conditionScore,
    required List<String> conditions,
    required List<String> goals,
  }) {
    final insights = <DashboardHealthInsight>[];

    if (bmi > 0 && bmi >= 23) {
      insights.add(
        const DashboardHealthInsight(
          title: 'BMI cần được theo dõi nhẹ nhàng',
          message:
              'Ưu tiên bữa tối gọn hơn, thêm rau xanh và đi bộ sau ăn 10 phút.',
          priority: 1,
        ),
      );
    } else if (bmi > 0 && bmi < 18.5) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Cơ thể cần thêm năng lượng tốt',
          message:
              'Bạn có thể tăng bữa phụ bằng sữa, trứng, đậu hoặc thực phẩm giàu protein.',
          priority: 1,
        ),
      );
    }

    if (hydrationScore < 70) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Uống nước từng chút sẽ dễ hơn',
          message:
              'Hãy bắt đầu bằng một cốc nước sau khi thức dậy và một cốc giữa buổi chiều.',
          priority: 2,
        ),
      );
    }

    if (sleepScore < 70) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Giấc ngủ nên là ưu tiên hôm nay',
          message:
              'Giảm màn hình trước ngủ 30 phút và thử đi ngủ sớm hơn 15 phút.',
          priority: 2,
        ),
      );
    }

    if (activityScore < 65) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Vận động không cần quá nặng',
          message:
              'Chỉ cần 10–15 phút đi bộ nhẹ cũng giúp cơ thể tỉnh hơn và tiêu hóa tốt hơn.',
          priority: 3,
        ),
      );
    }

    if (stressScore < 65) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Bạn có vẻ đang hơi căng',
          message:
              'Tạm dừng một chút, hít thở chậm và để cơ thể được nghỉ vài phút nhé.',
          priority: 2,
        ),
      );
    }

    if (conditionScore < 70 && conditions.isNotEmpty) {
      insights.add(
        DashboardHealthInsight(
          title: 'Có ${conditions.length} vấn đề cần theo dõi',
          message:
              'Nami sẽ ưu tiên các gợi ý an toàn, dễ áp dụng và tránh thay đổi quá đột ngột.',
          priority: 1,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const DashboardHealthInsight(
          title: 'Hôm nay bạn đang làm khá tốt',
          message:
              'Hãy duy trì nước uống, giấc ngủ và một chút vận động nhẹ để cơ thể ổn định hơn.',
          priority: 4,
        ),
      );
    }

    insights.sort((a, b) => a.priority.compareTo(b.priority));
    return insights.take(4).toList(growable: false);
  }

  static String _scoreLabel(int score) {
    if (score >= 85) return 'Rất tốt';
    if (score >= 70) return 'Ổn';
    if (score >= 55) return 'Cần cải thiện';
    return 'Cần chú ý';
  }

  static int _weightedAverage(List<_WeightedScore> scores) {
    final totalWeight = scores.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    if (totalWeight <= 0) return 0;

    final total = scores.fold<double>(
      0,
      (sum, item) => sum + item.score.clamp(0, 100).toDouble() * item.weight,
    );
    return (total / totalWeight).round();
  }

  static String _normalize(String? value) {
    if (value == null) return '';
    return value
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'd')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _WeightedScore {
  const _WeightedScore(this.score, this.weight);

  final int score;
  final double weight;
}

import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';

class DashboardMoodCodes {
  static const ok = 'ok';
  static const tired = 'tired';
  static const stressed = 'stressed';
  static const uncomfortable = 'uncomfortable';

  static const all = [ok, tired, stressed, uncomfortable];
}

class DashboardScoreBreakdownItem {
  final String title;
  final String message;
  final double progress;

  const DashboardScoreBreakdownItem({
    required this.title,
    required this.message,
    required this.progress,
  });
}

class DashboardCompanionService {
  const DashboardCompanionService._();

  static bool isSlowDayMood(String? mood) {
    final normalized = mood?.trim().toLowerCase();
    return normalized == DashboardMoodCodes.tired ||
        normalized == DashboardMoodCodes.stressed ||
        normalized == DashboardMoodCodes.uncomfortable;
  }

  static String moodLabel(String mood) {
    switch (mood) {
      case DashboardMoodCodes.ok:
        return 'Ổn áp';
      case DashboardMoodCodes.tired:
        return 'Hơi mệt';
      case DashboardMoodCodes.stressed:
        return 'Căng thẳng';
      case DashboardMoodCodes.uncomfortable:
        return 'Đau/khó chịu';
      default:
        return 'Chưa rõ';
    }
  }

  static String moodResponse(String mood) {
    switch (mood) {
      case DashboardMoodCodes.ok:
        return 'Nami mừng vì hôm nay bạn thấy ổn. Mình giữ nhịp nhẹ nhàng nhé.';
      case DashboardMoodCodes.tired:
        return 'Vậy hôm nay mình đi chậm lại một chút cũng được nha.';
      case DashboardMoodCodes.stressed:
        return 'Nami ở đây rồi, mình thở chậm lại một chút nhé.';
      case DashboardMoodCodes.uncomfortable:
        return 'Bạn nhớ lắng nghe cơ thể nhé. Nếu khó chịu kéo dài, mình nên tìm người có chuyên môn hỗ trợ.';
      default:
        return 'Nami vẫn ở đây để cùng bạn đi nhẹ từng chút một.';
    }
  }

  static DashboardTimelineItem? selectNextAction({
    required List<DashboardTimelineItem> timeline,
    String? mood,
  }) {
    final candidates = timeline
        .where((item) => item.canComplete && !item.isCompleted)
        .toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      if (isSlowDayMood(mood)) {
        final priorityCompare = _slowDayPriority(
          a.category,
        ).compareTo(_slowDayPriority(b.category));
        if (priorityCompare != 0) return priorityCompare;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return candidates.first;
  }

  static String nextActionMessage(DashboardTimelineItem? item) {
    if (item == null) {
      return 'Hôm nay bạn đang rất ổn rồi, Nami vẫn ở đây khi bạn cần.';
    }

    switch (_normalize(item.category)) {
      case 'water':
        return 'Mình bắt đầu bằng vài ngụm nước nhỏ thôi nhé.';
      case 'mind':
      case 'stress':
      case 'sleep':
        return 'Mình làm thật chậm và nhẹ, chỉ cần có mặt với cơ thể một chút.';
      case 'body':
      case 'exercise':
        return 'Nếu cơ thể sẵn sàng, mình vận động thật nhẹ thôi nha.';
      case 'meal':
        return 'Mình chăm bữa này gọn gàng trước, không cần vội.';
      default:
        return 'Chỉ một việc nhỏ thôi, Nami sẽ đi cùng bạn.';
    }
  }

  static String buildDailySummary({
    required DashboardDailyMetrics metrics,
    required String sleepQuality,
    required String activityLevel,
  }) {
    if (!metrics.hasAnyData) {
      return 'Nami chưa có đủ tín hiệu hôm nay, mình bắt đầu bằng một việc nhỏ thôi nhé.';
    }

    final taskRate = metrics.taskCompletionRate;
    final mealRate = metrics.mealCompletionRate;
    final hasLowWater = metrics.waterMl > 0 && metrics.waterMl < 1500;
    final hasLowTaskProgress = metrics.totalTasks > 0 && taskRate < 0.35;
    final hasGoodTaskProgress = metrics.totalTasks > 0 && taskRate >= 0.75;
    final hasGoodMealProgress = metrics.totalMeals > 0 && mealRate >= 0.75;

    if (metrics.dailyScore >= 85 &&
        (hasGoodTaskProgress || hasGoodMealProgress)) {
      return 'Bạn chăm mình rất ổn hôm nay, Nami thấy nhịp này rất đẹp.';
    }

    if (hasLowTaskProgress ||
        (metrics.dailyScore > 0 && metrics.dailyScore < 45)) {
      return 'Có vẻ hôm nay hơi nặng nhịp, mình chỉ cần hoàn thành một việc nhỏ trước thôi nha.';
    }

    if (hasLowWater) {
      return 'Hôm nay bạn đang đi đúng hướng, Nami chỉ muốn nhắc nhẹ thêm về nước.';
    }

    if (_normalize(sleepQuality).contains('mệt') ||
        _normalize(activityLevel).contains('ít vận động')) {
      return 'Cơ thể có thể cần mình chậm lại một chút, Nami sẽ nhắc thật nhẹ thôi.';
    }

    return 'Hôm nay bạn đang đi đúng hướng, mình cứ giữ nhịp nhẹ nhàng nhé.';
  }

  static List<DashboardScoreBreakdownItem> buildScoreBreakdown({
    required DashboardDailyMetrics metrics,
    required String sleepQuality,
    required String activityLevel,
  }) {
    return [
      DashboardScoreBreakdownItem(
        title: 'Nhiệm vụ',
        message: metrics.totalTasks == 0
            ? 'Chưa có việc nhỏ nào để Nami ghi nhận hôm nay.'
            : '${metrics.completedTasks}/${metrics.totalTasks} việc nhỏ đã hoàn thành.',
        progress: metrics.totalTasks == 0 ? 0 : metrics.taskCompletionRate,
      ),
      DashboardScoreBreakdownItem(
        title: 'Nước',
        message: metrics.waterMl == 0
            ? 'Chưa có ghi nhận nước hôm nay.'
            : 'Bạn đã ghi nhận ${metrics.waterMl} ml nước.',
        progress: metrics.waterMl == 0
            ? 0
            : (metrics.waterMl / 2000).clamp(0, 1).toDouble(),
      ),
      DashboardScoreBreakdownItem(
        title: 'Bữa ăn',
        message: _mealBreakdownMessage(metrics),
        progress: _mealProgress(metrics),
      ),
      DashboardScoreBreakdownItem(
        title: 'Vận động',
        message: metrics.stepsCount > 0
            ? 'Hôm nay bạn đã có ${metrics.stepsCount} bước chân.'
            : activityLevel.trim().isEmpty
            ? 'Chưa có tín hiệu vận động hôm nay.'
            : 'Nami đang dựa vào nhịp vận động bạn đã chia sẻ.',
        progress: metrics.stepsCount > 0
            ? (metrics.stepsCount / 8000).clamp(0, 1).toDouble()
            : activityLevel.trim().isEmpty
            ? 0
            : 0.5,
      ),
      DashboardScoreBreakdownItem(
        title: 'Giấc ngủ',
        message: metrics.sleepHours > 0
            ? 'Bạn đã ghi nhận ${metrics.sleepHours.toStringAsFixed(1)} giờ ngủ.'
            : sleepQuality.trim().isEmpty
            ? 'Chưa có tín hiệu giấc ngủ hôm nay.'
            : 'Nami đang dựa vào chất lượng giấc ngủ bạn đã chia sẻ.',
        progress: metrics.sleepHours > 0
            ? (metrics.sleepHours / 8).clamp(0, 1).toDouble()
            : sleepQuality.trim().isEmpty
            ? 0
            : 0.5,
      ),
    ];
  }

  static String _mealBreakdownMessage(DashboardDailyMetrics metrics) {
    if (metrics.totalMeals > 0) {
      return '${metrics.completedMeals}/${metrics.totalMeals} bữa trong kế hoạch đã hoàn thành.';
    }
    if (metrics.caloriesLogged > 0) {
      return 'Bạn đã ghi nhận ${metrics.caloriesLogged} kcal hôm nay.';
    }
    if (metrics.caloriesPlanned > 0) {
      return 'Hôm nay có ${metrics.caloriesPlanned} kcal dự kiến.';
    }
    return 'Chưa có tín hiệu bữa ăn hôm nay.';
  }

  static double _mealProgress(DashboardDailyMetrics metrics) {
    if (metrics.totalMeals > 0) return metrics.mealCompletionRate;
    if (metrics.caloriesLogged > 0 && metrics.caloriesPlanned > 0) {
      return (metrics.caloriesLogged / metrics.caloriesPlanned)
          .clamp(0, 1)
          .toDouble();
    }
    return 0;
  }

  static int _slowDayPriority(String category) {
    switch (_normalize(category)) {
      case 'water':
        return 0;
      case 'mind':
      case 'stress':
      case 'sleep':
        return 1;
      case 'body':
      case 'exercise':
        return 2;
      case 'meal':
        return 3;
      default:
        return 4;
    }
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

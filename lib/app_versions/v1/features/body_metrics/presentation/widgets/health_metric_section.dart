import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_metric.dart';

class HealthMetricSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<BodyMetricsHealthMetric> metrics;

  const HealthMetricSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.sm),
          for (final metric in metrics)
            _MetricTile(metric: metric, fallbackIcon: icon),
        ],
      ),
    );
  }
}

class BodyMetricsMetricPresentation {
  const BodyMetricsMetricPresentation._();

  static String title(BodyMetricsHealthMetric metric) => switch (metric.id) {
        BodyMetricsMetricIds.bmi => 'Cân nặng so với chiều cao',
        BodyMetricsMetricIds.bmiCategory => 'Khoảng cân nặng hiện tại',
        BodyMetricsMetricIds.restingEnergy =>
          'Năng lượng cơ thể cần khi nghỉ',
        BodyMetricsMetricIds.eer => 'Nhu cầu năng lượng ước tính',
        BodyMetricsMetricIds.tdee => 'Năng lượng cơ thể cần mỗi ngày',
        BodyMetricsMetricIds.plannedCalories => 'Năng lượng từ thực đơn',
        BodyMetricsMetricIds.energyGap =>
          'Chênh lệch ăn uống và nhu cầu',
        BodyMetricsMetricIds.energyAlignment =>
          'Ăn uống so với nhu cầu năng lượng',
        BodyMetricsMetricIds.proteinPerDay => 'Lượng đạm trung bình',
        BodyMetricsMetricIds.proteinPerKg =>
          'Lượng đạm so với cân nặng',
        BodyMetricsMetricIds.proteinEnergyPercent =>
          'Tỷ lệ năng lượng từ đạm',
        BodyMetricsMetricIds.carbEnergyPercent =>
          'Tỷ lệ năng lượng từ tinh bột',
        BodyMetricsMetricIds.fatEnergyPercent =>
          'Tỷ lệ năng lượng từ chất béo',
        BodyMetricsMetricIds.macroBalanceCount =>
          'Mức cân đối đạm - tinh bột - chất béo',
        BodyMetricsMetricIds.fiberCoverage => 'Chất xơ trong khẩu phần',
        BodyMetricsMetricIds.sodiumRatio =>
          'Natri so với mốc tham khảo',
        BodyMetricsMetricIds.waterAverage7d =>
          'Lượng nước trung bình 7 ngày',
        BodyMetricsMetricIds.waterAverage30d =>
          'Lượng nước trung bình 30 ngày',
        BodyMetricsMetricIds.sleepAverage7d =>
          'Thời gian ngủ trung bình 7 ngày',
        BodyMetricsMetricIds.sleepAverage30d =>
          'Thời gian ngủ trung bình 30 ngày',
        BodyMetricsMetricIds.sleepAdequacy => 'Số đêm bạn ngủ đủ',
        BodyMetricsMetricIds.stressAverage =>
          'Mức căng thẳng gần đây',
        BodyMetricsMetricIds.stepsAverage => 'Mức đi bộ trung bình',
        BodyMetricsMetricIds.latestHeartRate => 'Nhịp tim gần nhất',
        BodyMetricsMetricIds.averageHeartRate30d =>
          'Nhịp tim trung bình đã ghi nhận',
        BodyMetricsMetricIds.latestSpO2 => 'SpO₂ gần nhất',
        BodyMetricsMetricIds.averageSpO230d =>
          'SpO₂ trung bình đã ghi nhận',
        BodyMetricsMetricIds.bloodPressureObservation =>
          'Huyết áp đã ghi nhận',
        BodyMetricsMetricIds.bloodSugarObservation =>
          'Đường huyết đã ghi nhận',
        BodyMetricsMetricIds.mealCompletion =>
          'Mức duy trì thực đơn',
        BodyMetricsMetricIds.scheduleCompletion =>
          'Mức duy trì lịch chăm sóc',
        BodyMetricsMetricIds.dataCompletenessFreshness =>
          'Mức đầy đủ của dữ liệu',
        _ => metric.title,
      };

  static String value(BodyMetricsHealthMetric metric) {
    final number = metric.value;
    final text = metric.textValue?.trim();
    if (number != null) {
      final formatted = number.abs() >= 100
          ? number.round().toString()
          : number.toStringAsFixed(1);
      if (metric.id == BodyMetricsMetricIds.bmi) {
        return 'BMI $formatted';
      }
      final numeric = '$formatted ${metric.unit}'.trim();
      return text == null || text.isEmpty ? numeric : '$numeric • $text';
    }
    return text == null || text.isEmpty ? 'Chưa đủ dữ liệu' : text;
  }

  static String interpretation(BodyMetricsHealthMetric metric) {
    final value = metric.value;
    if (!metric.hasValue) return 'Chưa đủ dữ liệu';

    return switch (metric.id) {
      BodyMetricsMetricIds.bmi => _bmiInterpretation(value),
      BodyMetricsMetricIds.sleepAverage7d ||
      BodyMetricsMetricIds.sleepAverage30d => _sleepInterpretation(value),
      BodyMetricsMetricIds.sleepAdequacy => _sleepAdequacy(value),
      BodyMetricsMetricIds.macroBalanceCount => _macroInterpretation(value),
      BodyMetricsMetricIds.fiberCoverage => _fiberInterpretation(value),
      BodyMetricsMetricIds.sodiumRatio => _sodiumInterpretation(value),
      BodyMetricsMetricIds.latestHeartRate ||
      BodyMetricsMetricIds.averageHeartRate30d ||
      BodyMetricsMetricIds.latestSpO2 ||
      BodyMetricsMetricIds.averageSpO230d ||
      BodyMetricsMetricIds.bloodPressureObservation ||
      BodyMetricsMetricIds.bloodSugarObservation =>
        'Số đo theo dõi • không dùng riêng để chẩn đoán',
      BodyMetricsMetricIds.waterAverage7d ||
      BodyMetricsMetricIds.waterAverage30d => 'Lượng nước bạn đã ghi nhận',
      BodyMetricsMetricIds.stepsAverage => 'Mức vận động bạn đã ghi nhận',
      BodyMetricsMetricIds.dataCompletenessFreshness =>
        'Đây là độ đầy đủ dữ liệu, không phải điểm sức khỏe',
      BodyMetricsMetricIds.mealCompletion ||
      BodyMetricsMetricIds.scheduleCompletion =>
        'Đây là mức duy trì kế hoạch, không phải điểm sức khỏe',
      _ => metric.textValue?.trim().isNotEmpty == true
          ? metric.textValue!.trim()
          : 'Đang theo dõi',
    };
  }

  static Color color(BodyMetricsHealthMetric metric) {
    if (!metric.hasValue) return AppColors.textSecondary;
    final value = metric.value;
    return switch (metric.id) {
      BodyMetricsMetricIds.bmi =>
        value != null && value >= 18.5 && value < 25
            ? AppColors.success
            : AppColors.warning,
      BodyMetricsMetricIds.sleepAverage7d ||
      BodyMetricsMetricIds.sleepAverage30d =>
        value != null && value >= 7 && value <= 9
            ? AppColors.success
            : AppColors.warning,
      BodyMetricsMetricIds.sleepAdequacy =>
        value != null && value >= 70 ? AppColors.success : AppColors.warning,
      BodyMetricsMetricIds.macroBalanceCount =>
        value != null && value >= 3 ? AppColors.success : AppColors.warning,
      BodyMetricsMetricIds.fiberCoverage =>
        value != null && value >= 100 ? AppColors.success : AppColors.warning,
      BodyMetricsMetricIds.sodiumRatio =>
        value != null && value <= 100 ? AppColors.success : AppColors.warning,
      _ => AppColors.info,
    };
  }

  static IconData icon(BodyMetricsHealthMetric metric) => switch (metric.category) {
        BodyMetricsMetricCategory.body => Icons.monitor_weight_rounded,
        BodyMetricsMetricCategory.energy => Icons.local_fire_department_rounded,
        BodyMetricsMetricCategory.nutrition => Icons.restaurant_rounded,
        BodyMetricsMetricCategory.hydration => Icons.water_drop_rounded,
        BodyMetricsMetricCategory.recovery => Icons.bedtime_rounded,
        BodyMetricsMetricCategory.activity => Icons.directions_walk_rounded,
        BodyMetricsMetricCategory.observation => Icons.monitor_heart_outlined,
        BodyMetricsMetricCategory.adherence => Icons.fact_check_outlined,
        BodyMetricsMetricCategory.dataQuality => Icons.data_usage_rounded,
      };

  static String _bmiInterpretation(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value >= 18.5 && value < 25) return 'Trong khoảng tham khảo ✓';
    if (value < 18.5) return 'Thấp hơn khoảng tham khảo';
    if (value < 30) return 'Cao hơn khoảng tham khảo';
    return 'Cao đáng kể so với khoảng tham khảo';
  }

  static String _sleepInterpretation(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value >= 7 && value <= 9) return 'Trong khoảng tham khảo ✓';
    return 'Nên chú ý thời lượng ngủ';
  }

  static String _sleepAdequacy(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value >= 70) return 'Khá đều ✓';
    if (value >= 50) return 'Chưa thật đều';
    return 'Cần cải thiện';
  }

  static String _macroInterpretation(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value >= 3) return 'Cân đối ✓';
    if (value >= 2) return 'Khá cân đối';
    return 'Cần cân đối hơn';
  }

  static String _fiberInterpretation(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value >= 100) return 'Đạt mốc tham khảo ✓';
    if (value >= 70) return 'Gần đạt mốc tham khảo';
    return 'Cần bổ sung thêm';
  }

  static String _sodiumInterpretation(double? value) {
    if (value == null) return 'Chưa đủ dữ liệu';
    if (value <= 100) return 'Trong mốc tham khảo ✓';
    return 'Cao hơn mốc tham khảo';
  }
}

class _MetricTile extends StatelessWidget {
  final BodyMetricsHealthMetric metric;
  final IconData fallbackIcon;

  const _MetricTile({
    required this.metric,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final available = metric.hasValue;
    final color = BodyMetricsMetricPresentation.color(metric);
    final friendlyTitle = BodyMetricsMetricPresentation.title(metric);
    final interpretation = BodyMetricsMetricPresentation.interpretation(metric);
    final displayValue = BodyMetricsMetricPresentation.value(metric);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: Icon(
          available ? BodyMetricsMetricPresentation.icon(metric) : fallbackIcon,
          color: available ? color : context.semanticColors.textSecondary,
        ),
        title: Text(
          friendlyTitle,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        subtitle: Text(
          '$interpretation\n$displayValue',
          style: AppTextStyles.bodySmall.copyWith(
            color: available
                ? context.semanticColors.textSecondary
                : AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.semanticColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cách tính & chi tiết chuyên môn',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tên kỹ thuật: ${metric.title}\n'
                    'Mã chỉ số: ${metric.id}\n'
                    'Giá trị: ${_rawDisplay(metric)}\n'
                    'Nguồn: ${_source(metric.source)}\n'
                    'Cửa sổ dữ liệu: ${metric.dataWindow}\n'
                    'Công thức: ${metric.formulaVersion}\n'
                    'Tham chiếu: ${metric.reference}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.semanticColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rawDisplay(BodyMetricsHealthMetric metric) {
    final number = metric.value;
    final text = metric.textValue;
    if (number != null) {
      final formatted = number.abs() >= 100
          ? number.round().toString()
          : number.toStringAsFixed(1);
      return text == null || text.isEmpty
          ? '$formatted ${metric.unit}'.trim()
          : '$formatted ${metric.unit} • $text'.trim();
    }
    return text ?? 'Chưa đủ dữ liệu';
  }

  String _source(BodyMetricsMetricSource source) => switch (source) {
        BodyMetricsMetricSource.measured => 'Dữ liệu đo/ghi nhận',
        BodyMetricsMetricSource.calculated => 'Chỉ số tính toán',
        BodyMetricsMetricSource.aggregate => 'Tổng hợp dữ liệu',
        BodyMetricsMetricSource.observation => 'Quan sát, không chẩn đoán',
      };
}

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
          for (final metric in metrics) _MetricTile(metric: metric, icon: icon),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final BodyMetricsHealthMetric metric;
  final IconData icon;

  const _MetricTile({required this.metric, required this.icon});

  @override
  Widget build(BuildContext context) {
    final available = metric.hasValue;
    final display = available ? _display(metric) : 'Chưa đủ dữ liệu';
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: Icon(icon, color: available ? AppColors.primary : context.semanticColors.textSecondary),
        title: Text(metric.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: AppTypography.bold)),
        subtitle: Text(display, style: AppTextStyles.bodySmall.copyWith(color: available ? AppColors.textPrimary : AppColors.textSecondary)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nguồn: ${_source(metric.source)}\n'
              'Cửa sổ dữ liệu: ${metric.dataWindow}\n'
              'Công thức: ${metric.formulaVersion}\n'
              'Tham chiếu: ${metric.reference}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _display(BodyMetricsHealthMetric metric) {
    final text = metric.textValue;
    final number = metric.value;
    if (number != null) {
      final formatted = number.abs() >= 100 ? number.round().toString() : number.toStringAsFixed(1);
      return text == null || text.isEmpty
          ? '$formatted ${metric.unit}'.trim()
          : '$formatted ${metric.unit} • $text'.trim();
    }
    return text ?? 'Chưa đủ dữ liệu';
  }

  String _source(BodyMetricsMetricSource source) => switch (source) {
        BodyMetricsMetricSource.measured => 'Dữ liệu đo/ghi nhận',
        BodyMetricsMetricSource.calculated => 'Chỉ số tính toán deterministic',
        BodyMetricsMetricSource.aggregate => 'Tổng hợp dữ liệu',
        BodyMetricsMetricSource.observation => 'Quan sát, không chẩn đoán',
      };
}

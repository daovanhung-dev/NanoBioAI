import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_assessment.dart';
import '../../domain/entities/body_metrics_health_metric.dart';
import '../../domain/entities/body_metrics_health_report.dart';
import 'health_metric_section.dart';

class BodyMetricsHealthHighlights extends StatelessWidget {
  final BodyMetricsHealthAssessment assessment;

  const BodyMetricsHealthHighlights({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (assessment.strengths.isNotEmpty)
          _HighlightCard(
            title: 'Bạn đang làm tốt',
            subtitle: 'Những điểm nên tiếp tục duy trì.',
            icon: Icons.check_circle_outline_rounded,
            color: context.semanticColors.success,
            surface: context.semanticColors.successSoft,
            items: assessment.strengths,
          ),
        if (assessment.strengths.isNotEmpty &&
            assessment.attentionItems.isNotEmpty)
          const SizedBox(height: AppSpacing.sectionSpacing),
        if (assessment.attentionItems.isNotEmpty)
          _HighlightCard(
            title: 'Bạn nên chú ý',
            subtitle: 'Ưu tiên từng thay đổi nhỏ, không cần làm tất cả cùng lúc.',
            icon: Icons.flag_outlined,
            color: context.semanticColors.warning,
            surface: context.semanticColors.warningSoft,
            items: assessment.attentionItems,
          ),
        if (assessment.strengths.isEmpty &&
            assessment.attentionItems.isEmpty)
          const NamiCareInfoTile(
            icon: Icons.insights_rounded,
            color: AppColors.info,
            title: 'Chưa có đủ điểm nổi bật để tổng hợp',
            subtitle:
                'Nabi sẽ hiển thị điểm tốt và điều cần chú ý khi dữ liệu theo dõi đầy đủ hơn.',
          ),
      ],
    );
  }
}

class BodyMetricsKeyMetricsCard extends StatelessWidget {
  final BodyMetricsHealthReport report;
  final BodyMetricsHealthAssessment assessment;

  const BodyMetricsKeyMetricsCard({
    super.key,
    required this.report,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = assessment.keyMetricIds
        .map(report.metric)
        .whereType<BodyMetricsHealthMetric>()
        .toList(growable: false);
    if (metrics.isEmpty) return const SizedBox.shrink();

    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Chỉ số quan trọng',
            subtitle: 'Những thông tin dễ hiểu và hữu ích nhất ở thời điểm này.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < metrics.length; index++) ...[
            NamiCareInfoTile(
              icon: BodyMetricsMetricPresentation.icon(metrics[index]),
              color: BodyMetricsMetricPresentation.color(metrics[index]),
              title: BodyMetricsMetricPresentation.title(metrics[index]),
              subtitle:
                  '${BodyMetricsMetricPresentation.interpretation(metrics[index])}\n${BodyMetricsMetricPresentation.value(metrics[index])}',
            ),
            if (index != metrics.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color surface;
  final List<String> items;

  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surface,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < items.length; index++) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      items[index],
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

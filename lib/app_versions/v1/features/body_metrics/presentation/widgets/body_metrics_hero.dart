import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_assessment.dart';
import '../../domain/entities/body_metrics_health_report.dart';

class BodyMetricsHero extends StatelessWidget {
  final BodyMetricsHealthReport report;
  final BodyMetricsHealthAssessment assessment;

  const BodyMetricsHero({
    super.key,
    required this.report,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final visual = _visual(context, assessment.level);
    final percent = (report.dataCompleteness * 100).round();

    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SỨC KHỎE HIỆN TẠI',
            style: AppTextStyles.overline.copyWith(
              color: visual.color,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: visual.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, color: visual.color, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessment.headline,
                      style: AppTextStyles.heading1.copyWith(
                        color: visual.color,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      assessment.summary,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.semanticColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(
                icon: Icons.check_circle_outline_rounded,
                label: '${assessment.strengthCount} điểm đang ổn',
                color: colors.success,
                surface: colors.successSoft,
              ),
              _Pill(
                icon: Icons.priority_high_rounded,
                label: '${assessment.attentionCount} điều cần chú ý',
                color: assessment.attentionCount == 0
                    ? colors.info
                    : colors.warning,
                surface: assessment.attentionCount == 0
                    ? colors.infoSoft
                    : colors.warningSoft,
              ),
              _Pill(
                icon: Icons.data_usage_rounded,
                label: '${assessment.dataConfidenceLabel} • $percent%',
                color: colors.info,
                surface: colors.infoSoft,
              ),
            ],
          ),
          if (!assessment.hasEnoughData) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Hãy ưu tiên cập nhật cân nặng, giấc ngủ, vận động hoặc dữ liệu ăn uống gần đây để Nabi nhận định đáng tin cậy hơn.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _HealthVisual _visual(
    BuildContext context,
    BodyMetricsOverallHealthLevel level,
  ) {
    final colors = context.semanticColors;
    return switch (level) {
      BodyMetricsOverallHealthLevel.good => _HealthVisual(
          color: colors.success,
          surface: colors.successSoft,
          icon: Icons.verified_rounded,
        ),
      BodyMetricsOverallHealthLevel.fair => _HealthVisual(
          color: colors.info,
          surface: colors.infoSoft,
          icon: Icons.sentiment_satisfied_alt_rounded,
        ),
      BodyMetricsOverallHealthLevel.attention => _HealthVisual(
          color: colors.warning,
          surface: colors.warningSoft,
          icon: Icons.priority_high_rounded,
        ),
      BodyMetricsOverallHealthLevel.concern => _HealthVisual(
          color: colors.error,
          surface: colors.errorSoft,
          icon: Icons.health_and_safety_rounded,
        ),
      BodyMetricsOverallHealthLevel.insufficientData => _HealthVisual(
          color: colors.info,
          surface: colors.infoSoft,
          icon: Icons.data_usage_rounded,
        ),
    };
  }

}

class _HealthVisual {
  final Color color;
  final Color surface;
  final IconData icon;

  const _HealthVisual({
    required this.color,
    required this.surface,
    required this.icon,
  });
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

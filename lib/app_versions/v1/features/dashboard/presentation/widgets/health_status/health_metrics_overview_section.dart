import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_health_status.dart';

class HealthMetricsOverviewSection extends StatelessWidget {
  const HealthMetricsOverviewSection({super.key, required this.status});

  final DashboardHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final riskColor = _riskColor(status.riskLevel, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nabi vừa tính lại sức khỏe của bạn',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.tiny),
                        Text(
                          status.summaryMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ScoreBadge(
                    score: status.healthScore,
                    label: status.riskLabel,
                    color: riskColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _MetricGrid(metrics: status.metrics),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightList(insights: status.insights),
      ],
    );
  }

  Color _riskColor(DashboardRiskLevel riskLevel, AppSemanticColors colors) {
    switch (riskLevel) {
      case DashboardRiskLevel.excellent:
        return colors.success;
      case DashboardRiskLevel.good:
        return colors.primary;
      case DashboardRiskLevel.attention:
        return colors.warning;
      case DashboardRiskLevel.risk:
        return colors.error;
    }
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<DashboardMetricStatus> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final itemWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricTile(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final DashboardMetricStatus metric;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(metric.progress, context.semanticColors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.inputBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_iconFor(metric.code), color: color, size: 19),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.semanticColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                metric.value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.semanticColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: metric.progress.clamp(0.0, 1.0).toDouble(),
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            metric.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String code) {
    switch (code) {
      case 'bmi':
        return Icons.monitor_weight_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'activity':
        return Icons.directions_walk_rounded;
      case 'stress':
        return Icons.self_improvement_rounded;
      case 'condition':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.auto_graph_rounded;
    }
  }

  Color _colorFor(double progress, AppSemanticColors colors) {
    if (progress >= 0.85) return colors.success;
    if (progress >= 0.70) return colors.primary;
    if (progress >= 0.55) return colors.warning;
    return colors.error;
  }
}

class _InsightList extends StatelessWidget {
  const _InsightList({required this.insights});

  final List<DashboardHealthInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: insights
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: context.semanticColors.primarySoft.withValues(
                    alpha: 0.72,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: context.semanticColors.primary.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.semanticColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.tips_and_updates_rounded,
                        color: context.semanticColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.semanticColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            insight.message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.semanticColors.textSecondary,
                                  height: 1.42,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

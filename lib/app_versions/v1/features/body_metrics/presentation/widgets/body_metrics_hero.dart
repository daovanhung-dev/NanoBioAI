import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_health_report.dart';
import '../../domain/entities/body_metrics_health_snapshot.dart';

class BodyMetricsHero extends StatelessWidget {
  final BodyMetricsHealthSnapshot snapshot;
  final BodyMetricsHealthReport report;
  final int aiStageCount;

  const BodyMetricsHero({
    super.key,
    required this.snapshot,
    required this.report,
    required this.aiStageCount,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (report.dataCompleteness * 100).round();
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SỨC KHỎE CỦA BẠN',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.primary,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nabi đã tổng hợp dữ liệu cơ thể, dinh dưỡng, giấc ngủ, vận động và lịch chăm sóc gần đây.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(icon: Icons.fact_check_outlined, label: 'Dữ liệu đầy đủ $percent%'),
              _Pill(icon: Icons.timeline_rounded, label: '${snapshot.tracking.length} ngày tracking'),
              _Pill(icon: Icons.auto_awesome_rounded, label: '$aiStageCount góc nhìn Nabi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pastelSky,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.info),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

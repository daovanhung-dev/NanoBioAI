import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_ai_models.dart';

class HealthActionPlanCard extends StatelessWidget {
  final BodyMetricsAiSynthesis synthesis;

  const HealthActionPlanCard({super.key, required this.synthesis});

  @override
  Widget build(BuildContext context) {
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NamiCareSectionTitle(
            title: 'Kế hoạch cải thiện',
            subtitle: 'Action có lý do, mức ưu tiên, độ khó và metric theo dõi; không phải chỉ định điều trị.',
          ),
          const SizedBox(height: AppSpacing.md),
          _Actions(title: 'Hôm nay', icon: Icons.today_rounded, items: synthesis.actionsToday),
          _Actions(title: '7 ngày tới', icon: Icons.date_range_rounded, items: synthesis.actions7Days),
          _Actions(title: '30 ngày tới', icon: Icons.calendar_month_rounded, items: synthesis.actions30Days),
          if (synthesis.questionsForClinician.isNotEmpty)
            NamiCareInfoTile(
              icon: Icons.medical_information_outlined,
              color: AppColors.info,
              title: 'Có thể hỏi chuyên gia y tế',
              subtitle: synthesis.questionsForClinician.map((item) => '• $item').join('\n'),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<BodyMetricsAiAction> items;

  const _Actions({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: AppTypography.bold)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            NamiCareInfoTile(
              icon: icon,
              color: AppColors.primary,
              title: item.action,
              subtitle:
                  '${item.reason}\nƯu tiên: ${item.priority} • Độ khó: ${item.difficulty}\nTheo dõi: ${item.trackingMetricIds.isEmpty ? 'metric liên quan' : item.trackingMetricIds.join(', ')}',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

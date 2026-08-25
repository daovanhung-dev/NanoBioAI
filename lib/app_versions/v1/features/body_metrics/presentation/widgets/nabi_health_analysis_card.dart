import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/body_metrics_ai_models.dart';

class NabiHealthAnalysisCard extends StatelessWidget {
  final bool analyzing;
  final int currentStage;
  final int totalStages;
  final String? stageId;
  final BodyMetricsAiBundle? bundle;
  final VoidCallback onAnalyze;

  const NabiHealthAnalysisCard({
    super.key,
    required this.analyzing,
    required this.currentStage,
    required this.totalStages,
    required this.stageId,
    required this.bundle,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final synthesis = bundle?.synthesis;
    return NamiCareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NamiCareSectionTitle(
            title: synthesis == null
                ? 'Muốn Nabi phân tích sâu hơn?'
                : 'Nabi phân tích thêm',
            subtitle: synthesis == null
                ? 'Nhận định cơ bản phía trên đã có sẵn. Bạn chỉ cần dùng AI khi muốn hiểu sâu hơn và nhận thêm gợi ý cá nhân hóa.'
                : 'Đây là phần diễn giải bổ sung từ AI; kết luận sức khỏe cơ bản vẫn dựa trên các quy tắc và dữ liệu đã tính sẵn.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (analyzing) ...[
            LinearProgressIndicator(
              value: totalStages <= 0 ? null : currentStage / totalStages,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nabi đang xem kỹ dữ liệu... $currentStage / $totalStages${stageId == null ? '' : ' • $stageId'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ] else if (synthesis == null) ...[
            const NamiCareInfoTile(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.primary,
              title: 'Phân tích sâu theo dữ liệu của bạn',
              subtitle:
                  'Nabi sẽ giải thích các điểm nổi bật và gợi ý việc nên ưu tiên. AI không thay thế đánh giá y khoa.',
            ),
          ] else ...[
            NamiCareInfoTile(
              icon: Icons.summarize_rounded,
              color: AppColors.info,
              title: 'Tổng quan từ Nabi',
              subtitle: synthesis.overview,
            ),
            if (synthesis.strengths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _ListTile(
                title: 'Điểm Nabi thấy bạn đang làm tốt',
                icon: Icons.check_circle_outline_rounded,
                items: synthesis.strengths,
              ),
            ],
            if (synthesis.priorities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _ListTile(
                title: 'Điều Nabi gợi ý ưu tiên',
                icon: Icons.flag_outlined,
                items: synthesis.priorities,
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: analyzing ? null : onAnalyze,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              analyzing
                  ? 'Nabi đang phân tích...'
                  : bundle == null
                      ? 'Phân tích sâu với Nabi'
                      : 'Phân tích lại',
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _ListTile({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NamiCareInfoTile(
      icon: icon,
      color: AppColors.primary,
      title: title,
      subtitle: items.map((item) => '• $item').join('\n'),
    );
  }
}

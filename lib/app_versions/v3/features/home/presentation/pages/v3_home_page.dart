import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class V3HomePage extends StatelessWidget {
  const V3HomePage({super.key});

  static const _plannedFeatures = <_PlannedFeature>[
    _PlannedFeature(
      icon: Icons.auto_awesome_rounded,
      title: 'Trợ lý AI mở rộng',
      description: 'Hỗ trợ sâu hơn theo mục tiêu và lịch sinh hoạt.',
      tone: _PlannedFeatureTone.primary,
    ),
    _PlannedFeature(
      icon: Icons.timeline_rounded,
      title: 'Theo dõi nâng cao',
      description: 'Nhìn xu hướng sức khỏe theo cách trực quan và dễ hiểu.',
      tone: _PlannedFeatureTone.secondary,
    ),
    _PlannedFeature(
      icon: Icons.family_restroom_rounded,
      title: 'FamilyPlus',
      description: 'Chăm sóc nhiều thành viên với quyền riêng tư tách biệt.',
      tone: _PlannedFeatureTone.tertiary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return MedicalScrollPage(
      eyebrow: 'PLUS & FAMILYPLUS',
      title: 'Chăm sóc sâu hơn, vẫn thật dễ dùng',
      subtitle: 'Tính năng nâng cao mở theo quyền thành viên.',
      icon: Icons.workspace_premium_rounded,
      gradient: AppGradients.premium,
      children: [
        MedicalSectionHeader(
          title: 'Trải nghiệm đang được hoàn thiện',
          subtitle: 'Hiểu nhanh hơn, ít áp lực hơn.',
          icon: Icons.view_quilt_rounded,
          color: colors.tertiary,
        ),
        for (final feature in _plannedFeatures)
          MedicalSurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalIconBadge(
                  icon: feature.icon,
                  color: feature.tone.resolve(colors),
                  backgroundColor: feature.tone
                      .resolve(colors)
                      .withValues(alpha: .10),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feature.title, style: AppTextStyles.heading5),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        feature.description,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                MedicalStatusPill(
                  label: 'Sắp có',
                  foregroundColor: colors.tertiary,
                  backgroundColor: colors.tertiarySoft,
                ),
              ],
            ),
          ),
        MedicalEmptyState(
          icon: Icons.verified_user_rounded,
          color: colors.secondary,
          title: 'Quyền lợi luôn được kiểm tra an toàn',
          message: 'Nabi chỉ mở tính năng sau khi xác nhận quyền.',
        ),
      ],
    );
  }
}

class _PlannedFeature {
  final IconData icon;
  final String title;
  final String description;
  final _PlannedFeatureTone tone;

  const _PlannedFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });
}

enum _PlannedFeatureTone {
  primary,
  secondary,
  tertiary;

  Color resolve(AppSemanticColors colors) => switch (this) {
    _PlannedFeatureTone.primary => colors.primary,
    _PlannedFeatureTone.secondary => colors.secondary,
    _PlannedFeatureTone.tertiary => colors.tertiary,
  };
}

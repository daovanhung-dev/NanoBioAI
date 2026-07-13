import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class V3HomePage extends StatelessWidget {
  const V3HomePage({super.key});

  static const _plannedFeatures = <_PlannedFeature>[
    _PlannedFeature(
      icon: Icons.auto_awesome_rounded,
      title: 'Trợ lý AI mở rộng',
      description: 'Hỗ trợ sâu hơn theo mục tiêu và lịch sinh hoạt.',
      color: AppColors.primary,
    ),
    _PlannedFeature(
      icon: Icons.timeline_rounded,
      title: 'Theo dõi nâng cao',
      description: 'Nhìn xu hướng sức khỏe theo cách trực quan và dễ hiểu.',
      color: AppColors.secondary,
    ),
    _PlannedFeature(
      icon: Icons.family_restroom_rounded,
      title: 'FamilyPlus',
      description: 'Chăm sóc nhiều thành viên với quyền riêng tư tách biệt.',
      color: AppColors.tertiary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'PLUS & FAMILYPLUS',
      title: 'Chăm sóc sâu hơn, vẫn thật dễ dùng',
      subtitle:
          'Các trải nghiệm nâng cao chỉ được mở khi quyền thành viên được xác nhận an toàn và minh bạch.',
      icon: Icons.workspace_premium_rounded,
      gradient: AppGradients.premium,
      children: [
        const MedicalSectionHeader(
          title: 'Trải nghiệm đang được hoàn thiện',
          subtitle:
              'Mỗi chức năng được thiết kế để giúp bạn hiểu thông tin nhanh hơn, không tạo thêm áp lực.',
          icon: Icons.view_quilt_rounded,
          color: AppColors.tertiary,
        ),
        for (final feature in _plannedFeatures)
          MedicalSurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalIconBadge(
                  icon: feature.icon,
                  color: feature.color,
                  backgroundColor: feature.color.withValues(alpha: .10),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feature.title, style: AppTextStyles.heading5),
                      const SizedBox(height: AppSpacing.xs),
                      Text(feature.description, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const MedicalStatusPill(
                  label: 'Sắp có',
                  foregroundColor: AppColors.tertiary,
                  backgroundColor: AppColors.tertiarySoft,
                ),
              ],
            ),
          ),
        const MedicalEmptyState(
          icon: Icons.verified_user_rounded,
          color: AppColors.secondary,
          title: 'Quyền lợi luôn được kiểm tra an toàn',
          message:
              'Nabi không tự mở tính năng trả phí hoặc suy đoán gói thành viên. Trạng thái sẽ được xác nhận trước khi sử dụng.',
        ),
      ],
    );
  }
}

class _PlannedFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _PlannedFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

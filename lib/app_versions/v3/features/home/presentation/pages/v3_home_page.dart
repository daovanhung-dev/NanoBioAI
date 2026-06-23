import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class V3HomePage extends StatelessWidget {
  const V3HomePage({super.key});

  static const _plannedFeatures = <String>[
    'AI không giới hạn cho Plus',
    'Lộ trình riêng theo mục tiêu',
    'Theo dõi sức khỏe nâng cao',
    'Quản lý thành viên gia đình',
    'Lịch trình cho từng thành viên',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BioAI V3',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Khu vực Plus và FamilyPlus đang được chuẩn bị. '
                'Nabisẽ chỉ mở các tính năng này khi quyền thành viên '
                'được xác nhận an toàn.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecoration.card(
                  radius: AppRadius.xl,
                  shadows: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Các phần sẽ triển khai',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final feature in _plannedFeatures)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '• $feature',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class V2HomePage extends StatelessWidget {
  const V2HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'TÀI KHOẢN NANOBIO',
      title: 'Chăm sóc cá nhân, liền mạch hơn',
      subtitle: 'Đồng bộ an toàn để tiếp tục trên nhiều thiết bị.',
      icon: Icons.health_and_safety_rounded,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(V2RoutePaths.healthScore),
          icon: const Icon(Icons.monitor_heart_rounded),
          label: const Text('Xem điểm sức khỏe'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primaryDark,
          ),
        ),
      ],
      children: [
        const MedicalSectionHeader(
          title: 'Tổng quan tài khoản',
          subtitle: 'Các chức năng được sắp theo nhu cầu.',
          icon: Icons.dashboard_customize_rounded,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 660
                ? (width - AppSpacing.md) / 2
                : width;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: MedicalMetricCard(
                    label: 'Điểm sức khỏe',
                    value: 'Theo dõi mỗi ngày',
                    helper: 'Tổng hợp từ những thói quen bạn đã hoàn thành.',
                    icon: Icons.favorite_rounded,
                    color: AppColors.error,
                    onTap: () => context.go(V2RoutePaths.healthScore),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: MedicalMetricCard(
                    label: 'Điểm chăm sóc',
                    value: 'Đổi ưu đãi',
                    helper:
                        'Nhận điểm từ nhiệm vụ đúng giờ và đổi voucher phù hợp.',
                    icon: Icons.redeem_rounded,
                    color: AppColors.tertiary,
                    onTap: () => context.go(V2RoutePaths.wellnessRewards),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const MedicalMetricCard(
                    label: 'Đồng bộ cá nhân',
                    value: 'An toàn và chủ động',
                    helper:
                        'Nabi chỉ dùng dữ liệu để phục vụ trải nghiệm của bạn.',
                    icon: Icons.cloud_done_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            );
          },
        ),
        MedicalSurfaceCard(
          gradient: AppGradients.primarySoft,
          borderColor: AppColors.primary.withValues(alpha: .16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicalIconBadge(
                icon: Icons.shield_outlined,
                color: AppColors.primaryDark,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riêng tư là mặc định', style: AppTextStyles.heading5),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bạn luôn có thể xem, cập nhật hoặc xóa thông tin tài khoản trong phần Cài đặt.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

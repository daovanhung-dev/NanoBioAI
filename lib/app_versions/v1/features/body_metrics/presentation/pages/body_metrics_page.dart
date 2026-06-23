import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class BodyMetricsPage extends StatelessWidget {
  const BodyMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Cơ thể của bạn',
      subtitle: 'Mình chỉ cần ghi lại thật nhẹ nhàng, không cần áp lực.',
      badge: 'Lắng nghe cơ thể',
      icon: Icons.monitor_weight_rounded,
      gradient: AppGradients.primary,
      children: [
        const NamiCareSectionTitle(
          title: 'Những chỉ số nhỏ',
          subtitle:
              'Khi bạn sẵn sàng, Nabisẽ cùng bạn nhìn lại thay đổi của cơ thể theo cách dịu dàng nhất.',
        ),
        const SizedBox(height: AppSpacing.md),
        const NamiCareSurfaceCard(
          child: Column(
            children: [
              _MetricRow(
                icon: Icons.monitor_weight_rounded,
                color: AppColors.primary,
                title: 'Cân nặng',
                value: 'Chưa ghi nhận',
              ),
              SizedBox(height: AppSpacing.sm),
              _MetricRow(
                icon: Icons.height_rounded,
                color: AppColors.secondary,
                title: 'Chiều cao',
                value: 'Chưa ghi nhận',
              ),
              SizedBox(height: AppSpacing.sm),
              _MetricRow(
                icon: Icons.favorite_rounded,
                color: AppColors.success,
                title: 'BMI',
                value: 'Chưa sẵn sàng',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const NamiCareEmptyState(
          icon: Icons.edit_note_rounded,
          color: AppColors.primary,
          title: 'Ghi lại chỉ số hôm nay',
          message:
              'Nabichưa có đủ thông tin để nhìn lại cùng bạn. Khi sẵn sàng, mình ghi một vài chỉ số nhỏ nhé.',
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return NamiCareInfoTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: 'Nabisẽ dùng thông tin này để hiểu cơ thể bạn hơn.',
      trailing: value,
    );
  }
}

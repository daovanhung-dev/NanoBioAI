import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class WeeklySummaryPage extends StatelessWidget {
  const WeeklySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _SummaryItem(
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
        title: 'Nhiệm vụ đã chăm',
        subtitle: 'Những việc nhỏ bạn đã dành cho bản thân trong tuần.',
      ),
      _SummaryItem(
        icon: Icons.bedtime_rounded,
        color: AppColors.primary,
        title: 'Giấc ngủ',
        subtitle: 'Nhịp nghỉ ngơi sẽ được Nabinhìn lại thật nhẹ.',
      ),
      _SummaryItem(
        icon: Icons.restaurant_rounded,
        color: AppColors.secondary,
        title: 'Bữa ăn',
        subtitle: 'Những bữa ăn được gom lại để bạn dễ quan sát hơn.',
      ),
      _SummaryItem(
        icon: Icons.psychology_rounded,
        color: AppColors.info,
        title: 'Cảm xúc',
        subtitle: 'Một góc nhỏ để nhận ra điều đang ảnh hưởng đến bạn.',
      ),
      _SummaryItem(
        icon: Icons.auto_graph_rounded,
        color: AppColors.warning,
        title: 'Điểm chăm sóc',
        subtitle: 'Nabisẽ tổng hợp khi đã có đủ thông tin trong tuần.',
      ),
    ];

    return NamiCareScaffold(
      title: 'Tổng kết tuần',
      subtitle: 'Nabicùng bạn nhìn lại những điều nhỏ đã làm được.',
      badge: 'Nhìn lại dịu dàng',
      icon: Icons.insights_rounded,
      gradient: AppGradients.premium,
      children: [
        const NamiCareEmptyState(
          icon: Icons.calendar_month_rounded,
          color: AppColors.secondary,
          title: 'Tuần này mình bắt đầu từ hôm nay nhé',
          message:
              'Tuần này Nabichưa có đủ thông tin để tổng kết thật trọn vẹn. Mình cứ bắt đầu từ hôm nay nhé.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const NamiCareSectionTitle(
          title: 'Nabisẽ nhìn lại những điều này',
          subtitle:
              'Khi các góc chăm sóc có thêm ghi nhận, tổng kết tuần sẽ đầy đủ và gần với bạn hơn.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: item.icon,
              color: item.color,
              title: item.title,
              subtitle: item.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

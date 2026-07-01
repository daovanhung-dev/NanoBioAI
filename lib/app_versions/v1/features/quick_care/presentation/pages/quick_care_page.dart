import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class QuickCarePage extends StatelessWidget {
  const QuickCarePage({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickCareAction(
        icon: Icons.air_rounded,
        color: AppColors.secondary,
        title: 'Thở chậm 1 phút',
        subtitle: 'Hít vào thật nhẹ, thở ra chậm hơn một chút.',
        duration: '1 phút',
      ),
      _QuickCareAction(
        icon: Icons.water_drop_rounded,
        color: AppColors.info,
        title: 'Uống một cốc nước',
        subtitle: 'Một ngụm nhỏ cũng giúp cơ thể được đánh thức.',
        duration: '1 phút',
      ),
      _QuickCareAction(
        icon: Icons.accessibility_new_rounded,
        color: AppColors.success,
        title: 'Giãn vai',
        subtitle: 'Thả lỏng cổ và vai sau một lúc tập trung.',
        duration: '2 phút',
      ),
      _QuickCareAction(
        icon: Icons.visibility_rounded,
        color: AppColors.primary,
        title: 'Nghỉ mắt 30 giây',
        subtitle: 'Nhìn ra xa một chút để mắt được nghỉ.',
        duration: '30 giây',
      ),
      _QuickCareAction(
        icon: Icons.edit_note_rounded,
        color: AppColors.warning,
        title: 'Viết ra điều đang bận tâm',
        subtitle: 'Đặt suy nghĩ xuống giấy để lòng nhẹ hơn.',
        duration: '3 phút',
      ),
    ];

    return NamiCareScaffold(
      title: 'Chăm mình 5 phút',
      subtitle: 'Một khoảng nghỉ nhỏ cũng có thể làm bạn dễ chịu hơn.',
      badge: 'Dễ chịu ngay lúc này',
      icon: Icons.spa_rounded,
      gradient: AppGradients.meditation,
      children: [
        const NamiCareEmptyState(
          icon: Icons.favorite_rounded,
          color: AppColors.secondary,
          title: 'Mình dành vài phút cho bản thân nhé',
          message:
              'Bạn có thể chọn bất kỳ gợi ý nào bên dưới. Không cần làm nhiều, chỉ cần một khoảng nghỉ nhỏ là đủ.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const NamiCareSectionTitle(
          title: 'Gợi ý nhanh từ Nabi',
          subtitle: 'Những việc rất nhỏ, nhẹ nhàng và dễ bắt đầu ngay lúc này.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: action.icon,
              color: action.color,
              title: action.title,
              subtitle: action.subtitle,
              trailing: action.duration,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCareAction {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String duration;

  const _QuickCareAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.duration,
  });
}

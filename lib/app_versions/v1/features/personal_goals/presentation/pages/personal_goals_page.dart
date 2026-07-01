import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class PersonalGoalsPage extends StatefulWidget {
  const PersonalGoalsPage({super.key});

  @override
  State<PersonalGoalsPage> createState() => _PersonalGoalsPageState();
}

class _PersonalGoalsPageState extends State<PersonalGoalsPage> {
  int? _selectedIndex;

  static const _goals = [
    _GoalOption(
      icon: Icons.water_drop_rounded,
      color: AppColors.info,
      title: 'Uống đủ nước',
      subtitle: 'Nabi nhắc bạn chăm cơ thể bằng từng ngụm nhỏ.',
    ),
    _GoalOption(
      icon: Icons.bedtime_rounded,
      color: AppColors.primary,
      title: 'Ngủ sớm hơn',
      subtitle: 'Mình cho cơ thể thêm thời gian nghỉ ngơi nhé.',
    ),
    _GoalOption(
      icon: Icons.breakfast_dining_rounded,
      color: AppColors.warning,
      title: 'Ăn sáng đều hơn',
      subtitle: 'Một bữa sáng nhẹ cũng giúp ngày mới dễ chịu hơn.',
    ),
    _GoalOption(
      icon: Icons.directions_walk_rounded,
      color: AppColors.success,
      title: 'Vận động 10 phút',
      subtitle: 'Chỉ một chút chuyển động cũng đáng được ghi nhận.',
    ),
    _GoalOption(
      icon: Icons.spa_rounded,
      color: AppColors.secondary,
      title: 'Giảm căng thẳng',
      subtitle: 'Nabi cùng bạn tạo vài khoảng thở nhẹ trong ngày.',
    ),
    _GoalOption(
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.error,
      title: 'Ăn nhẹ nhàng hơn',
      subtitle: 'Mình lắng nghe cơ thể thay vì ép bản thân quá nhiều.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Mục tiêu của mình',
      subtitle: 'Chọn một điều nhỏ thôi, Nabi sẽ đi cùng bạn mỗi ngày.',
      badge: 'Một bước nhỏ',
      icon: Icons.flag_rounded,
      gradient: AppGradients.success,
      children: [
        const NamiCareSectionTitle(
          title: 'Hôm nay mình muốn chăm điều gì?',
          subtitle:
              'Bạn chỉ cần chọn một mục tiêu vừa sức. Nabi sẽ nhắc thật nhẹ, không tạo áp lực.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_goals.length, (index) {
          final goal = _goals[index];
          final selected = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: goal.icon,
              color: goal.color,
              title: goal.title,
              subtitle: goal.subtitle,
              selected: selected,
              trailing: selected ? 'Đang chọn' : null,
              onTap: () => setState(() => _selectedIndex = index),
            ),
          );
        }),
        if (_selectedIndex != null) ...[
          const SizedBox(height: AppSpacing.md),
          NamiCareEmptyState(
            icon: Icons.favorite_rounded,
            color: _goals[_selectedIndex!].color,
            title: 'Nabi đã đặt mục tiêu này vào góc nhỏ hôm nay của bạn',
            message:
                'Mình không cần làm thật nhiều ngay lập tức. Chỉ cần quay lại từng chút, Nabi sẽ cùng bạn giữ nhịp.',
          ),
        ],
      ],
    );
  }
}

class _GoalOption {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _GoalOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

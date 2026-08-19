import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

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
      subtitle: 'Xem trước một điều nhỏ, vừa sức cho hôm nay.',
      badge: 'Bản xem trước',
      icon: Icons.flag_rounded,
      gradient: AppGradients.success,
      children: [
        const NamiCareSectionTitle(
          title: 'Hôm nay mình muốn thử điều gì?',
          subtitle:
              'Lựa chọn ở đây chỉ giúp bạn xem trước; hiện chưa được lưu thành mục tiêu hoặc nhắc nhở.',
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
              onTap: () {
                AppFeedbackService.instance.emit(AppFeedbackType.selection);
                setState(() => _selectedIndex = index);
              },
            ),
          );
        }),
        AppStateSwitcher(
          alignment: Alignment.topCenter,
          child: _selectedIndex == null
              ? const SizedBox.shrink(key: ValueKey('goal-unselected'))
              : Padding(
                  key: ValueKey('goal-selected-$_selectedIndex'),
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: NamiCareEmptyState(
                    icon: Icons.favorite_rounded,
                    color: _goals[_selectedIndex!].color,
                    title: 'Bạn đang xem trước mục tiêu này',
                    message:
                        'Lựa chọn chỉ được giữ trong lúc trang này đang mở. Khi tính năng lưu mục tiêu sẵn sàng, Nabi sẽ nói rõ trước khi lưu hoặc tạo nhắc nhở.',
                  ),
                ),
        ),
      ],
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

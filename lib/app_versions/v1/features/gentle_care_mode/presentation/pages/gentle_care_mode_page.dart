import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';

class GentleCareModePage extends StatefulWidget {
  const GentleCareModePage({super.key});

  @override
  State<GentleCareModePage> createState() => _GentleCareModePageState();
}

class _GentleCareModePageState extends State<GentleCareModePage> {
  int? _selectedIndex;

  static const _moods = [
    _CareMood(
      icon: Icons.battery_2_bar_rounded,
      color: AppColors.warning,
      title: 'Mệt một chút',
      subtitle: 'Mình giảm nhịp lại, làm từng việc thật nhỏ thôi.',
    ),
    _CareMood(
      icon: Icons.psychology_rounded,
      color: AppColors.info,
      title: 'Căng thẳng',
      subtitle: 'Nabisẽ gợi ý vài khoảng thở để bạn dịu lại.',
    ),
    _CareMood(
      icon: Icons.nights_stay_rounded,
      color: AppColors.primary,
      title: 'Buồn ngủ',
      subtitle: 'Cơ thể đang cần nghỉ, mình lắng nghe một chút nhé.',
    ),
    _CareMood(
      icon: Icons.self_improvement_rounded,
      color: AppColors.secondary,
      title: 'Không muốn làm nhiều',
      subtitle: 'Không sao đâu, hôm nay ít hơn một chút cũng được.',
    ),
    _CareMood(
      icon: Icons.spa_rounded,
      color: AppColors.success,
      title: 'Cần nghỉ ngơi',
      subtitle: 'Mình cho bản thân một khoảng dừng thật tử tế nhé.',
    ),
  ];

  static const _suggestions = [
    _CareSuggestion(
      icon: Icons.water_drop_rounded,
      color: AppColors.info,
      title: 'Uống vài ngụm nước',
      subtitle:
          'Một ngụm nhỏ cũng là cách báo với cơ thể rằng bạn vẫn đang chăm mình.',
    ),
    _CareSuggestion(
      icon: Icons.visibility_rounded,
      color: AppColors.primary,
      title: 'Nghỉ mắt 2 phút',
      subtitle: 'Nhìn ra xa và thả lỏng vai một chút nhé.',
    ),
    _CareSuggestion(
      icon: Icons.restaurant_rounded,
      color: AppColors.warning,
      title: 'Ăn nhẹ nếu thấy đói',
      subtitle: 'Chọn một món dễ chịu, không cần ép mình quá nhiều.',
    ),
    _CareSuggestion(
      icon: Icons.air_rounded,
      color: AppColors.secondary,
      title: 'Hít thở chậm',
      subtitle: 'Hít vào thật nhẹ, thở ra dài hơn một chút.',
    ),
    _CareSuggestion(
      icon: Icons.bedtime_rounded,
      color: AppColors.primary,
      title: 'Ngủ sớm hơn tối nay',
      subtitle: 'Cho cơ thể thêm thời gian hồi lại sau một ngày dài.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Hôm nay mình mệt',
      subtitle:
          'Không sao đâu, hôm nay mình chăm bản thân nhẹ hơn một chút nhé.',
      badge: 'Chế độ dịu nhẹ',
      icon: Icons.nights_stay_rounded,
      gradient: AppGradients.warning,
      children: [
        const NamiCareSectionTitle(
          title: 'Bạn đang thấy thế nào?',
          subtitle:
              'Chọn cảm giác gần nhất lúc này. Nabisẽ giúp bạn hạ mục tiêu xuống thật vừa sức.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_moods.length, (index) {
          final mood = _moods[index];
          final selected = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: mood.icon,
              color: mood.color,
              title: mood.title,
              subtitle: mood.subtitle,
              selected: selected,
              trailing: selected ? 'Nabihiểu rồi' : null,
              onTap: () => setState(() => _selectedIndex = index),
            ),
          );
        }),
        if (_selectedIndex != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const NamiCareEmptyState(
            icon: Icons.favorite_rounded,
            color: AppColors.warning,
            title: 'Hôm nay không cần hoàn hảo đâu',
            message:
                'Mình chỉ cần không bỏ quên bản thân là được. Nabisẽ gợi ý vài việc thật nhẹ để bạn dễ chịu hơn.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const NamiCareSectionTitle(title: 'Gợi ý nhẹ cho bạn'),
          const SizedBox(height: AppSpacing.md),
          ..._suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: NamiCareInfoTile(
                icon: suggestion.icon,
                color: suggestion.color,
                title: suggestion.title,
                subtitle: suggestion.subtitle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CareMood {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _CareMood({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _CareSuggestion {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _CareSuggestion({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

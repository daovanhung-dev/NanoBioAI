import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/core/theme/app_spacing.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

class ExercisePlanningPreferencesEditor extends StatelessWidget {
  final ExercisePlanningPreferences value;
  final ValueChanged<ExercisePlanningPreferences> onChanged;
  final bool enabled;

  const ExercisePlanningPreferencesEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'Dụng cụ và giới hạn vận động',
          style: AppTextStyles.heading5,
        ),
        subtitle: const Text(
          'Giúp Nabi bỏ qua bài chưa phù hợp với điều kiện của bạn',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Dụng cụ bạn có thể dùng',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry
                  in ExercisePlanningPreferences.equipmentOptions.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: value.availableEquipment.contains(entry.key),
                  onSelected: enabled
                      ? (selected) => onChanged(
                          value.copyWith(
                            availableEquipment: _toggle(
                              value.availableEquipment,
                              entry.key,
                              selected,
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vùng đang đau hoặc hạn chế vận động',
              style: AppTextStyles.labelLarge,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry
                  in ExercisePlanningPreferences.limitationOptions.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: value.mobilityLimitations.contains(entry.key),
                  onSelected: enabled
                      ? (selected) => onChanged(
                          value.copyWith(
                            mobilityLimitations: _toggle(
                              value.mobilityLimitations,
                              entry.key,
                              selected,
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Các lựa chọn này chỉ lưu trên thiết bị. Nabi dùng chúng để lọc bài và không gửi chúng tới dịch vụ tra cứu thực phẩm.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<String> _toggle(List<String> source, String value, bool selected) {
    final values = {...source};
    if (selected) {
      values.add(value);
    } else {
      values.remove(value);
    }
    return values.toList(growable: false)..sort();
  }
}

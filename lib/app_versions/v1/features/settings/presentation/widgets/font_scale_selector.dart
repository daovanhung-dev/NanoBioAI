import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/theme.dart';

class FontScaleSelector extends StatelessWidget {
  const FontScaleSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.showPreview = true,
  });

  final AppTextScalePreset value;
  final ValueChanged<AppTextScalePreset> onChanged;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final presets = AppTextScalePreset.values;
    final selectedIndex = presets.indexOf(value);

    return Semantics(
      container: true,
      label: 'Chọn cỡ chữ hiển thị',
      value: value.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPreview) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              decoration: BoxDecoration(
                color: context.semanticColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.semanticColors.border),
              ),
              child: Text(
                'Nabi sẽ đồng hành cùng bạn mỗi ngày.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
          Slider(
            key: const Key('font_scale_slider'),
            value: selectedIndex.toDouble(),
            min: 0,
            max: (presets.length - 1).toDouble(),
            divisions: presets.length - 1,
            label: value.label,
            onChanged: (rawValue) {
              final index = rawValue
                  .round()
                  .clamp(0, presets.length - 1)
                  .toInt();
              onChanged(presets[index]);
            },
          ),
          Row(
            children: [
              for (final preset in presets)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: preset == value,
                    label: 'Cỡ chữ ${preset.label}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => onChanged(preset),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          preset.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: preset == value
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: preset == value
                                    ? AppColors.primary
                                    : context.semanticColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

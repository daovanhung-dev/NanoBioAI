import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';
import 'package:nano_app/core/theme/app_semantic_colors.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_stitch_components.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

import 'package:nano_app/core/theme/app_spacing.dart';

class ConditionsStep extends ConsumerStatefulWidget {
  const ConditionsStep({super.key});

  @override
  ConsumerState<ConditionsStep> createState() => _ConditionsStepState();
}

class _ConditionsStepState extends ConsumerState<ConditionsStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final normalized = _query.trim().toLowerCase();
    final specialOption = OnboardingCatalog.conditions.firstWhere(
      (option) => option.code == 'no_special_issue',
    );
    final visibleOptions = OnboardingCatalog.conditions
        .where((option) => option.code != 'no_special_issue')
        .where(
          (option) =>
              normalized.isEmpty ||
              option.label.toLowerCase().contains(normalized),
        )
        .toList(growable: false);

    return OnboardingStepShell(
      stepIndex: 3,
      title: 'Điều cần lưu ý',
      subtitle: 'Chọn nhiều nếu phù hợp.',
      mood: NabiOnboardingMood.care,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: OnboardingRevealColumn(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [colors.primarySubtle, colors.secondarySoft],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    color: colors.secondaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điều cần lưu ý',
                        style: AppTextStyles.heading5.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Chọn nhiều nếu phù hợp.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tình trạng sức khỏe...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () => setState(() => _query = ''),
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.card,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingChoiceRow(
            option: specialOption,
            selected: state.conditions.contains(specialOption.code),
            onTap: () => controller.toggleCondition(specialOption.code),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'DANH MỤC PHỔ BIẾN',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
              Text(
                'Đã chọn: ${state.conditions.where((code) => code != 'no_special_issue').length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (visibleOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Chưa tìm thấy mục phù hợp.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            for (final option in visibleOptions) ...[
              OnboardingChoiceRow(
                option: option,
                selected: state.conditions.contains(option.code),
                onTap: () => controller.toggleCondition(option.code),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          const SizedBox(height: AppSpacing.sm),
          OnboardingStitchCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                OnboardingTextField(
                  label: 'Thông tin khác (tùy chọn)',
                  hint: 'Ghi ngắn gọn điều cần lưu ý',
                  initialValue: state.otherCondition,
                  maxLines: 2,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.updateOtherCondition,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Thông tin này hỗ trợ gợi ý sức khỏe, không thay thế chẩn đoán.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

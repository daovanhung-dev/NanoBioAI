import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/app/app_radius.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
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
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final normalized = _query.trim().toLowerCase();
    final visibleOptions = OnboardingCatalog.conditions
        .where(
          (option) => normalized.isEmpty ||
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
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Tình trạng sức khỏe',
            icon: Icons.health_and_safety_rounded,
            accent: NabiPalette.careCoral,
            selectedCount: state.conditions.length,
            trailing: state.conditions.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Bỏ chọn tất cả',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      for (final code in [...state.conditions]) {
                        controller.toggleCondition(code);
                      }
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    color: NabiPalette.greenDeep,
                  ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Tìm bệnh lý',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () => setState(() => _query = ''),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: NabiPalette.mintSurface,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(
                        color: NabiPalette.greenPrimary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (visibleOptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: NabiAssistantMessage(
                      message: 'Chưa tìm thấy mục phù hợp',
                      icon: Icons.search_off_rounded,
                      accent: NabiPalette.calmBlue,
                    ),
                  )
                else
                  OnboardingChoiceGrid(
                    options: visibleOptions,
                    selectedCodes: state.conditions,
                    multiSelect: true,
                    onSelected: controller.toggleCondition,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingSectionCard(
            title: 'Thông tin khác',
            icon: Icons.edit_note_rounded,
            accent: NabiPalette.personalPurple,
            child: OnboardingTextField(
              label: 'Tùy chọn',
              hint: 'Ghi ngắn gọn điều cần lưu ý',
              initialValue: state.otherCondition,
              maxLines: 2,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              onChanged: controller.updateOtherCondition,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const OnboardingInlineInfo(
            icon: Icons.medical_information_outlined,
            text: 'Thông tin này hỗ trợ gợi ý sức khỏe, không thay thế chẩn đoán.',
            color: NabiPalette.calmBlue,
          ),
        ],
      ),
    );
  }
}

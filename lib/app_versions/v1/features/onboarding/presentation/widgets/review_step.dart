import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 7,
      title: 'Kiểm tra lại hồ sơ',
      subtitle:
          'Bạn có thể quay lại bất kỳ bước nào để chỉnh sửa trước khi NaBi tạo lịch trình.',
      onBack: controller.previousStep,
      footer: NabiPrimaryButton(
        onPressed: state.isSaving
            ? null
            : () => _submit(context, state, controller),
        label: state.isSaving
            ? 'NaBi đang chuẩn bị lịch trình...'
            : 'Bắt đầu cùng NaBi',
        icon: Icons.auto_awesome_rounded,
        isLoading: state.isSaving,
      ),
      child: Column(
        children: [
          OnboardingSectionCard(
            title: 'Thông tin cơ bản',
            child: _TwoColumns(
              children: [
                OnboardingLabelValue(
                  label: 'Họ và tên',
                  value: _value(state.fullName),
                  icon: Icons.person_outline_rounded,
                ),
                OnboardingLabelValue(
                  label: 'Giới tính',
                  value: OnboardingCatalog.labelOf(
                    OnboardingCatalog.genders,
                    state.gender,
                  ),
                  icon: Icons.person_outline_rounded,
                ),
                OnboardingLabelValue(
                  label: 'Năm sinh',
                  value: state.birthYear.toString(),
                  icon: Icons.cake_outlined,
                ),
                OnboardingLabelValue(
                  label: 'Nhịp sống',
                  value: OnboardingCatalog.labelOf(
                    OnboardingCatalog.occupations,
                    state.occupation,
                  ),
                  icon: Icons.work_outline_rounded,
                ),
                OnboardingLabelValue(
                  label: 'Chiều cao',
                  value: '${state.heightCm.toStringAsFixed(0)} cm',
                  icon: Icons.height_rounded,
                ),
                OnboardingLabelValue(
                  label: 'Cân nặng',
                  value: '${state.weightKg.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SelectionSummary(
            title: 'Mục tiêu của bạn',
            items: _labels(OnboardingCatalog.goals, state.goals),
            fallback: _value(state.otherGoal, fallback: 'Chưa chọn mục tiêu'),
          ),
          const SizedBox(height: 12),
          _SelectionSummary(
            title: 'Điều cần lưu ý',
            items: _labels(OnboardingCatalog.conditions, state.conditions),
            fallback: _value(state.otherCondition, fallback: 'Chưa có ghi chú'),
          ),
          const SizedBox(height: 12),
          _SelectionSummary(
            title: 'Thói quen & nhịp sinh hoạt',
            items: [
              ..._labels(OnboardingCatalog.habits, state.habits),
              'Ngủ: ${_value(state.sleepQuality)}',
              'Vận động: ${_value(state.activityLevel)}',
              'Nước: ${_value(state.waterPerDay)}',
            ],
            fallback: 'Chưa cập nhật',
          ),
          const SizedBox(height: 12),
          OnboardingSectionCard(
            title: 'Thông tin thêm',
            child: _TwoColumns(
              children: [
                OnboardingLabelValue(
                  label: 'Dị ứng / hạn chế',
                  value: _value(state.allergyName),
                  icon: Icons.no_food_outlined,
                ),
                OnboardingLabelValue(
                  label: 'Theo dõi sức khỏe',
                  value: _value(state.treatmentName),
                  icon: Icons.medical_information_outlined,
                ),
                OnboardingLabelValue(
                  label: 'Thuốc / sản phẩm',
                  value: _value(state.medicationName),
                  icon: Icons.medication_outlined,
                ),
                OnboardingLabelValue(
                  label: 'Mối quan tâm',
                  value: _value(state.concernText),
                  icon: Icons.favorite_outline_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _value(String value, {String fallback = 'Chưa cập nhật'}) {
    return value.trim().isEmpty ? fallback : value.trim();
  }

  static List<String> _labels(
    Iterable<OnboardingChoiceOption> options,
    Iterable<String> codes,
  ) {
    return codes
        .map((code) => OnboardingCatalog.labelOf(options, code, fallback: ''))
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _submit(
    BuildContext context,
    dynamic state,
    dynamic controller,
  ) async {
    if (!state.agreed) {
      controller.goToStep(6);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn hãy xác nhận trước khi tiếp tục nhé.'),
        ),
      );
      return;
    }
    if (!state.canSave) {
      controller.goToStep(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn hãy hoàn tất họ tên, giới tính và nhịp sống trước nhé.',
          ),
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AIGeneratingPage()));
    try {
      await controller.saveOnboarding();
      if (context.mounted) V1AppNavigator.goMenu(context);
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = error is AIOverloadedException
          ? AIOverloadedException.userMessage
          : error is StateError
          ? error.message.toString()
          : 'Mình chưa thể hoàn tất lúc này. Bạn thử lại giúp mình nhé.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _SelectionSummary extends StatelessWidget {
  final String title;
  final List<String> items;
  final String fallback;

  const _SelectionSummary({
    required this.title,
    required this.items,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final values = items.isEmpty ? [fallback] : items;
    return OnboardingSectionCard(
      title: title,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: values
            .map(
              (value) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: NabiPalette.royalBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Text(
                  value,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: NabiPalette.deepBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  final List<Widget> children;

  const _TwoColumns({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

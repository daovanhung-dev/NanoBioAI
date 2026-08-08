import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

import '../../providers/onboarding_provider.dart';
import '../controllers/onboarding_controller.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final goals = _labels(OnboardingCatalog.goals, state.goals);
    final conditions = _labels(OnboardingCatalog.conditions, state.conditions);
    final habits = _labels(OnboardingCatalog.habits, state.habits);

    return OnboardingStepShell(
      stepIndex: 8,
      title: 'Hồ sơ của bạn',
      subtitle: 'Xem nhanh trước khi tạo lộ trình.',
      mood: NabiOnboardingMood.review,
      onBack: controller.previousStep,
      footer: NabiPrimaryButton(
        onPressed: state.isSaving
            ? null
            : () => _submit(context, ref, state, controller),
        label: state.isSaving ? 'Đang tạo lộ trình...' : 'Tạo lộ trình',
        icon: Icons.auto_awesome_rounded,
        isLoading: state.isSaving,
      ),
      child: Column(
        children: [
          _ReadinessHero(ready: state.canSave, name: state.fullName),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Thông tin cơ bản',
            icon: Icons.person_rounded,
            accent: NabiPalette.greenPrimary,
            onEdit: () => controller.goToStep(1),
            child: Column(
              children: [
                _KeyValue(label: 'Họ tên', value: _value(state.fullName)),
                _KeyValue(
                  label: 'Giới tính',
                  value: OnboardingCatalog.labelOf(
                    OnboardingCatalog.genders,
                    state.gender,
                    fallback: 'Chưa cập nhật',
                  ),
                ),
                _KeyValue(label: 'Năm sinh', value: '${state.birthYear}'),
                _KeyValue(
                  label: 'Sinh hoạt',
                  value: OnboardingCatalog.labelOf(
                    OnboardingCatalog.occupations,
                    state.occupation,
                    fallback: 'Chưa cập nhật',
                  ),
                ),
                _KeyValue(
                  label: 'Thể trạng',
                  value:
                      '${state.heightCm.toStringAsFixed(0)} cm · ${state.weightKg.toStringAsFixed(1)} kg',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Mục tiêu',
            icon: Icons.flag_rounded,
            accent: NabiPalette.energyYellow,
            onEdit: () => controller.goToStep(2),
            child: _SummaryChips(
              values: [
                ...goals,
                if (state.otherGoal.trim().isNotEmpty) state.otherGoal.trim(),
              ],
              fallback: 'Chưa chọn',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Sức khỏe cần lưu ý',
            icon: Icons.health_and_safety_rounded,
            accent: NabiPalette.careCoral,
            onEdit: () => controller.goToStep(3),
            child: _SummaryChips(
              values: [
                ...conditions,
                if (state.otherCondition.trim().isNotEmpty)
                  state.otherCondition.trim(),
              ],
              fallback: 'Không có thông tin thêm',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Nhịp sống',
            icon: Icons.spa_rounded,
            accent: NabiPalette.calmBlue,
            onEdit: () => controller.goToStep(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryChips(values: habits, fallback: 'Chưa chọn thói quen'),
                const SizedBox(height: AppSpacing.sm),
                _KeyValue(label: 'Giấc ngủ', value: _value(state.sleepQuality)),
                _KeyValue(
                  label: 'Vận động',
                  value: _value(state.activityLevel),
                ),
                _KeyValue(
                  label: 'Nước uống',
                  value: _value(state.waterPerDay),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Thông tin bổ sung',
            icon: Icons.medical_information_rounded,
            accent: NabiPalette.personalPurple,
            onEdit: () => controller.goToStep(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabeledChips(
                  label: 'Dị ứng',
                  values: _splitValues(state.allergyName),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LabeledChips(
                  label: 'Điều trị',
                  values: _splitValues(state.treatmentName),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LabeledChips(
                  label: 'Thuốc / sản phẩm',
                  values: _splitValues(state.medicationName),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LabeledChips(
                  label: 'Mối quan tâm',
                  values: _splitValues(state.concernText),
                ),
                if (state.allergyNote.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _KeyValue(
                    label: 'Ghi chú dị ứng',
                    value: state.allergyNote.trim(),
                  ),
                ],
                if (state.treatmentNote.trim().isNotEmpty)
                  _KeyValue(
                    label: 'Ghi chú điều trị',
                    value: state.treatmentNote.trim(),
                    showDivider: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Khung giờ',
                  ready: state.routineConfirmed,
                  icon: Icons.schedule_rounded,
                  onTap: () => controller.goToStep(6),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatusCard(
                  title: 'Xác nhận',
                  ready: state.agreed,
                  icon: Icons.verified_user_rounded,
                  onTap: () => controller.goToStep(7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _value(String value, {String fallback = 'Chưa cập nhật'}) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static List<String> _splitValues(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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
    WidgetRef ref,
    OnboardingState state,
    OnboardingController controller,
  ) async {
    if (!state.agreed) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      controller.goToStep(7);
      _showMessage(context, 'Bạn cần xác nhận trước khi tiếp tục.');
      return;
    }
    if (!state.canSave) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      controller.goToStep(1);
      _showMessage(context, 'Bạn cần hoàn tất thông tin bắt buộc.');
      return;
    }

    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AIGeneratingPage()));
    try {
      await controller.saveOnboarding();
      AppFeedbackService.instance.emit(AppFeedbackType.milestone);
      final generationSource = ref
          .read(onboardingProvider)
          .initialPlanGenerationSource;
      if (generationSource.isBasicSuggestion && context.mounted) {
        _showMessage(context, 'NaBi đã tạo lịch gợi ý cơ bản đầu tiên.');
      }
      if (context.mounted) V1AppNavigator.goMenu(context);
    } catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = error is AIOverloadedException
          ? AIOverloadedException.userMessage
          : error is StateError
          ? error.message.toString()
          : 'Mình chưa thể hoàn tất lúc này. Bạn thử lại nhé.';
      _showMessage(context, message);
    }
  }

  static void _showMessage(BuildContext context, String message) {
    final colors = context.semanticColors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: colors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      );
  }
}

class _ReadinessHero extends StatelessWidget {
  final bool ready;
  final String name;

  const _ReadinessHero({required this.ready, required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final color = ready ? colors.primary : colors.warning;
    final normalizedName = name.trim();
    final greeting = normalizedName.isEmpty
        ? 'Sẵn sàng rồi!'
        : 'Sẵn sàng rồi, $normalizedName!';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: ready
            ? NabiPalette.hero
            : LinearGradient(
                colors: [NabiPalette.warning, NabiPalette.energyYellow],
              ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          NabiCompanionAvatar(
            size: 76,
            mood: ready
                ? NabiOnboardingMood.review
                : NabiOnboardingMood.thinking,
            showStatus: false,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? greeting : 'Còn một chút nữa',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ready
                      ? 'NaBi sẽ tạo lộ trình cá nhân.'
                      : 'Kiểm tra các mục chưa hoàn tất.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onEdit;
  final Widget child;

  const _SummarySection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return NabiGlassPanel(
      gradient: LinearGradient(colors: [colors.card, colors.cardAlt]),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      shadowColor: accent,
      borderColor: accent.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading5.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Sửa'),
                style: TextButton.styleFrom(foregroundColor: accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final bool ready;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusCard({
    required this.title,
    required this.ready,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final color = ready ? colors.success : colors.warning;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: color.withValues(alpha: 0.17)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ready ? 'Đã xong' : 'Cần xem lại',
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _KeyValue({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: colors.divider),
      ],
    );
  }
}

class _LabeledChips extends StatelessWidget {
  final String label;
  final List<String> values;

  const _LabeledChips({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.tiny),
        _SummaryChips(values: values, fallback: 'Chưa cập nhật'),
      ],
    );
  }
}

class _SummaryChips extends StatelessWidget {
  final List<String> values;
  final String fallback;

  const _SummaryChips({required this.values, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        fallback,
        style: AppTextStyles.bodyMedium.copyWith(
          color: context.semanticColors.textSecondary,
        ),
      );
    }
    return OnboardingSelectedChips(values: values);
  }
}

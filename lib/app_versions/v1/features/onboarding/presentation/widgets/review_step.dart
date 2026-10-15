import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

import '../../providers/onboarding_provider.dart';
import '../controllers/onboarding_controller.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_schedule_progress_panel.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

String onboardingSubmissionErrorMessage(Object error) {
  if (error is AIOverloadedException) return AIOverloadedException.userMessage;
  if (error is OnboardingInitialPlanException) return error.message;
  if (error is StateError) return error.message.toString();
  return 'Mình chưa thể hoàn tất lúc này. Bạn thử lại nhé.';
}

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final goals = _labels(OnboardingCatalog.goals, state.goals);
    final conditions = _labels(OnboardingCatalog.conditions, state.conditions);
    final habits = _labels(OnboardingCatalog.habits, state.habits);
    final routine = state.routinePreferences;
    final colors = context.semanticColors;
    final conditionSummary = [
      ...conditions,
      if (state.otherCondition.trim().isNotEmpty) state.otherCondition.trim(),
    ];
    final lifestyleSummary = [
      if (habits.isNotEmpty) 'Thói quen: ${_preview(habits)}',
      if (state.sleepQuality.trim().isNotEmpty)
        'Giấc ngủ: ${state.sleepQuality}',
      if (state.activityLevel.trim().isNotEmpty)
        'Vận động: ${state.activityLevel}',
      if (state.waterPerDay.trim().isNotEmpty)
        'Nước uống: ${state.waterPerDay}',
    ].join(' · ');
    final extrasSummary = [
      if (_splitValues(state.allergyName).isNotEmpty)
        'Dị ứng: ${_preview(_splitValues(state.allergyName))}',
      if (_splitValues(state.treatmentName).isNotEmpty)
        'Theo dõi: ${_preview(_splitValues(state.treatmentName))}',
      if (_splitValues(state.medicationName).isNotEmpty)
        'Thuốc: ${_preview(_splitValues(state.medicationName))}',
      if (state.medicationReminders.isNotEmpty)
        'Lịch nhắc: ${_preview(state.medicationReminders.map((reminder) => '${reminder.medicineName.trim()} (${reminder.reminderMinutes.map(_formatReminderMinute).join(', ')})').toList(growable: false))}',
      if (_splitValues(state.concernText).isNotEmpty)
        'Quan tâm: ${_preview(_splitValues(state.concernText))}',
      if (state.allergyNote.trim().isNotEmpty)
        'Ghi chú: ${state.allergyNote.trim()}',
      if (state.treatmentNote.trim().isNotEmpty)
        'Điều trị: ${state.treatmentNote.trim()}',
    ].join(' · ');

    return OnboardingStepShell(
      stepIndex: 8,
      title: 'Hồ sơ của bạn',
      subtitle: 'Xem lại trước khi Nabi bắt đầu tạo lộ trình.',
      mood: NabiOnboardingMood.review,
      onBack: controller.previousStep,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NabiPrimaryButton(
            key: const Key('onboarding_review_create_plan'),
            onPressed: state.isSaving
                ? null
                : () => _submit(context, ref, state, controller),
            label: state.isSaving ? 'Đang tạo lộ trình...' : 'Tạo lộ trình',
            icon: Icons.auto_awesome_rounded,
            isLoading: state.isSaving,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nabi tôn trọng dữ liệu cá nhân • Có thể điều chỉnh lại bất cứ lúc nào',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      child: OnboardingRevealColumn(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colors.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'HOÀN TẤT THU THẬP DỮ LIỆU',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              Text(
                'Bước 9/9',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingNabiNote(
            mood: NabiOnboardingMood.review,
            eyebrow: 'NABI AI ĐỒNG HÀNH',
            compact: true,
            message: state.canSave
                ? 'Tuyệt vời! Bạn vừa hoàn thành các thông tin cốt lõi. Hãy lướt lại các mục trước khi tạo lộ trình nhé.'
                : 'Hãy kiểm tra các mục còn thiếu trước khi tạo lộ trình.',
          ),
          const SizedBox(height: AppSpacing.md),
          const OnboardingScreenHeading(
            title: 'Hồ sơ của bạn',
            subtitle:
                'Kiểm tra lại các chi tiết trước khi Nabi bắt đầu tính toán và thiết lập nhịp sinh học.',
            bottomSpacing: AppSpacing.sm,
          ),
          _ReadinessHero(ready: state.canSave, name: state.fullName),
          const SizedBox(height: AppSpacing.sm),
          _SummarySection(
            title: 'Thông tin cơ bản',
            icon: Icons.badge_outlined,
            accent: colors.primary,
            onEdit: () => controller.goToStep(1),
            child: Text(
              [
                _value(state.fullName),
                OnboardingCatalog.labelOf(
                  OnboardingCatalog.genders,
                  state.gender,
                  fallback: 'Chưa chọn giới tính',
                ),
                if (state.birthYear > 0) '${state.birthYear}',
                if (state.occupation.trim().isNotEmpty)
                  OnboardingCatalog.labelOf(
                    OnboardingCatalog.occupations,
                    state.occupation,
                    fallback: '',
                  ),
                if (state.heightCm > 0)
                  '${state.heightCm.toStringAsFixed(0)} cm',
                if (state.weightKg > 0)
                  '${state.weightKg.toStringAsFixed(1)} kg',
              ].where((value) => value.trim().isNotEmpty).join(' · '),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Mục tiêu cải thiện',
            icon: Icons.flag_rounded,
            accent: colors.secondary,
            onEdit: () => controller.goToStep(2),
            child: Text(goals.isEmpty ? 'Chưa chọn mục tiêu' : _preview(goals)),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Lưu ý sức khỏe',
            icon: Icons.health_and_safety_rounded,
            accent: colors.tertiary,
            onEdit: () => controller.goToStep(3),
            child: Text(
              conditionSummary.isEmpty
                  ? 'Chưa ghi nhận'
                  : _preview(conditionSummary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Nhịp sống & thói quen',
            icon: Icons.spa_rounded,
            accent: colors.info,
            onEdit: () => controller.goToStep(4),
            child: Text(
              lifestyleSummary.isEmpty ? 'Chưa thiết lập' : lifestyleSummary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Thông tin bổ sung',
            icon: Icons.medication_rounded,
            accent: colors.secondaryDark,
            onEdit: () => controller.goToStep(5),
            child: Text(
              extrasSummary.isEmpty
                  ? 'Chưa có thông tin bổ sung'
                  : extrasSummary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Khung giờ trong ngày',
            icon: Icons.schedule_rounded,
            accent: colors.primary,
            onEdit: () => controller.goToStep(6),
            child: Text(
              'Ngày thường: thức ${routine.weekday.wakeTime}, ngủ ${routine.weekday.sleepTime} · Cuối tuần: thức ${routine.weekend.wakeTime}, ngủ ${routine.weekend.sleepTime}',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummarySection(
            title: 'Quyền riêng tư',
            icon: Icons.verified_user_rounded,
            accent: colors.success,
            onEdit: () => controller.goToStep(7),
            child: Text(
              state.agreed ? 'Đã xác nhận đồng thuận' : 'Chưa xác nhận',
            ),
          ),
        ],
      ),
    );
  }

  static String _preview(List<String> values, {int count = 3}) {
    if (values.length <= count) return values.join(', ');
    return '${values.take(count).join(', ')} +${values.length - count}';
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AIGeneratingPage(
          progressContent: OnboardingScheduleProgressPanel(),
        ),
      ),
    );
    try {
      await controller.saveOnboarding();
      AppFeedbackService.instance.emit(AppFeedbackType.milestone);
      final generationSource = ref
          .read(onboardingProvider)
          .initialPlanGenerationSource;
      if (generationSource.isBasicSuggestion && context.mounted) {
        _showMessage(context, 'Nabi đã tạo lịch gợi ý cơ bản đầu tiên.');
      }
      if (context.mounted) V1AppNavigator.goMenu(context);
    } catch (error, stackTrace) {
      AppLogger.error(
        'ONBOARDING_REVIEW',
        'Submit failed while saving profile or generating initial plan',
        error,
        stackTrace,
      );
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      _showMessage(context, onboardingSubmissionErrorMessage(error));
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

String _formatReminderMinute(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.ready, required this.name});

  final bool ready;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final statusColor = ready ? colors.secondaryDark : colors.warning;
    final normalizedName = name.trim();
    return OnboardingStitchCard(
      color: colors.primarySubtle,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monitor_heart_rounded,
              color: colors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mức độ tương thích hồ sơ',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ready
                      ? normalizedName.isEmpty
                            ? 'Sẵn sàng khởi tạo'
                            : 'Hồ sơ của $normalizedName sẵn sàng khởi tạo'
                      : 'Cần hoàn tất thông tin bắt buộc',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ready ? Icons.schedule_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  ready ? 'Chờ thiết lập' : 'Cần kiểm tra',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
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
  const _SummarySection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onEdit,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Sửa'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DefaultTextStyle.merge(
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../../daily_routine/domain/entities/daily_routine_preferences.dart';
import '../../../daily_routine/presentation/widgets/daily_routine_preferences_editor.dart';
import '../controllers/onboarding_controller.dart';
import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

const _routineQuestions = [
  'Bạn thức dậy vào lúc mấy giờ?',
  'Bạn ăn sáng từ lúc mấy giờ?',
  'Bạn ăn bữa phụ sáng lúc mấy giờ?',
  'Bạn ăn trưa từ lúc mấy giờ?',
  'Bạn ăn bữa phụ chiều lúc mấy giờ?',
  'Bạn ăn tối từ lúc mấy giờ?',
  'Bạn thường đi ngủ lúc mấy giờ?',
];

class DailyRoutineStep extends ConsumerStatefulWidget {
  const DailyRoutineStep({super.key});

  @override
  ConsumerState<DailyRoutineStep> createState() => _DailyRoutineStepState();
}

class _DailyRoutineStepState extends ConsumerState<DailyRoutineStep> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final preferences = state.routinePreferences;
    final questionIndex = state.routineQuestionIndex;
    final showingOptionalDetails =
        questionIndex >= OnboardingController.routineQuestionCount;
    final profileQuestionIndex =
        questionIndex % OnboardingController.routineQuestionsPerProfile;
    final isWeekend =
        questionIndex >= OnboardingController.routineQuestionsPerProfile;
    final profileLabel = isWeekend ? 'Cuối tuần' : 'Ngày thường';
    final prompt = showingOptionalDetails
        ? 'Bạn muốn thêm giờ nào không?'
        : _routineQuestions[profileQuestionIndex];
    final template = isWeekend ? preferences.weekend : preferences.weekday;
    final errors = preferences.validate();

    return OnboardingStepShell(
      stepIndex: OnboardingController.dailyRoutineStepIndex,
      title: prompt,
      subtitle: showingOptionalDetails ? 'Không bắt buộc' : profileLabel,
      mood: NabiOnboardingMood.routine,
      onBack: controller.previousRoutineQuestion,
      footer: NabiPrimaryButton(
        key: Key(
          showingOptionalDetails
              ? 'daily_routine_confirm'
              : 'daily_routine_next',
        ),
        onPressed: showingOptionalDetails
            ? (errors.isEmpty ? controller.confirmRoutineAndContinue : null)
            : controller.nextRoutineQuestion,
        label: showingOptionalDetails ? 'Xác nhận' : 'Tiếp tục',
        icon: Icons.arrow_forward_rounded,
      ),
      child: OnboardingRevealColumn(
        children: [
          Text(
            showingOptionalDetails ? 'TÙY CHỌN' : profileLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.semanticColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              color: context.semanticColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!showingOptionalDetails) ...[
            Semantics(
              label: 'Tiến độ lịch $profileLabel',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value:
                      (profileQuestionIndex + 1) /
                      OnboardingController.routineQuestionsPerProfile,
                  minHeight: 4,
                  backgroundColor: context.semanticColors.primarySoft,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RoutineTimeCard(
              time: _timeForQuestion(template, profileQuestionIndex),
              onPick: () => _pickAndUpdateTime(
                context: context,
                controller: controller,
                preferences: preferences,
                template: template,
                questionIndex: profileQuestionIndex,
                isWeekend: isWeekend,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ước lượng cũng được nhé.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ] else ...[
            OnboardingAccordionCard(
              key: const Key('daily_routine_optional_editor'),
              title: 'Thêm giờ tùy chọn',
              subtitle: 'Ngủ trưa, tập luyện và thời gian bận.',
              icon: Icons.tune_rounded,
              expanded: _detailsExpanded,
              onToggle: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
              child: DailyRoutinePreferencesEditor(
                value: preferences,
                showCoreTimes: false,
                onChanged: controller.updateRoutinePreferences,
              ),
            ),
          ],
          if (showingOptionalDetails && errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            OnboardingInlineInfo(
              icon: Icons.info_outline_rounded,
              text: errors.first,
              color: NabiPalette.warning,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUpdateTime({
    required BuildContext context,
    required OnboardingController controller,
    required DailyRoutinePreferences preferences,
    required RoutineDayTemplate template,
    required int questionIndex,
    required bool isWeekend,
  }) async {
    final value = await _pickTime(
      context,
      _timeForQuestion(template, questionIndex),
    );
    if (!mounted || value == null) return;

    final updatedTemplate = _templateWithQuestionTime(
      template,
      questionIndex,
      value,
    );
    controller.updateRoutinePreferences(
      isWeekend
          ? preferences.copyWith(weekend: updatedTemplate)
          : preferences.copyWith(weekday: updatedTemplate),
    );
  }

  String _timeForQuestion(RoutineDayTemplate template, int index) {
    if (index == 0) return template.wakeTime;
    if (index == _routineQuestions.length - 1) return template.sleepTime;
    return template.mealTimes[index - 1];
  }

  RoutineDayTemplate _templateWithQuestionTime(
    RoutineDayTemplate template,
    int index,
    String time,
  ) {
    if (index == 0) return template.copyWith(wakeTime: time);
    if (index == _routineQuestions.length - 1) {
      return template.copyWith(sleepTime: time);
    }

    final mealTimes = [...template.mealTimes]..[index - 1] = time;
    return template.copyWith(mealTimes: mealTimes);
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '') ?? 8,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
    final value = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (value == null) return null;
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _RoutineTimeCard extends StatelessWidget {
  const _RoutineTimeCard({required this.time, required this.onPick});

  final String time;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            key: const Key('daily_routine_selected_time'),
            style: AppTextStyles.displaySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('daily_routine_time_picker'),
            onPressed: onPick,
            icon: const Icon(Icons.schedule_rounded),
            label: const Text('Chọn giờ'),
          ),
        ],
      ),
    );
  }
}

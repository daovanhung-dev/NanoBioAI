import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../../daily_routine/domain/entities/daily_routine_preferences.dart';
import '../controllers/onboarding_controller.dart';
import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

enum _RoutineProfile { weekday, weekend }

enum _RoutineQuestionKind { coreTime, yesNo, range }

enum _RoutineCoreTime {
  wake,
  breakfast,
  morningSnack,
  lunch,
  afternoonSnack,
  dinner,
  sleep,
}

enum _RoutineToggle { nap, busy }

enum _RoutineRange { nap, firstWorkout, secondWorkout, busy }

class _RoutineQuestion {
  const _RoutineQuestion({
    required this.id,
    required this.prompt,
    required this.profile,
    required this.kind,
    this.coreTime,
    this.toggle,
    this.range,
  });

  final String id;
  final String prompt;
  final _RoutineProfile profile;
  final _RoutineQuestionKind kind;
  final _RoutineCoreTime? coreTime;
  final _RoutineToggle? toggle;
  final _RoutineRange? range;
}

List<_RoutineQuestion> _routineQuestionsFor(
  DailyRoutinePreferences preferences,
) => [
  ..._profileRoutineQuestions(_RoutineProfile.weekday, preferences.weekday),
  ..._profileRoutineQuestions(_RoutineProfile.weekend, preferences.weekend),
];

List<_RoutineQuestion> _profileRoutineQuestions(
  _RoutineProfile profile,
  RoutineDayTemplate template,
) {
  final prefix = profile.name;
  final questions = <_RoutineQuestion>[
    _RoutineQuestion(
      id: '${prefix}_wake',
      prompt: 'Bạn thức dậy vào lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.wake,
    ),
    _RoutineQuestion(
      id: '${prefix}_breakfast',
      prompt: 'Bạn ăn sáng từ lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.breakfast,
    ),
    _RoutineQuestion(
      id: '${prefix}_morning_snack',
      prompt: 'Bạn ăn bữa phụ sáng lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.morningSnack,
    ),
    _RoutineQuestion(
      id: '${prefix}_lunch',
      prompt: 'Bạn ăn trưa từ lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.lunch,
    ),
    _RoutineQuestion(
      id: '${prefix}_afternoon_snack',
      prompt: 'Bạn ăn bữa phụ chiều lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.afternoonSnack,
    ),
    _RoutineQuestion(
      id: '${prefix}_dinner',
      prompt: 'Bạn ăn tối từ lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.dinner,
    ),
    _RoutineQuestion(
      id: '${prefix}_sleep',
      prompt: 'Bạn thường đi ngủ lúc mấy giờ?',
      profile: profile,
      kind: _RoutineQuestionKind.coreTime,
      coreTime: _RoutineCoreTime.sleep,
    ),
    _RoutineQuestion(
      id: '${prefix}_nap_enabled',
      prompt: 'Bạn có ngủ trưa không?',
      profile: profile,
      kind: _RoutineQuestionKind.yesNo,
      toggle: _RoutineToggle.nap,
    ),
  ];

  if (template.napEnabled) {
    questions.add(
      _RoutineQuestion(
        id: '${prefix}_nap_range',
        prompt: 'Bạn thường ngủ trưa từ mấy giờ đến mấy giờ?',
        profile: profile,
        kind: _RoutineQuestionKind.range,
        range: _RoutineRange.nap,
      ),
    );
  }

  questions
    ..add(
      _RoutineQuestion(
        id: '${prefix}_workout_1',
        prompt: 'Lần tập đầu tiên trong ngày của bạn là khi nào?',
        profile: profile,
        kind: _RoutineQuestionKind.range,
        range: _RoutineRange.firstWorkout,
      ),
    )
    ..add(
      _RoutineQuestion(
        id: '${prefix}_workout_2',
        prompt: 'Lần tập thứ hai trong ngày của bạn là khi nào?',
        profile: profile,
        kind: _RoutineQuestionKind.range,
        range: _RoutineRange.secondWorkout,
      ),
    )
    ..add(
      _RoutineQuestion(
        id: '${prefix}_busy_enabled',
        prompt: 'Bạn có khoảng thời gian bận học hoặc làm việc không?',
        profile: profile,
        kind: _RoutineQuestionKind.yesNo,
        toggle: _RoutineToggle.busy,
      ),
    );

  if (template.busyRange != null) {
    questions.add(
      _RoutineQuestion(
        id: '${prefix}_busy_range',
        prompt: 'Bạn thường bận từ mấy giờ đến mấy giờ?',
        profile: profile,
        kind: _RoutineQuestionKind.range,
        range: _RoutineRange.busy,
      ),
    );
  }

  return questions;
}

extension on _RoutineProfile {
  String get label =>
      this == _RoutineProfile.weekday ? 'Ngày thường' : 'Cuối tuần';
}

class DailyRoutineStep extends ConsumerStatefulWidget {
  const DailyRoutineStep({super.key});

  @override
  ConsumerState<DailyRoutineStep> createState() => _DailyRoutineStepState();
}

class _DailyRoutineStepState extends ConsumerState<DailyRoutineStep> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final preferences = state.routinePreferences;
    final questions = _routineQuestionsFor(preferences);
    final questionIndex = state.routineQuestionIndex
        .clamp(0, questions.length - 1)
        .toInt();
    final question = questions[questionIndex];
    final profileLabel = question.profile.label;
    final profileQuestionCount = questions
        .where((item) => item.profile == question.profile)
        .length;
    final profileStartIndex = questions.indexWhere(
      (item) => item.profile == question.profile,
    );
    final profileQuestionIndex = questionIndex - profileStartIndex;
    final isFinalQuestion = questionIndex == questions.length - 1;
    final errors = preferences.validate();
    final screenSize = MediaQuery.sizeOf(context);
    final mascotSize = screenSize.width < 360 || screenSize.height < 680
        ? 72.0
        : 96.0;

    return OnboardingStepShell(
      stepIndex: OnboardingController.dailyRoutineStepIndex,
      title: question.prompt,
      subtitle: profileLabel,
      mood: NabiOnboardingMood.routine,
      onBack: controller.previousRoutineQuestion,
      footer: NabiPrimaryButton(
        key: Key(
          isFinalQuestion ? 'daily_routine_confirm' : 'daily_routine_next',
        ),
        onPressed: isFinalQuestion
            ? (errors.isEmpty ? controller.confirmRoutineAndContinue : null)
            : controller.nextRoutineQuestion,
        label: isFinalQuestion ? 'Xác nhận' : 'Tiếp tục',
        icon: Icons.arrow_forward_rounded,
      ),
      child: OnboardingRevealColumn(
        children: [
          Text(
            profileLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.semanticColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              color: context.semanticColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Image.asset(
            key: const Key('daily_routine_nabi'),
            NabiOnboardingMood.routine.assetPath,
            width: mascotSize,
            height: mascotSize,
            fit: BoxFit.contain,
            cacheWidth: (mascotSize * 3).round(),
            semanticLabel: 'Nabi đồng hành',
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label:
                'Tiến độ lịch $profileLabel, câu ${profileQuestionIndex + 1} trên $profileQuestionCount',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (profileQuestionIndex + 1) / profileQuestionCount,
                minHeight: 4,
                backgroundColor: context.semanticColors.primarySoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionInput(
            question: question,
            preferences: preferences,
            controller: controller,
          ),
          if (question.kind != _RoutineQuestionKind.yesNo) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ước lượng cũng được nhé.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
          ],
          if (isFinalQuestion && errors.isNotEmpty) ...[
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

  Widget _buildQuestionInput({
    required _RoutineQuestion question,
    required DailyRoutinePreferences preferences,
    required OnboardingController controller,
  }) {
    final template = _templateFor(preferences, question.profile);
    return switch (question.kind) {
      _RoutineQuestionKind.coreTime => _RoutineTimeCard(
        time: _timeForCoreQuestion(template, question.coreTime!),
        onPick: () => _pickCoreTime(
          context: context,
          controller: controller,
          preferences: preferences,
          question: question,
          template: template,
        ),
      ),
      _RoutineQuestionKind.yesNo => _RoutineYesNoCard(
        key: Key('daily_routine_toggle_${question.id}'),
        selected: _toggleValue(template, question.toggle!),
        onChanged: (value) => _updateToggle(
          controller: controller,
          preferences: preferences,
          question: question,
          template: template,
          value: value,
        ),
      ),
      _RoutineQuestionKind.range => _RoutineTimeRangeCard(
        range: _rangeForQuestion(template, question.range!),
        onStartPick: () => _pickRangeTime(
          context: context,
          controller: controller,
          preferences: preferences,
          question: question,
          template: template,
          isStart: true,
        ),
        onEndPick: () => _pickRangeTime(
          context: context,
          controller: controller,
          preferences: preferences,
          question: question,
          template: template,
          isStart: false,
        ),
      ),
    };
  }

  Future<void> _pickCoreTime({
    required BuildContext context,
    required OnboardingController controller,
    required DailyRoutinePreferences preferences,
    required RoutineDayTemplate template,
    required _RoutineQuestion question,
  }) async {
    final value = await _pickTime(
      context,
      _timeForCoreQuestion(template, question.coreTime!),
    );
    if (!mounted || value == null) return;

    final updatedTemplate = _templateWithCoreTime(
      template,
      question.coreTime!,
      value,
    );
    _updateProfileTemplate(
      controller,
      preferences,
      question.profile,
      updatedTemplate,
    );
  }

  void _updateToggle({
    required OnboardingController controller,
    required DailyRoutinePreferences preferences,
    required _RoutineQuestion question,
    required RoutineDayTemplate template,
    required bool value,
  }) {
    final updatedTemplate = switch (question.toggle!) {
      _RoutineToggle.nap => template.copyWith(
        napEnabled: value,
        napRange: value
            ? template.napRange ??
                  const RoutineTimeRange(start: '12:45', end: '13:15')
            : template.napRange,
      ),
      _RoutineToggle.busy => template.copyWith(
        busyRange: value
            ? template.busyRange ??
                  const RoutineTimeRange(start: '08:30', end: '11:30')
            : null,
        clearBusyRange: !value,
      ),
    };
    _updateProfileTemplate(
      controller,
      preferences,
      question.profile,
      updatedTemplate,
    );
  }

  Future<void> _pickRangeTime({
    required BuildContext context,
    required OnboardingController controller,
    required DailyRoutinePreferences preferences,
    required _RoutineQuestion question,
    required RoutineDayTemplate template,
    required bool isStart,
  }) async {
    final current = _rangeForQuestion(template, question.range!);
    final value = await _pickTime(
      context,
      isStart ? current.start : current.end,
    );
    if (!mounted || value == null) return;

    final updatedRange = isStart
        ? current.copyWith(start: value)
        : current.copyWith(end: value);
    _updateProfileTemplate(
      controller,
      preferences,
      question.profile,
      _templateWithRange(template, question.range!, updatedRange),
    );
  }

  void _updateProfileTemplate(
    OnboardingController controller,
    DailyRoutinePreferences preferences,
    _RoutineProfile profile,
    RoutineDayTemplate template,
  ) {
    controller.updateRoutinePreferences(
      profile == _RoutineProfile.weekday
          ? preferences.copyWith(weekday: template)
          : preferences.copyWith(weekend: template),
    );
  }

  RoutineDayTemplate _templateFor(
    DailyRoutinePreferences preferences,
    _RoutineProfile profile,
  ) => profile == _RoutineProfile.weekday
      ? preferences.weekday
      : preferences.weekend;

  String _timeForCoreQuestion(
    RoutineDayTemplate template,
    _RoutineCoreTime field,
  ) => switch (field) {
    _RoutineCoreTime.wake => template.wakeTime,
    _RoutineCoreTime.breakfast => template.mealTimes[0],
    _RoutineCoreTime.morningSnack => template.mealTimes[1],
    _RoutineCoreTime.lunch => template.mealTimes[2],
    _RoutineCoreTime.afternoonSnack => template.mealTimes[3],
    _RoutineCoreTime.dinner => template.mealTimes[4],
    _RoutineCoreTime.sleep => template.sleepTime,
  };

  RoutineDayTemplate _templateWithCoreTime(
    RoutineDayTemplate template,
    _RoutineCoreTime field,
    String time,
  ) {
    return switch (field) {
      _RoutineCoreTime.wake => template.copyWith(wakeTime: time),
      _RoutineCoreTime.breakfast => _templateWithMealTime(template, 0, time),
      _RoutineCoreTime.morningSnack => _templateWithMealTime(template, 1, time),
      _RoutineCoreTime.lunch => _templateWithMealTime(template, 2, time),
      _RoutineCoreTime.afternoonSnack => _templateWithMealTime(
        template,
        3,
        time,
      ),
      _RoutineCoreTime.dinner => _templateWithMealTime(template, 4, time),
      _RoutineCoreTime.sleep => template.copyWith(sleepTime: time),
    };
  }

  RoutineDayTemplate _templateWithMealTime(
    RoutineDayTemplate template,
    int index,
    String time,
  ) {
    final mealTimes = [...template.mealTimes]..[index] = time;
    return template.copyWith(mealTimes: mealTimes);
  }

  bool _toggleValue(RoutineDayTemplate template, _RoutineToggle toggle) =>
      switch (toggle) {
        _RoutineToggle.nap => template.napEnabled,
        _RoutineToggle.busy => template.busyRange != null,
      };

  RoutineTimeRange _rangeForQuestion(
    RoutineDayTemplate template,
    _RoutineRange range,
  ) => switch (range) {
    _RoutineRange.nap =>
      template.napRange ?? const RoutineTimeRange(start: '12:45', end: '13:15'),
    _RoutineRange.firstWorkout => template.workoutRanges[0],
    _RoutineRange.secondWorkout => template.workoutRanges[1],
    _RoutineRange.busy =>
      template.busyRange ??
          const RoutineTimeRange(start: '08:30', end: '11:30'),
  };

  RoutineDayTemplate _templateWithRange(
    RoutineDayTemplate template,
    _RoutineRange range,
    RoutineTimeRange value,
  ) {
    return switch (range) {
      _RoutineRange.nap => template.copyWith(napRange: value),
      _RoutineRange.firstWorkout => _templateWithWorkout(template, 0, value),
      _RoutineRange.secondWorkout => _templateWithWorkout(template, 1, value),
      _RoutineRange.busy => template.copyWith(busyRange: value),
    };
  }

  RoutineDayTemplate _templateWithWorkout(
    RoutineDayTemplate template,
    int index,
    RoutineTimeRange value,
  ) {
    final ranges = [...template.workoutRanges]..[index] = value;
    return template.copyWith(workoutRanges: ranges);
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

class _RoutineYesNoCard extends StatelessWidget {
  const _RoutineYesNoCard({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStitchCard(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Có')),
          ButtonSegment(value: false, label: Text('Không')),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}

class _RoutineTimeRangeCard extends StatelessWidget {
  const _RoutineTimeRangeCard({
    required this.range,
    required this.onStartPick,
    required this.onEndPick,
  });

  final RoutineTimeRange range;
  final VoidCallback onStartPick;
  final VoidCallback onEndPick;

  @override
  Widget build(BuildContext context) {
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fields = [
            _RangeTimeField(
              key: const Key('daily_routine_range_start'),
              label: 'Bắt đầu',
              value: range.start,
              onPick: onStartPick,
            ),
            _RangeTimeField(
              key: const Key('daily_routine_range_end'),
              label: 'Kết thúc',
              value: range.end,
              onPick: onEndPick,
            ),
          ];

          if (constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fields[0],
                const SizedBox(height: AppSpacing.sm),
                fields[1],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: fields[0]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: fields[1]),
            ],
          );
        },
      ),
    );
  }
}

class _RangeTimeField extends StatelessWidget {
  const _RangeTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: context.semanticColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton(onPressed: onPick, child: Text(value)),
      ],
    );
  }
}

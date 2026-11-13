import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/data/onboarding_voice_runtime.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/onboarding_voice_questions.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_voice_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingVoiceStep extends ConsumerStatefulWidget {
  const OnboardingVoiceStep({super.key, required this.stepIndex});

  final int stepIndex;

  @override
  ConsumerState<OnboardingVoiceStep> createState() =>
      _OnboardingVoiceStepState();
}

class _OnboardingVoiceStepState extends ConsumerState<OnboardingVoiceStep>
    with WidgetsBindingObserver {
  final _inputController = TextEditingController();
  final _searchController = TextEditingController();
  String? _inputQuestionId;
  String _optionFilter = '';
  String? _runningQuestionId;
  bool _running = false;
  int _runGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureQuestion());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!ref.read(onboardingVoiceProvider).isVoiceMode) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
  }

  void _ensureQuestion() {
    if (!mounted) return;
    var onboarding = ref.read(onboardingProvider);
    var voice = ref.read(onboardingVoiceProvider);
    if (voice.stepIndex != widget.stepIndex) {
      ref.read(onboardingVoiceProvider.notifier).syncStep(widget.stepIndex);
      onboarding = ref.read(onboardingProvider);
      voice = ref.read(onboardingVoiceProvider);
    }
    final questions = _questions(onboarding, voice);
    if (questions.isEmpty) return;
    final current = questions.where((item) => item.id == voice.questionId);
    if (current.isEmpty) {
      ref
          .read(onboardingVoiceProvider.notifier)
          .setQuestion(questions.first.id);
    } else {
      unawaited(_runQuestion());
    }
  }

  List<OnboardingVoiceQuestion> _questions(
    OnboardingState state,
    OnboardingVoiceState voice,
  ) => OnboardingVoiceQuestions.forStep(
    step: widget.stepIndex,
    state: state,
    voiceState: voice,
  );

  OnboardingVoiceQuestion? _currentQuestion() {
    final onboarding = ref.read(onboardingProvider);
    final voice = ref.read(onboardingVoiceProvider);
    final questions = _questions(onboarding, voice);
    for (final question in questions) {
      if (question.id == voice.questionId) return question;
    }
    return questions.isEmpty ? null : questions.first;
  }

  Future<void> _runQuestion({bool userRetry = false}) async {
    final question = _currentQuestion();
    if (!mounted ||
        question == null ||
        !ref.read(onboardingVoiceProvider).isVoiceMode) {
      return;
    }
    if (_running && _runningQuestionId == question.id) return;
    final generation = ++_runGeneration;
    _running = true;
    _runningQuestionId = question.id;
    _syncInput(question);
    final voiceController = ref.read(onboardingVoiceProvider.notifier);
    final runtime = ref.read(onboardingVoiceRuntimeProvider);
    try {
      if (question.requiresManualSelection) {
        voiceController.setPhase(
          OnboardingVoicePhase.preparing,
          clearMessage: true,
        );
        await runtime.prepareSpeech();
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(OnboardingVoicePhase.speaking);
        await runtime.speak(question.prompt);
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(OnboardingVoicePhase.manual);
        return;
      }

      for (var attempt = 0; attempt < 2; attempt++) {
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(
          OnboardingVoicePhase.preparing,
          clearMessage: true,
          clearDownloadProgress: attempt > 0,
        );
        await runtime.prepare(
          onDownloadProgress: (progress) {
            if (_isRunActive(generation)) {
              voiceController.setPhase(
                OnboardingVoicePhase.preparing,
                downloadProgress: progress,
              );
            }
          },
        );
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(OnboardingVoicePhase.speaking);
        await runtime.speak(
          '${attempt > 0 ? 'Mình chưa nghe rõ, mình hỏi lại nhé. ' : ''}${question.spokenPrompt}',
        );
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(OnboardingVoicePhase.listening);
        final transcript = await runtime.listenAndTranscribe();
        if (!_isRunActive(generation)) return;
        voiceController.setPhase(
          OnboardingVoicePhase.processing,
          transcript: transcript,
        );
        if (transcript.isNotEmpty && _applySpokenAnswer(question, transcript)) {
          return;
        }
      }
      voiceController.setPhase(
        OnboardingVoicePhase.error,
        transcript: ref.read(onboardingVoiceProvider).transcript,
        message:
            'Mình chưa nhận ra câu trả lời. Bạn thử nói lại hoặc nhập câu trả lời nhé.',
      );
    } on OnboardingVoicePermissionException {
      if (_isRunActive(generation)) {
        voiceController.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Cần cho phép dùng micro để tiếp tục bằng giọng nói. Bạn vẫn có thể chuyển sang thao tác chạm.',
        );
      }
    } on OnboardingVoiceUnavailableException {
      if (_isRunActive(generation)) {
        voiceController.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Chưa thể khởi động giọng đọc hoặc nhận dạng tiếng Việt trên thiết bị này.',
        );
      }
    } catch (_) {
      if (_isRunActive(generation)) {
        voiceController.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Đã có lỗi khi nghe câu trả lời. Bạn có thể thử lại hoặc chuyển sang thao tác chạm.',
        );
      }
    } finally {
      if (_runGeneration == generation) {
        _running = false;
        if (_runningQuestionId == question.id) _runningQuestionId = null;
      }
      if (_runGeneration == generation &&
          userRetry &&
          mounted &&
          ref.read(onboardingVoiceProvider).phase ==
              OnboardingVoicePhase.error) {
        setState(() {});
      }
    }
  }

  bool _isRunActive(int generation) =>
      mounted &&
      generation == _runGeneration &&
      ref.read(onboardingVoiceProvider).isVoiceMode;

  Future<void> _useManualAnswer(
    OnboardingVoiceQuestion question,
    String value,
  ) async {
    _runGeneration++;
    _running = false;
    _runningQuestionId = null;
    await ref.read(onboardingVoiceRuntimeProvider).stopAll();
    if (!mounted) return;
    if (!_applySpokenAnswer(question, value)) {
      ref
          .read(onboardingVoiceProvider.notifier)
          .setPhase(
            OnboardingVoicePhase.error,
            message:
                'Câu trả lời chưa hợp lệ. Bạn kiểm tra lại rồi thử lần nữa nhé.',
          );
    }
  }

  void _syncInput(OnboardingVoiceQuestion question) {
    if (_inputQuestionId == question.id) return;
    _inputQuestionId = question.id;
    final voice = ref.read(onboardingVoiceProvider);
    _inputController.text = voice.draftQuestionId == question.id
        ? voice.draftText ?? question.currentValue
        : question.currentValue;
    _optionFilter = '';
    _searchController.clear();
  }

  bool _applySpokenAnswer(OnboardingVoiceQuestion question, String transcript) {
    if (question.optional && OnboardingVoiceParser.isSkip(transcript)) {
      _applyValue(question.id, '');
      _advance(question);
      return true;
    }
    if (question.id == 'welcome_start') {
      if (!OnboardingVoiceParser.isStart(transcript)) return false;
      ref.read(onboardingProvider.notifier).nextStep();
      return true;
    }
    if (question.id == 'routine_confirm') {
      if (!OnboardingVoiceParser.isConfirmRoutine(transcript)) return false;
      _confirmRoutine();
      return true;
    }
    if (question.kind == OnboardingVoiceAnswerKind.singleChoice) {
      final option = OnboardingVoiceParser.choice(transcript, question.options);
      if (option == null) return false;
      _applyValue(question.id, option.code);
      _advance(question);
      return true;
    }
    if (question.kind == OnboardingVoiceAnswerKind.number) {
      final value = question.id == 'birth_year'
          ? OnboardingVoiceParser.year(transcript)?.toDouble()
          : OnboardingVoiceParser.number(transcript);
      if (value == null ||
          (question.minimum != null && value < question.minimum!) ||
          (question.maximum != null && value > question.maximum!)) {
        return false;
      }
      _applyValue(question.id, value.toString());
      _advance(question);
      return true;
    }
    if (question.kind == OnboardingVoiceAnswerKind.time) {
      final minute = OnboardingVoiceParser.timeMinutes(transcript);
      if (minute == null) return false;
      _applyValue(question.id, onboardingVoiceFormatTime(minute));
      _advance(question);
      return true;
    }
    if (question.kind == OnboardingVoiceAnswerKind.text) {
      final value = transcript.trim();
      if (value.isEmpty) return false;
      _applyValue(question.id, value);
      _advance(question);
      return true;
    }
    return false;
  }

  void _applyValue(String id, String value) {
    final controller = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);
    final normalizedId = id.startsWith('reminder_more_') ? 'reminder_more' : id;
    switch (normalizedId) {
      case 'full_name':
        controller.updateFullName(value);
      case 'gender':
        controller.updateGender(value);
      case 'birth_year':
        controller.updateBirthYear(value);
      case 'occupation':
        controller.updateOccupation(value);
      case 'height':
        controller.updateHeight(value);
      case 'weight':
        controller.updateWeight(value);
      case 'other_goal':
        controller.updateOtherGoal(value);
      case 'other_condition':
        controller.updateOtherCondition(value);
      case 'sleep_quality':
        controller.updateSleepQuality(
          _choiceLabel(OnboardingOptions.sleepQualityChoices, value),
        );
      case 'activity_level':
        controller.updateActivityLevel(
          _choiceLabel(OnboardingOptions.activityChoices, value),
        );
      case 'water_per_day':
        controller.updateWaterPerDay(
          _choiceLabel(OnboardingOptions.waterChoices, value),
        );
      case 'allergy_note':
        controller.updateAllergyNote(value);
      case 'treatment_note':
        controller.updateTreatmentNote(value);
      case 'reminder_want':
        if (value == 'yes') {
          controller.addMedicationReminder();
        } else {
          ref
              .read(onboardingVoiceProvider.notifier)
              .finishMedicationReminders();
        }
      case 'reminder_more':
        if (value == 'yes' && state.medicationReminders.length < 5) {
          controller.addMedicationReminder();
        } else {
          ref
              .read(onboardingVoiceProvider.notifier)
              .finishMedicationReminders();
        }
      case 'routine_confirm':
        _confirmRoutine();
      case 'text_scale':
        final preset = AppTextScalePreset.values.firstWhere(
          (item) => item.name == value,
          orElse: () => AppTextScalePreset.standard,
        );
        unawaited(
          ref
              .read(appTextScaleControllerProvider.notifier)
              .select(preset, markConfigured: true),
        );
      default:
        if (id.startsWith('reminder_name_')) {
          final index = int.tryParse(id.substring('reminder_name_'.length));
          if (index != null) {
            controller.updateMedicationReminderName(index, value);
          }
        } else if (id.startsWith('reminder_time_')) {
          final index = int.tryParse(id.substring('reminder_time_'.length));
          final time = _minuteFromFormatted(value);
          if (index != null && time != null) {
            controller.addMedicationReminderTime(index, time);
          }
        } else if (id.startsWith('routine_')) {
          _applyRoutineValue(id, value, state);
        }
    }
  }

  String _choiceLabel(List<dynamic> options, String code) {
    for (final option in options) {
      if (option.code == code) return option.label;
    }
    return code;
  }

  int? _minuteFromFormatted(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  void _applyRoutineValue(String id, String value, OnboardingState state) {
    final pieces = id.split('_');
    if (pieces.length < 3) return;
    final dayKey = pieces[1];
    final field = pieces.sublist(2).join('_');
    final preferences = state.routinePreferences;
    final day = dayKey == 'weekday' ? preferences.weekday : preferences.weekend;
    RoutineDayTemplate updated = day;
    final time = value;
    if (field == 'wake') {
      updated = day.copyWith(wakeTime: time);
    } else if (field == 'sleep') {
      updated = day.copyWith(sleepTime: time);
    } else if (field.startsWith('meal_')) {
      final index = int.tryParse(field.substring('meal_'.length));
      if (index == null || index < 0 || index >= 5) return;
      final meals = List<String>.generate(
        5,
        (mealIndex) =>
            mealIndex < day.mealTimes.length ? day.mealTimes[mealIndex] : '',
      )..[index] = time;
      updated = day.copyWith(mealTimes: meals);
    } else if (field == 'nap_enabled') {
      final enabled = value == 'yes';
      updated = day.copyWith(
        napEnabled: enabled,
        napRange: enabled
            ? (day.napRange ?? const RoutineTimeRange(start: '', end: ''))
            : null,
        clearNapRange: !enabled,
      );
    } else if (field == 'nap_start' || field == 'nap_end') {
      final range = copyRoutineRange(
        day.napRange,
        start: field == 'nap_start' ? time : null,
        end: field == 'nap_end' ? time : null,
      );
      updated = day.copyWith(napRange: range, napEnabled: true);
    } else if (field.startsWith('workout_')) {
      final match = RegExp(r'^workout_(\d+)_(start|end)$').firstMatch(field);
      final index = int.tryParse(match?.group(1) ?? '');
      if (index == null) return;
      final ranges = [...day.workoutRanges];
      while (ranges.length <= index && ranges.length < 2) {
        ranges.add(const RoutineTimeRange(start: '', end: ''));
      }
      if (index >= ranges.length) return;
      ranges[index] = copyRoutineRange(
        ranges[index],
        start: match?.group(2) == 'start' ? time : null,
        end: match?.group(2) == 'end' ? time : null,
      );
      updated = day.copyWith(workoutRanges: ranges);
    } else if (field == 'busy_enabled') {
      final enabled = value == 'yes';
      updated = day.copyWith(
        busyRange: enabled
            ? (day.busyRange ?? const RoutineTimeRange(start: '', end: ''))
            : null,
        clearBusyRange: !enabled,
      );
    } else if (field == 'busy_start' || field == 'busy_end') {
      updated = day.copyWith(
        busyRange: copyRoutineRange(
          day.busyRange,
          start: field == 'busy_start' ? time : null,
          end: field == 'busy_end' ? time : null,
        ),
      );
    } else {
      return;
    }
    ref
        .read(onboardingProvider.notifier)
        .updateRoutinePreferences(
          dayKey == 'weekday'
              ? preferences.copyWith(weekday: updated)
              : preferences.copyWith(weekend: updated),
        );
  }

  void _toggleManualOption(OnboardingVoiceQuestion question, String value) {
    final state = ref.read(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    switch (question.id) {
      case 'occupation':
        _applyValue('occupation', value);
        _advance(question);
      case 'goals':
        controller.toggleGoal(value);
      case 'conditions':
        controller.toggleCondition(value);
      case 'habits':
        controller.toggleHabit(value);
      case 'allergies':
        controller.updateAllergyName(_toggleTextList(state.allergyName, value));
      case 'treatments':
        controller.updateTreatmentName(
          _toggleTextList(state.treatmentName, value),
        );
      case 'medications':
        controller.updateMedicationName(
          _toggleTextList(state.medicationName, value),
        );
      case 'concerns':
        controller.updateConcernText(_toggleTextList(state.concernText, value));
      default:
        break;
    }
  }

  String _toggleTextList(String original, String value) {
    final values = original
        .split(RegExp(r'[,;|\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
    return values.join(', ');
  }

  bool _isSelected(OnboardingVoiceQuestion question, String value) {
    final state = ref.read(onboardingProvider);
    return switch (question.id) {
      'occupation' => state.occupation == value,
      'goals' => state.goals.contains(value),
      'conditions' => state.conditions.contains(value),
      'habits' => state.habits.contains(value),
      'allergies' => _containsText(state.allergyName, value),
      'treatments' => _containsText(state.treatmentName, value),
      'medications' => _containsText(state.medicationName, value),
      'concerns' => _containsText(state.concernText, value),
      _ => false,
    };
  }

  bool _containsText(String list, String value) =>
      list.split(RegExp(r'[,;|\n]')).map((item) => item.trim()).contains(value);

  void _advance(OnboardingVoiceQuestion question) {
    if (!mounted) return;
    final voiceController = ref.read(onboardingVoiceProvider.notifier);
    final state = ref.read(onboardingProvider);
    final voiceState = ref.read(onboardingVoiceProvider);
    var questions = _questions(state, voiceState);
    var index = questions.indexWhere((item) => item.id == question.id);
    if (question.id == 'reminder_want' ||
        question.id.startsWith('reminder_more_')) {
      final remindersFinished = ref
          .read(onboardingVoiceProvider)
          .remindersFinished;
      if (remindersFinished) {
        final treatmentNoteIndex = questions.indexWhere(
          (item) => item.id == 'treatment_note',
        );
        index = treatmentNoteIndex - 1;
      } else {
        final newReminderIndex = state.medicationReminders.length - 1;
        final newReminderId = 'reminder_name_$newReminderIndex';
        index = questions.indexWhere((item) => item.id == newReminderId) - 1;
      }
      questions = _questions(state, ref.read(onboardingVoiceProvider));
    } else if (question.id.startsWith('reminder_name_') ||
        question.id.startsWith('reminder_time_')) {
      final voiceState = ref.read(onboardingVoiceProvider);
      final targetId = _nextReminderQuestionId(state, voiceState);
      if (targetId == null) {
        ref.read(onboardingProvider.notifier).nextStep();
        return;
      }
      final targetIndex = questions.indexWhere((item) => item.id == targetId);
      if (targetIndex >= 0) {
        voiceController.setQuestion(questions[targetIndex].id);
        return;
      }
    }
    final nextIndex = index + 1;
    if (index < 0 || nextIndex >= questions.length) {
      ref.read(onboardingProvider.notifier).nextStep();
      return;
    }
    voiceController.setQuestion(questions[nextIndex].id);
  }

  String? _nextReminderQuestionId(
    OnboardingState state,
    OnboardingVoiceState voiceState,
  ) {
    if (voiceState.remindersFinished) return 'treatment_note';
    for (var index = 0; index < state.medicationReminders.length; index++) {
      final reminder = state.medicationReminders[index];
      if (reminder.medicineName.trim().isEmpty) return 'reminder_name_$index';
      if (reminder.reminderMinutes.isEmpty) return 'reminder_time_$index';
    }
    if (state.medicationReminders.isNotEmpty &&
        state.medicationReminders.length < 5) {
      return 'reminder_more_${state.medicationReminders.length - 1}';
    }
    return 'treatment_note';
  }

  void _confirmRoutine() {
    final state = ref.read(onboardingProvider);
    final errors = state.routinePreferences.validate();
    if (errors.isNotEmpty) {
      final voice = ref.read(onboardingVoiceProvider.notifier);
      voice.setPhase(OnboardingVoicePhase.error, message: errors.join(' '));
      voice.setQuestion('routine_weekday_wake');
      return;
    }
    ref.read(onboardingProvider.notifier).confirmRoutineAndContinue();
  }

  Future<void> _submitTyped(OnboardingVoiceQuestion question) async {
    final value = _inputController.text.trim();
    await _useManualAnswer(question, value);
  }

  Widget _questionBody(
    BuildContext context,
    OnboardingVoiceQuestion question,
    OnboardingVoiceState voice,
  ) {
    final colors = context.semanticColors;
    final options = question.options;
    final filtered = _optionFilter.trim().isEmpty
        ? options
        : options
              .where(
                (option) => option.label.toLowerCase().contains(
                  _optionFilter.toLowerCase(),
                ),
              )
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondarySoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Image.asset(
                NabiOnboardingMood.guide.assetPath,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                semanticLabel: 'Nabi',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _statusLabel(voice),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (voice.phase == OnboardingVoicePhase.listening)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
        ),
        if (voice.downloadProgress case final progress?) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đang tải bộ nhận dạng dùng ngoại tuyến: ${(progress * 100).round()}%',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        if (voice.transcript.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _VoiceInfoCard(label: 'Mình đã nghe', value: voice.transcript),
        ],
        if (voice.message case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          _VoiceInfoCard(
            label: 'Nabi',
            value: message,
            isError: voice.phase == OnboardingVoicePhase.error,
          ),
        ],
        if (question.kind == OnboardingVoiceAnswerKind.text ||
            question.kind == OnboardingVoiceAnswerKind.number ||
            question.kind == OnboardingVoiceAnswerKind.time) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: ValueKey('onboarding_voice_input_${question.id}'),
            controller: _inputController,
            keyboardType: question.kind == OnboardingVoiceAnswerKind.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: question.kind == OnboardingVoiceAnswerKind.number
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]'))]
                : null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) => ref
                .read(onboardingVoiceProvider.notifier)
                .setDraft(question.id, value),
            decoration: InputDecoration(
              labelText: question.kind == OnboardingVoiceAnswerKind.time
                  ? 'Giờ, ví dụ 07:30'
                  : question.kind == OnboardingVoiceAnswerKind.number
                  ? 'Câu trả lời bằng số'
                  : 'Bạn có thể nhập câu trả lời',
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ],
        if (question.requiresManualSelection && options.length >= 12) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _optionFilter = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm lựa chọn',
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ],
        if (options.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in filtered)
                if (question.kind == OnboardingVoiceAnswerKind.manualMulti)
                  FilterChip(
                    key: Key('onboarding_voice_${question.id}_${option.code}'),
                    selected: _isSelected(
                      question,
                      question.id == 'goals' ||
                              question.id == 'conditions' ||
                              question.id == 'habits'
                          ? option.code
                          : option.label,
                    ),
                    label: Text('${option.emoji} ${option.label}'),
                    onSelected: (_) => _toggleManualOption(
                      question,
                      question.id == 'goals' ||
                              question.id == 'conditions' ||
                              question.id == 'habits'
                          ? option.code
                          : option.label,
                    ),
                  )
                else
                  ChoiceChip(
                    key: Key('onboarding_voice_${question.id}_${option.code}'),
                    selected:
                        question.kind == OnboardingVoiceAnswerKind.manualSingle
                        ? ref.read(onboardingProvider).occupation == option.code
                        : false,
                    label: Text('${option.emoji} ${option.label}'),
                    onSelected: (_) {
                      if (question.kind ==
                          OnboardingVoiceAnswerKind.manualSingle) {
                        _toggleManualOption(question, option.code);
                      } else {
                        unawaited(_useManualAnswer(question, option.label));
                      }
                    },
                  ),
            ],
          ),
        ],
        if (question.requiresManualSelection &&
            question.selectedValues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${question.selectedValues.length} mục đã chọn',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(OnboardingVoiceState voice) => switch (voice.phase) {
    OnboardingVoicePhase.idle => 'Nabi sẽ hỏi, rồi tự bật micro để nghe bạn.',
    OnboardingVoicePhase.preparing =>
      voice.downloadProgress == null
          ? 'Đang chuẩn bị giọng nói trên thiết bị…'
          : 'Đang tải bộ nhận dạng tiếng Việt…',
    OnboardingVoicePhase.speaking => 'Nabi đang hỏi bạn…',
    OnboardingVoicePhase.listening =>
      'Nabi đang lắng nghe. Bạn hãy nói tự nhiên.',
    OnboardingVoicePhase.processing =>
      'Nabi đang xử lý câu trả lời trên thiết bị…',
    OnboardingVoicePhase.manual =>
      'Hãy chọn trực tiếp trên màn hình rồi tiếp tục.',
    OnboardingVoicePhase.error =>
      'Bạn có thể thử lại, nhập câu trả lời hoặc chuyển sang thao tác chạm.',
  };

  Widget _footer(OnboardingVoiceQuestion question, OnboardingVoiceState voice) {
    final manualMulti = question.kind == OnboardingVoiceAnswerKind.manualMulti;
    final typed =
        question.kind == OnboardingVoiceAnswerKind.text ||
        question.kind == OnboardingVoiceAnswerKind.number ||
        question.kind == OnboardingVoiceAnswerKind.time;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (voice.phase == OnboardingVoicePhase.error)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('onboarding_voice_retry'),
              onPressed: () => unawaited(_runQuestion(userRetry: true)),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Thử nói lại'),
            ),
          ),
        if (manualMulti || typed) ...[
          SizedBox(
            width: double.infinity,
            child: NabiPrimaryButton(
              key: Key('onboarding_voice_continue_${question.id}'),
              onPressed: typed
                  ? () => unawaited(_submitTyped(question))
                  : () => _advance(question),
              label: typed ? 'Dùng câu trả lời' : 'Xong câu này',
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
        if (question.optional) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: Key('onboarding_voice_skip_${question.id}'),
            onPressed: () => unawaited(_useManualAnswer(question, 'bỏ qua')),
            child: const Text('Bỏ qua'),
          ),
        ],
        if (question.kind == OnboardingVoiceAnswerKind.command &&
            voice.phase == OnboardingVoicePhase.error)
          TextButton(
            onPressed: () =>
                ref.read(onboardingVoiceProvider.notifier).setTouchMode(),
            child: const Text('Chuyển sang thao tác chạm'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      onboardingVoiceProvider.select((state) => state.questionId),
      (previous, next) {
        if (next == null || next == previous) return;
        _inputQuestionId = null;
        unawaited(_runQuestion());
      },
    );
    final state = ref.watch(onboardingProvider);
    final voice = ref.watch(onboardingVoiceProvider);
    final questions = _questions(state, voice);
    final question =
        questions.where((item) => item.id == voice.questionId).firstOrNull ??
        (questions.isEmpty ? null : questions.first);
    if (question == null) return const SizedBox.shrink();
    _syncInput(question);
    return OnboardingStepShell(
      stepIndex: widget.stepIndex,
      title: question.prompt,
      subtitle: question.optional
          ? 'Câu hỏi không bắt buộc. Bạn có thể nói “bỏ qua”.'
          : 'Nabi hỏi từng câu một; câu trả lời chỉ xử lý trên thiết bị.',
      mood: NabiOnboardingMood.guide,
      onBack: state.currentStep > 0
          ? ref.read(onboardingProvider.notifier).previousStep
          : () {
              ref.read(onboardingVoiceProvider.notifier).setTouchMode();
              context.go(V1RoutePaths.onboardingEntry);
            },
      showNextAction: false,
      showCompanion: false,
      footer: _footer(question, voice),
      child: _questionBody(context, question, voice),
    );
  }
}

class OnboardingVoiceTextScalePage extends ConsumerStatefulWidget {
  const OnboardingVoiceTextScalePage({super.key});

  @override
  ConsumerState<OnboardingVoiceTextScalePage> createState() =>
      _OnboardingVoiceTextScalePageState();
}

class _OnboardingVoiceTextScalePageState
    extends ConsumerState<OnboardingVoiceTextScalePage>
    with WidgetsBindingObserver {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPrompt());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
  }

  Future<void> _startPrompt() async {
    if (_started || !mounted) return;
    _started = true;
    final question = OnboardingVoiceQuestions.textScaleQuestion();
    final voice = ref.read(onboardingVoiceProvider.notifier);
    final runtime = ref.read(onboardingVoiceRuntimeProvider);
    try {
      voice.setPhase(OnboardingVoicePhase.preparing, clearMessage: true);
      await runtime.prepare(
        onDownloadProgress: (progress) => voice.setPhase(
          OnboardingVoicePhase.preparing,
          downloadProgress: progress,
        ),
      );
      if (!mounted) return;
      voice.setPhase(OnboardingVoicePhase.speaking);
      await runtime.speak(question.spokenPrompt);
      if (!mounted) return;
      voice.setPhase(OnboardingVoicePhase.listening);
      final transcript = await runtime.listenAndTranscribe();
      if (!mounted) return;
      final option = OnboardingVoiceParser.choice(transcript, question.options);
      if (option == null) {
        voice.setPhase(
          OnboardingVoicePhase.error,
          transcript: transcript,
          message:
              'Bạn có thể chọn cỡ chữ bằng giọng nói hoặc chạm vào một lựa chọn.',
        );
        return;
      }
      await ref
          .read(appTextScaleControllerProvider.notifier)
          .select(
            AppTextScalePreset.values.firstWhere(
              (item) => item.name == option.code,
            ),
            markConfigured: true,
          );
    } on OnboardingVoicePermissionException {
      if (mounted) {
        voice.setPhase(
          OnboardingVoicePhase.error,
          message: 'Cần cho phép dùng micro để chọn bằng giọng nói.',
        );
      }
    } catch (_) {
      if (mounted) {
        voice.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Chưa thể khởi động giọng nói. Bạn có thể chuyển sang thao tác chạm.',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!ref.read(onboardingVoiceProvider).isVoiceMode) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(onboardingVoiceProvider);
    final textScale =
        ref.watch(appTextScaleControllerProvider).value?.preset ??
        AppTextScalePreset.standard;
    final colors = context.semanticColors;
    final question = OnboardingVoiceQuestions.textScaleQuestion();
    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Dùng thao tác chạm',
                    onPressed: () => ref
                        .read(onboardingVoiceProvider.notifier)
                        .setTouchMode(),
                    icon: const Icon(Icons.touch_app_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cỡ chữ',
                      style: AppTextStyles.heading5.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      NabiOnboardingMood.guide.assetPath,
                      width: 132,
                      height: 132,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading5.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Lần đầu có thể cần tải bộ nhận dạng ngoại tuyến khoảng 31 MB. Bản ghi và câu trả lời được xử lý trên điện thoại, không gửi lên máy chủ.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final option in question.options)
                          ChoiceChip(
                            label: Text(option.label),
                            selected: textScale.name == option.code,
                            onSelected: (_) => unawaited(
                              ref
                                  .read(appTextScaleControllerProvider.notifier)
                                  .select(
                                    AppTextScalePreset.values.firstWhere(
                                      (item) => item.name == option.code,
                                    ),
                                    markConfigured: true,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    if (voice.downloadProgress case final progress?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      LinearProgressIndicator(value: progress),
                    ],
                    if (voice.phase == OnboardingVoicePhase.listening) ...[
                      const SizedBox(height: AppSpacing.md),
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Nabi đang lắng nghe…'),
                    ],
                    if (voice.message case final message?) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.error),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () {
                          _started = false;
                          unawaited(_startPrompt());
                        },
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Thử lại bằng giọng nói'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingConsentVoiceReader extends ConsumerStatefulWidget {
  const OnboardingConsentVoiceReader({super.key});

  @override
  ConsumerState<OnboardingConsentVoiceReader> createState() =>
      _OnboardingConsentVoiceReaderState();
}

class _OnboardingConsentVoiceReaderState
    extends ConsumerState<OnboardingConsentVoiceReader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ref.read(onboardingVoiceProvider).isVoiceMode) return;
      try {
        await ref
            .read(onboardingVoiceRuntimeProvider)
            .speak(
              'Thông tin của bạn. Hồ sơ được lưu trong ứng dụng. Khi dùng AI văn bản hoặc phân tích ảnh, dữ liệu tối thiểu cần cho tác vụ được gửi qua kết nối bảo mật tới máy chủ NanoBio. Ứng dụng không dùng mô hình văn bản hoặc ảnh cục bộ thay thế. Trợ lý ESP ba hai có thể tải Whisper để nhận dạng giọng nói trên điện thoại. Cần đăng nhập để dùng AI của máy chủ. Lưu ý sức khỏe. Nabi gợi ý lối sống, không thay thế chẩn đoán y tế. Hãy chạm vào ô đồng ý trên màn hình nếu bạn muốn tiếp tục.',
            );
      } catch (_) {
        // Consent remains fully available to read on screen.
      }
    });
  }

  @override
  void dispose() {
    if (!ref.read(onboardingVoiceProvider).isVoiceMode) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopSpeech());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class OnboardingReviewVoicePanel extends ConsumerStatefulWidget {
  const OnboardingReviewVoicePanel({super.key, required this.summary});

  final String summary;

  @override
  ConsumerState<OnboardingReviewVoicePanel> createState() =>
      _OnboardingReviewVoicePanelState();
}

class _OnboardingReviewVoicePanelState
    extends ConsumerState<OnboardingReviewVoicePanel>
    with WidgetsBindingObserver {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenForCreate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!ref.read(onboardingVoiceProvider).isVoiceMode) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(ref.read(onboardingVoiceRuntimeProvider).stopAll());
    }
  }

  Future<void> _listenForCreate() async {
    if (_running ||
        !mounted ||
        !ref.read(onboardingVoiceProvider).isVoiceMode) {
      return;
    }
    _running = true;
    final voice = ref.read(onboardingVoiceProvider.notifier);
    final runtime = ref.read(onboardingVoiceRuntimeProvider);
    try {
      voice.setPhase(OnboardingVoicePhase.preparing, clearMessage: true);
      await runtime.prepare(
        onDownloadProgress: (progress) => voice.setPhase(
          OnboardingVoicePhase.preparing,
          downloadProgress: progress,
        ),
      );
      if (!mounted || !ref.read(onboardingVoiceProvider).isVoiceMode) return;
      voice.setPhase(OnboardingVoicePhase.speaking);
      await runtime.speak(
        'Mình đã đọc lại tóm tắt hồ sơ. ${widget.summary} Nếu bạn đồng ý, hãy nói tạo lộ trình.',
      );
      if (!mounted || !ref.read(onboardingVoiceProvider).isVoiceMode) return;
      voice.setPhase(OnboardingVoicePhase.listening);
      final transcript = await runtime.listenAndTranscribe();
      if (!mounted || !ref.read(onboardingVoiceProvider).isVoiceMode) return;
      if (OnboardingVoiceParser.isCreatePlan(transcript)) {
        voice.setPhase(OnboardingVoicePhase.processing, transcript: transcript);
        voice.requestCreatePlan();
      } else {
        voice.setPhase(
          OnboardingVoicePhase.error,
          transcript: transcript,
          message:
              'Khi đã sẵn sàng, hãy nói “Tạo lộ trình” hoặc chạm nút tạo bên dưới.',
        );
      }
    } on OnboardingVoicePermissionException {
      if (mounted) {
        voice.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Micro chưa được cấp quyền. Bạn có thể chạm nút tạo lộ trình.',
        );
      }
    } catch (_) {
      if (mounted) {
        voice.setPhase(
          OnboardingVoicePhase.error,
          message:
              'Không thể nghe câu lệnh lúc này. Bạn có thể chạm nút tạo lộ trình.',
        );
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(onboardingVoiceProvider);
    final colors = context.semanticColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nabi đã đọc tóm tắt. Nói “Tạo lộ trình” để tiếp tục.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (voice.phase == OnboardingVoicePhase.listening)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (voice.downloadProgress case final progress?) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progress),
          ],
          if (voice.message case final message?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: colors.error),
            ),
          ],
          if (voice.phase == OnboardingVoicePhase.error) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => unawaited(_listenForCreate()),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Nghe lại'),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceInfoCard extends StatelessWidget {
  const _VoiceInfoCard({
    required this.label,
    required this.value,
    this.isError = false,
  });

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colors.error.withValues(alpha: 0.08) : colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isError ? colors.error.withValues(alpha: 0.25) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isError ? colors.error : colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

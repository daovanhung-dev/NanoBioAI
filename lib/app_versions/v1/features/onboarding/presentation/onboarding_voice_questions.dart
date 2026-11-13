import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/constants/gender_options.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_voice_provider.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';

enum OnboardingVoiceAnswerKind {
  command,
  text,
  number,
  time,
  singleChoice,
  manualSingle,
  manualMulti,
}

class OnboardingVoiceQuestion {
  const OnboardingVoiceQuestion({
    required this.id,
    required this.prompt,
    required this.kind,
    this.options = const [],
    this.optional = false,
    this.currentValue = '',
    this.selectedValues = const [],
    this.minimum,
    this.maximum,
  });

  final String id;
  final String prompt;
  final OnboardingVoiceAnswerKind kind;
  final List<OnboardingChoiceOption> options;
  final bool optional;
  final String currentValue;
  final List<String> selectedValues;
  final double? minimum;
  final double? maximum;

  bool get requiresManualSelection =>
      kind == OnboardingVoiceAnswerKind.manualSingle ||
      kind == OnboardingVoiceAnswerKind.manualMulti;

  bool get supportsSpokenChoice =>
      kind == OnboardingVoiceAnswerKind.singleChoice;

  String get spokenPrompt {
    if (!supportsSpokenChoice || options.isEmpty) return prompt;
    final choices = options.indexed
        .map((entry) => '${entry.$1 + 1}. ${entry.$2.label}')
        .join('. ');
    return '$prompt Bạn có thể nói tên lựa chọn hoặc số thứ tự. $choices.';
  }
}

abstract final class OnboardingVoiceQuestions {
  static OnboardingVoiceQuestion textScaleQuestion() => OnboardingVoiceQuestion(
    id: 'text_scale',
    prompt: 'Bạn muốn cỡ chữ nào? Hãy nói nhỏ, vừa, lớn hoặc rất lớn.',
    kind: OnboardingVoiceAnswerKind.singleChoice,
    options: [
      for (final preset in AppTextScalePreset.values)
        OnboardingChoiceOption(
          code: preset.name,
          label: preset == AppTextScalePreset.standard ? 'Vừa' : preset.label,
          emoji: '🔤',
        ),
    ],
  );

  static List<OnboardingVoiceQuestion> forStep({
    required int step,
    required OnboardingState state,
    required OnboardingVoiceState voiceState,
  }) {
    return switch (step) {
      0 => [
        const OnboardingVoiceQuestion(
          id: 'welcome_start',
          prompt: 'Khi sẵn sàng, hãy nói bắt đầu để Nabi hỏi bạn từng câu.',
          kind: OnboardingVoiceAnswerKind.command,
        ),
      ],
      1 => _basicInfo(state),
      2 => _goals(state),
      3 => _conditions(state),
      4 => _lifestyle(state),
      5 => _extras(state, voiceState),
      6 => _dailyRoutine(state),
      _ => const [],
    };
  }

  static List<OnboardingVoiceQuestion> _basicInfo(OnboardingState state) => [
    OnboardingVoiceQuestion(
      id: 'full_name',
      prompt: 'Bạn tên là gì?',
      kind: OnboardingVoiceAnswerKind.text,
      currentValue: state.fullName,
    ),
    OnboardingVoiceQuestion(
      id: 'gender',
      prompt: 'Bạn muốn chọn giới tính nào?',
      kind: OnboardingVoiceAnswerKind.singleChoice,
      options: onboardingGenderOptions,
    ),
    OnboardingVoiceQuestion(
      id: 'birth_year',
      prompt: 'Bạn sinh năm nào?',
      kind: OnboardingVoiceAnswerKind.number,
      currentValue: state.birthYear.toString(),
      minimum: 1920,
      maximum: DateTime.now().year - 6,
    ),
    OnboardingVoiceQuestion(
      id: 'occupation',
      prompt: 'Hãy chọn nhóm công việc hoặc sinh hoạt gần nhất trên màn hình.',
      kind: OnboardingVoiceAnswerKind.manualSingle,
      options: OnboardingCatalog.occupations,
      currentValue: state.occupation,
    ),
    OnboardingVoiceQuestion(
      id: 'height',
      prompt: 'Chiều cao của bạn khoảng bao nhiêu xăng ti mét?',
      kind: OnboardingVoiceAnswerKind.number,
      currentValue: state.heightCm.toStringAsFixed(0),
      minimum: 50,
      maximum: 250,
    ),
    OnboardingVoiceQuestion(
      id: 'weight',
      prompt: 'Cân nặng của bạn khoảng bao nhiêu ki lô gam?',
      kind: OnboardingVoiceAnswerKind.number,
      currentValue: state.weightKg.toStringAsFixed(1),
      minimum: 20,
      maximum: 400,
    ),
  ];

  static List<OnboardingVoiceQuestion> _goals(OnboardingState state) => [
    OnboardingVoiceQuestion(
      id: 'goals',
      prompt: 'Hãy chọn một hoặc nhiều mục tiêu sức khỏe trên màn hình.',
      kind: OnboardingVoiceAnswerKind.manualMulti,
      options: OnboardingCatalog.goals,
      selectedValues: state.goals,
    ),
    OnboardingVoiceQuestion(
      id: 'other_goal',
      prompt: 'Bạn có mục tiêu nào khác muốn chia sẻ không? Có thể nói bỏ qua.',
      kind: OnboardingVoiceAnswerKind.text,
      optional: true,
      currentValue: state.otherGoal,
    ),
  ];

  static List<OnboardingVoiceQuestion> _conditions(OnboardingState state) => [
    OnboardingVoiceQuestion(
      id: 'conditions',
      prompt: 'Hãy chọn tình trạng sức khỏe phù hợp trên màn hình.',
      kind: OnboardingVoiceAnswerKind.manualMulti,
      options: OnboardingCatalog.conditions,
      selectedValues: state.conditions,
    ),
    OnboardingVoiceQuestion(
      id: 'other_condition',
      prompt: 'Bạn có lưu ý sức khỏe nào khác không? Có thể nói bỏ qua.',
      kind: OnboardingVoiceAnswerKind.text,
      optional: true,
      currentValue: state.otherCondition,
    ),
  ];

  static List<OnboardingVoiceQuestion> _lifestyle(OnboardingState state) => [
    OnboardingVoiceQuestion(
      id: 'habits',
      prompt: 'Hãy chọn những thói quen thường gặp trên màn hình.',
      kind: OnboardingVoiceAnswerKind.manualMulti,
      options: OnboardingCatalog.habits,
      selectedValues: state.habits,
    ),
    OnboardingVoiceQuestion(
      id: 'sleep_quality',
      prompt: 'Giấc ngủ của bạn thường như thế nào?',
      kind: OnboardingVoiceAnswerKind.singleChoice,
      options: OnboardingOptions.sleepQualityChoices,
    ),
    OnboardingVoiceQuestion(
      id: 'activity_level',
      prompt: 'Mức vận động hằng tuần của bạn thế nào?',
      kind: OnboardingVoiceAnswerKind.singleChoice,
      options: OnboardingOptions.activityChoices,
    ),
    OnboardingVoiceQuestion(
      id: 'water_per_day',
      prompt: 'Mỗi ngày bạn uống khoảng bao nhiêu nước?',
      kind: OnboardingVoiceAnswerKind.singleChoice,
      options: OnboardingOptions.waterChoices,
    ),
  ];

  static List<OnboardingVoiceQuestion> _extras(
    OnboardingState state,
    OnboardingVoiceState voiceState,
  ) {
    final questions = <OnboardingVoiceQuestion>[
      OnboardingVoiceQuestion(
        id: 'allergies',
        prompt:
            'Hãy chọn thực phẩm hoặc thành phần bạn cần tránh trên màn hình.',
        kind: OnboardingVoiceAnswerKind.manualMulti,
        options: OnboardingOptions.allergyChoices,
        selectedValues: _split(state.allergyName),
      ),
      OnboardingVoiceQuestion(
        id: 'allergy_note',
        prompt: 'Bạn có ghi chú dị ứng nào không? Có thể nói bỏ qua.',
        kind: OnboardingVoiceAnswerKind.text,
        optional: true,
        currentValue: state.allergyNote,
      ),
      OnboardingVoiceQuestion(
        id: 'treatments',
        prompt:
            'Hãy chọn tình trạng đang được theo dõi hoặc điều trị trên màn hình.',
        kind: OnboardingVoiceAnswerKind.manualMulti,
        options: OnboardingOptions.treatmentChoices,
        selectedValues: _split(state.treatmentName),
      ),
      OnboardingVoiceQuestion(
        id: 'medications',
        prompt:
            'Hãy chọn thuốc hoặc thực phẩm bổ sung bạn đang dùng trên màn hình.',
        kind: OnboardingVoiceAnswerKind.manualMulti,
        options: OnboardingOptions.medicationChoices,
        selectedValues: _split(state.medicationName),
      ),
    ];

    if (!voiceState.remindersFinished) {
      final reminders = state.medicationReminders;
      if (reminders.isEmpty) {
        questions.add(
          const OnboardingVoiceQuestion(
            id: 'reminder_want',
            prompt: 'Bạn có muốn tạo lịch nhắc uống thuốc không?',
            kind: OnboardingVoiceAnswerKind.singleChoice,
            options: _yesNoChoices,
          ),
        );
      } else {
        for (var index = 0; index < reminders.length; index++) {
          final reminder = reminders[index];
          if (reminder.medicineName.trim().isEmpty) {
            questions.add(
              OnboardingVoiceQuestion(
                id: 'reminder_name_$index',
                prompt: 'Bạn muốn nhắc uống loại thuốc nào?',
                kind: OnboardingVoiceAnswerKind.text,
                currentValue: reminder.medicineName,
              ),
            );
          }
          if (reminder.reminderMinutes.isEmpty) {
            questions.add(
              OnboardingVoiceQuestion(
                id: 'reminder_time_$index',
                prompt: 'Bạn muốn nhận nhắc uống thuốc vào lúc mấy giờ?',
                kind: OnboardingVoiceAnswerKind.time,
              ),
            );
          }
        }
        if (reminders.length < 5) {
          questions.add(
            OnboardingVoiceQuestion(
              id: 'reminder_more_${reminders.length - 1}',
              prompt: 'Bạn có muốn thêm một lịch nhắc thuốc nữa không?',
              kind: OnboardingVoiceAnswerKind.singleChoice,
              options: _yesNoChoices,
            ),
          );
        }
      }
    }

    questions.addAll([
      OnboardingVoiceQuestion(
        id: 'treatment_note',
        prompt:
            'Bạn có ghi chú điều trị nào muốn Nabi lưu ý không? Có thể nói bỏ qua.',
        kind: OnboardingVoiceAnswerKind.text,
        optional: true,
        currentValue: state.treatmentNote,
      ),
      OnboardingVoiceQuestion(
        id: 'concerns',
        prompt: 'Hãy chọn những chủ đề bạn muốn Nabi ưu tiên trên màn hình.',
        kind: OnboardingVoiceAnswerKind.manualMulti,
        options: OnboardingOptions.concernChoices,
        selectedValues: _split(state.concernText),
      ),
    ]);
    return questions;
  }

  static List<OnboardingVoiceQuestion> _dailyRoutine(OnboardingState state) {
    final questions = <OnboardingVoiceQuestion>[];
    _appendDayQuestions(
      questions,
      state.routinePreferences.weekday,
      'weekday',
      'ngày thường',
    );
    _appendDayQuestions(
      questions,
      state.routinePreferences.weekend,
      'weekend',
      'cuối tuần',
    );
    questions.add(
      const OnboardingVoiceQuestion(
        id: 'routine_confirm',
        prompt: 'Bạn đã hoàn tất giờ giấc. Hãy nói xác nhận để tiếp tục.',
        kind: OnboardingVoiceAnswerKind.command,
      ),
    );
    return questions;
  }

  static void _appendDayQuestions(
    List<OnboardingVoiceQuestion> questions,
    RoutineDayTemplate day,
    String key,
    String label,
  ) {
    void time(String id, String question, String value) {
      questions.add(
        OnboardingVoiceQuestion(
          id: 'routine_${key}_$id',
          prompt: question,
          kind: OnboardingVoiceAnswerKind.time,
          currentValue: value,
        ),
      );
    }

    OnboardingVoiceQuestion yesNo(String id, String question) =>
        OnboardingVoiceQuestion(
          id: 'routine_${key}_$id',
          prompt: question,
          kind: OnboardingVoiceAnswerKind.singleChoice,
          options: _yesNoChoices,
        );

    time('wake', 'Bạn thức dậy vào lúc mấy giờ vào $label?', day.wakeTime);
    String mealTime(int index) =>
        index < day.mealTimes.length ? day.mealTimes[index] : '';

    time('meal_0', 'Bạn ăn sáng vào lúc mấy giờ vào $label?', mealTime(0));
    time(
      'meal_1',
      'Bạn ăn nhẹ buổi sáng vào lúc mấy giờ vào $label?',
      mealTime(1),
    );
    time('meal_2', 'Bạn ăn trưa vào lúc mấy giờ vào $label?', mealTime(2));
    questions.add(yesNo('nap_enabled', 'Bạn có ngủ trưa vào $label không?'));
    if (day.napEnabled) {
      final range = day.napRange ?? const RoutineTimeRange(start: '', end: '');
      time(
        'nap_start',
        'Bạn bắt đầu ngủ trưa vào lúc mấy giờ vào $label?',
        range.start,
      );
      time(
        'nap_end',
        'Bạn thức dậy sau giấc trưa vào lúc mấy giờ vào $label?',
        range.end,
      );
    }
    time(
      'meal_3',
      'Bạn ăn nhẹ buổi chiều vào lúc mấy giờ vào $label?',
      mealTime(3),
    );
    time('meal_4', 'Bạn ăn tối vào lúc mấy giờ vào $label?', mealTime(4));
    for (var index = 0; index < 2; index++) {
      final range = index < day.workoutRanges.length
          ? day.workoutRanges[index]
          : const RoutineTimeRange(start: '', end: '');
      final ordinal = index == 0 ? 'thứ nhất' : 'thứ hai';
      time(
        'workout_${index}_start',
        'Buổi tập $ordinal bắt đầu lúc mấy giờ vào $label?',
        range.start,
      );
      time(
        'workout_${index}_end',
        'Buổi tập $ordinal kết thúc lúc mấy giờ vào $label?',
        range.end,
      );
    }
    questions.add(
      yesNo(
        'busy_enabled',
        'Bạn có khoảng thời gian bận cố định vào $label không?',
      ),
    );
    if (day.busyRange != null) {
      time(
        'busy_start',
        'Khoảng bận của bạn bắt đầu lúc mấy giờ vào $label?',
        day.busyRange!.start,
      );
      time(
        'busy_end',
        'Khoảng bận của bạn kết thúc lúc mấy giờ vào $label?',
        day.busyRange!.end,
      );
    }
    time(
      'sleep',
      'Bạn thường đi ngủ vào lúc mấy giờ vào $label?',
      day.sleepTime,
    );
  }

  static const _yesNoChoices = [
    OnboardingChoiceOption(code: 'yes', label: 'Có', emoji: '✅'),
    OnboardingChoiceOption(code: 'no', label: 'Không', emoji: '➖'),
  ];

  static List<String> _split(String value) => value
      .split(RegExp(r'[,;|\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

abstract final class OnboardingVoiceParser {
  static OnboardingChoiceOption? choice(
    String transcript,
    List<OnboardingChoiceOption> options,
  ) {
    final normalized = _fold(transcript);
    if (normalized.isEmpty) return null;
    final matches = options
        .where((option) {
          final label = _fold(option.label);
          return normalized == label ||
              normalized.contains(' $label ') ||
              normalized.startsWith('$label ') ||
              normalized.endsWith(' $label');
        })
        .toList(growable: false);
    if (matches.length == 1) return matches.single;

    final ordinal = _ordinal(normalized);
    if (ordinal != null && ordinal >= 1 && ordinal <= options.length) {
      return options[ordinal - 1];
    }
    return null;
  }

  static double? number(String transcript) {
    final normalized = _fold(transcript).replaceAll(',', '.');
    final match = RegExp(r'(?<!\d)\d+(?:\.\d+)?(?!\d)').firstMatch(normalized);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static int? year(String transcript) {
    final direct = number(transcript)?.round();
    if (direct != null && direct >= 1920 && direct <= DateTime.now().year - 6) {
      return direct;
    }
    final normalized = _fold(transcript);
    if (normalized.contains('hai nghin')) {
      final suffix = _ordinal(normalized.replaceFirst('hai nghin', ''));
      if (suffix != null) return 2000 + suffix;
      return 2000;
    }
    return null;
  }

  static int? timeMinutes(String transcript) {
    var normalized = _fold(transcript);
    normalized = normalized
        .replaceAll('muoi lam', '15')
        .replaceAll('muoi bon', '14')
        .replaceAll('muoi ba', '13')
        .replaceAll('muoi hai', '12')
        .replaceAll('muoi mot', '11')
        .replaceAll('bay muoi', '70')
        .replaceAll('sau muoi', '60')
        .replaceAll('nam muoi', '50')
        .replaceAll('bon muoi', '40')
        .replaceAll('ba muoi', '30')
        .replaceAll('hai muoi', '20')
        .replaceAll('muoi', '10');
    for (final entry in _numberWords.entries) {
      normalized = normalized.replaceAll(
        RegExp('\\b${entry.key}\\b'),
        '${entry.value}',
      );
    }
    final match = RegExp(
      r'(?<!\d)(\d{1,2})(?:\s*(?::|h|gio)\s*(\d{1,2}))?',
    ).firstMatch(normalized);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0');
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    final afternoon = RegExp(r'\b(chieu|trua|toi|dem)\b').hasMatch(normalized);
    final morning = RegExp(r'\bsang\b').hasMatch(normalized);
    final saysHalf = normalized.contains('ruoi');
    var adjustedMinute = saysHalf && match.group(2) == null ? 30 : minute;
    if (afternoon && hour < 12) hour += 12;
    if (normalized.contains('12') && afternoon) hour = 12;
    if (morning && hour == 12) hour = 0;
    if (hour > 23 || adjustedMinute > 59) return null;
    return hour * 60 + adjustedMinute;
  }

  static bool isSkip(String transcript) {
    final text = _fold(transcript);
    return text.contains('bo qua') ||
        text.contains('khong co') ||
        text.contains('khong can') ||
        text == 'khong' ||
        text == 'skip';
  }

  static bool isYes(String transcript) {
    final text = _fold(transcript);
    return text == 'co' ||
        text.startsWith('co ') ||
        text.contains('dong y') ||
        text == 'muon';
  }

  static bool isNo(String transcript) {
    final text = _fold(transcript);
    return text == 'khong' ||
        text.startsWith('khong ') ||
        text.contains('khong muon');
  }

  static bool isStart(String transcript) {
    final text = _fold(transcript);
    return text.contains('bat dau') ||
        text.contains('tiep tuc') ||
        text.contains('san sang');
  }

  static bool isCreatePlan(String transcript) {
    final text = _fold(transcript);
    return text.contains('tao lo trinh') ||
        text.contains('tao lich') ||
        text.contains('bat dau tao') ||
        text.contains('hoan tat');
  }

  static bool isConfirmRoutine(String transcript) {
    final text = _fold(transcript);
    return text.contains('xac nhan') ||
        text.contains('tiep tuc') ||
        text.contains('hoan tat');
  }

  static int? _ordinal(String text) {
    final match = RegExp(
      r'(?:so|thu|lua chon)?\s*(\d{1,2})\b',
    ).firstMatch(text);
    final digit = int.tryParse(match?.group(1) ?? '');
    if (digit != null) return digit;
    for (final entry in _numberWords.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(text)) return entry.value;
    }
    return null;
  }

  static String _fold(String text) {
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    var output = text.toLowerCase();
    for (final entry in groups.entries) {
      for (final character in entry.value.split('')) {
        output = output.replaceAll(character, entry.key);
      }
    }
    return output
        .replaceAll(RegExp(r'[^a-z0-9:., ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _numberWords = <String, int>{
    'khong': 0,
    'mot': 1,
    'hai': 2,
    'ba': 3,
    'bon': 4,
    'tu': 4,
    'nam': 5,
    'sau': 6,
    'bay': 7,
    'tam': 8,
    'chin': 9,
    'muoi': 10,
  };
}

String onboardingVoiceFormatTime(int minuteOfDay) {
  final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

RoutineTimeRange copyRoutineRange(
  RoutineTimeRange? range, {
  String? start,
  String? end,
}) => RoutineTimeRange(
  start: start ?? range?.start ?? '',
  end: end ?? range?.end ?? '',
);

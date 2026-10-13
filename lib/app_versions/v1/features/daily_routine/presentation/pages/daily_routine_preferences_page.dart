import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/daily_routine_preferences.dart';
import '../../domain/entities/exercise_planning_preferences.dart';
import '../../providers/exercise_planning_preferences_provider.dart';
import '../../providers/daily_routine_preferences_provider.dart';
import '../widgets/daily_routine_preferences_editor.dart';
import '../widgets/exercise_planning_preferences_editor.dart';

class DailyRoutinePreferencesPage extends ConsumerStatefulWidget {
  const DailyRoutinePreferencesPage({super.key});

  @override
  ConsumerState<DailyRoutinePreferencesPage> createState() =>
      _DailyRoutinePreferencesPageState();
}

class _DailyRoutinePreferencesPageState
    extends ConsumerState<DailyRoutinePreferencesPage> {
  DailyRoutinePreferences? _draft;
  ExercisePlanningPreferences? _exerciseDraft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(dailyRoutinePreferencesProvider);
    final exerciseAsync = ref.watch(exercisePlanningPreferencesProvider);
    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Tùy chỉnh lịch cá nhân')),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: asyncValue.when(
          loading: () => const Center(
            key: ValueKey('daily-routine-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => _DailyRoutineLoadError(onRetry: _retry),
          data: (saved) {
            final preferences =
                _draft ?? saved ?? DailyRoutinePreferences.defaults();
            final exercisePreferences =
                _exerciseDraft ??
                exerciseAsync.value ??
                const ExercisePlanningPreferences();
            return _EditorBody(
              key: const ValueKey('daily-routine-ready'),
              preferences: preferences,
              saving: _saving,
              exercisePreferences: exercisePreferences,
              exercisePreferencesReady: exerciseAsync.hasValue,
              exercisePreferencesError: exerciseAsync.hasError,
              onChanged: (value) => setState(() => _draft = value),
              onExerciseChanged: (value) =>
                  setState(() => _exerciseDraft = value),
              onRetryExercisePreferences: _retryExercisePreferences,
              onSave: _save,
            );
          },
        ),
      ),
    );
  }

  void _retry() {
    setState(() => _draft = null);
    ref.invalidate(dailyRoutinePreferencesProvider);
  }

  void _retryExercisePreferences() {
    ref.invalidate(exercisePlanningPreferencesProvider);
  }

  Future<void> _save() async {
    final loaded = ref.read(dailyRoutinePreferencesProvider);
    if (loaded.isLoading || loaded.hasError) return;

    final preferences =
        _draft ?? loaded.value ?? DailyRoutinePreferences.defaults();
    final exerciseAsync = ref.read(exercisePlanningPreferencesProvider);
    if (!exerciseAsync.hasValue) return;
    final exercisePreferences =
        _exerciseDraft ??
        exerciseAsync.value ??
        const ExercisePlanningPreferences();
    final exerciseErrors = exercisePreferences.validate();
    if (exerciseErrors.isNotEmpty) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exerciseErrors.first)));
      return;
    }
    final errors = preferences.validate();
    if (errors.isNotEmpty) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.first)));
      return;
    }
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() => _saving = true);
    try {
      await ref
          .read(dailyRoutinePreferencesRepositoryProvider)
          .saveForCurrentUser(preferences);
      await ref
          .read(exercisePlanningPreferencesRepositoryProvider)
          .saveForCurrentUser(exercisePreferences);
      ref.invalidate(dailyRoutinePreferencesProvider);
      ref.invalidate(exercisePlanningPreferencesProvider);
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nabi chưa lưu được lịch cá nhân. Bạn thử lại nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DailyRoutineLoadError extends StatelessWidget {
  const _DailyRoutineLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('daily-routine-error'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: context.semanticColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nabi chưa đọc được lịch cá nhân',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dữ liệu hiện có vẫn được giữ nguyên. Bạn thử tải lại trước khi chỉnh sửa nhé.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  final DailyRoutinePreferences preferences;
  final bool saving;
  final ExercisePlanningPreferences exercisePreferences;
  final bool exercisePreferencesReady;
  final bool exercisePreferencesError;
  final ValueChanged<DailyRoutinePreferences> onChanged;
  final ValueChanged<ExercisePlanningPreferences> onExerciseChanged;
  final VoidCallback onRetryExercisePreferences;
  final VoidCallback onSave;

  const _EditorBody({
    super.key,
    required this.preferences,
    required this.saving,
    required this.exercisePreferences,
    required this.exercisePreferencesReady,
    required this.exercisePreferencesError,
    required this.onChanged,
    required this.onExerciseChanged,
    required this.onRetryExercisePreferences,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      children: [
        Text(
          'Nabi dùng các mốc này cho những ngày được tạo mới. Lịch hiện tại sẽ không bị thay đổi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        DailyRoutinePreferencesEditor(value: preferences, onChanged: onChanged),
        const SizedBox(height: AppSpacing.md),
        ExercisePlanningPreferencesEditor(
          value: exercisePreferences,
          onChanged: onExerciseChanged,
          enabled: exercisePreferencesReady && !saving,
        ),
        if (!exercisePreferencesReady) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            exercisePreferencesError
                ? 'Chưa đọc được tùy chọn vận động. Hãy tải lại trước khi lưu.'
                : 'Đang tải tùy chọn vận động; bạn có thể lưu sau khi tải xong.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (exercisePreferencesError)
            TextButton.icon(
              onPressed: onRetryExercisePreferences,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại tùy chọn vận động'),
            ),
        ],
        const SizedBox(height: AppSpacing.sectionSpacing),
        FilledButton.icon(
          onPressed: saving || !exercisePreferencesReady ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Lưu nhịp sinh hoạt'),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
      ],
    );
  }
}

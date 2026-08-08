import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

class TodayTaskCard extends ConsumerStatefulWidget {
  const TodayTaskCard({required this.task, required this.now, super.key});

  final LifestyleScheduleItemEntity task;
  final DateTime now;

  @override
  ConsumerState<TodayTaskCard> createState() => _TodayTaskCardState();
}

class _TodayTaskCardState extends ConsumerState<TodayTaskCard> {
  bool _isUpdating = false;
  bool _isReplacingMeal = false;

  LifestyleScheduleItemEntity get task => widget.task;

  @override
  Widget build(BuildContext context) {
    final status = task.completionStatusAt(widget.now);
    final presentation = _TaskStatusPresentation.from(
      status,
      context.semanticColors,
    );
    final canToggle = task.isCompleted
        ? task.isWithinCompletionWindow(widget.now)
        : status == CompletionWindowStatus.open;

    return MedicalSurfaceCard(
      key: ValueKey('today-task-${task.id}'),
      elevated: status == CompletionWindowStatus.open,
      borderColor: presentation.color.withValues(alpha: .20),
      semanticLabel:
          '${task.title}. ${presentation.label}. ${task.startTime} đến ${task.endTime}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalIconBadge(
                icon: presentation.icon,
                color: presentation.color,
                backgroundColor: presentation.color.withValues(alpha: .10),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.heading4.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? context.semanticColors.textSecondary
                            : context.semanticColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _timeRange(task),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.semanticColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              MedicalStatusPill(
                label: presentation.label,
                icon: presentation.icon,
                foregroundColor: presentation.color,
                backgroundColor: presentation.color.withValues(alpha: .09),
              ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              task.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _TaskWindowHint(task: task, status: status, now: widget.now),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: canToggle && !_isUpdating && !_isReplacingMeal
                    ? _toggleCompletion
                    : null,
                icon: _isUpdating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(task.isCompleted ? Icons.undo_rounded : Icons.check),
                label: Text(
                  _isUpdating
                      ? 'Đang cập nhật'
                      : task.isCompleted
                      ? 'Hoàn tác'
                      : 'Hoàn thành',
                ),
              ),
              if (task.isMealLinked)
                OutlinedButton.icon(
                  onPressed:
                      !_isUpdating && !_isReplacingMeal && !task.isCompleted
                      ? _replaceMeal
                      : null,
                  icon: _isReplacingMeal
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz_rounded),
                  label: Text(_isReplacingMeal ? 'Đang thay món' : 'Thay món'),
                ),
              TextButton.icon(
                onPressed: _showDetails,
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Chi tiết'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompletion() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final controller = ref.read(lifestyleScheduleControllerProvider.notifier);
      var result = await controller.toggleItem(task);
      if (!mounted) return;

      if (result ==
          LifestyleScheduleToggleResult.requiresNoRewardConfirmation) {
        final confirmed = await _confirmCompletionWithoutReward();
        if (!mounted || confirmed != true) return;
        result = await controller.toggleItem(task, allowWithoutReward: true);
      }
      if (!mounted) return;
      _showToggleResult(result);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<bool?> _confirmCompletionWithoutReward() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hoàn thành không cộng điểm?'),
        content: const Text(
          'Nabi chưa thể xác nhận điều kiện cộng Điểm chăm sóc lúc này. '
          'Bạn vẫn có thể lưu nhiệm vụ đã hoàn thành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Vẫn hoàn thành'),
          ),
        ],
      ),
    );
  }

  void _showToggleResult(LifestyleScheduleToggleResult result) {
    final message = switch (result) {
      LifestyleScheduleToggleResult.completed =>
        'Bạn đã hoàn thành nhiệm vụ này.',
      LifestyleScheduleToggleResult.undone => 'Đã hoàn tác nhiệm vụ.',
      LifestyleScheduleToggleResult.cancelled =>
        'Bạn chưa chọn ảnh minh chứng.',
      LifestyleScheduleToggleResult.requiresNoRewardConfirmation => null,
      LifestyleScheduleToggleResult.pendingRewardSync =>
        'Nhiệm vụ đã lưu. Điểm chăm sóc sẽ đồng bộ khi có mạng.',
      LifestyleScheduleToggleResult.blocked =>
        'Nhiệm vụ chưa thể cập nhật trong thời gian này.',
      LifestyleScheduleToggleResult.ignored => null,
    };

    if (result == LifestyleScheduleToggleResult.blocked) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
    }
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _replaceMeal() async {
    final sourceId = task.sourceId?.trim();
    if (sourceId == null || sourceId.isEmpty || _isReplacingMeal) return;

    setState(() => _isReplacingMeal = true);
    try {
      await ref
          .read(mealPlanControllerProvider.notifier)
          .replaceMealById(sourceId);
      await ref.read(lifestyleScheduleControllerProvider.notifier).refresh();
      ref.invalidate(getMealPlanProvider);
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nabi đã đổi sang món phù hợp khác.')),
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nabi chưa tìm thấy món thay thế phù hợp lúc này.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isReplacingMeal = false);
    }
  }

  void _showDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),
              _DetailLine(
                icon: Icons.schedule_rounded,
                label: 'Thời gian',
                value: _timeRange(task),
              ),
              if (task.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailLine(
                  icon: Icons.notes_rounded,
                  label: 'Hướng dẫn',
                  value: task.description.trim(),
                ),
              ],
              if (task.targetValue > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailLine(
                  icon: Icons.flag_outlined,
                  label: 'Mục tiêu',
                  value:
                      '${_formatTarget(task.targetValue)} ${task.unit.trim()}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskWindowHint extends StatelessWidget {
  const _TaskWindowHint({
    required this.task,
    required this.status,
    required this.now,
  });

  final LifestyleScheduleItemEntity task;
  final CompletionWindowStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      CompletionWindowStatus.open =>
        'Đang trong thời gian xác nhận. Bạn có thể hoàn thành và thêm ảnh minh chứng.',
      CompletionWindowStatus.waiting =>
        'Nhiệm vụ sẽ mở khi đến ${task.startTime}.',
      CompletionWindowStatus.locked =>
        'Thời gian xác nhận đã kết thúc. Kết quả được giữ nguyên.',
      CompletionWindowStatus.completed =>
        task.isWithinCompletionWindow(now)
            ? 'Đã hoàn thành. Bạn vẫn có thể hoàn tác trong cửa sổ hiện tại.'
            : 'Đã hoàn thành và kết quả đã được khóa.',
    };
    final color = switch (status) {
      CompletionWindowStatus.open => context.semanticColors.primary,
      CompletionWindowStatus.waiting => context.semanticColors.info,
      CompletionWindowStatus.locked => context.semanticColors.textSecondary,
      CompletionWindowStatus.completed => context.semanticColors.success,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: color, height: 1.4),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicalIconBadge(
          icon: icon,
          color: context.semanticColors.primary,
          backgroundColor: context.semanticColors.primarySoft,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.semanticColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskStatusPresentation {
  const _TaskStatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _TaskStatusPresentation.from(
    CompletionWindowStatus status,
    AppSemanticColors colors,
  ) {
    return switch (status) {
      CompletionWindowStatus.open => _TaskStatusPresentation(
        label: 'Đang đến giờ',
        icon: Icons.bolt_rounded,
        color: colors.primary,
      ),
      CompletionWindowStatus.waiting => _TaskStatusPresentation(
        label: 'Sắp tới',
        icon: Icons.schedule_rounded,
        color: colors.info,
      ),
      CompletionWindowStatus.completed => _TaskStatusPresentation(
        label: 'Đã xong',
        icon: Icons.check_circle_rounded,
        color: colors.success,
      ),
      CompletionWindowStatus.locked => _TaskStatusPresentation(
        label: 'Đã kết thúc',
        icon: Icons.lock_clock_rounded,
        color: colors.textSecondary,
      ),
    };
  }
}

String _timeRange(LifestyleScheduleItemEntity task) {
  final endTime = task.endTime.trim();
  return endTime.isEmpty ? task.startTime : '${task.startTime} – $endTime';
}

String _formatTarget(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

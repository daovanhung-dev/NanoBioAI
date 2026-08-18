import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_action_type.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/schedule_health_action_policy.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_health_action_page.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_item_detail_page.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/widgets/meal_replacement_picker.dart';
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
    final action = ScheduleHealthActionPolicy.forItem(task);
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
                icon: _actionIcon(action),
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
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
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
          _TaskWindowHint(
            task: task,
            status: status,
            now: widget.now,
            action: action,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: canToggle && !_isUpdating && !_isReplacingMeal
                    ? () => _handlePrimary(action)
                    : null,
                icon: _isUpdating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        task.isCompleted
                            ? Icons.undo_rounded
                            : _actionPrimaryIcon(action),
                      ),
                label: Text(
                  _isUpdating
                      ? 'Đang cập nhật'
                      : task.isCompleted
                          ? 'Hoàn tác'
                          : _primaryLabel(action),
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

  Future<void> _handlePrimary(ScheduleHealthActionType action) async {
    if (_isUpdating) return;

    if (!task.isCompleted &&
        action != ScheduleHealthActionType.photoProof &&
        ScheduleHealthActionPolicy.requiresInput(action)) {
      await _openHealthAction();
      return;
    }

    setState(() => _isUpdating = true);
    try {
      if (action == ScheduleHealthActionType.photoProof) {
        final result = await ref
            .read(lifestyleScheduleControllerProvider.notifier)
            .toggleItem(task);
        if (!mounted) return;
        _showPhotoToggleResult(result);
        return;
      }

      final result = task.isCompleted
          ? await ref.read(dailyHealthHubControllerProvider).undoTask(task)
          : await ref
              .read(dailyHealthHubControllerProvider)
              .completeTask(item: task);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openHealthAction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LifestyleScheduleHealthActionPage(initialItem: task),
      ),
    );
  }

  void _showPhotoToggleResult(LifestyleScheduleToggleResult result) {
    final message = switch (result) {
      LifestyleScheduleToggleResult.completed =>
        'Bạn đã hoàn thành nhiệm vụ và hệ thống đã xác nhận Điểm chăm sóc.',
      LifestyleScheduleToggleResult.undone => 'Đã hoàn tác nhiệm vụ.',
      LifestyleScheduleToggleResult.cancelled =>
        'Bạn chưa chọn ảnh minh chứng.',
      LifestyleScheduleToggleResult.pendingRewardSync =>
        'Ảnh đã lưu. Điểm chăm sóc sẽ đồng bộ khi có mạng.',
      LifestyleScheduleToggleResult.blocked =>
        'Nabi chưa thể cập nhật nhiệm vụ này lúc này.',
      LifestyleScheduleToggleResult.ignored => null,
    };

    if (result == LifestyleScheduleToggleResult.blocked) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _replaceMeal() async {
    final sourceId = task.sourceId?.trim();
    if (sourceId == null || sourceId.isEmpty || _isReplacingMeal) return;

    setState(() => _isReplacingMeal = true);
    try {
      final controller = ref.read(mealPlanControllerProvider.notifier);
      final result = await showMealReplacementPicker(
        context: context,
        candidatesFuture: controller.loadReplacementCandidates(sourceId),
        onConfirm: (candidate) => controller.replaceMealByCatalogCode(
          mealId: sourceId,
          catalogCode: candidate.code,
        ),
      );
      if (result == null || !mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      final message = switch (result.syncStatus) {
        MealReplacementSyncStatus.synced => 'Đã đổi món và đồng bộ.',
        MealReplacementSyncStatus.pending =>
          'Đã đổi món. Dữ liệu sẽ được đồng bộ khi kết nối ổn định.',
        MealReplacementSyncStatus.localOnly => 'Đã đổi món trên thiết bị.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _showDetails() async {
    final action = ScheduleHealthActionPolicy.forItem(task);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => action == ScheduleHealthActionType.photoProof
            ? LifestyleScheduleItemDetailPage(initialItem: task)
            : LifestyleScheduleHealthActionPage(initialItem: task),
      ),
    );
  }
}

class _TaskWindowHint extends StatelessWidget {
  const _TaskWindowHint({
    required this.task,
    required this.status,
    required this.now,
    required this.action,
  });

  final LifestyleScheduleItemEntity task;
  final CompletionWindowStatus status;
  final DateTime now;
  final ScheduleHealthActionType action;

  @override
  Widget build(BuildContext context) {
    final completionCopy = action == ScheduleHealthActionType.photoProof
        ? 'Bạn có thể chụp ảnh minh chứng để xác nhận.'
        : 'Bạn có thể ghi nhận theo hướng dẫn của nhiệm vụ.';
    final text = switch (status) {
      CompletionWindowStatus.open => completionCopy,
      CompletionWindowStatus.waiting =>
        'Nhiệm vụ sẽ mở khi đến ${task.startTime}.',
      CompletionWindowStatus.locked =>
        'Thời gian xác nhận đã kết thúc. Kết quả được giữ nguyên.',
      CompletionWindowStatus.completed => task.isWithinCompletionWindow(now)
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

IconData _actionIcon(ScheduleHealthActionType action) => switch (action) {
      ScheduleHealthActionType.photoProof => Icons.photo_camera_rounded,
      ScheduleHealthActionType.quickComplete => Icons.check_circle_outline,
      ScheduleHealthActionType.hydration => Icons.water_drop_rounded,
      ScheduleHealthActionType.moodStress => Icons.mood_rounded,
      ScheduleHealthActionType.sleepCheckIn => Icons.bedtime_rounded,
      ScheduleHealthActionType.weightCheckIn => Icons.monitor_weight_outlined,
    };

IconData _actionPrimaryIcon(ScheduleHealthActionType action) => switch (action) {
      ScheduleHealthActionType.photoProof => Icons.photo_camera_rounded,
      ScheduleHealthActionType.hydration => Icons.water_drop_rounded,
      ScheduleHealthActionType.moodStress => Icons.mood_rounded,
      ScheduleHealthActionType.sleepCheckIn => Icons.bedtime_rounded,
      ScheduleHealthActionType.weightCheckIn => Icons.monitor_weight_outlined,
      ScheduleHealthActionType.quickComplete => Icons.check_rounded,
    };

String _primaryLabel(ScheduleHealthActionType action) => switch (action) {
      ScheduleHealthActionType.photoProof => 'Chụp ảnh',
      ScheduleHealthActionType.hydration => 'Ghi nhận nước',
      ScheduleHealthActionType.moodStress => 'Check-in cảm xúc',
      ScheduleHealthActionType.sleepCheckIn => 'Ghi nhận ngủ',
      ScheduleHealthActionType.weightCheckIn => 'Ghi cân nặng',
      ScheduleHealthActionType.quickComplete => 'Hoàn thành',
    };

String _timeRange(LifestyleScheduleItemEntity task) {
  final endTime = task.endTime.trim();
  return endTime.isEmpty ? task.startTime : '${task.startTime} – $endTime';
}

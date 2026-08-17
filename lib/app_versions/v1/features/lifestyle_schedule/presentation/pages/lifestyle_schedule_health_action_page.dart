import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/manual_health_task_draft.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../domain/services/schedule_health_action_policy.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/daily_health_hub_controller.dart';
import '../widgets/manual_health_task_sheet.dart';

class LifestyleScheduleHealthActionPage extends ConsumerStatefulWidget {
  final LifestyleScheduleItemEntity initialItem;

  const LifestyleScheduleHealthActionPage({
    super.key,
    required this.initialItem,
  });

  @override
  ConsumerState<LifestyleScheduleHealthActionPage> createState() =>
      _LifestyleScheduleHealthActionPageState();
}

class _LifestyleScheduleHealthActionPageState
    extends ConsumerState<LifestyleScheduleHealthActionPage> {
  late LifestyleScheduleItemEntity _lastItem;
  final _valueController = TextEditingController();
  String _mood = 'neutral';
  double _stress = 3;
  bool _submitting = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _lastItem = widget.initialItem;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(lifestyleScheduleControllerProvider);
    final items = schedule.whenOrNull(data: (value) => value.summary.items);
    if (items != null) {
      for (final item in items) {
        if (item.id == widget.initialItem.id) {
          _lastItem = item;
          break;
        }
      }
    }

    final item = _lastItem;
    final action = ScheduleHealthActionPolicy.forItem(item);
    final now = ref.watch(lifestyleScheduleClockProvider)();
    final status = item.completionStatusAt(now);

    return MedicalPageScaffold(
      ambientBackground: false,
      appBar: AppBar(
        title: const Text('Ghi nhận nhiệm vụ'),
        actions: item.isManualHealthTask && !item.isCompleted
            ? [
                IconButton(
                  tooltip: 'Sửa nhiệm vụ',
                  onPressed: _submitting ? null : () => _editManual(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Xóa nhiệm vụ',
                  onPressed: _submitting ? null : () => _deleteManual(item),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacingTokens.pagePadding,
          AppSpacingTokens.itemSpacingLarge,
          AppSpacingTokens.pagePadding,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TaskHeader(item: item, action: action, status: status),
                const SizedBox(height: AppSpacingTokens.sectionSpacing),
                _TaskInfo(item: item, action: action),
                const SizedBox(height: AppSpacingTokens.sectionSpacing),
                if (!item.isCompleted && status == CompletionWindowStatus.open)
                  _actionInput(action)
                else
                  _StatusGuidance(item: item, status: status),
                const SizedBox(height: AppSpacingTokens.sectionSpacing),
                _primaryAction(item: item, action: action, now: now),
                if (item.isManualHealthTask) ...[
                  const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
                  Text(
                    _manualRepeatLabel(item),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionInput(ScheduleHealthActionType action) {
    switch (action) {
      case ScheduleHealthActionType.hydration:
        return _InputCard(
          title: 'Bạn vừa uống bao nhiêu?',
          subtitle: 'Chọn nhanh lượng nước vừa dùng.',
          child: Wrap(
            spacing: AppSpacingTokens.itemSpacing,
            runSpacing: AppSpacingTokens.itemSpacing,
            children: [
              FilledButton.tonal(
                onPressed: _submitting ? null : () => _completeWater(250),
                child: const Text('+250 ml'),
              ),
              FilledButton.tonal(
                onPressed: _submitting ? null : () => _completeWater(500),
                child: const Text('+500 ml'),
              ),
            ],
          ),
        );
      case ScheduleHealthActionType.moodStress:
        return _InputCard(
          title: 'Check-in cảm xúc',
          subtitle: 'Ghi nhận ngắn, không phán xét.',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _mood,
                decoration: const InputDecoration(labelText: 'Cảm xúc'),
                items: const [
                  DropdownMenuItem(value: 'very_good', child: Text('Rất tốt')),
                  DropdownMenuItem(value: 'good', child: Text('Tốt')),
                  DropdownMenuItem(value: 'neutral', child: Text('Bình thường')),
                  DropdownMenuItem(value: 'tired', child: Text('Hơi mệt')),
                  DropdownMenuItem(value: 'stressed', child: Text('Căng thẳng')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _mood = value);
                      },
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Mức căng thẳng: ${_stress.round()}/5'),
              ),
              Slider(
                value: _stress,
                min: 1,
                max: 5,
                divisions: 4,
                label: _stress.round().toString(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _stress = value),
              ),
            ],
          ),
        );
      case ScheduleHealthActionType.sleepCheckIn:
        return _InputCard(
          title: 'Giấc ngủ gần nhất',
          subtitle: 'Nhập thời lượng bạn muốn ghi lại.',
          child: TextField(
            controller: _valueController,
            enabled: !_submitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(
              labelText: 'Thời lượng ngủ',
              suffixText: 'giờ',
            ),
          ),
        );
      case ScheduleHealthActionType.weightCheckIn:
        return _InputCard(
          title: 'Cân nặng',
          subtitle: 'Chỉ ghi nhận khi bạn chủ động muốn theo dõi.',
          child: TextField(
            controller: _valueController,
            enabled: !_submitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(
              labelText: 'Cân nặng',
              suffixText: 'kg',
            ),
          ),
        );
      case ScheduleHealthActionType.quickComplete:
        return const _InputCard(
          title: 'Xác nhận nhanh',
          subtitle: 'Không cần nhập thêm dữ liệu cho mốc chăm sóc này.',
          child: SizedBox.shrink(),
        );
      case ScheduleHealthActionType.photoProof:
        return const SizedBox.shrink();
    }
  }

  Widget _primaryAction({
    required LifestyleScheduleItemEntity item,
    required ScheduleHealthActionType action,
    required DateTime now,
  }) {
    if (item.isCompleted) {
      final canUndo = item.isWithinCompletionWindow(now);
      return OutlinedButton.icon(
        key: const ValueKey('health-action-undo'),
        onPressed: _submitting || !canUndo ? null : () => _undo(item),
        icon: const Icon(Icons.undo_rounded),
        label: Text(canUndo ? 'Hoàn tác nhiệm vụ' : 'Đã hoàn thành'),
      );
    }

    if (!item.isWithinCompletionWindow(now)) {
      return const FilledButton(
        onPressed: null,
        child: Text('Chưa thể xác nhận'),
      );
    }

    if (action == ScheduleHealthActionType.hydration) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      key: const ValueKey('health-action-complete'),
      onPressed: _submitting ? null : () => _complete(item, action),
      icon: _submitting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_rounded),
      label: const Text('Hoàn thành nhiệm vụ'),
    );
  }

  Future<void> _completeWater(int amount) async {
    await _run(
      () => ref.read(dailyHealthHubControllerProvider).completeTask(
            item: _lastItem,
            input: DailyHealthCheckInInput(waterDeltaMl: amount),
          ),
    );
  }

  Future<void> _complete(
    LifestyleScheduleItemEntity item,
    ScheduleHealthActionType action,
  ) async {
    final input = switch (action) {
      ScheduleHealthActionType.moodStress => DailyHealthCheckInInput(
          mood: _mood,
          stressLevel: _stress.round(),
        ),
      ScheduleHealthActionType.sleepCheckIn => DailyHealthCheckInInput(
          sleepHours: double.tryParse(_valueController.text.trim()),
        ),
      ScheduleHealthActionType.weightCheckIn => DailyHealthCheckInInput(
          weightKg: double.tryParse(_valueController.text.trim()),
        ),
      _ => const DailyHealthCheckInInput(),
    };
    await _run(
      () => ref.read(dailyHealthHubControllerProvider).completeTask(
            item: item,
            input: input,
          ),
    );
  }

  Future<void> _undo(LifestyleScheduleItemEntity item) async {
    await _run(
      () => ref.read(dailyHealthHubControllerProvider).undoTask(item),
    );
  }

  Future<void> _run(
    Future<DailyHealthHubActionResult> Function() operation,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await operation();
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _editManual(LifestyleScheduleItemEntity item) async {
    await showManualHealthTaskSheet(
      context: context,
      ref: ref,
      initialDate: DateTime.tryParse(item.scheduleDate) ?? DateTime.now(),
      existingItem: item,
    );
  }

  Future<void> _deleteManual(LifestyleScheduleItemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhiệm vụ tự tạo?'),
        content: const Text(
          'Nhiệm vụ này và các lần lặp từ ngày hiện tại trở đi sẽ được xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final result = await ref.read(dailyHealthHubControllerProvider).deleteManualTask(item);
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.succeeded) Navigator.of(context).pop();
  }

  String _manualRepeatLabel(LifestyleScheduleItemEntity item) {
    final metadata = ManualHealthTaskMetadata.tryParse(item.sourceId);
    final repeat = switch (metadata?.repeat) {
      ManualHealthTaskRepeat.daily => 'Lặp mỗi ngày trong chu kỳ 7 ngày',
      ManualHealthTaskRepeat.weekdays => 'Lặp vào ngày thường',
      ManualHealthTaskRepeat.weekends => 'Lặp vào cuối tuần',
      _ => 'Nhiệm vụ một lần',
    };
    final reminder = metadata?.reminderEnabled == false ? 'không nhắc' : 'có nhắc';
    return '$repeat • $reminder';
  }
}

class _TaskHeader extends StatelessWidget {
  final LifestyleScheduleItemEntity item;
  final ScheduleHealthActionType action;
  final CompletionWindowStatus status;

  const _TaskHeader({
    required this.item,
    required this.action,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vietnameseSystemUiText(
              item.title,
              fallback: 'Nhiệm vụ chăm sóc sức khỏe',
            ),
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacing),
          Wrap(
            spacing: AppSpacingTokens.itemSpacing,
            runSpacing: AppSpacingTokens.itemSpacing,
            children: [
              _Pill(text: _statusLabel(status), color: color),
              _Pill(text: action.label, color: AppColorTokens.primary),
              if (item.isManualHealthTask)
                const _Pill(text: 'Tự tạo', color: AppColorTokens.tertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskInfo extends StatelessWidget {
  final LifestyleScheduleItemEntity item;
  final ScheduleHealthActionType action;

  const _TaskInfo({required this.item, required this.action});

  @override
  Widget build(BuildContext context) {
    final description = vietnameseSystemUiText(
      item.description,
      fallback: ScheduleHealthActionPolicy.encouragement(action),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18),
              const SizedBox(width: AppSpacingTokens.itemSpacing),
              Text(_timeRange(item), style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          Text(description, style: AppTextStyles.bodyMedium.copyWith(height: 1.45)),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          Text(
            'Điểm chăm sóc được xác nhận ở hệ thống sau khi dữ liệu hợp lệ; ứng dụng không tự cộng điểm.',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _InputCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          child,
        ],
      ),
    );
  }
}

class _StatusGuidance extends StatelessWidget {
  final LifestyleScheduleItemEntity item;
  final CompletionWindowStatus status;

  const _StatusGuidance({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      CompletionWindowStatus.waiting => 'Nhiệm vụ chưa đến giờ. Bạn có thể quay lại khi cửa sổ xác nhận mở.',
      CompletionWindowStatus.locked => 'Cửa sổ xác nhận đã kết thúc. Dữ liệu lịch sử vẫn được giữ nguyên.',
      CompletionWindowStatus.completed => 'Nhiệm vụ đã được ghi nhận hoàn thành.',
      CompletionWindowStatus.open => 'Bạn có thể ghi nhận nhiệm vụ ngay bây giờ.',
    };
    return _InputCard(
      title: _statusLabel(status),
      subtitle: text,
      child: const SizedBox.shrink(),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

String _statusLabel(CompletionWindowStatus status) => switch (status) {
      CompletionWindowStatus.waiting => 'Sắp tới',
      CompletionWindowStatus.open => 'Đang đến giờ',
      CompletionWindowStatus.locked => 'Đã kết thúc',
      CompletionWindowStatus.completed => 'Đã hoàn thành',
    };

Color _statusColor(BuildContext context, CompletionWindowStatus status) =>
    switch (status) {
      CompletionWindowStatus.waiting => AppColorTokens.info,
      CompletionWindowStatus.open => AppColorTokens.primary,
      CompletionWindowStatus.locked => Theme.of(context).colorScheme.onSurfaceVariant,
      CompletionWindowStatus.completed => AppColorTokens.success,
    };

String _timeRange(LifestyleScheduleItemEntity item) {
  final start = item.startTime.trim().isEmpty ? '--:--' : item.startTime;
  final end = item.endTime.trim();
  return end.isEmpty ? start : '$start – $end';
}

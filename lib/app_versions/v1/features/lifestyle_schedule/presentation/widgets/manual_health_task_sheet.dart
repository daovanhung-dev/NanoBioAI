import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/manual_health_task_draft.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../providers/lifestyle_schedule_provider.dart';

Future<bool> showManualHealthTaskSheet({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime initialDate,
  LifestyleScheduleItemEntity? existingItem,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ManualHealthTaskSheet(
      initialDate: initialDate,
      existingItem: existingItem,
    ),
  );
  return result == true;
}


class _ManualHealthPreset {
  final String label;
  final String title;
  final String description;
  final ScheduleHealthActionType action;

  const _ManualHealthPreset({
    required this.label,
    required this.title,
    required this.description,
    this.action = ScheduleHealthActionType.quickComplete,
  });
}

class ManualHealthTaskSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final LifestyleScheduleItemEntity? existingItem;

  const ManualHealthTaskSheet({
    super.key,
    required this.initialDate,
    this.existingItem,
  });

  @override
  ConsumerState<ManualHealthTaskSheet> createState() =>
      _ManualHealthTaskSheetState();
}

class _ManualHealthTaskSheetState extends ConsumerState<ManualHealthTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late TimeOfDay _time;
  late ScheduleHealthActionType _action;
  late String _repeat;
  late bool _reminderEnabled;
  bool _saving = false;

  static const _allowedActions = <ScheduleHealthActionType>[
    ScheduleHealthActionType.quickComplete,
    ScheduleHealthActionType.hydration,
    ScheduleHealthActionType.moodStress,
    ScheduleHealthActionType.sleepCheckIn,
    ScheduleHealthActionType.weightCheckIn,
  ];


  static const _wellnessPresets = <_ManualHealthPreset>[
    _ManualHealthPreset(
      label: 'Nghỉ mắt',
      title: 'Nghỉ mắt 5 phút',
      description: 'Rời màn hình, nhìn xa và cho mắt nghỉ trong vài phút.',
    ),
    _ManualHealthPreset(
      label: 'Giãn cơ',
      title: 'Giãn cơ 5 phút',
      description: 'Thả lỏng vai, cổ, lưng và vận động nhẹ nhàng.',
    ),
    _ManualHealthPreset(
      label: 'Hít thở',
      title: 'Hít thở chậm 3 phút',
      description: 'Dành vài phút hít thở chậm và thả lỏng cơ thể.',
    ),
    _ManualHealthPreset(
      label: 'Đi bộ',
      title: 'Đi bộ nhẹ 10 phút',
      description: 'Đi bộ ở nhịp thoải mái phù hợp với thể trạng hiện tại.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    final metadata = ManualHealthTaskMetadata.tryParse(existing?.sourceId);
    final today = DateUtils.dateOnly(
      ref.read(lifestyleScheduleClockProvider)(),
    );
    final requestedInitial = DateUtils.dateOnly(widget.initialDate);
    _date = existing == null
        ? (requestedInitial.isBefore(today) ? today : requestedInitial)
        : DateTime.tryParse(existing.scheduleDate) ?? requestedInitial;
    _time = _parseTime(existing?.startTime) ?? _defaultTime();
    _action = metadata?.actionType ?? ScheduleHealthActionType.quickComplete;
    _repeat = metadata?.repeat ?? ManualHealthTaskRepeat.once;
    _reminderEnabled = metadata?.reminderEnabled ?? true;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingTokens.pagePadding,
        AppSpacingTokens.sectionSpacing,
        AppSpacingTokens.pagePadding,
        bottom + AppSpacingTokens.sectionSpacing,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existingItem == null
                          ? 'Thêm nhiệm vụ sức khỏe'
                          : 'Sửa nhiệm vụ sức khỏe',
                      style: AppTextStyles.heading2,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacing),
              Text(
                'Nhiệm vụ tự tạo được lưu trong lịch cá nhân. Điểm chăm sóc chỉ được ghi khi hệ thống xác nhận đủ điều kiện.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacingTokens.sectionSpacing),
              if (widget.existingItem == null) ...[
                Text('Gợi ý chăm sóc nhanh', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Wrap(
                  spacing: AppSpacingTokens.itemSpacing,
                  runSpacing: AppSpacingTokens.itemSpacing,
                  children: _wellnessPresets
                      .map(
                        (preset) => ActionChip(
                          label: Text(preset.label),
                          onPressed: _saving ? null : () => _applyPreset(preset),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              ],
              DropdownButtonFormField<ScheduleHealthActionType>(
                value: _action,
                decoration: const InputDecoration(labelText: 'Cách ghi nhận'),
                items: _allowedActions
                    .map(
                      (action) => DropdownMenuItem(
                        value: action,
                        child: Text(action.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _action = value);
                      },
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              TextFormField(
                controller: _titleController,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Tên nhiệm vụ',
                  hintText: 'Ví dụ: Nghỉ mắt 5 phút',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Nhập tên nhiệm vụ ít nhất 2 ký tự.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacing),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(_formatDate(_date)),
                    ),
                  ),
                  const SizedBox(width: AppSpacingTokens.itemSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(_formatTime(_time)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              DropdownButtonFormField<String>(
                value: _repeat,
                decoration: const InputDecoration(labelText: 'Lặp lại'),
                items: const [
                  DropdownMenuItem(
                    value: ManualHealthTaskRepeat.once,
                    child: Text('Một lần'),
                  ),
                  DropdownMenuItem(
                    value: ManualHealthTaskRepeat.daily,
                    child: Text('Mỗi ngày trong 7 ngày tới'),
                  ),
                  DropdownMenuItem(
                    value: ManualHealthTaskRepeat.weekdays,
                    child: Text('Ngày thường trong 7 ngày tới'),
                  ),
                  DropdownMenuItem(
                    value: ManualHealthTaskRepeat.weekends,
                    child: Text('Cuối tuần trong 7 ngày tới'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _repeat = value);
                      },
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _reminderEnabled,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _reminderEnabled = value),
                title: const Text('Nhắc khi đến giờ'),
                subtitle: const Text(
                  'Bạn có thể tắt nhắc riêng cho nhiệm vụ tự tạo này.',
                ),
              ),
              const SizedBox(height: AppSpacingTokens.sectionSpacing),
              FilledButton.icon(
                key: const ValueKey('manual-health-task-save'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(
                  widget.existingItem == null
                      ? 'Thêm vào lịch'
                      : 'Lưu thay đổi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyPreset(_ManualHealthPreset preset) {
    _titleController.text = preset.title;
    _descriptionController.text = preset.description;
    setState(() => _action = preset.action);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(
      ref.read(lifestyleScheduleClockProvider)(),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = ManualHealthTaskDraft(
      firstDate: _date,
      startTime: _formatTime(_time),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryFor(_action),
      actionType: _action,
      repeat: _repeat,
      reminderEnabled: _reminderEnabled,
    );
    final controller = ref.read(dailyHealthHubControllerProvider);
    final result = widget.existingItem == null
        ? await controller.createManualTask(draft)
        : await controller.replaceManualTask(
            existingItem: widget.existingItem!,
            draft: draft,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.succeeded) Navigator.of(context).pop(true);
  }

  TimeOfDay _defaultTime() {
    final now = ref.read(lifestyleScheduleClockProvider)();
    final candidate = now.add(const Duration(hours: 1));
    return TimeOfDay(hour: candidate.hour, minute: candidate.minute);
  }

  TimeOfDay? _parseTime(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _categoryFor(ScheduleHealthActionType action) => switch (action) {
        ScheduleHealthActionType.hydration => LifestyleScheduleCategories.water,
        ScheduleHealthActionType.moodStress => LifestyleScheduleCategories.mind,
        ScheduleHealthActionType.sleepCheckIn => LifestyleScheduleCategories.sleep,
        ScheduleHealthActionType.weightCheckIn => LifestyleScheduleCategories.metric,
        _ => LifestyleScheduleCategories.routine,
      };

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

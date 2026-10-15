import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/notification_settings_provider.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/providers/medication_reminder_settings_provider.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('notification_settings_back_button'),
          tooltip: 'Quay về',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(
              Uri(
                path: V1RoutePaths.menu,
                queryParameters: const {'tab': 'settings'},
              ).toString(),
            );
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Quản lý thông báo'),
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Đang tải cài đặt nhắc nhở…',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 32,
                    color: context.semanticColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Chưa tải được cài đặt nhắc nhở',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bạn có thể thử lại ngay.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.invalidate(notificationSettingsControllerProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (preferences) =>
              _NotificationSettingsBody(preferences: preferences),
        ),
      ),
    );
  }
}

class _NotificationSettingsBody extends ConsumerWidget {
  const _NotificationSettingsBody({required this.preferences});

  final NabiHealthReminderPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth >= 720
            ? 640.0
            : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.xxxl,
              ),
              children: [
                _SettingsCard(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: _SettingIconBadge(
                        icon: Icons.notifications_active_rounded,
                        active: preferences.masterEnabled,
                      ),
                      title: const Text('Cho phép Nabi nhắc bạn'),
                      subtitle: const Text(
                        'Công tắc tổng. Tắt sẽ hủy các thông báo đang chờ nhưng giữ lựa chọn từng loại.',
                      ),
                      value: preferences.masterEnabled,
                      onChanged: (value) async {
                        final granted = await controller.setMasterEnabled(
                          value,
                        );
                        if (!context.mounted || granted || !value) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bạn cần cho phép thông báo trong cài đặt thiết bị để Nabi có thể nhắc.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MedicationReminderSettingsSection(
                  masterEnabled: preferences.masterEnabled,
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionTitle('Các loại nhắc nhở'),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    _SwitchRow(
                      icon: Icons.event_available_rounded,
                      title: 'Lịch trình cá nhân',
                      subtitle:
                          'Giữ nhắc bữa ăn, vận động và nhiệm vụ hiện có.',
                      value: preferences.scheduleEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setScheduleEnabled,
                    ),
                    const Divider(indent: 56),
                    _SwitchRow(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Hỏi thăm tình trạng sức khỏe',
                      subtitle: 'Mặc định mỗi 1 giờ trong khung giờ bạn chọn.',
                      value: preferences.healthCheckInEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setHealthCheckInEnabled,
                    ),
                    if (preferences.healthCheckInEnabled) ...[
                      _ChoiceRow<int>(
                        label: 'Tần suất hỏi thăm',
                        value: preferences.healthCheckInIntervalMinutes,
                        values: const [60, 120, 180, 240],
                        labelOf: (value) => '${value ~/ 60} giờ',
                        onChanged: controller.setHealthCheckInInterval,
                      ),
                      _TimeWindowRow(
                        label: 'Khung giờ hỏi thăm',
                        startMinutes: preferences.healthCheckInStartMinutes,
                        endMinutes: preferences.healthCheckInEndMinutes,
                        onChanged: controller.setHealthCheckInWindow,
                      ),
                    ],
                    const Divider(indent: 56),
                    _SwitchRow(
                      icon: Icons.flag_outlined,
                      title: 'Xem lại mục tiêu',
                      subtitle: 'Hỏi vào ngày 01 và ngày 15 hằng tháng.',
                      value: preferences.goalReviewEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setGoalReviewEnabled,
                    ),
                    if (preferences.goalReviewEnabled)
                      _SingleTimeRow(
                        label: 'Giờ hỏi mục tiêu',
                        minutes: preferences.goalReviewMinutes,
                        onChanged: controller.setGoalReviewTime,
                      ),
                    const Divider(indent: 56),
                    _SwitchRow(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Cập nhật thông tin thay đổi',
                      subtitle:
                          'Hỏi lại cân nặng, chiều cao, vận động, giấc ngủ và lượng nước.',
                      value: preferences.profileReviewEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setProfileReviewEnabled,
                    ),
                    if (preferences.profileReviewEnabled) ...[
                      _ChoiceRow<int>(
                        label: 'Chu kỳ hỏi lại',
                        value: preferences.profileReviewIntervalDays,
                        values: const [15, 30, 60, 90],
                        labelOf: (value) => '$value ngày',
                        onChanged: controller.setProfileReviewIntervalDays,
                      ),
                      _SingleTimeRow(
                        label: 'Giờ hỏi cập nhật',
                        minutes: preferences.profileReviewMinutes,
                        onChanged: controller.setProfileReviewTime,
                      ),
                    ],
                    const Divider(indent: 56),
                    _SwitchRow(
                      icon: Icons.water_drop_outlined,
                      title: 'Nhắc uống nước',
                      subtitle:
                          'Tự dừng trong ngày khi mục tiêu nước đã hoàn thành.',
                      value: preferences.waterReminderEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setWaterReminderEnabled,
                    ),
                    if (preferences.waterReminderEnabled) ...[
                      _ChoiceRow<int>(
                        label: 'Tần suất uống nước',
                        value: preferences.waterReminderIntervalMinutes,
                        values: const [60, 90, 120, 180],
                        labelOf: (value) => value == 90
                            ? '1 giờ 30 phút'
                            : '${value ~/ 60} giờ',
                        onChanged: controller.setWaterReminderInterval,
                      ),
                      _TimeWindowRow(
                        label: 'Khung giờ uống nước',
                        startMinutes: preferences.waterReminderStartMinutes,
                        endMinutes: preferences.waterReminderEndMinutes,
                        onChanged: controller.setWaterReminderWindow,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionTitle('Âm thanh & thời gian yên tĩnh'),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    _SwitchRow(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Nabi nhắc bằng giọng nói',
                      subtitle:
                          'Mặc định tắt. Khi bật, notification dùng lời nhắc ngắn, không đọc bệnh lý hay dữ liệu nhạy cảm trên màn hình khóa.',
                      value: preferences.voiceEnabled,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setVoiceEnabled,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_circle_outline_rounded),
                      title: const Text('Nghe thử giọng nhắc'),
                      subtitle: const Text(
                        'Không dùng micro và không gửi nội dung sức khỏe.',
                      ),
                      onTap: () async {
                        final ok = await controller.previewVoice();
                        if (!context.mounted || ok) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chưa thể phát giọng nhắc lúc này. Hãy dừng cuộc trò chuyện bằng giọng nói rồi thử lại.',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _SwitchRow(
                      icon: Icons.bedtime_outlined,
                      title: 'Theo giờ ngủ của bạn',
                      subtitle:
                          'Ưu tiên khung ngủ/thức đã lưu trong lịch sinh hoạt cá nhân.',
                      value: preferences.usePersonalQuietHours,
                      enabled: preferences.masterEnabled,
                      onChanged: controller.setUsePersonalQuietHours,
                    ),
                    if (!preferences.usePersonalQuietHours)
                      _TimeWindowRow(
                        label: 'Không làm phiền',
                        startMinutes: preferences.fallbackQuietStartMinutes,
                        endMinutes: preferences.fallbackQuietEndMinutes,
                        onChanged: controller.setFallbackQuietHours,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: context.semanticColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Nabi chỉ hiện nội dung chung trên notification. Cập nhật bệnh lý, mục tiêu và hồ sơ chỉ được lưu sau khi bạn mở ứng dụng và xác nhận.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MedicationReminderSettingsSection extends ConsumerWidget {
  const _MedicationReminderSettingsSection({required this.masterEnabled});

  final bool masterEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(medicationReminderSettingsProvider);
    final denied = ref.watch(medicationReminderPermissionDeniedProvider);
    final controller = ref.read(medicationReminderSettingsProvider.notifier);
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Nhắc uống thuốc'),
        const SizedBox(height: AppSpacing.sm),
        _SettingsCard(
          children: [
            Text(
              'Lịch được lưu trên thiết bị. Bạn có thể thêm thuốc và lịch nhắc, đổi tên thuốc, sửa giờ, tạm dừng hoặc xóa lịch tại đây. Thông báo chỉ hiện nội dung chung, không hiện tên thuốc.',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (!masterEnabled)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Công tắc tổng thông báo đang tắt. Lịch thuốc vẫn được giữ và sẽ nhắc lại khi bạn bật công tắc phía trên.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            denied.maybeWhen(
              data: (wasDenied) => wasDenied
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            color: colors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Lịch vẫn được lưu. Hãy bật quyền thông báo trên thiết bị để nhận nhắc uống thuốc.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            denied.maybeWhen(
              data: (wasDenied) => wasDenied
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('medication_reminder_retry_permission'),
                        onPressed: () async {
                          final granted = await controller.requestPermission();
                          ref.invalidate(
                            notificationSettingsControllerProvider,
                          );
                          if (!context.mounted || granted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hãy bật quyền thông báo trong cài đặt thiết bị rồi thử lại.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Thử bật quyền thông báo'),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            const Divider(),
            reminders.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chưa tải được lịch nhắc thuốc'),
                trailing: IconButton(
                  tooltip: 'Thử tải lại',
                  onPressed: () =>
                      ref.invalidate(medicationReminderSettingsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              data: (items) => Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('settings_add_medication_reminder'),
                      onPressed: () async {
                        final draft = await _createMedicationReminder(context);
                        if (draft == null) return;
                        await controller.create(
                          medicineName: draft.medicineName,
                          minutes: draft.minutes,
                        );
                        ref.invalidate(notificationSettingsControllerProvider);
                      },
                      icon: const Icon(Icons.add_alarm_rounded),
                      label: const Text('Thêm thuốc và lịch nhắc'),
                    ),
                  ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Bạn chưa có lịch nhắc uống thuốc.'),
                      ),
                    )
                  else
                    for (final reminder in items)
                      _MedicationReminderSettingsRow(
                        reminder: reminder,
                        onEnabledChanged: (enabled) async {
                          await controller.setEnabled(reminder, enabled);
                        },
                        onNameChanged: (name) =>
                            controller.updateMedicineName(reminder, name),
                        onTimesChanged: (minutes) =>
                            controller.updateTimes(reminder, minutes),
                        onDelete: () => controller.delete(reminder),
                      ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicationReminderSettingsRow extends StatelessWidget {
  const _MedicationReminderSettingsRow({
    required this.reminder,
    required this.onEnabledChanged,
    required this.onNameChanged,
    required this.onTimesChanged,
    required this.onDelete,
  });

  final MedicationReminder reminder;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<List<int>> onTimesChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: Key('medication_reminder_${reminder.id}'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.medication_outlined, color: colors.primary),
          title: Text(reminder.medicineName),
          subtitle: Text(reminder.enabled ? 'Đang bật' : 'Đang tạm dừng'),
          trailing: Switch.adaptive(
            value: reminder.enabled,
            onChanged: onEnabledChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final minute in reminder.reminderMinutes)
                InputChip(
                  label: Text(_formatReminderTime(minute)),
                  tooltip: 'Chạm để sửa giờ',
                  onPressed: () => _editReminderTime(
                    context,
                    minute,
                    reminder.reminderMinutes,
                    onTimesChanged,
                  ),
                  onDeleted: reminder.reminderMinutes.length > 1
                      ? () => onTimesChanged(
                          reminder.reminderMinutes
                              .where((value) => value != minute)
                              .toList(growable: false),
                        )
                      : null,
                ),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Sửa tên thuốc'),
                onPressed: () async {
                  final name = await _editMedicineName(
                    context,
                    reminder.medicineName,
                  );
                  if (name != null) onNameChanged(name);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm giờ'),
                onPressed: () => _editReminderTime(
                  context,
                  null,
                  reminder.reminderMinutes,
                  onTimesChanged,
                ),
              ),
              IconButton(
                tooltip: 'Xóa lịch nhắc ${reminder.medicineName}',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: colors.error),
              ),
            ],
          ),
        ),
        const Divider(indent: 48),
      ],
    );
  }
}

class _MedicationReminderDraft {
  final String medicineName;
  final List<int> minutes;

  const _MedicationReminderDraft({
    required this.medicineName,
    required this.minutes,
  });
}

Future<_MedicationReminderDraft?> _createMedicationReminder(
  BuildContext context,
) => showDialog<_MedicationReminderDraft>(
  context: context,
  builder: (_) => const _CreateMedicationReminderDialog(),
);

class _CreateMedicationReminderDialog extends StatefulWidget {
  const _CreateMedicationReminderDialog();

  @override
  State<_CreateMedicationReminderDialog> createState() =>
      _CreateMedicationReminderDialogState();
}

class _CreateMedicationReminderDialogState
    extends State<_CreateMedicationReminderDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Set<int> _minutes = {};
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final initialTime = _minutes.isEmpty
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: _minutes.last ~/ 60, minute: _minutes.last % 60);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Chọn giờ nhắc uống thuốc',
    );
    if (picked == null) return;
    setState(() => _minutes.add(picked.hour * 60 + picked.minute));
  }

  void _save() {
    setState(() => _submitted = true);
    final medicineName = _nameController.text.trim();
    if (medicineName.isEmpty || _minutes.isEmpty) return;
    Navigator.of(context).pop(
      _MedicationReminderDraft(
        medicineName: medicineName,
        minutes: _minutes.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thuốc và lịch nhắc'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('settings_medication_name_input'),
                controller: _nameController,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc',
                  hintText: 'Nhập tên thuốc',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final minute in (_minutes.toList()..sort()))
                    InputChip(
                      label: Text(_formatReminderTime(minute)),
                      onDeleted: _minutes.length > 1
                          ? () => setState(() => _minutes.remove(minute))
                          : null,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(_minutes.isEmpty ? 'Chọn giờ' : 'Thêm giờ'),
                    onPressed: _addTime,
                  ),
                ],
              ),
              if (_submitted && _nameController.text.trim().isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hãy nhập tên thuốc.',
                  style: TextStyle(color: context.semanticColors.error),
                ),
              ],
              if (_submitted && _minutes.isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hãy chọn ít nhất một giờ nhắc.',
                  style: TextStyle(color: context.semanticColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('settings_save_medication_reminder'),
          onPressed: _save,
          child: const Text('Lưu lịch'),
        ),
      ],
    );
  }
}

Future<String?> _editMedicineName(BuildContext context, String currentName) =>
    showDialog<String>(
      context: context,
      builder: (_) => _EditMedicationNameDialog(currentName: currentName),
    );

class _EditMedicationNameDialog extends StatefulWidget {
  const _EditMedicationNameDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditMedicationNameDialog> createState() =>
      _EditMedicationNameDialogState();
}

class _EditMedicationNameDialogState extends State<_EditMedicationNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Sửa tên thuốc'),
    content: TextField(
      key: const Key('settings_edit_medication_name_input'),
      controller: _controller,
      autofocus: true,
      maxLength: 80,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) {
        if (_submitted) setState(() {});
      },
      decoration: InputDecoration(
        labelText: 'Tên thuốc',
        errorText: _submitted && _controller.text.trim().isEmpty
            ? 'Hãy nhập tên thuốc.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu tên')),
    ],
  );
}

Future<void> _editReminderTime(
  BuildContext context,
  int? currentMinute,
  List<int> existingMinutes,
  ValueChanged<List<int>> onChanged,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: currentMinute == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: currentMinute ~/ 60, minute: currentMinute % 60),
    helpText: 'Chọn giờ nhắc uống thuốc',
  );
  if (picked == null) return;
  final minute = picked.hour * 60 + picked.minute;
  onChanged({...existingMinutes, minute}.toList()..sort());
}

String _formatReminderTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingIconBadge extends StatelessWidget {
  const _SettingIconBadge({
    required this.icon,
    required this.active,
    this.enabled = true,
  });

  final IconData icon;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? colors.primarySoft : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        icon,
        size: 20,
        color: !enabled
            ? colors.textMuted
            : active
            ? colors.primaryDark
            : colors.textSecondary,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.heading3);
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: _SettingIconBadge(icon: icon, active: value, enabled: enabled),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(labelOf(item))),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

class _SingleTimeRow extends StatelessWidget {
  const _SingleTimeRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton.icon(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _timeOfDay(minutes),
          );
          if (picked != null) onChanged(picked.hour * 60 + picked.minute);
        },
        icon: const Icon(Icons.schedule_rounded),
        label: Text(_formatMinutes(minutes)),
      ),
    );
  }
}

class _TimeWindowRow extends StatelessWidget {
  const _TimeWindowRow({
    required this.label,
    required this.startMinutes,
    required this.endMinutes,
    required this.onChanged,
  });

  final String label;
  final int startMinutes;
  final int endMinutes;
  final Future<void> Function(int start, int end) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '${_formatMinutes(startMinutes)} – ${_formatMinutes(endMinutes)}',
      ),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () async {
        final start = await showTimePicker(
          context: context,
          initialTime: _timeOfDay(startMinutes),
        );
        if (start == null || !context.mounted) return;
        final end = await showTimePicker(
          context: context,
          initialTime: _timeOfDay(endMinutes),
        );
        if (end == null) return;
        await onChanged(
          start.hour * 60 + start.minute,
          end.hour * 60 + end.minute,
        );
      },
    );
  }
}

TimeOfDay _timeOfDay(int minutes) => TimeOfDay(
  hour: minutes.clamp(0, 1439) ~/ 60,
  minute: minutes.clamp(0, 1439) % 60,
);

String _formatMinutes(int minutes) {
  final value = minutes.clamp(0, 1439);
  final hour = (value ~/ 60).toString().padLeft(2, '0');
  final minute = (value % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

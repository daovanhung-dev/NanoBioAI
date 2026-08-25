import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/notification_settings_provider.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(title: const Text('Quản lý thông báo')),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(notificationSettingsControllerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
          data: (preferences) => _NotificationSettingsBody(
            preferences: preferences,
          ),
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
    final controller = ref.read(notificationSettingsControllerProvider.notifier);
    return ListView(
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
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text('Cho phép Nabi nhắc bạn'),
              subtitle: const Text(
                'Công tắc tổng. Tắt sẽ hủy các thông báo đang chờ nhưng giữ lựa chọn từng loại.',
              ),
              value: preferences.masterEnabled,
              onChanged: (value) async {
                final granted = await controller.setMasterEnabled(value);
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
        _SectionTitle('Các loại nhắc nhở'),
        const SizedBox(height: AppSpacing.sm),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.event_available_rounded,
              title: 'Lịch trình cá nhân',
              subtitle: 'Giữ nhắc bữa ăn, vận động và nhiệm vụ hiện có.',
              value: preferences.scheduleEnabled,
              enabled: preferences.masterEnabled,
              onChanged: controller.setScheduleEnabled,
            ),
            const Divider(),
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
            const Divider(),
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
            const Divider(),
            _SwitchRow(
              icon: Icons.manage_accounts_outlined,
              title: 'Cập nhật thông tin thay đổi',
              subtitle: 'Hỏi lại cân nặng, chiều cao, vận động, giấc ngủ và lượng nước.',
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
            const Divider(),
            _SwitchRow(
              icon: Icons.water_drop_outlined,
              title: 'Nhắc uống nước',
              subtitle: 'Tự dừng trong ngày khi mục tiêu nước đã hoàn thành.',
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
              subtitle: const Text('Không dùng micro và không gửi nội dung sức khỏe.'),
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: context.semanticColors.primary),
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
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.heading3);
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
      secondary: Icon(icon),
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
      subtitle: Text('${_formatMinutes(startMinutes)} – ${_formatMinutes(endMinutes)}'),
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

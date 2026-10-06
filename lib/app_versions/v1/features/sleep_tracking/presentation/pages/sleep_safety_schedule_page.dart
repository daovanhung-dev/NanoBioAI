import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/sleep_safety_providers.dart';

class SleepSafetySchedulePage extends ConsumerStatefulWidget {
  const SleepSafetySchedulePage({super.key});

  @override
  ConsumerState<SleepSafetySchedulePage> createState() =>
      _SleepSafetySchedulePageState();
}

class _SleepSafetySchedulePageState
    extends ConsumerState<SleepSafetySchedulePage> {
  bool? _enabled;
  TimeOfDay? _start;
  TimeOfDay? _end;
  Set<int>? _days;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepSafetyControllerProvider);
    final preference = state.preference;
    if (preference == null) {
      return MedicalPageScaffold(
        appBar: AppBar(title: const Text('Lịch giám sát')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Đang tải lựa chọn của bạn…'),
            ],
          ),
        ),
      );
    }

    _enabled ??= preference.scheduleEnabled;
    _start ??= _timeOfDay(preference.scheduleStartMinutes);
    _end ??= _timeOfDay(preference.scheduleEndMinutes);
    _days ??= {...preference.selectedWeekdays};

    final colors = context.semanticColors;
    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Lịch giám sát')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
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
                    Text(
                      'Chọn nhịp giám sát phù hợp với giờ nghỉ của bạn.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MedicalSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          secondary: MedicalIconBadge(
                            icon: Icons.bedtime_outlined,
                            color: colors.primaryDark,
                            backgroundColor: colors.primarySoft,
                            size: 42,
                          ),
                          title: const Text('Nhắc bật giám sát theo lịch'),
                          subtitle: const Text(
                            'Đến giờ, Nabi sẽ nhắc bạn mở ứng dụng và tự xác nhận bắt đầu. Micro không tự bật khi ứng dụng đang đóng.',
                          ),
                          value: _enabled!,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const MedicalSectionHeader(
                      title: 'Khung giờ',
                      subtitle: 'Chọn thời điểm bắt đầu và kết thúc.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MedicalSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          Material(
                            type: MaterialType.transparency,
                            child: Column(
                              children: [
                                _TimeChoiceTile(
                                  title: 'Bắt đầu',
                                  value: _start!.format(context),
                                  icon: Icons.play_circle_outline_rounded,
                                  onTap: () => _pickTime(isStart: true),
                                ),
                                const Divider(indent: 60),
                                _TimeChoiceTile(
                                  title: 'Kết thúc',
                                  value: _end!.format(context),
                                  icon: Icons.nights_stay_outlined,
                                  onTap: () => _pickTime(isStart: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const MedicalSectionHeader(
                      title: 'Ngày áp dụng',
                      subtitle: 'Chọn những ngày bạn muốn nhận lời nhắc.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MedicalSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          const labels = [
                            'Thứ 2',
                            'Thứ 3',
                            'Thứ 4',
                            'Thứ 5',
                            'Thứ 6',
                            'Thứ 7',
                            'Chủ nhật',
                          ];
                          final selected = _days!.contains(day);
                          return FilterChip(
                            label: Text(labels[index]),
                            selected: selected,
                            onSelected: (value) => setState(() {
                              if (value) {
                                _days!.add(day);
                              } else {
                                _days!.remove(day);
                              }
                            }),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final updated = preference.copyWith(
                            scheduleEnabled: _enabled,
                            scheduleStartMinutes:
                                _start!.hour * 60 + _start!.minute,
                            scheduleEndMinutes: _end!.hour * 60 + _end!.minute,
                            selectedWeekdays: _days,
                          );
                          await ref
                              .read(sleepSafetyControllerProvider.notifier)
                              .savePreference(updated);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Lưu lịch'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start! : _end!;
    final value = await showTimePicker(context: context, initialTime: current);
    if (value == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  TimeOfDay _timeOfDay(int minutes) => TimeOfDay(
    hour: minutes.clamp(0, 1439) ~/ 60,
    minute: minutes.clamp(0, 1439) % 60,
  );
}

class _TimeChoiceTile extends StatelessWidget {
  const _TimeChoiceTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return ListTile(
      minTileHeight: 64,
      leading: MedicalIconBadge(
        icon: icon,
        color: colors.primaryDark,
        backgroundColor: colors.primarySoft,
        size: 42,
      ),
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: colors.borderLight),
        ),
        child: Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(color: colors.primaryDark),
        ),
      ),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';
import 'onboarding_text_field.dart';

class ExtrasStep extends ConsumerStatefulWidget {
  const ExtrasStep({super.key});

  @override
  ConsumerState<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends ConsumerState<ExtrasStep> {
  final Map<int, bool> _expanded = {0: false, 1: false, 2: false, 3: true};

  void _toggle(int index) {
    setState(() => _expanded[index] = !(_expanded[index] ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final colors = context.semanticColors;

    return OnboardingStepShell(
      stepIndex: 5,
      title: 'Thông tin cần lưu ý',
      subtitle: 'Bạn có thể cập nhật các chi tiết này sau.',
      mood: NabiOnboardingMood.thinking,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: OnboardingRevealColumn(
        children: [
          const OnboardingNabiNote(
            mood: NabiOnboardingMood.thinking,
            message:
                'Mỗi cơ thể là một vũ trụ riêng. Những chi tiết nhỏ giúp gợi ý của Nabi gần với bạn hơn.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const OnboardingScreenHeading(
            title: 'Thông tin cần lưu ý',
            subtitle:
                'Chia sẻ điều bạn thấy phù hợp để Nabi cá nhân hóa lộ trình.',
            bottomSpacing: AppSpacing.md,
          ),
          OnboardingAccordionCard(
            title: 'Dị ứng hoặc thực phẩm cần tránh',
            subtitle: _summary(
              _split(state.allergyName),
              'Hải sản, hạt, lactose…',
            ),
            icon: Icons.spa_rounded,
            accent: colors.primary,
            expanded: _expanded[0] ?? false,
            onToggle: () => _toggle(0),
            child: Column(
              children: [
                OnboardingMultiChoicePickerField(
                  label: 'Thực phẩm hoặc thành phần',
                  hint: 'Chọn nếu có',
                  icon: Icons.restaurant_rounded,
                  options: OnboardingOptions.allergyChoices,
                  selectedLabels: _split(state.allergyName),
                  onChanged: (values) =>
                      controller.updateAllergyName(_join(values)),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingTextField(
                  label: 'Ghi chú (tùy chọn)',
                  hint: 'Ghi chú thêm nếu cần',
                  initialValue: state.allergyNote,
                  maxLines: 2,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.updateAllergyNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingAccordionCard(
            title: 'Chỉ số đang theo dõi đặc biệt',
            subtitle: _summary(
              _split(state.treatmentName),
              'Đường huyết, huyết áp…',
            ),
            icon: Icons.monitor_heart_rounded,
            accent: colors.info,
            expanded: _expanded[1] ?? false,
            onToggle: () => _toggle(1),
            child: OnboardingMultiChoicePickerField(
              label: 'Tình trạng hoặc điều trị',
              hint: 'Chọn nội dung phù hợp',
              icon: Icons.medical_information_rounded,
              options: OnboardingOptions.treatmentChoices,
              selectedLabels: _split(state.treatmentName),
              onChanged: (values) =>
                  controller.updateTreatmentName(_join(values)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingAccordionCard(
            title: 'Thực phẩm bổ sung hoặc thuốc',
            subtitle: _summary(
              _split(state.medicationName),
              'Vitamin, khoáng chất…',
            ),
            icon: Icons.medication_rounded,
            accent: colors.tertiary,
            expanded: _expanded[2] ?? false,
            onToggle: () => _toggle(2),
            child: Column(
              children: [
                OnboardingMultiChoicePickerField(
                  label: 'Đang sử dụng',
                  hint: 'Chọn sản phẩm nếu có',
                  icon: Icons.medication_liquid_rounded,
                  options: OnboardingOptions.medicationChoices,
                  selectedLabels: _split(state.medicationName),
                  onChanged: (values) =>
                      controller.updateMedicationName(_join(values)),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lịch nhắc uống thuốc (tùy chọn)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tên thuốc và giờ nhắc chỉ lưu trên thiết bị. Thông báo sẽ dùng nội dung chung, không hiện tên thuốc. Sau khi hoàn tất, để thêm/xóa lịch nhắc, đổi tên thuốc hoặc chỉnh giờ, vào Cài đặt > Quản lý thông báo > Nhắc uống thuốc.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (
                  var index = 0;
                  index < state.medicationReminders.length;
                  index++
                ) ...[
                  _MedicationReminderDraftCard(
                    key: ValueKey('medication_reminder_draft_$index'),
                    name: state.medicationReminders[index].medicineName,
                    minutes: state.medicationReminders[index].reminderMinutes,
                    onNameChanged: (value) =>
                        controller.updateMedicationReminderName(index, value),
                    onAddTime: () async {
                      final initial =
                          state
                              .medicationReminders[index]
                              .reminderMinutes
                              .isNotEmpty
                          ? _timeOfDay(
                              state
                                  .medicationReminders[index]
                                  .reminderMinutes
                                  .last,
                            )
                          : const TimeOfDay(hour: 8, minute: 0);
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                        helpText: 'Chọn giờ nhắc uống thuốc',
                      );
                      if (picked != null) {
                        controller.addMedicationReminderTime(
                          index,
                          picked.hour * 60 + picked.minute,
                        );
                      }
                    },
                    onEditTime: (minute) async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _timeOfDay(minute),
                        helpText: 'Chọn giờ nhắc uống thuốc',
                      );
                      if (picked != null) {
                        controller.changeMedicationReminderTime(
                          index,
                          minute,
                          picked.hour * 60 + picked.minute,
                        );
                      }
                    },
                    onRemoveTime: (minute) =>
                        controller.removeMedicationReminderTime(index, minute),
                    onRemove: () => controller.removeMedicationReminder(index),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (!state.medicationReminders.every(
                  (reminder) => reminder.isValid,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      'Mỗi lịch cần có tên thuốc và ít nhất một giờ nhắc. Bạn có thể xóa lịch chưa hoàn tất.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('onboarding_add_medication_reminder'),
                    onPressed: controller.addMedicationReminder,
                    icon: const Icon(Icons.add_alarm_rounded),
                    label: const Text('Thêm lịch nhắc'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingTextField(
                  label: 'Ghi chú điều trị (tùy chọn)',
                  hint: 'Ví dụ: thời điểm dùng theo chỉ định',
                  initialValue: state.treatmentNote,
                  maxLines: 2,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.updateTreatmentNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingAccordionCard(
            title: 'Chủ đề bạn muốn Nabi ưu tiên',
            subtitle: _summary(
              _split(state.concernText),
              'Chọn chủ đề quan tâm (tùy chọn)',
            ),
            icon: Icons.favorite_rounded,
            accent: colors.secondary,
            expanded: _expanded[3] ?? false,
            onToggle: () => _toggle(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn những chủ đề bạn quan tâm để Nabi sắp xếp lịch trình cá nhân hóa.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingMultiChoicePickerField(
                  label: 'Mối quan tâm',
                  hint: 'Chọn chủ đề',
                  icon: Icons.auto_awesome_rounded,
                  options: OnboardingOptions.concernChoices,
                  selectedLabels: _split(state.concernText),
                  onChanged: (values) =>
                      controller.updateConcernText(_join(values)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Không bắt buộc. Bạn luôn có thể cập nhật lại trong Hồ sơ.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _summary(List<String> values, String fallback) {
    if (values.isEmpty) return fallback;
    final joined = values.join(', ');
    return joined.length > 38 ? '${joined.substring(0, 35)}…' : joined;
  }

  static List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  static String _join(List<String> values) => values.join(', ');
}

class _MedicationReminderDraftCard extends StatelessWidget {
  const _MedicationReminderDraftCard({
    super.key,
    required this.name,
    required this.minutes,
    required this.onNameChanged,
    required this.onAddTime,
    required this.onEditTime,
    required this.onRemoveTime,
    required this.onRemove,
  });

  final String name;
  final List<int> minutes;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onAddTime;
  final ValueChanged<int> onEditTime;
  final ValueChanged<int> onRemoveTime;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OnboardingTextField(
                  key: const Key('onboarding_medication_reminder_name'),
                  label: 'Tên thuốc',
                  hint: 'Nhập tên thuốc',
                  initialValue: name,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: onNameChanged,
                ),
              ),
              IconButton(
                tooltip: 'Xóa lịch nhắc này',
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline_rounded, color: colors.error),
              ),
            ],
          ),
          if (minutes.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final minute in minutes)
                  InputChip(
                    label: Text(_formatMinute(minute)),
                    onPressed: () => onEditTime(minute),
                    onDeleted: () => onRemoveTime(minute),
                    deleteButtonTooltipMessage:
                        'Xóa giờ ${_formatMinute(minute)}',
                  ),
              ],
            ),
          TextButton.icon(
            onPressed: onAddTime,
            icon: const Icon(Icons.access_time_rounded),
            label: Text(minutes.isEmpty ? 'Chọn giờ nhắc' : 'Thêm giờ'),
          ),
        ],
      ),
    );
  }
}

TimeOfDay _timeOfDay(int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

String _formatMinute(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../../daily_routine/domain/entities/daily_routine_preferences.dart';
import '../../../daily_routine/presentation/widgets/daily_routine_preferences_editor.dart';
import '../controllers/onboarding_controller.dart';
import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

class DailyRoutineStep extends ConsumerStatefulWidget {
  const DailyRoutineStep({super.key});

  @override
  ConsumerState<DailyRoutineStep> createState() => _DailyRoutineStepState();
}

class _DailyRoutineStepState extends ConsumerState<DailyRoutineStep> {
  bool _weekend = false;
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final preferences = state.routinePreferences;
    final template = _weekend ? preferences.weekend : preferences.weekday;
    final errors = preferences.validate();
    final colors = context.semanticColors;

    return OnboardingStepShell(
      stepIndex: 6,
      title: 'Một ngày của bạn',
      subtitle: 'Chọn khung giờ quen thuộc để Nabi nhắc nhở đúng lúc.',
      mood: NabiOnboardingMood.routine,
      onBack: controller.previousStep,
      footer: NabiPrimaryButton(
        onPressed: errors.isEmpty ? controller.confirmRoutineAndContinue : null,
        label: 'Xác nhận khung giờ',
        icon: Icons.arrow_forward_rounded,
      ),
      child: OnboardingRevealColumn(
        children: [
          const OnboardingScreenHeading(
            eyebrow: 'NHỊP SINH HỌC CÁ NHÂN',
            icon: Icons.schedule_rounded,
            title: 'Một ngày của bạn',
            subtitle:
                'Nabi sẽ gửi nhắc nhở dịu nhẹ vào những thời điểm cơ thể cần được nạp lại năng lượng.',
            bottomSpacing: AppSpacing.md,
          ),
          const OnboardingNabiNote(
            mood: NabiOnboardingMood.routine,
            eyebrow: 'LỜI NHẮN TỪ NABI',
            compact: true,
            message:
                'Không cần vội vã. Hãy chọn giờ giấc quen thuộc để cơ thể thích ứng tự nhiên.',
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Ngày thường')),
              ButtonSegment<bool>(value: true, label: Text('Cuối tuần')),
            ],
            selected: {_weekend},
            showSelectedIcon: false,
            onSelectionChanged: (values) =>
                setState(() => _weekend = values.first),
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineItem(
            number: 'MỐC 1',
            icon: Icons.wb_twilight_rounded,
            title: 'Thời gian thức giấc',
            subtitle: 'Bắt đầu ngày mới cùng sự tươi mát',
            time: template.wakeTime,
            actionLabel: 'Chọn giờ',
            onPick: () async {
              final value = await _pickTime(context, template.wakeTime);
              if (value == null) return;
              _updateTemplate(
                controller,
                preferences,
                template.copyWith(wakeTime: value),
              );
            },
          ),
          _TimelineItem(
            number: 'MỐC 2',
            icon: Icons.restaurant_rounded,
            title: 'Khung giờ ăn trưa và tối',
            subtitle: 'Duy trì bữa ăn nhẹ nhàng, đều đặn',
            time: '${template.mealTimes[2]}  ·  ${template.mealTimes[4]}',
            actionLabel: 'Chọn giờ ăn',
            onPick: () async {
              final value = await _pickTime(context, template.mealTimes[2]);
              if (value == null) return;
              final meals = [...template.mealTimes]..[2] = value;
              _updateTemplate(
                controller,
                preferences,
                template.copyWith(mealTimes: meals),
              );
            },
            secondaryAction: () async {
              final value = await _pickTime(context, template.mealTimes[4]);
              if (value == null) return;
              final meals = [...template.mealTimes]..[4] = value;
              _updateTemplate(
                controller,
                preferences,
                template.copyWith(mealTimes: meals),
              );
            },
            secondaryLabel: 'Tối ${template.mealTimes[4]}',
          ),
          _TimelineItem(
            number: 'MỐC 3',
            icon: Icons.self_improvement_rounded,
            title: 'Khoảng nghỉ tái tạo giữa ngày',
            subtitle: 'Vận động nhẹ hoặc hít thở sâu',
            time: template.workoutRanges.first.start,
            actionLabel: 'Chọn khung giờ',
            onPick: () async {
              final ranges = [...template.workoutRanges];
              final current = ranges.first;
              final value = await _pickTime(context, current.start);
              if (value == null) return;
              ranges[0] = current.copyWith(start: value);
              _updateTemplate(
                controller,
                preferences,
                template.copyWith(workoutRanges: ranges),
              );
            },
            secondaryAction: () => setState(() => _detailsExpanded = true),
            secondaryLabel: 'Thêm khung tập',
          ),
          _TimelineItem(
            number: 'MỐC 4',
            icon: Icons.bedtime_rounded,
            title: 'Thư giãn chuẩn bị ngủ',
            subtitle: 'Buông bỏ căng thẳng, an tâm nghỉ ngơi',
            time: template.sleepTime,
            actionLabel: 'Chọn giờ ngủ',
            last: true,
            onPick: () async {
              final value = await _pickTime(context, template.sleepTime);
              if (value == null) return;
              _updateTemplate(
                controller,
                preferences,
                template.copyWith(sleepTime: value),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          OnboardingAccordionCard(
            title: 'Tùy chỉnh các khung giờ khác',
            subtitle: 'Bữa ăn, ngủ trưa, tập luyện và thời gian bận',
            icon: Icons.tune_rounded,
            expanded: _detailsExpanded,
            onToggle: () =>
                setState(() => _detailsExpanded = !_detailsExpanded),
            child: DailyRoutinePreferencesEditor(
              value: preferences,
              onChanged: controller.updateRoutinePreferences,
            ),
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            OnboardingInlineInfo(
              icon: Icons.info_outline_rounded,
              text: errors.first,
              color: NabiPalette.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_rounded, size: 17, color: colors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Bạn có thể thay đổi các mốc giờ này trong phần Cài đặt sau.',
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

  void _updateTemplate(
    OnboardingController controller,
    DailyRoutinePreferences current,
    RoutineDayTemplate updated,
  ) {
    controller.updateRoutinePreferences(
      _weekend
          ? current.copyWith(weekend: updated)
          : current.copyWith(weekday: updated),
    );
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '') ?? 8,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
    final value = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (value == null) return null;
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.actionLabel,
    required this.onPick,
    this.secondaryAction,
    this.secondaryLabel,
    this.last = false,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String actionLabel;
  final VoidCallback onPick;
  final VoidCallback? secondaryAction;
  final String? secondaryLabel;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.textPrimary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: colors.secondaryDark, size: 21),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: colors.primarySoft,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: OnboardingStitchCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            number,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.secondaryDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.35,
                            ),
                          ),
                        ),
                        Icon(icon, size: 17, color: colors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _TimeButton(
                          icon: Icons.schedule_rounded,
                          label: '$actionLabel · $time',
                          onPressed: onPick,
                        ),
                        if (secondaryAction != null && secondaryLabel != null)
                          _TimeButton(
                            icon: Icons.edit_calendar_rounded,
                            label: secondaryLabel!,
                            onPressed: secondaryAction!,
                            subtle: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtle = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Material(
      color: subtle ? colors.cardAlt : colors.primarySubtle,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                if (compact)
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      softWrap: true,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  )
                else
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

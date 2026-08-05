import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/app_text_styles.dart';

import '../../../daily_routine/presentation/widgets/daily_routine_preferences_editor.dart';
import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';

import 'package:nano_app/core/theme/app_spacing.dart';
class DailyRoutineStep extends ConsumerWidget {
  const DailyRoutineStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final errors = state.routinePreferences.validate();
    return OnboardingStepShell(
      stepIndex: 6,
      title: 'Một ngày của bạn',
      subtitle: 'Chọn khung giờ gần đúng.',
      mood: NabiOnboardingMood.routine,
      onBack: controller.previousStep,
      footer: NabiPrimaryButton(
        onPressed: errors.isEmpty ? controller.confirmRoutineAndContinue : null,
        label: 'Xác nhận khung giờ',
        icon: Icons.check_rounded,
      ),
      child: Column(
        children: [
          const _RoutineTimelinePreview(),
          const SizedBox(height: AppSpacing.sm),
          if (errors.isNotEmpty) ...[
            OnboardingInlineInfo(
              icon: Icons.error_outline_rounded,
              text: errors.first,
              color: NabiPalette.error,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OnboardingSectionCard(
            title: 'Điều chỉnh thời gian',
            icon: Icons.schedule_rounded,
            accent: NabiPalette.energyYellow,
            child: DailyRoutinePreferencesEditor(
              value: state.routinePreferences,
              onChanged: controller.updateRoutinePreferences,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineTimelinePreview extends StatelessWidget {
  const _RoutineTimelinePreview();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.wb_sunny_rounded, 'Sáng', NabiPalette.energyYellow),
      (Icons.restaurant_rounded, 'Trưa', NabiPalette.careCoral),
      (Icons.directions_walk_rounded, 'Chiều', NabiPalette.greenPrimary),
      (Icons.bedtime_rounded, 'Tối', NabiPalette.personalPurple),
    ];
    return NabiGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      elevated: false,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: items[index].$3.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[index].$1,
                      color: items[index].$3,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    items[index].$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: NabiPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (index < items.length - 1)
              Container(
                width: 14,
                height: 2,
                color: NabiPalette.line,
              ),
          ],
        ],
      ),
    );
  }
}

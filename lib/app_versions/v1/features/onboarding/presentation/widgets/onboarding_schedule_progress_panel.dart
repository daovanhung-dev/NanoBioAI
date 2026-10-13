import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingScheduleProgressPanel extends ConsumerWidget {
  const OnboardingScheduleProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      onboardingProvider.select((state) => state.initialPlanProgress),
    );
    final colors = context.semanticColors;
    final completedDays = progress.completedDays;
    final totalDays = progress.totalDays;
    final percent = progress.percentComplete;
    final progressValue = totalDays <= 0 ? 0.0 : completedDays / totalDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ tạo lịch',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Đã lưu $completedDays / $totalDays ngày',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$percent%',
                key: const ValueKey('onboarding-schedule-progress-percent'),
                style: AppTextStyles.heading4.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Tiến độ tạo lịch',
            value:
                '$percent phần trăm hoàn tất. Đã lưu $completedDays trên $totalDays ngày.',
            liveRegion: true,
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  color: colors.primary,
                  backgroundColor: colors.primarySoft,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ngày đã lưu',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (progress.savedDays.isEmpty)
            Text(
              'Các ngày sẽ xuất hiện ở đây sau khi được lưu.',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final day in progress.savedDays) _SavedDayChip(day: day),
              ],
            ),
        ],
      ),
    );
  }
}

class _SavedDayChip extends StatelessWidget {
  final int day;

  const _SavedDayChip({required this.day});

  static const _ordinals = [
    '',
    'thứ nhất',
    'thứ hai',
    'thứ ba',
    'thứ tư',
    'thứ năm',
    'thứ sáu',
    'thứ bảy',
  ];

  String get _label => day > 0 && day < _ordinals.length
      ? 'Ngày ${_ordinals[day]}'
      : 'Ngày $day';

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Semantics(
      label: '$_label đã lưu',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.success.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

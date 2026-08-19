import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

class WeeklySummaryPage extends ConsumerWidget {
  const WeeklySummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);
    final now = ref.watch(lifestyleScheduleClockProvider)();

    return scheduleAsync.when(
      loading: () => _WeeklySummaryFrame(
        children: const [
          NamiCareSurfaceCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => _WeeklySummaryFrame(
        children: [
          NamiCareEmptyState(
            icon: Icons.cloud_off_rounded,
            color: AppColors.warning,
            title: 'Chưa đọc được dữ liệu tuần',
            message:
                'Dữ liệu đã có trên thiết bị vẫn được giữ nguyên. Bạn có thể thử tải lại.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => ref
                .read(lifestyleScheduleControllerProvider.notifier)
                .refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
      data: (state) {
        final aggregate = _WeekAggregate.fromItems(
          items: state.summary.items,
          now: now,
        );
        return _WeeklySummaryFrame(
          children: [
            if (aggregate.total == 0)
              const NamiCareEmptyState(
                icon: Icons.calendar_month_rounded,
                color: AppColors.secondary,
                title: 'Tuần này chưa có nhiệm vụ để tổng kết',
                message:
                    'Khi lịch chăm sóc có dữ liệu thật, Nabi sẽ tổng hợp tiến trình của đúng tuần hiện tại tại đây.',
              )
            else ...[
              NamiCareSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tiến trình tuần này', style: AppTextStyles.heading4),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: aggregate.completionRatio,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${aggregate.completed}/${aggregate.total} nhiệm vụ đã hoàn thành',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              const NamiCareSectionTitle(
                title: 'Những gì đã được ghi nhận',
                subtitle:
                    'Các số dưới đây chỉ dùng dữ liệu nhiệm vụ thật trong tuần, không tạo giá trị mẫu.',
              ),
              const SizedBox(height: AppSpacing.md),
              NamiCareInfoTile(
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
                title: 'Nhiệm vụ đã chăm',
                subtitle:
                    '${aggregate.completed} nhiệm vụ đã hoàn thành trong ${aggregate.activeDays} ngày có lịch.',
                trailing: '${aggregate.completed}/${aggregate.total}',
              ),
              const SizedBox(height: AppSpacing.sm),
              NamiCareInfoTile(
                icon: Icons.calendar_today_rounded,
                color: AppColors.primary,
                title: 'Ngày có hoạt động',
                subtitle:
                    'Số ngày trong tuần hiện tại có ít nhất một nhiệm vụ được lên lịch.',
                trailing: '${aggregate.activeDays} ngày',
              ),
              const SizedBox(height: AppSpacing.sm),
              NamiCareInfoTile(
                icon: Icons.insights_rounded,
                color: AppColors.info,
                title: 'Tỷ lệ hoàn thành',
                subtitle:
                    'Tính trực tiếp từ nhiệm vụ đã hoàn thành trên tổng nhiệm vụ của tuần.',
                trailing: '${aggregate.completionPercent}%',
              ),
            ],
            const SizedBox(height: AppSpacing.sectionSpacing),
            OutlinedButton.icon(
              onPressed: scheduleAsync.isLoading
                  ? null
                  : () => ref
                      .read(lifestyleScheduleControllerProvider.notifier)
                      .refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới dữ liệu tuần'),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklySummaryFrame extends StatelessWidget {
  final List<Widget> children;

  const _WeeklySummaryFrame({required this.children});

  @override
  Widget build(BuildContext context) {
    return NamiCareScaffold(
      title: 'Tổng kết tuần',
      subtitle: 'Nabi cùng bạn nhìn lại những điều nhỏ đã làm được.',
      badge: 'Dữ liệu tuần hiện tại',
      icon: Icons.insights_rounded,
      gradient: AppGradients.premium,
      children: children,
    );
  }
}

class _WeekAggregate {
  final int total;
  final int completed;
  final int activeDays;

  const _WeekAggregate({
    required this.total,
    required this.completed,
    required this.activeDays,
  });

  double get completionRatio => total == 0 ? 0 : completed / total;
  int get completionPercent => (completionRatio * 100).round();

  factory _WeekAggregate.fromItems({
    required List<LifestyleScheduleItemEntity> items,
    required DateTime now,
  }) {
    final today = DateUtils.dateOnly(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final dates = <String>{};
    var total = 0;
    var completed = 0;

    for (final item in items) {
      final date = DateTime.tryParse(item.scheduleDate.trim());
      if (date == null) continue;
      final day = DateUtils.dateOnly(date);
      if (day.isBefore(weekStart) || !day.isBefore(weekEnd)) continue;
      total += 1;
      if (item.isCompleted) completed += 1;
      dates.add(item.scheduleDate.trim());
    }

    return _WeekAggregate(
      total: total,
      completed: completed,
      activeDays: dates.length,
    );
  }
}

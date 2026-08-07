import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/today_tasks/domain/services/today_task_selector.dart';
import 'package:nano_app/app_versions/v1/features/today_tasks/presentation/widgets/today_tasks_states.dart';
import 'package:nano_app/core/theme/theme.dart';

class TodayTasksPage extends ConsumerWidget {
  const TodayTasksPage({super.key});

  static const _selector = TodayTaskSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);
    final now = ref.watch(lifestyleScheduleClockProvider)();

    return MedicalPageScaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ hôm nay'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: scheduleAsync.isLoading
                ? null
                : () => ref
                      .read(lifestyleScheduleControllerProvider.notifier)
                      .refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: scheduleAsync.when(
          loading: () => const TodayTasksPageFrame(
            child: TodayTasksLoadingState(),
          ),
          error: (_, __) => TodayTasksPageFrame(
            child: TodayTasksErrorState(
              onRetry: () => ref
                  .read(lifestyleScheduleControllerProvider.notifier)
                  .refresh(),
            ),
          ),
          data: (state) {
            final tasks = _selector.select(
              items: state.summary.items,
              today: now,
            );
            return TodayTasksReadyState(
              tasks: tasks,
              now: now,
              onRefresh: () => ref
                  .read(lifestyleScheduleControllerProvider.notifier)
                  .refresh(),
            );
          },
        ),
      ),
    );
  }
}

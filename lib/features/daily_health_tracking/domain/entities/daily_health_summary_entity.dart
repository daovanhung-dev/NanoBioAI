import 'daily_health_task_entity.dart';

class DailyHealthSummaryEntity {
  final String userId;
  final String fullName;
  final String taskDate;
  final List<DailyHealthTaskEntity> tasks;

  const DailyHealthSummaryEntity({
    required this.userId,
    required this.fullName,
    required this.taskDate,
    required this.tasks,
  });

  int get totalTasks => tasks.length;

  int get completedTasks => tasks.where((task) => task.isCompleted).length;

  int get score {
    if (tasks.isEmpty) return 0;
    return ((completedTasks / tasks.length) * 100).round();
  }

  Map<String, double> get categoryProgress {
    final result = <String, double>{};
    for (final category in const ['water', 'body', 'mind', 'brain']) {
      final categoryTasks = tasks
          .where((task) => task.category == category)
          .toList(growable: false);
      if (categoryTasks.isEmpty) {
        result[category] = 0;
        continue;
      }
      final total = categoryTasks.fold<double>(
        0,
        (sum, task) => sum + task.progressRatio,
      );
      result[category] = total / categoryTasks.length;
    }
    return result;
  }
}

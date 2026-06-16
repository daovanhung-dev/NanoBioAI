import '../../domain/entities/daily_health_summary_entity.dart';
import '../../domain/entities/daily_health_task_entity.dart';

class DailyHealthTrackingState {
  final DailyHealthSummaryEntity summary;
  final String? lastEncouragement;

  const DailyHealthTrackingState({
    required this.summary,
    this.lastEncouragement,
  });

  List<DailyHealthTaskEntity> get tasks => summary.tasks;
  int get score => summary.score;
  int get completedTasks => summary.completedTasks;
  int get totalTasks => summary.totalTasks;
  Map<String, double> get categoryProgress => summary.categoryProgress;

  DailyHealthTrackingState copyWith({
    DailyHealthSummaryEntity? summary,
    String? lastEncouragement,
    bool clearEncouragement = false,
  }) {
    return DailyHealthTrackingState(
      summary: summary ?? this.summary,
      lastEncouragement: clearEncouragement
          ? null
          : lastEncouragement ?? this.lastEncouragement,
    );
  }
}

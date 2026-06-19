import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/features/dashboard/domain/services/dashboard_companion_service.dart';

void main() {
  test('selectNextAction prioritizes light items on slow days', () {
    final action = DashboardCompanionService.selectNextAction(
      mood: DashboardMoodCodes.tired,
      timeline: [
        _timeline(
          id: 'task-body',
          category: 'body',
          sortOrder: 1,
          title: 'Đi bộ',
        ),
        _timeline(
          id: 'task-water',
          category: 'water',
          sortOrder: 9,
          title: 'Uống nước',
        ),
      ],
    );

    expect(action?.id, 'task-water');
  });

  test(
    'buildDailySummary returns missing-data copy when metrics are empty',
    () {
      final summary = DashboardCompanionService.buildDailySummary(
        metrics: const DashboardDailyMetrics.empty(),
        sleepQuality: '',
        activityLevel: '',
      );

      expect(summary, contains('Nami chưa có đủ tín hiệu'));
    },
  );

  test('buildDailySummary nudges water when hydration is low', () {
    final summary = DashboardCompanionService.buildDailySummary(
      metrics: const DashboardDailyMetrics(
        completedTasks: 2,
        totalTasks: 3,
        completedMeals: 0,
        totalMeals: 0,
        caloriesLogged: 0,
        caloriesPlanned: 0,
        waterMl: 800,
        stepsCount: 0,
        sleepHours: 0,
        stressLevel: 0,
        dailyScore: 70,
        nutritionLogCount: 0,
      ),
      sleepQuality: '',
      activityLevel: '',
    );

    expect(summary, contains('nước'));
  });

  test('buildScoreBreakdown returns expected user-facing groups', () {
    final items = DashboardCompanionService.buildScoreBreakdown(
      metrics: const DashboardDailyMetrics(
        completedTasks: 1,
        totalTasks: 2,
        completedMeals: 1,
        totalMeals: 2,
        caloriesLogged: 300,
        caloriesPlanned: 600,
        waterMl: 1000,
        stepsCount: 3000,
        sleepHours: 6,
        stressLevel: 0,
        dailyScore: 60,
        nutritionLogCount: 1,
      ),
      sleepQuality: 'Ngủ ổn',
      activityLevel: 'Đi bộ nhẹ',
    );

    expect(items.map((item) => item.title), [
      'Nhiệm vụ',
      'Nước',
      'Bữa ăn',
      'Vận động',
      'Giấc ngủ',
    ]);
  });
}

DashboardTimelineItem _timeline({
  required String id,
  required String category,
  required int sortOrder,
  required String title,
}) {
  return DashboardTimelineItem(
    id: id,
    sourceType: DashboardTimelineSourceTypes.task,
    sourceId: id,
    status: DashboardTimelineStatus.pending,
    canComplete: true,
    timeLabel: '08:00',
    title: title,
    subtitle: '',
    category: category,
    isCompleted: false,
    sortOrder: sortOrder,
  );
}

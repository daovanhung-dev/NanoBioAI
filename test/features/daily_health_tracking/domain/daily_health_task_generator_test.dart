import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_summary_entity.dart';
import 'package:nano_app/features/daily_health_tracking/domain/services/daily_health_task_generator.dart';

void main() {
  const generator = DailyHealthTaskGenerator();

  test('generates at least four default category tasks', () {
    final tasks = generator.generate(
      profile: const DailyHealthProfileEntity(
        userId: 'u1',
        fullName: 'Test User',
        goals: [],
        conditions: [],
        habits: [],
        sleepQuality: 'Ngủ ngon',
        activityLevel: 'Ít vận động',
        waterPerDay: 'Dưới 1 lít nước/ngày',
      ),
      taskDate: '2026-06-16',
      createdAt: '2026-06-16T08:00:00',
    );

    expect(tasks.length, greaterThanOrEqualTo(4));
    expect(
      tasks.map((task) => task.category).toSet(),
      containsAll(['water', 'body', 'mind', 'brain']),
    );
  });

  test('personalizes low water, sedentary, stress, and sleep risks', () {
    final tasks = generator.generate(
      profile: const DailyHealthProfileEntity(
        userId: 'u1',
        fullName: 'Test User',
        goals: ['reduce_stress'],
        conditions: ['insomnia', 'stress'],
        habits: ['low_water', 'fast_food'],
        sleepQuality: 'Mất ngủ',
        activityLevel: 'Ít vận động',
        waterPerDay: 'Dưới 1 lít nước/ngày',
      ),
      taskDate: '2026-06-16',
      createdAt: '2026-06-16T08:00:00',
    );

    expect(tasks.length, lessThanOrEqualTo(6));
    expect(tasks.any((task) => task.taskCode == 'water_morning'), isTrue);
    expect(tasks.any((task) => task.taskCode == 'mind_sleep_reset'), isTrue);

    final water = tasks.singleWhere((task) => task.taskCode == 'water_daily');
    final body = tasks.singleWhere((task) => task.taskCode == 'body_steps');
    expect(water.targetValue, 1500);
    expect(body.targetValue, 3000);
  });

  test('summary score and category progress are calculated from tasks', () {
    final tasks = generator.generate(
      profile: const DailyHealthProfileEntity(
        userId: 'u1',
        fullName: 'Test User',
        goals: [],
        conditions: [],
        habits: [],
        sleepQuality: 'Ngủ ngon',
        activityLevel: 'Nhẹ',
        waterPerDay: '1.5-2 lít nước/ngày',
      ),
      taskDate: '2026-06-16',
      createdAt: '2026-06-16T08:00:00',
    );

    final completedTask = tasks.first.copyWith(
      currentValue: tasks.first.targetValue,
      isCompleted: true,
    );
    final summary = DailyHealthSummaryEntity(
      userId: 'u1',
      fullName: 'Test User',
      taskDate: '2026-06-16',
      tasks: [completedTask, ...tasks.skip(1)],
    );

    expect(summary.score, 25);
    expect(summary.categoryProgress['water'], 1);
  });
}

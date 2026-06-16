import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/health_tracking_log_model.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_task_model.dart';

void main() {
  test('DailyHealthTaskModel maps booleans and values for SQLite', () {
    const model = DailyHealthTaskModel(
      id: 'task-1',
      userId: 'u1',
      taskDate: '2026-06-16',
      taskCode: 'water_daily',
      category: 'water',
      title: 'Drink water',
      description: 'Drink enough water',
      targetValue: 2000,
      currentValue: 500,
      unit: 'ml',
      isCompleted: false,
      sortOrder: 1,
      source: 'profile',
      encouragement: 'Nice',
      createdAt: '2026-06-16T08:00:00',
      updatedAt: '2026-06-16T08:00:00',
    );

    final map = model.toMap();
    expect(map['is_completed'], 0);
    expect(map['target_value'], 2000);

    final restored = DailyHealthTaskModel.fromMap({...map, 'is_completed': 1});

    expect(restored.isCompleted, isTrue);
    expect(restored.toEntity().progressRatio, .25);
  });

  test('HealthTrackingLogModel maps date and metric fields', () {
    const model = HealthTrackingLogModel(
      id: 'log-1',
      userId: 'u1',
      logDate: '2026-06-16',
      waterMl: 750,
      stepsCount: 1200,
      createdAt: '2026-06-16T08:00:00',
      updatedAt: '2026-06-16T09:00:00',
    );

    final map = model.toMap();
    expect(map['log_date'], '2026-06-16');
    expect(map['water_ml'], 750);

    final restored = HealthTrackingLogModel.fromJson(map);
    expect(restored.logDate, '2026-06-16');
    expect(restored.stepsCount, 1200);
  });
}

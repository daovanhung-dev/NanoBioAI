import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/daily_schedule_score_service.dart';

void main() {
  test('manual tasks never change official daily schedule health score', () {
    final result = DailyScheduleScoreService.calculate(
      items: [
        _item(id: 'generated-1', completed: true),
        _item(id: 'generated-2', completed: false),
        _item(
          id: 'manual-1',
          completed: true,
          sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
        ),
        _item(
          id: 'manual-2',
          completed: true,
          sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
        ),
      ],
      scheduleDate: '2026-08-17',
      now: DateTime(2026, 8, 17, 12),
    );

    expect(result.dueItems, 2);
    expect(result.completedDueItems, 1);
    expect(result.score, 50);
    expect(
      DailyScheduleScoreService.formulaVersion,
      'daily_schedule_equal_v2_2026_08',
    );
  });
}

LifestyleScheduleItemEntity _item({
  required String id,
  required bool completed,
  String sourceType = LifestyleScheduleSourceTypes.aiSchedule,
}) {
  return LifestyleScheduleItemEntity(
    id: id,
    userId: 'user-1',
    scheduleDate: '2026-08-17',
    startTime: '09:00',
    title: id,
    category: LifestyleScheduleCategories.routine,
    sourceType: sourceType,
    isCompleted: completed,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/manual_health_task_draft.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_health_action_type.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/schedule_health_action_policy.dart';

void main() {
  test('meal and exercise keep photo proof completion', () {
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(
          sourceType: LifestyleScheduleSourceTypes.mealPlan,
          category: LifestyleScheduleCategories.meal,
        ),
      ),
      ScheduleHealthActionType.photoProof,
    );
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(
          sourceType: LifestyleScheduleSourceTypes.exerciseTask,
          category: LifestyleScheduleCategories.body,
        ),
      ),
      ScheduleHealthActionType.photoProof,
    );
  });

  test('routine health categories use lightweight actions', () {
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(category: LifestyleScheduleCategories.water),
      ),
      ScheduleHealthActionType.hydration,
    );
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(category: LifestyleScheduleCategories.metric),
      ),
      ScheduleHealthActionType.weightCheckIn,
    );
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(category: LifestyleScheduleCategories.routine),
      ),
      ScheduleHealthActionType.quickComplete,
    );
  });

  test('manual metadata preserves action reminder and repeat contract', () {
    const metadata = ManualHealthTaskMetadata(
      seriesId: '9bd3f704-f950-4ee1-95e4-7dc018b73b08',
      actionType: ScheduleHealthActionType.moodStress,
      reminderEnabled: false,
      repeat: ManualHealthTaskRepeat.weekdays,
    );
    final parsed = ManualHealthTaskMetadata.tryParse(metadata.encode());

    expect(parsed, isNotNull);
    expect(parsed!.seriesId, metadata.seriesId);
    expect(parsed.actionType, ScheduleHealthActionType.moodStress);
    expect(parsed.reminderEnabled, isFalse);
    expect(parsed.repeat, ManualHealthTaskRepeat.weekdays);
    expect(
      ScheduleHealthActionPolicy.forItem(
        _item(
          sourceType: LifestyleScheduleSourceTypes.manualHealthTask,
          category: LifestyleScheduleCategories.mind,
          sourceId: metadata.encode(),
        ),
      ),
      ScheduleHealthActionType.moodStress,
    );
  });

  test('repeat generation is bounded to seven-day horizon', () {
    final draft = ManualHealthTaskDraft(
      firstDate: _FixedDate.monday,
      startTime: '09:00',
      title: 'Nghỉ mắt',
      category: LifestyleScheduleCategories.routine,
      actionType: ScheduleHealthActionType.quickComplete,
      repeat: ManualHealthTaskRepeat.weekdays,
    );

    final dates = draft.occurrenceDates();

    expect(dates, hasLength(5));
    expect(dates.first.weekday, DateTime.monday);
    expect(dates.last.weekday, DateTime.friday);
  });

  test('manual tasks can never request photo proof action', () {
    final draft = ManualHealthTaskDraft(
      firstDate: _FixedDate.monday,
      startTime: '09:00',
      title: 'Tự chụp ảnh',
      category: LifestyleScheduleCategories.routine,
      actionType: ScheduleHealthActionType.photoProof,
    );

    expect(draft.validate(), contains('Nhiệm vụ tự tạo không dùng ảnh minh chứng bắt buộc.'));
  });
}

class _FixedDate {
  static final monday = DateTime(2026, 8, 17);
}

LifestyleScheduleItemEntity _item({
  String sourceType = LifestyleScheduleSourceTypes.aiSchedule,
  String category = LifestyleScheduleCategories.routine,
  String? sourceId,
}) {
  return LifestyleScheduleItemEntity(
    id: 'item-1',
    userId: 'user-1',
    scheduleDate: '2026-08-17',
    startTime: '09:00',
    title: 'Nhiệm vụ',
    category: category,
    sourceType: sourceType,
    sourceId: sourceId,
  );
}

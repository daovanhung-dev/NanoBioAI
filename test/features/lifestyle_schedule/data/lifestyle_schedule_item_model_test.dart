import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';

void main() {
  test('LifestyleScheduleItemModel maps SQLite and JSON fields', () {
    final map = {
      'id': 'schedule-1',
      'user_id': 'u1',
      'schedule_date': '2026-06-17',
      'start_time': '07:00',
      'end_time': '07:30',
      'title': 'Breakfast',
      'description': 'Eat the generated breakfast',
      'category': 'meal',
      'source_type': 'meal_plan',
      'source_id': 'meal-1',
      'target_value': 1,
      'current_value': 0,
      'unit': 'lan',
      'is_completed': 0,
      'sort_order': 2,
      'ai_generated': 1,
      'encouragement': 'Nice',
      'created_at': '2026-06-16T08:00:00',
      'updated_at': '2026-06-16T08:00:00',
    };

    final model = LifestyleScheduleItemModel.fromMap(map);

    expect(model.id, 'schedule-1');
    expect(model.isCompleted, isFalse);
    expect(model.aiGenerated, isTrue);
    expect(model.toMap()['is_completed'], 0);
    expect(model.toMap()['ai_generated'], 1);
    expect(model.toJson()['is_completed'], isFalse);
    expect(model.toEntity().sourceId, 'meal-1');
  });
}

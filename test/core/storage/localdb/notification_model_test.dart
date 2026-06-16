import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('round-trips all reminder fields through map serialization', () {
      const model = NotificationModel(
        id: 'reminder_meal_meal-1_2026-06-17T07:00:00.000',
        userId: 'user-1',
        title: 'Meal reminder',
        body: 'Time for breakfast',
        type: 'reminder',
        isRead: true,
        sourceType: 'meal',
        sourceId: 'meal-1',
        scheduledAt: '2026-06-17T07:00:00.000',
        notificationId: 12345,
        actionStatus: NotificationActionStatuses.done,
        respondedAt: '2026-06-17T07:05:00.000',
        payload: '{"sourceType":"meal"}',
        createdAt: '2026-06-16T08:00:00.000',
        updatedAt: '2026-06-17T07:05:00.000',
      );

      final restored = NotificationModel.fromMap(model.toMap());

      expect(restored.id, model.id);
      expect(restored.userId, model.userId);
      expect(restored.title, model.title);
      expect(restored.body, model.body);
      expect(restored.type, model.type);
      expect(restored.isRead, isTrue);
      expect(restored.sourceType, model.sourceType);
      expect(restored.sourceId, model.sourceId);
      expect(restored.scheduledAt, model.scheduledAt);
      expect(restored.notificationId, model.notificationId);
      expect(restored.actionStatus, model.actionStatus);
      expect(restored.respondedAt, model.respondedAt);
      expect(restored.payload, model.payload);
      expect(restored.createdAt, model.createdAt);
      expect(restored.updatedAt, model.updatedAt);

      expect(model.toMap()['is_read'], 1);
    });

    test('parses read status from int, bool, and string values', () {
      expect(
        NotificationModel.fromMap({'id': 'n1', 'is_read': 1}).isRead,
        true,
      );
      expect(
        NotificationModel.fromMap({'id': 'n2', 'is_read': true}).isRead,
        true,
      );
      expect(
        NotificationModel.fromMap({'id': 'n3', 'is_read': 'yes'}).isRead,
        true,
      );
      expect(
        NotificationModel.fromMap({'id': 'n4', 'is_read': 0}).isRead,
        false,
      );
    });

    test('parses notification id from number and string values', () {
      expect(
        NotificationModel.fromMap({
          'id': 'n1',
          'notification_id': 42.7,
        }).notificationId,
        42,
      );
      expect(
        NotificationModel.fromMap({
          'id': 'n2',
          'notification_id': '123',
        }).notificationId,
        123,
      );
    });

    test('defaults action status to pending when it is missing', () {
      final model = NotificationModel.fromMap({'id': 'n1'});

      expect(model.actionStatus, NotificationActionStatuses.pending);
    });
  });
}

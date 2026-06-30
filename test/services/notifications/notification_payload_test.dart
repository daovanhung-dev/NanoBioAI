import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_payload.dart';

void main() {
  test('parses legacy payload without subject metadata', () {
    final payload = NotificationPayload.fromJsonString(
      '{"notificationId":101,"sourceType":"lifestyle_schedule_item",'
      '"sourceId":"schedule-1","scheduledAt":"2026-06-17T07:00:00.000"}',
    );

    expect(payload.payloadVersion, 1);
    expect(payload.notificationId, 101);
    expect(payload.sourceType, 'lifestyle_schedule_item');
    expect(payload.sourceId, 'schedule-1');
    expect(payload.scheduledAt, '2026-06-17T07:00:00.000');
    expect(payload.subjectUserId, isNull);
  });

  test('round trips subject-aware payload metadata', () {
    final json = NotificationPayload(
      notificationId: 202,
      sourceType: 'lifestyle_schedule_item',
      sourceId: 'schedule-2',
      scheduledAt: '2026-06-18T07:00:00.000',
      subjectUserId: 'user-2',
      actorUserId: 'user-1',
      familyPackageId: 'family-1',
      correlationId: 'corr-1',
    ).toJsonString();

    final payload = NotificationPayload.fromJsonString(json);

    expect(payload.payloadVersion, NotificationPayload.currentPayloadVersion);
    expect(payload.notificationId, 202);
    expect(payload.subjectUserId, 'user-2');
    expect(payload.actorUserId, 'user-1');
    expect(payload.familyPackageId, 'family-1');
    expect(payload.correlationId, 'corr-1');
  });
}

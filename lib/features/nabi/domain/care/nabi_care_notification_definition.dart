import '../notifications/nabi_notification_models.dart';

abstract final class NabiCareNotificationDefinition {
  static const id = 'NBI-CARE-AI-001';

  static const definition = NabiNotificationDefinition(
    id: id,
    contentVersion: 1,
    category: NabiNotificationCategory.care,
    priority: 650,
    policyKey: 'ai_care_ready',
    audiences: {
      'guest',
      'free',
      'plus_monthly',
      'plus_yearly',
      'family_plus',
    },
    title: 'NaBi vừa xem dữ liệu của bạn',
    body: '{care_summary}',
    emotionKey: 'listening',
    primaryLabel: 'Xem NaBi Care',
    primaryDestination: NabiNotificationDestination(actionKey: 'nabi_care'),
    channels: {NabiNotificationChannel.inApp},
    cooldown: Duration(hours: 6),
    requiredVariables: {'care_summary'},
  );
}

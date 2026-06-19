import 'dart:convert';

class NotificationPayload {
  final int notificationId;
  final String sourceType;
  final String sourceId;
  final String scheduledAt;

  const NotificationPayload({
    required this.notificationId,
    required this.sourceType,
    required this.sourceId,
    required this.scheduledAt,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      notificationId: _readInt(json['notificationId']) ?? 0,
      sourceType: json['sourceType']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      scheduledAt: json['scheduledAt']?.toString() ?? '',
    );
  }

  factory NotificationPayload.fromJsonString(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      throw const FormatException('Notification payload must be a JSON object');
    }
    return NotificationPayload.fromJson(Map<String, dynamic>.from(decoded));
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'scheduledAt': scheduledAt,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

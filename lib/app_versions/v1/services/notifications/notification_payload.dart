import 'dart:convert';

class NotificationPayload {
  static const currentPayloadVersion = 2;

  final int payloadVersion;
  final int notificationId;
  final String sourceType;
  final String sourceId;
  final String scheduledAt;
  final String? subjectUserId;
  final String? actorUserId;
  final String? familyPackageId;
  final String? correlationId;

  const NotificationPayload({
    this.payloadVersion = currentPayloadVersion,
    required this.notificationId,
    required this.sourceType,
    required this.sourceId,
    required this.scheduledAt,
    this.subjectUserId,
    this.actorUserId,
    this.familyPackageId,
    this.correlationId,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      payloadVersion: _readInt(json['payloadVersion']) ?? 1,
      notificationId: _readInt(json['notificationId']) ?? 0,
      sourceType: json['sourceType']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      scheduledAt: json['scheduledAt']?.toString() ?? '',
      subjectUserId: _readString(json['subjectUserId']),
      actorUserId: _readString(json['actorUserId']),
      familyPackageId: _readString(json['familyPackageId']),
      correlationId: _readString(json['correlationId']),
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
      'payloadVersion': payloadVersion,
      'notificationId': notificationId,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'scheduledAt': scheduledAt,
      if (subjectUserId != null) 'subjectUserId': subjectUserId,
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (familyPackageId != null) 'familyPackageId': familyPackageId,
      if (correlationId != null) 'correlationId': correlationId,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _readString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

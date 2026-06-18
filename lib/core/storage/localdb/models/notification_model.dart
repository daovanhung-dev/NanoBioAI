class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? sourceType;
  final String? sourceId;
  final String? scheduledAt;
  final int? notificationId;
  final String actionStatus;
  final String? respondedAt;
  final String? payload;
  final String createdAt;
  final String updatedAt;

  const NotificationModel({
    required this.id,
    this.userId,
    this.title = '',
    this.body = '',
    this.type = '',
    this.isRead = false,
    this.sourceType,
    this.sourceId,
    this.scheduledAt,
    this.notificationId,
    this.actionStatus = NotificationActionStatuses.pending,
    this.respondedAt,
    this.payload,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isRead: _readBool(map['is_read']),
      sourceType: map['source_type']?.toString(),
      sourceId: map['source_id']?.toString(),
      scheduledAt: map['scheduled_at']?.toString(),
      notificationId: _readInt(map['notification_id']),
      actionStatus:
          map['action_status']?.toString() ??
          NotificationActionStatuses.pending,
      respondedAt: map['responded_at']?.toString(),
      payload: map['payload']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'source_type': sourceType,
      'source_id': sourceId,
      'scheduled_at': scheduledAt,
      'notification_id': notificationId,
      'action_status': actionStatus,
      'responded_at': respondedAt,
      'payload': payload,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    String? sourceType,
    String? sourceId,
    String? scheduledAt,
    int? notificationId,
    String? actionStatus,
    String? respondedAt,
    String? payload,
    String? createdAt,
    String? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      actionStatus: actionStatus ?? this.actionStatus,
      respondedAt: respondedAt ?? this.respondedAt,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes';
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class NotificationActionStatuses {
  static const pending = 'pending';
  static const done = 'done';
  static const skipped = 'skipped';
  static const permissionDenied = 'permission_denied';
  static const scheduleFailed = 'schedule_failed';
  static const actionFailed = 'action_failed';
}

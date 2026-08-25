import 'dart:convert';

import 'package:nano_app/features/nabi/domain/notifications/nabi_health_reminder_preferences.dart';

class NabiCompanionNotificationPayload {
  static const currentVersion = 1;

  final int version;
  final String occurrenceId;
  final String actorKey;
  final NabiHealthReminderCategory category;
  final String scheduledAt;
  final bool voiceEnabled;

  const NabiCompanionNotificationPayload({
    this.version = currentVersion,
    required this.occurrenceId,
    required this.actorKey,
    required this.category,
    required this.scheduledAt,
    required this.voiceEnabled,
  });

  Map<String, Object?> toJson() => {
        'type': 'nabi_companion',
        'version': version,
        'occurrenceId': occurrenceId,
        'actorKey': actorKey,
        'category': category.payloadValue,
        'scheduledAt': scheduledAt,
        'voiceEnabled': voiceEnabled,
      };

  String toJsonString() => jsonEncode(toJson());

  static NabiCompanionNotificationPayload? tryParse(String? payload) {
    final raw = payload?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, Object?>.from(decoded);
      if (map['type']?.toString() != 'nabi_companion') return null;
      final occurrenceId = map['occurrenceId']?.toString().trim() ?? '';
      final actorKey = map['actorKey']?.toString().trim() ?? '';
      final category = nabiHealthReminderCategoryFromValue(
        map['category']?.toString() ?? '',
      );
      final scheduledAt = map['scheduledAt']?.toString().trim() ?? '';
      if (occurrenceId.isEmpty ||
          actorKey.isEmpty ||
          category == null ||
          DateTime.tryParse(scheduledAt) == null) {
        return null;
      }
      final version = _readInt(map['version']) ?? currentVersion;
      if (version > currentVersion || version < 1) return null;
      return NabiCompanionNotificationPayload(
        version: version,
        occurrenceId: occurrenceId,
        actorKey: actorKey,
        category: category,
        scheduledAt: scheduledAt,
        voiceEnabled: _readBool(map['voiceEnabled']),
      );
    } catch (_) {
      return null;
    }
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}

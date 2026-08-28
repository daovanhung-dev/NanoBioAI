enum AiContentReportReason {
  incorrect(code: 'incorrect', label: 'Thông tin có vẻ sai'),
  unsafe(code: 'unsafe', label: 'Có thể gây hại hoặc không an toàn'),
  inappropriate(
    code: 'inappropriate',
    label: 'Nội dung không phù hợp / xúc phạm',
  ),
  privacy(code: 'privacy', label: 'Vấn đề quyền riêng tư'),
  other(code: 'other', label: 'Khác');

  final String code;
  final String label;

  const AiContentReportReason({required this.code, required this.label});
}

class AiContentReport {
  static const maxMessageIdLength = 160;
  static const maxSnapshotLength = 4000;
  static const maxNoteLength = 500;
  static const maxAppVersionLength = 64;

  final String messageId;
  final AiContentReportReason reason;
  final String? note;
  final String messageSnapshot;
  final String appVersion;
  final String? installationId;

  const AiContentReport({
    required this.messageId,
    required this.reason,
    required this.messageSnapshot,
    required this.appVersion,
    this.note,
    this.installationId,
  });

  Map<String, Object?> toMap() {
    return {
      'message_id': messageId.trim(),
      'message_role': 'assistant',
      'reason_code': reason.code,
      'note': _bounded(note, maxNoteLength),
      'message_snapshot': _bounded(messageSnapshot, maxSnapshotLength),
      'app_version': _bounded(appVersion, maxAppVersionLength),
      if (installationId?.trim().isNotEmpty == true)
        'installation_id': _bounded(installationId, 128),
    };
  }

  String? _bounded(String? value, int length) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= length ? trimmed : trimmed.substring(0, length);
  }
}

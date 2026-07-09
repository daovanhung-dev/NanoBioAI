class WellnessPointLedgerModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String sourceType;
  final String sourceId;
  final String scheduleDate;
  final int pointsDelta;
  final String programCode;
  final String idempotencyKey;
  final String createdAt;
  final String updatedAt;

  const WellnessPointLedgerModel({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.sourceType,
    required this.sourceId,
    required this.scheduleDate,
    required this.pointsDelta,
    required this.programCode,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WellnessPointLedgerModel.fromMap(Map<String, dynamic> map) {
    return WellnessPointLedgerModel(
      id: _readString(map['id']),
      userId: _readString(map['user_id']),
      subjectId: _readNullableString(map['subject_id']),
      sourceType: _readString(map['source_type']),
      sourceId: _readString(map['source_id']),
      scheduleDate: _readString(map['schedule_date']),
      pointsDelta: _readInt(map['points_delta']) ?? 0,
      programCode: _readString(map['program_code']),
      idempotencyKey: _readString(map['idempotency_key']),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'source_type': sourceType,
      'source_id': sourceId,
      'schedule_date': scheduleDate,
      'points_delta': pointsDelta,
      'program_code': programCode,
      'idempotency_key': idempotencyKey,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class HealthScoreLedgerModel {
  final String id;
  final String userId;
  final String? subjectId;
  final String periodStart;
  final String periodEnd;
  final int score;
  final String formulaVersion;
  final String breakdown;
  final String? idempotencyKey;
  final String calculatedAt;
  final String createdAt;
  final String updatedAt;

  const HealthScoreLedgerModel({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.periodStart,
    required this.periodEnd,
    required this.score,
    required this.formulaVersion,
    this.breakdown = '{}',
    this.idempotencyKey,
    required this.calculatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthScoreLedgerModel.fromMap(Map<String, dynamic> map) {
    return HealthScoreLedgerModel(
      id: _readString(map['id']),
      userId: _readString(map['user_id']),
      subjectId: _readNullableString(map['subject_id']),
      periodStart: _readString(map['period_start']),
      periodEnd: _readString(map['period_end']),
      score: _readInt(map['score']) ?? 0,
      formulaVersion: _readString(map['formula_version']),
      breakdown: _readString(map['breakdown'], fallback: '{}'),
      idempotencyKey: _readNullableString(map['idempotency_key']),
      calculatedAt: _readString(map['calculated_at']),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'period_start': periodStart,
      'period_end': periodEnd,
      'score': score,
      'formula_version': formulaVersion,
      'breakdown': breakdown,
      'idempotency_key': idempotencyKey,
      'calculated_at': calculatedAt,
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

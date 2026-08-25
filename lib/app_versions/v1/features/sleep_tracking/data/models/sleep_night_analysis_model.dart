import 'dart:convert';

import '../../domain/entities/sleep_morning_checkin.dart';
import '../../domain/entities/sleep_night_analysis.dart';

class SleepNightAnalysisModelMapper {
  const SleepNightAnalysisModelMapper._();

  static Map<String, Object?> toMap(SleepNightAnalysis value) => {
        'session_id': value.sessionId,
        'user_id': value.userId,
        'formula_version': value.formulaVersion,
        'started_at': value.startedAt.toIso8601String(),
        'ended_at': value.endedAt?.toIso8601String(),
        'metrics_json': jsonEncode(value.metrics),
        'event_distribution_json': jsonEncode(value.eventDistribution),
        'trend_json': jsonEncode(value.trend),
        'data_quality_score': value.dataQualityScore,
        'safety_attention_score': value.safetyAttentionScore,
        'sleep_wellness_score': value.sleepWellnessScore,
        'morning_checkin_json': value.morningCheckin == null
            ? null
            : jsonEncode(value.morningCheckin!.toJson()),
        'ai_analysis_json': value.aiAnalysisJson == null
            ? null
            : jsonEncode(value.aiAnalysisJson),
        'ai_model': value.aiModel,
        'ai_generated_at': value.aiGeneratedAt?.toIso8601String(),
        'ai_request_fingerprint': value.aiRequestFingerprint,
        'created_at': value.createdAt.toIso8601String(),
        'updated_at': value.updatedAt.toIso8601String(),
      };

  static SleepNightAnalysis fromMap(Map<String, Object?> row) {
    return SleepNightAnalysis(
      sessionId: row['session_id'].toString(),
      userId: row['user_id'].toString(),
      formulaVersion: row['formula_version']?.toString() ?? 'unknown',
      startedAt: _date(row['started_at']) ?? DateTime.now(),
      endedAt: _date(row['ended_at']),
      metrics: _doubleMap(row['metrics_json']),
      eventDistribution: _intMap(row['event_distribution_json']),
      trend: _doubleMap(row['trend_json']),
      dataQualityScore: (row['data_quality_score'] as num?)?.toDouble() ?? 0,
      safetyAttentionScore:
          (row['safety_attention_score'] as num?)?.toDouble() ?? 0,
      sleepWellnessScore:
          (row['sleep_wellness_score'] as num?)?.toDouble() ?? 0,
      morningCheckin: _checkin(row['morning_checkin_json']),
      aiAnalysisJson: _objectMap(row['ai_analysis_json']),
      aiModel: row['ai_model']?.toString(),
      aiGeneratedAt: _date(row['ai_generated_at']),
      aiRequestFingerprint: row['ai_request_fingerprint']?.toString(),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      updatedAt: _date(row['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : DateTime.tryParse(text);
  }

  static Object? _decode(Object? raw) {
    final text = raw?.toString();
    if (text == null || text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static Map<String, double> _doubleMap(Object? raw) {
    final decoded = _decode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).toDouble(),
    };
  }

  static Map<String, int> _intMap(Object? raw) {
    final decoded = _decode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).toInt(),
    };
  }

  static Map<String, Object?>? _objectMap(Object? raw) {
    final decoded = _decode(raw);
    if (decoded is! Map) return null;
    return {
      for (final entry in decoded.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  static SleepMorningCheckin? _checkin(Object? raw) {
    final map = _objectMap(raw);
    return map == null ? null : SleepMorningCheckin.fromJson(map);
  }
}

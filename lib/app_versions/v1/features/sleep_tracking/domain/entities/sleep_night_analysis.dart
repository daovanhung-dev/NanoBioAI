import 'sleep_morning_checkin.dart';

class SleepNightAnalysis {
  const SleepNightAnalysis({
    required this.sessionId,
    required this.userId,
    required this.formulaVersion,
    required this.startedAt,
    required this.endedAt,
    required this.metrics,
    required this.eventDistribution,
    required this.trend,
    required this.dataQualityScore,
    required this.safetyAttentionScore,
    required this.sleepWellnessScore,
    required this.createdAt,
    required this.updatedAt,
    this.morningCheckin,
    this.aiAnalysisJson,
    this.aiModel,
    this.aiGeneratedAt,
    this.aiRequestFingerprint,
  });

  final String sessionId;
  final String userId;
  final String formulaVersion;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, double> metrics;
  final Map<String, int> eventDistribution;
  final Map<String, double> trend;
  final double dataQualityScore;
  final double safetyAttentionScore;
  final double sleepWellnessScore;
  final SleepMorningCheckin? morningCheckin;
  final Map<String, Object?>? aiAnalysisJson;
  final String? aiModel;
  final DateTime? aiGeneratedAt;
  final String? aiRequestFingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepNightAnalysis copyWith({
    Map<String, double>? metrics,
    Map<String, int>? eventDistribution,
    Map<String, double>? trend,
    double? dataQualityScore,
    double? safetyAttentionScore,
    double? sleepWellnessScore,
    SleepMorningCheckin? morningCheckin,
    bool clearMorningCheckin = false,
    Map<String, Object?>? aiAnalysisJson,
    bool clearAiAnalysis = false,
    String? aiModel,
    DateTime? aiGeneratedAt,
    String? aiRequestFingerprint,
    DateTime? updatedAt,
  }) {
    return SleepNightAnalysis(
      sessionId: sessionId,
      userId: userId,
      formulaVersion: formulaVersion,
      startedAt: startedAt,
      endedAt: endedAt,
      metrics: metrics ?? this.metrics,
      eventDistribution: eventDistribution ?? this.eventDistribution,
      trend: trend ?? this.trend,
      dataQualityScore: dataQualityScore ?? this.dataQualityScore,
      safetyAttentionScore: safetyAttentionScore ?? this.safetyAttentionScore,
      sleepWellnessScore: sleepWellnessScore ?? this.sleepWellnessScore,
      morningCheckin:
          clearMorningCheckin ? null : morningCheckin ?? this.morningCheckin,
      aiAnalysisJson:
          clearAiAnalysis ? null : aiAnalysisJson ?? this.aiAnalysisJson,
      aiModel: clearAiAnalysis ? null : aiModel ?? this.aiModel,
      aiGeneratedAt:
          clearAiAnalysis ? null : aiGeneratedAt ?? this.aiGeneratedAt,
      aiRequestFingerprint: clearAiAnalysis
          ? null
          : aiRequestFingerprint ?? this.aiRequestFingerprint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toSafeAiPayload() => {
        'schema_version': 'm31_sleep_ai_v1',
        'formula_version': formulaVersion,
        'session': {
          'started_at': startedAt.toIso8601String(),
          'ended_at': endedAt?.toIso8601String(),
        },
        'metrics': metrics,
        'event_distribution': eventDistribution,
        'trend_7_nights': trend,
        'morning_checkin': morningCheckin?.toJson(),
        'data_quality_score': dataQualityScore,
        'safety_attention_score': safetyAttentionScore,
        'sleep_wellness_score': sleepWellnessScore,
      };
}

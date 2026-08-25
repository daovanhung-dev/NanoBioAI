import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/services/sleep_analysis_ai_service.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_night_analysis.dart';

void main() {
  test('AI payload excludes identity, audio, phone and API key material', () async {
    late Map<String, Object?> captured;
    final service = SleepAnalysisAIService(
      modelOverride: 'test-model',
      textGenerator: ({required model, required payload}) async {
        captured = payload;
        return jsonEncode({
          for (final key in const [
            'overall_summary',
            'night_pattern',
            'acoustic_event_analysis',
            'seven_night_trend',
            'wellness_observations',
            'recommended_actions',
            'what_to_monitor_next',
            'data_limitations',
            'care_guidance',
          ])
            key: {
              'title': key,
              'summary': 'Tóm tắt',
              'evidence': ['Chỉ số tổng hợp'],
              'recommendations': ['Theo dõi thêm'],
              'confidence': 0.7,
            },
        });
      },
    );
    final analysis = SleepNightAnalysis(
      sessionId: 'session-secret',
      userId: 'user-secret',
      formulaVersion: 'v1',
      startedAt: DateTime(2026, 8, 24, 22),
      endedAt: DateTime(2026, 8, 25, 6),
      metrics: const {'eventCount': 2},
      eventDistribution: const {'suddenLoudSound': 2},
      trend: const {'nightCount': 3},
      dataQualityScore: 1,
      safetyAttentionScore: 20,
      sleepWellnessScore: 80,
      createdAt: DateTime(2026, 8, 25, 6),
      updatedAt: DateTime(2026, 8, 25, 6),
    );

    final result = await service.generate(analysis);
    final encoded = jsonEncode(captured).toLowerCase();
    expect(result.sections, hasLength(9));
    expect(encoded, isNot(contains('user-secret')));
    expect(encoded, isNot(contains('session-secret')));
    expect(encoded, isNot(contains('phone')));
    expect(encoded, isNot(contains('api_key')));
    expect(encoded, isNot(contains('pcm')));
    expect(encoded, isNot(contains('audio_blob')));
    expect(encoded, isNot(contains('transcript')));
  });
}

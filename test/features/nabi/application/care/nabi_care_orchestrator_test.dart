import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_ai_analyzer.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_orchestrator.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_models.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_repository.dart';

void main() {
  test('reuses cached analysis when fingerprint is unchanged', () async {
    final clock = DateTime(2026, 8, 24, 12);
    final repository = _FakeRepository(clock);
    final gateway = _CountingGateway(clock);
    final orchestrator = NabiCareOrchestrator(
      repository: repository,
      aiAnalyzer: NabiCareAiAnalyzer(gateway: gateway, now: () => clock),
      now: () => clock,
    );

    final first = await orchestrator.evaluate(
      trigger: NabiCareTrigger.appOpen,
    );
    final second = await orchestrator.evaluate(
      trigger: NabiCareTrigger.appResume,
    );

    expect(gateway.calls, 1);
    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.fingerprint, first.fingerprint);
  });

  test('AI payload excludes direct identity fields', () async {
    final clock = DateTime(2026, 8, 24, 12);
    final repository = _FakeRepository(clock);
    final gateway = _CountingGateway(clock);
    final orchestrator = NabiCareOrchestrator(
      repository: repository,
      aiAnalyzer: NabiCareAiAnalyzer(gateway: gateway, now: () => clock),
      now: () => clock,
    );

    await orchestrator.evaluate(
      trigger: NabiCareTrigger.manualReview,
      force: true,
    );

    final payload = gateway.lastPayload!;
    final encoded = jsonEncode(payload);
    expect(encoded, isNot(contains('demo@example.com')));
    expect(encoded, isNot(contains('0900000000')));
    expect(encoded, isNot(contains('Nguyen Demo')));
    expect(payload.containsKey('actorKey'), isFalse);
  });
}

class _CountingGateway implements NabiCareAiGateway {
  final DateTime clock;
  int calls = 0;
  Map<String, Object?>? lastPayload;

  _CountingGateway(this.clock);

  @override
  Future<String> generateAnalysis({
    required Map<String, Object?> payload,
    required String systemInstruction,
  }) async {
    calls++;
    lastPayload = payload;
    return jsonEncode({
      'overall_status': 'stable',
      'summary': 'Dữ liệu gần đây đang khá ổn định.',
      'observations': [
        {
          'title': 'Giấc ngủ cần theo dõi',
          'detail': 'Thời lượng ngủ mới nhất thấp hơn baseline cá nhân.',
          'severity': 'low',
          'confidence': 0.9,
          'evidence_keys': [
            'health.sleep_hours.current',
            'baseline.sleep_hours_avg_7d',
          ],
        },
      ],
      'care_actions': [
        {
          'id': 'sleep-routine',
          'title': 'Ưu tiên giờ nghỉ',
          'description': 'Thử dành một khoảng nghỉ sớm hơn tối nay.',
          'priority': 1,
          'channel_hint': 'in_app',
          'evidence_keys': ['health.sleep_hours.current'],
        },
      ],
      'questions': [],
      'attention_flags': [],
      'missing_data': [],
      'next_review_at': clock.add(const Duration(hours: 12)).toIso8601String(),
    });
  }
}

class _FakeRepository implements NabiCareRepository {
  final DateTime clock;
  NabiCareCachedAnalysis? cached;

  _FakeRepository(this.clock);

  @override
  Future<NabiCareRawContext> loadRawContext({String? subjectId}) async {
    return NabiCareRawContext(
      actorKey: subjectId ?? 'user-1',
      rowsByTable: {
        'users': [
          {
            'id': 'user-1',
            'full_name': 'Nguyen Demo',
            'email': 'demo@example.com',
            'phone': '0900000000',
            'gender': 'male',
            'birth_year': 2000,
            'subscription_tier': 'free',
            'product_access_status': 'member',
          },
        ],
        'health_tracking_logs': [
          {
            'user_id': 'user-1',
            'sleep_hours': 5.0,
            'log_date': clock.toIso8601String(),
          },
          {
            'user_id': 'user-1',
            'sleep_hours': 7.0,
            'log_date': clock
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },
        ],
      },
    );
  }

  @override
  Future<NabiCareCachedAnalysis?> loadLatestCachedAnalysis(
    String actorKey,
  ) async => cached;

  @override
  Future<void> saveAnalysis({
    required String actorKey,
    required String fingerprint,
    required NabiCareAnalysis analysis,
  }) async {
    cached = NabiCareCachedAnalysis(
      fingerprint: fingerprint,
      analysis: analysis,
      createdAt: clock,
    );
  }

  @override
  Future<void> saveFeedback({
    required String actorKey,
    required String fingerprint,
    required NabiCareFeedbackType feedback,
    String? actionId,
  }) async {}
}

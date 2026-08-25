import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_morning_checkin.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_event.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_session.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_night_analysis_service.dart';

void main() {
  const service = SleepNightAnalysisService();
  final start = DateTime(2026, 8, 24, 22);

  SleepSafetySession session({String id = 'session-1', DateTime? startedAt, DateTime? endedAt}) {
    final started = startedAt ?? start;
    return SleepSafetySession(
      id: id,
      userId: 'user-1',
      startedAt: started,
      endedAt: endedAt ?? started.add(const Duration(hours: 8)),
      sensitivity: SleepSafetySensitivity.balanced,
      status: SleepSafetySessionStatus.stopped,
      startSource: 'manual',
      platform: 'android',
      appVersion: 'test',
      createdAt: started,
      updatedAt: endedAt ?? started.add(const Duration(hours: 8)),
    );
  }

  SleepSafetyEvent event({
    required String id,
    required DateTime at,
    SleepSafetyEventType type = SleepSafetyEventType.suddenLoudSound,
    String severity = 'attention',
    double confidence = 0.8,
    double energy = 2.5,
    int repetition = 1,
    SleepSafetyResponse response = SleepSafetyResponse.ok,
    bool escalation = false,
  }) => SleepSafetyEvent(
    id: id,
    sessionId: 'session-1',
    userId: 'user-1',
    detectedAt: at,
    eventType: type,
    severity: severity,
    confidence: confidence,
    relativeEnergy: energy,
    baselineDelta: 0.04,
    repetitionCount: repetition,
    state: 'detected',
    response: response,
    responseAt: response == SleepSafetyResponse.none ? null : at.add(const Duration(seconds: 12)),
    escalationRequired: escalation,
    escalationStatus: escalation ? SleepSafetyEscalationStatus.accepted : SleepSafetyEscalationStatus.notRequired,
    createdAt: at,
    updatedAt: at.add(const Duration(seconds: 12)),
  );

  test('zero-event night remains non-clinical and bounded', () {
    final result = service.calculate(
      session: session(),
      events: const [],
      now: DateTime(2026, 8, 25, 7),
    );
    expect(result.metrics['eventCount'], 0);
    expect(result.metrics['eventsPerHour'], 0);
    expect(result.dataQualityScore, inInclusiveRange(0, 1));
    expect(result.sleepWellnessScore, inInclusiveRange(0, 100));
    expect(result.toSafeAiPayload().containsKey('user_id'), isFalse);
  });

  test('calculates response, repetition, clustering and composite metrics', () {
    final events = [
      event(
        id: 'e1',
        at: start.add(const Duration(hours: 2)),
        severity: 'high',
        confidence: 0.95,
        energy: 5.2,
        repetition: 3,
      ),
      event(
        id: 'e2',
        at: start.add(const Duration(hours: 2, minutes: 10)),
        type: SleepSafetyEventType.repeatedSuspiciousPattern,
        response: SleepSafetyResponse.noResponse,
        escalation: true,
      ),
    ];
    final result = service.calculate(session: session(), events: events);
    expect(result.metrics['eventCount'], 2);
    expect(result.metrics['highSeverityCount'], 1);
    expect(result.metrics['repeatedEventRatio'], greaterThan(0));
    expect(result.metrics['alertClusteringIndex'], greaterThan(0));
    expect(result.metrics['noResponseRate'], greaterThan(0));
    expect(result.metrics['weightedDisturbanceIndex'], greaterThan(0));
    expect(result.safetyAttentionScore, inInclusiveRange(0, 100));
  });

  test('morning check-in adds self-reported metrics without inventing stages', () {
    final result = service.calculate(
      session: session(),
      events: const [],
      morningCheckin: const SleepMorningCheckin(
        timeInBedMinutes: 480,
        sleepLatencyMinutes: 20,
        rememberedAwakenings: 2,
        awakeDuringNightMinutes: 30,
        restfulness: 4,
      ),
    );
    expect(result.metrics['estimatedTotalSleepMinutes'], 430);
    expect(result.metrics['selfReportedSleepEfficiency'], closeTo(430 / 480, 0.001));
    expect(result.metrics.keys.any((key) => key.toLowerCase().contains('rem')), isFalse);
    expect(result.metrics.keys.any((key) => key.toLowerCase().contains('deep')), isFalse);
  });
}

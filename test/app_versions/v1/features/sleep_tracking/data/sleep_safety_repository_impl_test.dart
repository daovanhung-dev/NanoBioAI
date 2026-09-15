import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/repositories/sleep_safety_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_event.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_session.dart';

void main() {
  test(
    'dispatch syncs session and event before invoking the Edge Function',
    () async {
      final local = _FakeLocalDatasource(_session(), _event());
      final cloud = _FakeCloudDatasource();
      final repository = SleepSafetyRepositoryImpl(
        local: local,
        cloud: cloud,
        native: _FakeNativeGateway(),
      );

      await repository.dispatchEmergency('event-1', 'sleep-safety-event-1');

      expect(cloud.syncedTables, [
        'sleep_safety_sessions',
        'sleep_safety_events',
      ]);
      expect(cloud.dispatchCalled, isTrue);
    },
  );

  test(
    'dispatch does not call provider when mandatory sync fails after retry',
    () async {
      final local = _FakeLocalDatasource(_session(), _event());
      final cloud = _FakeCloudDatasource(syncFailuresRemaining: 2);
      final repository = SleepSafetyRepositoryImpl(
        local: local,
        cloud: cloud,
        native: _FakeNativeGateway(),
      );

      await expectLater(
        repository.dispatchEmergency('event-1', 'sleep-safety-event-1'),
        throwsA(isA<StateError>()),
      );
      expect(cloud.syncedTables, [
        'sleep_safety_sessions',
        'sleep_safety_sessions',
      ]);
      expect(cloud.dispatchCalled, isFalse);
    },
  );
}

SleepSafetySession _session() {
  final now = DateTime.utc(2026, 8, 24, 4);
  return SleepSafetySession(
    id: 'session-1',
    userId: 'user-1',
    startedAt: now,
    sensitivity: SleepSafetySensitivity.balanced,
    status: SleepSafetySessionStatus.monitoring,
    startSource: 'manual',
    platform: 'android',
    appVersion: '1.0.0',
    createdAt: now,
    updatedAt: now,
  );
}

SleepSafetyEvent _event() {
  final now = DateTime.utc(2026, 8, 24, 4, 1);
  return SleepSafetyEvent(
    id: 'event-1',
    sessionId: 'session-1',
    userId: 'user-1',
    detectedAt: now,
    eventType: SleepSafetyEventType.abnormalScream,
    severity: 'high',
    confidence: 0.95,
    relativeEnergy: 8,
    baselineDelta: 0.2,
    repetitionCount: 1,
    state: 'escalating',
    response: SleepSafetyResponse.needHelp,
    escalationRequired: true,
    escalationStatus: SleepSafetyEscalationStatus.dispatching,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeLocalDatasource extends SleepSafetyLocalDatasource {
  _FakeLocalDatasource(this.session, this.event) : super();

  final SleepSafetySession session;
  final SleepSafetyEvent event;

  @override
  Future<SleepSafetySession?> getSession(String id) async =>
      id == session.id ? session : null;

  @override
  Future<SleepSafetyEvent?> getEvent(String id) async =>
      id == event.id ? event : null;
}

class _FakeCloudDatasource extends SleepSafetyCloudDatasource {
  _FakeCloudDatasource({this.syncFailuresRemaining = 0}) : super();

  int syncFailuresRemaining;
  final List<String> syncedTables = [];
  bool dispatchCalled = false;

  @override
  Future<void> syncRow(String table, Map<String, Object?> values) async {
    syncedTables.add(table);
    if (syncFailuresRemaining > 0) {
      syncFailuresRemaining -= 1;
      throw StateError('sync_failed');
    }
  }

  @override
  Future<Map<String, Object?>> dispatchEvent({
    required String eventId,
    required String idempotencyKey,
  }) async {
    dispatchCalled = true;
    return const {'accepted': true};
  }
}

class _FakeNativeGateway implements SleepSafetyNativeGateway {
  final StreamController<SleepSafetyNativeEvent> _events =
      StreamController<SleepSafetyNativeEvent>.broadcast();

  @override
  Stream<SleepSafetyNativeEvent> get events => _events.stream;

  @override
  Future<bool> ensureMicrophonePermission() async => true;

  @override
  Future<void> startMonitoring(Map<String, Object?> config) async {}

  @override
  Future<void> stopMonitoring(String reason) async {}

  @override
  Future<void> startCalibration() async {}

  @override
  Future<void> updateRuntimeConfig(Map<String, Object?> config) async {}

  @override
  Future<void> respondToAlert({
    required String eventId,
    required String response,
  }) async {}

  @override
  Future<void> dismissAlert({required String eventId}) async {}

  @override
  Future<Map<String, Object?>> getMonitoringStatus() async => const {};
}

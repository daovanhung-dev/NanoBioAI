import 'dart:convert';

import 'package:nano_app/core/storage/localdb/daos/sleep_safety_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_night_analysis.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/entities/sleep_safety_dispatch_retry.dart';
import '../../domain/entities/sleep_safety_preference.dart';
import '../../domain/entities/sleep_safety_session.dart';
import '../models/sleep_night_analysis_model.dart';
import '../models/sleep_safety_models.dart';

class SleepSafetyLocalDatasource {
  const SleepSafetyLocalDatasource({this.databaseOverride});

  final Database? databaseOverride;

  Future<SleepSafetyDao> _dao() async =>
      SleepSafetyDao(databaseOverride ?? await DatabaseService.database);

  Future<SleepSafetyPreference> loadPreference(String userId) async {
    final row = await (await _dao()).getPreference(userId);
    return row == null
        ? SleepSafetyPreference.defaults(userId)
        : SleepSafetyModelMapper.preferenceFromMap(row);
  }

  Future<void> savePreference(SleepSafetyPreference value) async =>
      (await _dao()).upsertPreference(
        SleepSafetyModelMapper.preferenceToMap(value),
      );

  Future<void> saveSession(SleepSafetySession value) async =>
      (await _dao()).insertSession(SleepSafetyModelMapper.sessionToMap(value));

  Future<SleepSafetySession?> getSession(String id) async {
    final row = await (await _dao()).getSession(id);
    return row == null ? null : SleepSafetyModelMapper.sessionFromMap(row);
  }

  Future<List<SleepSafetySession>> listSessions(
    String userId, {
    int limit = 14,
  }) async {
    final rows = await (await _dao()).listSessions(userId, limit: limit);
    return rows
        .map(SleepSafetyModelMapper.sessionFromMap)
        .toList(growable: false);
  }

  Future<void> updateSession(String id, Map<String, Object?> values) async =>
      (await _dao()).updateSession(id, values);

  Future<void> saveEvent(SleepSafetyEvent value) async =>
      (await _dao()).insertEvent(SleepSafetyModelMapper.eventToMap(value));

  Future<SleepSafetyEvent?> getEvent(String id) async {
    final row = await (await _dao()).getEvent(id);
    return row == null ? null : SleepSafetyModelMapper.eventFromMap(row);
  }

  Future<void> updateEvent(String id, Map<String, Object?> values) async =>
      (await _dao()).updateEvent(id, values);

  Future<List<SleepSafetyEvent>> listEvents(String userId) async =>
      (await (await _dao()).listEvents(
        userId,
      )).map(SleepSafetyModelMapper.eventFromMap).toList(growable: false);

  Future<List<SleepSafetyEvent>> listEventsForSession(String sessionId) async =>
      (await (await _dao()).listEventsForSession(
        sessionId,
      )).map(SleepSafetyModelMapper.eventFromMap).toList(growable: false);

  Future<void> saveNightAnalysis(SleepNightAnalysis value) async =>
      (await _dao()).upsertNightAnalysis(
        SleepNightAnalysisModelMapper.toMap(value),
      );

  Future<SleepNightAnalysis?> getNightAnalysis(String sessionId) async {
    final row = await (await _dao()).getNightAnalysis(sessionId);
    return row == null ? null : SleepNightAnalysisModelMapper.fromMap(row);
  }

  Future<void> cacheContacts(
    String userId,
    List<SafetyContact> contacts,
  ) async => (await _dao()).replaceContacts(
    userId,
    contacts.map(SleepSafetyModelMapper.contactToMap).toList(growable: false),
  );

  Future<void> cacheContact(SafetyContact contact) async => (await _dao())
      .upsertContact(SleepSafetyModelMapper.contactToMap(contact));

  Future<void> deleteCachedContact(String id) async =>
      (await _dao()).deleteContact(id);

  Future<List<SafetyContact>> listCachedContacts(String userId) async =>
      (await (await _dao()).listContacts(
        userId,
      )).map(SleepSafetyModelMapper.contactFromMap).toList(growable: false);

  Future<void> enqueueDispatchRetry({
    required String userId,
    required SleepSafetyEvent event,
    required String idempotencyKey,
  }) => _dao().then(
    (dao) => dao.enqueueDispatchRetry(
      userId: userId,
      eventId: event.id,
      idempotencyKey: idempotencyKey,
      createdAt: event.detectedAt,
    ),
  );

  Future<List<SleepSafetyDispatchRetry>> listPendingDispatches() async {
    final rows = await (await _dao()).listPendingDispatches();
    return rows
        .map((row) {
          final payload = jsonDecode(row['payload_json']?.toString() ?? '{}');
          final data = payload is Map
              ? Map<String, Object?>.from(payload)
              : <String, Object?>{};
          return SleepSafetyDispatchRetry(
            id: row['id'].toString(),
            userId: row['user_id'].toString(),
            eventId: data['event_id']?.toString() ?? row['event_id'].toString(),
            idempotencyKey: data['idempotency_key']?.toString() ?? '',
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
            attemptCount: (row['attempt_count'] as num?)?.toInt() ?? 0,
            status: row['status']?.toString() ?? 'pending',
            nextRetryAt: DateTime.tryParse(
              row['next_retry_at']?.toString() ?? '',
            ),
            lastErrorCode: row['last_error_code']?.toString(),
          );
        })
        .toList(growable: false);
  }

  Future<void> markDispatchSending(String id) =>
      _dao().then((dao) => dao.markDispatchSending(id, DateTime.now()));

  Future<void> markDispatchAcknowledged(String id) =>
      _dao().then((dao) => dao.markDispatchAcknowledged(id, DateTime.now()));

  Future<void> markDispatchFailed({
    required String id,
    required String errorCode,
    DateTime? nextRetryAt,
  }) => _dao().then(
    (dao) => dao.markDispatchFailed(
      id: id,
      errorCode: errorCode,
      now: DateTime.now(),
      nextRetryAt: nextRetryAt,
    ),
  );
}

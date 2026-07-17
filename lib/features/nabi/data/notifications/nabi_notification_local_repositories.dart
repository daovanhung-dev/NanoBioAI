import 'dart:convert';
import 'dart:math';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/nabi_notification_tables.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/notifications/nabi_notification_catalog.dart';
import '../../domain/notifications/nabi_notification_models.dart';
import '../../domain/notifications/nabi_notification_repositories.dart';

class BundledNabiNotificationConfigRepository
    implements NabiNotificationConfigRepository {
  const BundledNabiNotificationConfigRepository();

  @override
  Future<List<NabiNotificationDefinition>> loadActiveDefinitions() async {
    return NabiNotificationCatalog.definitions
        .where((definition) => definition.active)
        .toList(growable: false);
  }
}

class SqliteNabiNotificationStateRepository
    implements NabiNotificationStateRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteNabiNotificationStateRepository({
    this.databaseOverride,
    this.now = DateTime.now,
  });

  Future<Database> get _database async =>
      databaseOverride ?? DatabaseService.database;

  @override
  Future<List<NabiNotificationHistoryEntry>> loadHistory(
    String actorKey,
  ) async {
    final db = await _database;
    final rows = await db.query(
      NabiNotificationTables.occurrences,
      where: 'actor_key = ? AND presented_at IS NOT NULL',
      whereArgs: [actorKey],
      orderBy: 'presented_at DESC',
      limit: 200,
    );
    return rows.map(_historyFromRow).whereType<NabiNotificationHistoryEntry>().toList();
  }

  @override
  Future<NabiNotificationOccurrence> claim({
    required NabiNotificationDefinition definition,
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
  }) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final id = NabiIdGenerator.uuidV4();
    await db.insert(
      NabiNotificationTables.occurrences,
      {
        'id': id,
        'actor_key': snapshot.actorKey,
        'user_id': snapshot.actorKind == 'guest' ? null : snapshot.actorKey,
        'notification_id': definition.id,
        'content_version': definition.contentVersion,
        'source_event_id': snapshot.sourceEventId,
        'source_type': definition.policyKey,
        'category': definition.category.name,
        'priority': definition.priority,
        'status': NabiNotificationStatus.queued.name,
        'eligible_at': snapshot.occurredAt.toUtc().toIso8601String(),
        'session_id': uiContext.sessionId,
        'screen_instance_id': uiContext.screenInstanceId,
        'membership_plan': snapshot.membershipPlan,
        'billing_cycle': snapshot.billingCycle,
        'snapshot_json': jsonEncode(snapshot.variables),
        'created_at': timestamp,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    final rows = await db.query(
      NabiNotificationTables.occurrences,
      where:
          'actor_key = ? AND notification_id = ? AND source_event_id = ? '
          'AND content_version = ?',
      whereArgs: [
        snapshot.actorKey,
        definition.id,
        snapshot.sourceEventId,
        definition.contentVersion,
      ],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('notification_claim_failed');
    return _occurrenceFromRow(rows.first);
  }

  @override
  Future<void> updateStatus({
    required String occurrenceId,
    required NabiNotificationStatus status,
    DateTime? deferredUntil,
    String? errorCode,
  }) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final values = <String, Object?>{
      'status': status.name,
      'updated_at': timestamp,
      'deferred_until': deferredUntil?.toUtc().toIso8601String(),
      'last_error_code': errorCode,
    };
    if (status == NabiNotificationStatus.presented) {
      await db.rawUpdate(
        'UPDATE ${NabiNotificationTables.occurrences} '
        'SET status = ?, updated_at = ?, presented_at = ?, '
        'display_count = display_count + 1, deferred_until = ?, last_error_code = ? '
        'WHERE id = ?',
        [
          status.name,
          timestamp,
          timestamp,
          values['deferred_until'],
          errorCode,
          occurrenceId,
        ],
      );
      return;
    }
    switch (status) {
      case NabiNotificationStatus.opened:
        values['opened_at'] = timestamp;
        break;
      case NabiNotificationStatus.actioned:
        values['actioned_at'] = timestamp;
        break;
      case NabiNotificationStatus.converted:
        values['converted_at'] = timestamp;
        break;
      case NabiNotificationStatus.presented:
      case NabiNotificationStatus.eligible ||
          NabiNotificationStatus.queued ||
          NabiNotificationStatus.collapsed ||
          NabiNotificationStatus.deferred ||
          NabiNotificationStatus.expired ||
          NabiNotificationStatus.cancelled ||
          NabiNotificationStatus.failed:
        break;
    }
    await db.update(
      NabiNotificationTables.occurrences,
      values,
      where: 'id = ?',
      whereArgs: [occurrenceId],
    );
  }

  NabiNotificationOccurrence _occurrenceFromRow(Map<String, Object?> row) {
    return NabiNotificationOccurrence(
      id: row['id']?.toString() ?? '',
      actorKey: row['actor_key']?.toString() ?? '',
      notificationId: row['notification_id']?.toString() ?? '',
      contentVersion: _readInt(row['content_version']),
      sourceEventId: row['source_event_id']?.toString() ?? '',
      status: _status(row['status']),
      eligibleAt: DateTime.parse(row['eligible_at']!.toString()),
      deferredUntil: _date(row['deferred_until']),
    );
  }

  NabiNotificationHistoryEntry? _historyFromRow(Map<String, Object?> row) {
    final notificationId = row['notification_id']?.toString();
    final presentedAt = _date(row['presented_at']);
    if (notificationId == null || presentedAt == null) return null;
    final category = NabiNotificationCategory.values.where(
      (value) => value.name == row['category']?.toString(),
    );
    final definition = NabiNotificationCatalog.definitions.where(
      (item) => item.id == notificationId,
    );
    final resolvedCategory = category.isEmpty
        ? NabiNotificationCategory.care
        : category.first;
    final resolvedDefinition = definition.isEmpty ? null : definition.first;
    return NabiNotificationHistoryEntry(
      notificationId: notificationId,
      category: resolvedCategory,
      presentedAt: presentedAt,
      sessionId: row['session_id']?.toString() ?? '',
      screenInstanceId: row['screen_instance_id']?.toString() ?? '',
      proactive: resolvedDefinition?.proactive ?? true,
      upsell: resolvedDefinition?.upsell ?? false,
      status: _status(row['status']),
      deferredUntil: _date(row['deferred_until']),
    );
  }

  NabiNotificationStatus _status(Object? value) {
    return NabiNotificationStatus.values.firstWhere(
      (status) => status.name == value?.toString(),
      orElse: () => NabiNotificationStatus.failed,
    );
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _date(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : DateTime.tryParse(text);
  }
}

class SqliteNabiNotificationAnalyticsRepository
    implements NabiNotificationAnalyticsRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteNabiNotificationAnalyticsRepository({
    this.databaseOverride,
    this.now = DateTime.now,
  });

  Future<Database> get _database async =>
      databaseOverride ?? DatabaseService.database;

  @override
  Future<void> append({
    required String eventName,
    required NabiNotificationOccurrence occurrence,
    required NabiUiContext uiContext,
    String? resultCode,
  }) async {
    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    final id = NabiIdGenerator.uuidV4();
    await db.insert(NabiNotificationTables.eventOutbox, {
      'id': id,
      'occurrence_id': occurrence.id,
      'actor_key': occurrence.actorKey,
      'user_id': null,
      'event_name': eventName,
      'event_json': jsonEncode({
        'id': id,
        'occurrence_id': occurrence.id,
        'notification_id': occurrence.notificationId,
        'event_name': eventName,
        'session_id': uiContext.sessionId,
        'screen_key': uiContext.screenKey,
        'result_code': resultCode,
        'created_at': timestamp,
      }),
      'status': 'pending',
      'attempt_count': 0,
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  @override
  Future<int> drainPending() async {
    // Remote upload is intentionally opt-in and is wired by the authenticated
    // Supabase adapter. Local analytics remains durable without network access.
    return 0;
  }
}

abstract final class NabiIdGenerator {
  static final Random _random = Random.secure();

  static String uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

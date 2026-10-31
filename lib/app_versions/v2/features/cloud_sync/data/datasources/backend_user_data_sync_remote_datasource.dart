import 'dart:convert';
import 'dart:math';

import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';

import '../../domain/entities/user_data_snapshot.dart';
import 'meal_plan_nutrition_sync_columns.dart';
import 'user_data_sync_datasource_contracts.dart';
import 'user_data_sync_tables.dart';

class BackendUserDataSyncRemoteDatasource
    implements UserDataSyncRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendUserDataSyncRemoteDatasource({this.clientOverride});

  BackendApiClient? get _client => clientOverride ?? BackendApiClient.shared;

  @override
  String? get currentUserId => _client?.currentUserId;

  @override
  Future<Map<String, Object?>?> currentUserRow() async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;
    return _copyDynamicRow(
      await client.requestMap('GET', '/api/v1/profile/me'),
    );
  }

  @override
  Future<UserDataSnapshot?> pullCurrentUserSnapshot() async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;

    final response = await client.requestMap(
      'GET',
      '/api/v1/cloud-sync/snapshot',
    );
    final revision = _readInt(response['revision']) ?? 0;
    final rawUser = response['user'];
    final user = rawUser is Map
        ? _copyDynamicRow(rawUser)
        : await currentUserRow();
    if (user == null) return null;
    final tables = <String, List<Map<String, Object?>>>{};
    final rawTables = response['tables'];
    if (rawTables is Map) {
      for (final table in UserDataSyncTables.cloudPullTables) {
        if (rawTables.containsKey(table)) {
          tables[table] = _copyDynamicRows(rawTables[table]);
        }
      }
    }
    await AppPrefs.setCloudRevisionFor(userId, revision);
    return UserDataSnapshot(user: user, tables: tables, revision: revision);
  }

  @override
  Future<void> replaceCloudWithLocalSnapshot(
    UserDataSnapshot localSnapshot,
    String authUserId,
  ) async {
    final client = _client;
    if (client == null) {
      throw StateError('Missing backend API client for cloud sync.');
    }
    if (client.currentUserId != authUserId) {
      throw StateError('Phiên đồng bộ không khớp với dữ liệu trên thiết bị.');
    }
    if (!localSnapshot.hasUser) return;

    var expectedRevision = await AppPrefs.cloudRevisionFor(authUserId);
    if (expectedRevision == null) {
      final current = await client.requestMap(
        'GET',
        '/api/v1/cloud-sync/snapshot',
      );
      expectedRevision = _readInt(current['revision']) ?? 0;
      if (expectedRevision > 0 && current['user'] != null) {
        throw const BackendApiException(
          statusCode: 409,
          businessCode: 'SNAPSHOT_REVISION_REVIEW_REQUIRED',
          message:
              'Tài khoản đã có dữ liệu trên máy chủ. Hãy tải dữ liệu mới nhất trước khi gửi phần đang chờ.',
        );
      }
    }
    final payload = _cloudSnapshotPayload(localSnapshot, authUserId);
    final result = await client.requestMap(
      'PUT',
      '/api/v1/cloud-sync/snapshot',
      body: {'snapshot': payload, 'expected_revision': expectedRevision},
    );
    final revision = _readInt(result['revision']);
    if (revision == null) {
      throw const FormatException('Backend sync response has no revision.');
    }
    await AppPrefs.setCloudRevisionFor(authUserId, revision);
  }

  Map<String, Object?> _cloudSnapshotPayload(
    UserDataSnapshot snapshot,
    String authUserId,
  ) {
    final idMap = _buildCloudIdMap(snapshot);
    final tables = <String, Object?>{};

    for (final table in UserDataSyncTables.localUserOwnedTables) {
      final sourceRows =
          snapshot.tables[table] ?? const <Map<String, Object?>>[];
      tables[table] = sourceRows
          .map((row) => _cloudInsertRow(table, row, authUserId, idMap))
          .toList(growable: false);
    }

    return {'user': _cloudUpdateRow('users', snapshot.user!), 'tables': tables};
  }

  Set<String> _allowedCloudColumns(String table) {
    final baseColumns = UserDataSyncTables.cloudColumnsByTable[table];
    if (baseColumns == null) {
      throw StateError('Unsupported cloud sync table: $table');
    }
    return table == 'meal_plans'
        ? <String>{...baseColumns, ...mealPlanNutritionSyncColumns}
        : baseColumns;
  }

  Map<String, Object?> _cloudUpdateRow(
    String table,
    Map<String, Object?> source,
  ) {
    final allowedColumns = _allowedCloudColumns(table);

    final row = <String, Object?>{};
    for (final entry in source.entries) {
      final column = entry.key;
      if (!allowedColumns.contains(column)) continue;
      if (column == 'id' || column == 'user_id' || column == 'subject_id') {
        continue;
      }
      row[column] = _cloudValue(column, entry.value);
    }

    return row;
  }

  Map<String, Object?> _cloudInsertRow(
    String table,
    Map<String, Object?> source,
    String authUserId,
    Map<String, String> idMap,
  ) {
    final allowedColumns = _allowedCloudColumns(table);

    final isRequestLedger = table == 'personal_schedule_ai_requests';
    final oldId = _readNonEmptyString(
      source[isRequestLedger ? 'request_id' : 'id'],
    );
    final row = <String, Object?>{
      if (isRequestLedger)
        'request_id': oldId ?? _newUuidV4()
      else
        'id': oldId == null ? _newUuidV4() : idMap[oldId] ?? _newUuidV4(),
      'user_id': authUserId,
    };

    for (final entry in source.entries) {
      final column = entry.key;
      if (!allowedColumns.contains(column)) continue;
      if (column == 'id' ||
          column == 'request_id' ||
          column == 'user_id' ||
          column == 'subject_id') {
        continue;
      }

      if (column == 'source_id') {
        final sourceId = _readNonEmptyString(entry.value);
        row[column] = sourceId == null ? null : idMap[sourceId] ?? sourceId;
        continue;
      }

      row[column] = _cloudValue(column, entry.value);
    }

    return row;
  }

  Map<String, String> _buildCloudIdMap(UserDataSnapshot snapshot) {
    final idMap = <String, String>{};
    for (final table in UserDataSyncTables.cloudCollectionTables) {
      final rows = snapshot.tables[table] ?? const <Map<String, Object?>>[];
      for (final row in rows) {
        final localId = _readNonEmptyString(row['id']);
        if (localId == null || idMap.containsKey(localId)) continue;

        idMap[localId] = _isUuid(localId) ? localId : _newUuidV4();
      }
    }

    return idMap;
  }

  Object? _cloudValue(String column, Object? value) {
    if (value == null) return null;
    if (UserDataSyncTables.booleanColumns.contains(column)) {
      return _asBool(value);
    }
    if (column == 'payload' ||
        column == 'breakdown' ||
        column == 'program_json') {
      return _decodeJsonPayload(value);
    }
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  bool _asBool(Object value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  Object? _decodeJsonPayload(Object value) {
    if (value is! String) return value;
    final text = value.trim();
    if (text.isEmpty) return null;

    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  List<Map<String, Object?>> _copyDynamicRows(Object? response) {
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map(_copyDynamicRow)
        .toList(growable: false);
  }

  Map<String, Object?> _copyDynamicRow(Map<dynamic, dynamic> row) {
    return row.map((key, value) => MapEntry(key.toString(), value));
  }

  int? _readInt(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };

  String? _readNonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();

    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

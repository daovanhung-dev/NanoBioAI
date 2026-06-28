import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_data_snapshot.dart';
import 'user_data_sync_datasource_contracts.dart';
import 'user_data_sync_tables.dart';

class SupabaseUserDataSyncRemoteDatasource
    implements UserDataSyncRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseUserDataSyncRemoteDatasource({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  @override
  Future<Map<String, Object?>?> currentUserRow() async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;

    final row = await client
        .from('users')
        .select(
          'id,email,phone,full_name,avatar_url,gender,birth_year,'
          'subscription_tier,product_access_status,sale_status,onboarding_status,'
          'onboarding_completed_at,created_at,updated_at',
        )
        .eq('id', userId)
        .maybeSingle();

    return row == null ? null : _copyDynamicRow(row);
  }

  @override
  Future<UserDataSnapshot?> pullCurrentUserSnapshot() async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;

    final user = await currentUserRow();
    if (user == null) return null;

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in UserDataSyncTables.localUserOwnedTables) {
      final response = await client.from(table).select().eq('user_id', userId);
      tables[table] = _copyDynamicRows(response);
    }

    return UserDataSnapshot(user: user, tables: tables);
  }

  @override
  Future<void> replaceCloudWithLocalSnapshot(
    UserDataSnapshot localSnapshot,
    String authUserId,
  ) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Missing Supabase client for cloud sync.');
    }
    if (!localSnapshot.hasUser) return;

    final payload = _cloudSnapshotPayload(localSnapshot, authUserId);
    await client.rpc(
      'sync_my_mobile_snapshot',
      params: {'p_snapshot': payload},
    );
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

  Map<String, Object?> _cloudUpdateRow(
    String table,
    Map<String, Object?> source,
  ) {
    final allowedColumns = UserDataSyncTables.cloudColumnsByTable[table];
    if (allowedColumns == null) {
      throw StateError('Unsupported cloud sync table: $table');
    }

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
    final allowedColumns = UserDataSyncTables.cloudColumnsByTable[table];
    if (allowedColumns == null) {
      throw StateError('Unsupported cloud sync table: $table');
    }

    final oldId = _readNonEmptyString(source['id']);
    final row = <String, Object?>{
      'id': oldId == null ? _newUuidV4() : idMap[oldId] ?? _newUuidV4(),
      'user_id': authUserId,
    };

    for (final entry in source.entries) {
      final column = entry.key;
      if (!allowedColumns.contains(column)) continue;
      if (column == 'id' || column == 'user_id' || column == 'subject_id') {
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
    if (column == 'payload') {
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

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FamilyPlusRemoteDatasource {
  Future<Map<String, Object?>> getContext();

  Future<Map<String, Object?>> upsertGroup({
    required String displayName,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> upsertMember({
    required String subjectId,
    required String displayName,
    required String role,
    required bool canView,
    required bool canEdit,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> removeMember({
    required String memberId,
    required String idempotencyKey,
  });
}

class SupabaseFamilyPlusRemoteDatasource implements FamilyPlusRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseFamilyPlusRemoteDatasource({this.clientOverride});

  SupabaseClient _client() => clientOverride ?? Supabase.instance.client;

  @override
  Future<Map<String, Object?>> getContext() async {
    return _map(await _client().rpc('get_my_familyplus_context'));
  }

  @override
  Future<Map<String, Object?>> upsertGroup({
    required String displayName,
    required String idempotencyKey,
  }) async {
    return _map(
      await _client().rpc(
        'upsert_my_familyplus_group',
        params: {
          'p_display_name': displayName,
          'p_idempotency_key': idempotencyKey,
        },
      ),
    );
  }

  @override
  Future<Map<String, Object?>> upsertMember({
    required String subjectId,
    required String displayName,
    required String role,
    required bool canView,
    required bool canEdit,
    required String idempotencyKey,
  }) async {
    return _map(
      await _client().rpc(
        'upsert_my_familyplus_member',
        params: {
          'p_subject_id': subjectId,
          'p_display_name': displayName,
          'p_role': role,
          'p_can_view': canView,
          'p_can_edit': canEdit,
          'p_idempotency_key': idempotencyKey,
        },
      ),
    );
  }

  @override
  Future<Map<String, Object?>> removeMember({
    required String memberId,
    required String idempotencyKey,
  }) async {
    return _map(
      await _client().rpc(
        'remove_my_familyplus_member',
        params: {'p_member_id': memberId, 'p_idempotency_key': idempotencyKey},
      ),
    );
  }

  Map<String, Object?> _map(Object? response) {
    if (response is Map) return _copyMap(response);
    if (response is List && response.isNotEmpty && response.first is Map) {
      return _copyMap(response.first as Map);
    }
    return const {};
  }

  Map<String, Object?> _copyMap(Map<dynamic, dynamic> row) {
    return row.map((key, value) => MapEntry(key.toString(), value));
  }
}

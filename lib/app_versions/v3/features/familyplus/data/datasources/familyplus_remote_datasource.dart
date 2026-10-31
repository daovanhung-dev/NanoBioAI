import 'package:nano_app/core/network/backend_api_client.dart';

abstract interface class FamilyPlusRemoteDatasource {
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

class BackendFamilyPlusRemoteDatasource implements FamilyPlusRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendFamilyPlusRemoteDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<Map<String, Object?>> getContext() =>
      _client.requestMap('GET', '/api/v1/family-plus/context');

  @override
  Future<Map<String, Object?>> upsertGroup({
    required String displayName,
    required String idempotencyKey,
  }) => _client.requestMap(
    'PUT',
    '/api/v1/family-plus/group',
    body: {'display_name': displayName, 'idempotency_key': idempotencyKey},
  );

  @override
  Future<Map<String, Object?>> upsertMember({
    required String subjectId,
    required String displayName,
    required String role,
    required bool canView,
    required bool canEdit,
    required String idempotencyKey,
  }) => _client.requestMap(
    'PUT',
    '/api/v1/family-plus/members',
    body: {
      'subject_id': subjectId,
      'display_name': displayName,
      'role': role,
      'can_view': canView,
      'can_edit': canEdit,
      'idempotency_key': idempotencyKey,
    },
  );

  @override
  Future<Map<String, Object?>> removeMember({
    required String memberId,
    required String idempotencyKey,
  }) => _client.requestMap(
    'DELETE',
    '/api/v1/family-plus/members/$memberId',
    body: {'idempotency_key': idempotencyKey},
  );
}

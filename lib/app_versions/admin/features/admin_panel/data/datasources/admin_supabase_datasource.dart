import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSupabaseDatasource {
  final SupabaseClient? clientOverride;

  const AdminSupabaseDatasource({this.clientOverride});

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client().auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _client().auth.signOut();
  }

  Future<AdminSession> fetchSession() async {
    final response = await _client().rpc('get_my_admin_session');
    return AdminSession.fromMap(_firstMap(response));
  }

  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
  }) async {
    final response = await _client().rpc(
      'get_admin_dashboard_summary',
      params: {
        'p_from': from.toIso8601String(),
        'p_to': to.toIso8601String(),
        'p_scope': scope,
      },
    );
    return _maps(response).map(AdminDashboardMetric.fromMap).toList();
  }

  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) async {
    final response = await _client().rpc(
      adminListRpcForSection(section),
      params: {'p_query': query, 'p_limit': 50},
    );
    return _maps(response).map(AdminWorkItem.fromMap).toList();
  }

  Future<List<AdminAuditEvent>> fetchAuditEvents({
    required String query,
  }) async {
    final response = await _client().rpc(
      'admin_list_audit_events',
      params: {'p_query': query, 'p_limit': 50},
    );
    return _maps(response).map(AdminAuditEvent.fromMap).toList();
  }

  Future<AdminMutationResult> runMutation(AdminMutationCommand command) async {
    final response = await _client().rpc(
      adminRpcFunctionFor(command),
      params: adminRpcParamsFor(command),
    );
    return AdminMutationResult.fromMap(_firstMap(response));
  }

  SupabaseClient _client() => clientOverride ?? Supabase.instance.client;
}

String adminRpcFunctionFor(AdminMutationCommand command) {
  return switch (command.section) {
    AdminPanelSection.users => 'admin_update_user_status',
    AdminPanelSection.payments => 'admin_review_payment',
    AdminPanelSection.sales => 'admin_review_sale_profile',
    AdminPanelSection.saleConversions => 'admin_review_sale_point_conversion',
    AdminPanelSection.plans => 'admin_upsert_config_version',
    AdminPanelSection.reports => 'admin_request_report_export',
    AdminPanelSection.config => 'admin_upsert_config_version',
    AdminPanelSection.audit => 'admin_list_audit_events',
    AdminPanelSection.dashboard => 'get_admin_dashboard_summary',
  };
}

String adminListRpcForSection(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.users => 'admin_search_users',
    AdminPanelSection.payments => 'admin_list_payments',
    AdminPanelSection.sales => 'admin_list_sales',
    AdminPanelSection.saleConversions => 'admin_list_sale_point_conversions',
    AdminPanelSection.plans => 'admin_list_config_versions',
    AdminPanelSection.reports => 'admin_list_report_exports',
    AdminPanelSection.config => 'admin_list_config_versions',
    AdminPanelSection.audit => 'admin_list_audit_events',
    AdminPanelSection.dashboard => 'admin_search_users',
  };
}

Map<String, Object?> adminRpcParamsFor(AdminMutationCommand command) {
  final base = <String, Object?>{
    'p_reason': command.reason,
    'p_idempotency_key': command.idempotencyKey,
  };

  switch (command.section) {
    case AdminPanelSection.users:
      return {
        ...base,
        'p_user_id': command.targetId,
        'p_status': command.action,
      };
    case AdminPanelSection.payments:
      return {
        ...base,
        'p_payment_event_id': command.targetId,
        'p_decision': command.action,
      };
    case AdminPanelSection.sales:
      return {
        ...base,
        'p_sale_user_id': command.targetId,
        'p_decision': command.action,
      };
    case AdminPanelSection.saleConversions:
      return {
        ...base,
        'p_conversion_id': command.targetId,
        'p_decision': command.action,
      };
    case AdminPanelSection.plans:
    case AdminPanelSection.config:
      return {
        ...base,
        'p_config_key': command.targetId,
        'p_config_value': {'action': command.action},
      };
    case AdminPanelSection.reports:
      return {
        ...base,
        'p_report_type': command.action,
        'p_filters': {'target_id': command.targetId},
      };
    case AdminPanelSection.audit:
    case AdminPanelSection.dashboard:
      return base;
  }
}

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) return _copyMap(response);
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map) return _copyMap(first);
  }
  return const {};
}

List<Map<String, Object?>> _maps(Object? response) {
  if (response is! List) return const [];
  return response.whereType<Map>().map(_copyMap).toList(growable: false);
}

Map<String, Object?> _copyMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

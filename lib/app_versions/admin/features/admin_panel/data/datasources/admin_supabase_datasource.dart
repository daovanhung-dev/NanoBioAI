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
    required String timeZone,
  }) async {
    final response = await _client().rpc(
      'get_admin_dashboard_summary',
      params: {
        'p_from': from.toIso8601String(),
        'p_to': to.toIso8601String(),
        'p_scope': scope,
        'p_time_zone': timeZone,
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
    AdminPanelSection.payments => _paymentRpcFunctionFor(command.action),
    AdminPanelSection.sales => 'admin_review_sale_profile',
    AdminPanelSection.saleConversions =>
      command.action == 'adjust_points'
          ? 'admin_adjust_sale_points'
          : 'admin_review_sale_point_conversion',
    AdminPanelSection.reconciliation =>
      command.action == 'create_run'
          ? 'admin_create_reconciliation_run'
          : 'admin_update_reconciliation_discrepancy_status',
    AdminPanelSection.plans => 'admin_upsert_config_version',
    AdminPanelSection.reports => 'admin_request_report_export',
    AdminPanelSection.config => 'admin_upsert_config_version',
    AdminPanelSection.audit || AdminPanelSection.dashboard =>
      throw UnsupportedError('Read-only Admin sections cannot mutate.'),
  };
}

String adminListRpcForSection(AdminPanelSection section) {
  return switch (section) {
    AdminPanelSection.users => 'admin_search_users',
    AdminPanelSection.payments => 'admin_list_payments',
    AdminPanelSection.sales => 'admin_list_sales',
    AdminPanelSection.saleConversions => 'admin_list_sale_point_conversions',
    AdminPanelSection.reconciliation =>
      'admin_list_reconciliation_discrepancies',
    AdminPanelSection.plans => 'admin_list_plan_config_versions',
    AdminPanelSection.reports => 'admin_list_report_catalog',
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
      if (command.action == 'adjust_points') {
        return {
          ...base,
          'p_sale_user_id': command.targetId,
          'p_point_delta_cents': _readPayloadInt(
            command.payload['point_delta_cents'],
          ),
        };
      }
      return {
        ...base,
        'p_conversion_id': command.targetId,
        'p_decision': command.action,
        if (_readPayloadString(command.payload['payment_proof_path']) != null)
          'p_payment_proof_path': _readPayloadString(
            command.payload['payment_proof_path'],
          ),
      };
    case AdminPanelSection.reconciliation:
      if (command.action == 'create_run') {
        return {...base, 'p_scope': command.targetId};
      }
      return {
        ...base,
        'p_discrepancy_id': command.targetId,
        'p_status': command.action,
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
        'p_report_type': command.targetId,
        'p_filters': {
          'report_type': command.targetId,
          'time_zone': AdminTimeDefaults.vietnamTimeZone,
        },
      };
    case AdminPanelSection.audit:
    case AdminPanelSection.dashboard:
      throw UnsupportedError('Read-only Admin sections cannot mutate.');
  }
}

String _paymentRpcFunctionFor(String action) {
  return switch (action) {
    'refund' || 'cancel' || 'chargeback' => 'admin_refund_or_cancel_payment',
    _ => 'admin_review_payment',
  };
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

int _readPayloadInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readPayloadString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

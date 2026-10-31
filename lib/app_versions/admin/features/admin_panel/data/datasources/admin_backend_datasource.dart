import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_account_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

class AdminBackendDatasource {
  final BackendApiClient? clientOverride;

  const AdminBackendDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  Stream<void> watchAuthChanges() => _client.authChanges.map<void>((_) {});

  bool get hasValidSession {
    final session = _client.session;
    return session != null && session.expiresAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.requestMap(
      'POST',
      '/api/v1/auth/login',
      authenticated: false,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    await _client.establishSession(response);
  }

  Future<void> signOut() => _client.signOut();

  Future<AdminSession> fetchSession() async {
    try {
      final response = await _client.requestMap('GET', '/api/v1/admin/session');
      return AdminSession.fromMap(response);
    } on BackendApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        throw const AdminAccessRevokedException();
      }
      rethrow;
    }
  }

  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
    required String timeZone,
  }) async {
    final data = await _client.request(
      'GET',
      '/api/v1/admin/dashboard',
      query: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    return _mapList(
      data,
    ).map(AdminDashboardMetric.fromMap).toList(growable: false);
  }

  Future<AdminPaymentReviewAlert> fetchPaymentReviewAlert() async {
    final response = await _client.requestMap(
      'GET',
      '/api/v1/admin/payments/review-alert',
    );
    return AdminPaymentReviewAlert.fromMap(response);
  }

  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) async {
    if (section == AdminPanelSection.dashboard) {
      final data = await _client.request(
        'GET',
        '/api/v1/admin/users/search',
        query: {'q': query, 'limit': 50},
      );
      return _mapList(data).map(AdminWorkItem.fromMap).toList(growable: false);
    }
    if (section == AdminPanelSection.payments ||
        section == AdminPanelSection.users ||
        section == AdminPanelSection.audit) {
      final path = switch (section) {
        AdminPanelSection.payments => '/api/v1/admin/payments',
        AdminPanelSection.audit => '/api/v1/admin/audit-events',
        _ => '/api/v1/admin/users/search',
      };
      final data = await _client.request(
        'GET',
        path,
        query: {'q': query, 'limit': 50},
      );
      return _mapList(data).map(AdminWorkItem.fromMap).toList(growable: false);
    }
    final sectionPath = _adminSectionPath(section);
    final data = await _client.request(
      'GET',
      '/api/v1/admin/business/$sectionPath',
      query: {'q': query, 'limit': 50},
    );
    return _mapList(data).map(AdminWorkItem.fromMap).toList(growable: false);
  }

  Future<List<AdminAuditEvent>> fetchAuditEvents({
    required String query,
  }) async {
    final data = await _client.request(
      'GET',
      '/api/v1/admin/audit-events',
      query: {'q': query, 'limit': 100},
    );
    return _mapList(data).map(AdminAuditEvent.fromMap).toList(growable: false);
  }

  Future<AdminMutationResult> runMutation(AdminMutationCommand command) async {
    if (command.section == AdminPanelSection.users) {
      final response = await _client.requestMap(
        'PATCH',
        '/api/v1/admin/users/${Uri.encodeComponent(command.targetId)}/status',
        body: {
          'status': command.action,
          'reason': command.reason,
          'idempotency_key': command.idempotencyKey,
        },
      );
      return AdminMutationResult.fromMap(response);
    }
    if (command.section == AdminPanelSection.payments) {
      final reversing = const {"refund", "cancel", "chargeback"}.contains(
        command.action,
      );
      final response = await _client.requestMap(
        'POST',
        '/api/v1/admin/payments/${Uri.encodeComponent(command.targetId)}/'
        '${reversing ? 'reversal' : 'review'}',
        body: {
          'decision': command.action,
          'reason': command.reason,
          'idempotency_key': command.idempotencyKey,
          if (!reversing)
            'transfer_verified': command.payload['transfer_verified'] == true,
        },
      );
      return AdminMutationResult.fromMap(response);
    }
    if (command.section == AdminPanelSection.dashboard ||
        command.section == AdminPanelSection.audit) {
      throw UnsupportedError('Read-only Admin sections cannot mutate.');
    }
    final response = await _client.requestMap(
      'POST',
      '/api/v1/admin/business/${_adminSectionPath(command.section)}',
      body: {
        'action': command.action,
        'target_id': command.targetId,
        'reason': command.reason,
        'idempotency_key': command.idempotencyKey,
        'payload': command.payload,
      },
    );
    return AdminMutationResult.fromMap(response);
  }

  Future<List<AdminAccountSummary>> searchAccounts({
    required String query,
  }) async {
    final data = await _client.request(
      'GET',
      '/api/v1/admin/users/search',
      query: {'q': query, 'limit': 50},
    );
    return _mapList(data)
        .map(AdminWorkItem.fromMap)
        .map(_accountSummaryFromWorkItem)
        .toList(growable: false);
  }

  Future<AdminCreateAccountResult> createAccount(
    AdminCreateAccountRequest request,
  ) async {
    final data = await _client.requestMap(
      'POST',
      '/api/v1/admin/accounts',
      body: {
        'full_name': request.fullName,
        'email': request.email,
        'password': request.password,
        'phone': request.phone ?? '',
        'reason': request.reason,
        'idempotency_key': request.idempotencyKey,
      },
    );
    return AdminCreateAccountResult.fromMap(data);
  }

  Future<AdminMembershipGrantResult> grantMembership(
    AdminMembershipGrantRequest request,
  ) async {
    final data = await _client.requestMap(
      'POST',
      '/api/v1/admin/memberships/grant',
      body: {
        'user_id': request.userId,
        'plan_code': request.planCode,
        'starts_at': request.startsAt.toUtc().toIso8601String(),
        'ends_at': request.endsAt.toUtc().toIso8601String(),
        'reason': request.reason,
        'idempotency_key': request.idempotencyKey,
      },
    );
    return AdminMembershipGrantResult.fromMap(data);
  }
}

String _adminSectionPath(AdminPanelSection section) => switch (section) {
  AdminPanelSection.dashboard => 'dashboard',
  AdminPanelSection.users => 'users',
  AdminPanelSection.payments => 'payments',
  AdminPanelSection.sales => 'sales',
  AdminPanelSection.saleConversions => 'sale-conversions',
  AdminPanelSection.wellnessRewards => 'wellness-rewards',
  AdminPanelSection.reconciliation => 'reconciliation',
  AdminPanelSection.plans => 'plans',
  AdminPanelSection.reports => 'reports',
  AdminPanelSection.audit => 'audit',
  AdminPanelSection.config => 'config',
};

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) {
        return row.map((key, entry) => MapEntry(key.toString(), entry));
      })
      .toList(growable: false);
}

AdminAccountSummary _accountSummaryFromWorkItem(AdminWorkItem item) {
  return AdminAccountSummary(
    id: item.id,
    displayName: item.title,
    email: item.metadata['email']?.toString() ?? '',
    phone: item.metadata['phone']?.toString(),
    accountStatus: item.status,
    planCode: item.metadata['plan_code']?.toString() ?? 'free',
    saleStatus: item.metadata['sale_status']?.toString() ?? 'none',
    createdAt: DateTime.tryParse(item.metadata['created_at']?.toString() ?? ''),
    subscriptionStatus: item.metadata['subscription_status']?.toString(),
    subscriptionStartsAt: DateTime.tryParse(
      item.metadata['subscription_starts_at']?.toString() ?? '',
    ),
    subscriptionEndsAt: DateTime.tryParse(
      item.metadata['subscription_ends_at']?.toString() ?? '',
    ),
  );
}

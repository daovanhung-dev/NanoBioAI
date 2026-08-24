import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_account_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart';

class AdminAccountsState {
  final AdminSession session;
  final List<AdminAccountSummary> accounts;
  final String query;
  final String? message;

  const AdminAccountsState({
    required this.session,
    required this.accounts,
    required this.query,
    this.message,
  });

  bool get canManageAccounts => session.hasPermission(AdminPermissions.usersWrite);

  bool get canCreateAccount {
    return session.roles.contains(AdminRoleCode.superAdmin) ||
        session.roles.contains(AdminRoleCode.supportAdmin);
  }

  bool get canGrantMembership {
    return session.roles.contains(AdminRoleCode.superAdmin);
  }
}

class AdminAccountsController extends AsyncNotifier<AdminAccountsState> {
  String? _pendingCreateFingerprint;
  String? _pendingCreateIdempotencyKey;
  String? _pendingGrantFingerprint;
  String? _pendingGrantIdempotencyKey;
  DateTime? _pendingGrantStartsAt;
  DateTime? _pendingGrantEndsAt;

  @override
  Future<AdminAccountsState> build() => _load('');

  Future<void> search(String query) async {
    final normalized = query.trim();
    final current = state.asData?.value;
    if (current != null && current.query == normalized) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(normalized));
  }

  Future<void> refresh() async {
    final query = state.asData?.value.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(query));
  }

  Future<AdminCreateAccountResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String reason,
  }) async {
    final current = state.asData?.value ?? await _load('');
    if (!current.canCreateAccount) {
      throw StateError('Tài khoản quản trị chưa được phép tạo tài khoản mới.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Vui lòng nhập lý do tạo tài khoản.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    final fingerprint = '$normalizedEmail|${fullName.trim()}|${normalizedPhone ?? ''}|$trimmedReason';
    if (_pendingCreateFingerprint != fingerprint ||
        _pendingCreateIdempotencyKey == null) {
      _pendingCreateFingerprint = fingerprint;
      _pendingCreateIdempotencyKey = _idempotency('create-account', normalizedEmail);
    }
    final result = await ref.read(adminRepositoryProvider).createAccount(
      AdminCreateAccountRequest(
        fullName: fullName.trim(),
        email: normalizedEmail,
        password: password,
        phone: normalizedPhone,
        reason: trimmedReason,
        idempotencyKey: _pendingCreateIdempotencyKey!,
      ),
    );
    _pendingCreateFingerprint = null;
    _pendingCreateIdempotencyKey = null;
    final next = await _load(current.query);
    state = AsyncData(
      AdminAccountsState(
        session: next.session,
        accounts: next.accounts,
        query: next.query,
        message: result.message.isEmpty ? 'Đã tạo tài khoản.' : result.message,
      ),
    );
    return result;
  }

  Future<void> updateAccountStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    final current = state.asData?.value ?? await _load('');
    if (!current.canManageAccounts) {
      throw StateError('Tài khoản quản trị chưa được phép quản lý người dùng.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Vui lòng nhập lý do cho thao tác này.');
    }
    await ref.read(adminRepositoryProvider).runMutation(
      AdminMutationCommand(
        section: AdminPanelSection.users,
        action: status,
        targetId: userId,
        reason: trimmedReason,
        idempotencyKey: _idempotency('account-status-$status', userId),
      ),
    );
    final next = await _load(current.query);
    state = AsyncData(
      AdminAccountsState(
        session: next.session,
        accounts: next.accounts,
        query: next.query,
        message: status == 'active'
            ? 'Đã mở lại tài khoản.'
            : 'Đã tạm khóa tài khoản.',
      ),
    );
  }

  Future<AdminMembershipGrantResult> grantMembership({
    required String userId,
    required String planCode,
    required int durationMonths,
    required String reason,
  }) async {
    final current = state.asData?.value ?? await _load('');
    if (!current.canGrantMembership) {
      throw StateError('Chỉ Super Admin được cấp gói thành viên thủ công.');
    }
    if (planCode != 'plus' && planCode != 'family_plus') {
      throw StateError('Gói thành viên không hợp lệ.');
    }
    if (!const {1, 3, 6, 12}.contains(durationMonths)) {
      throw StateError('Thời hạn cấp gói không hợp lệ.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Vui lòng nhập lý do cấp gói.');
    }

    final fingerprint = '$userId|$planCode|$durationMonths|$trimmedReason';
    if (_pendingGrantFingerprint != fingerprint ||
        _pendingGrantIdempotencyKey == null ||
        _pendingGrantStartsAt == null ||
        _pendingGrantEndsAt == null) {
      final startsAt = DateTime.now().toUtc();
      _pendingGrantFingerprint = fingerprint;
      _pendingGrantIdempotencyKey = _idempotency('grant-$planCode', userId);
      _pendingGrantStartsAt = startsAt;
      _pendingGrantEndsAt = DateTime.utc(
        startsAt.year,
        startsAt.month + durationMonths,
        startsAt.day,
        startsAt.hour,
        startsAt.minute,
        startsAt.second,
      );
    }
    final result = await ref.read(adminRepositoryProvider).grantMembership(
      AdminMembershipGrantRequest(
        userId: userId,
        planCode: planCode,
        startsAt: _pendingGrantStartsAt!,
        endsAt: _pendingGrantEndsAt!,
        reason: trimmedReason,
        idempotencyKey: _pendingGrantIdempotencyKey!,
      ),
    );
    _pendingGrantFingerprint = null;
    _pendingGrantIdempotencyKey = null;
    _pendingGrantStartsAt = null;
    _pendingGrantEndsAt = null;
    final next = await _load(current.query);
    state = AsyncData(
      AdminAccountsState(
        session: next.session,
        accounts: next.accounts,
        query: next.query,
        message: result.message.isEmpty ? 'Đã cập nhật gói thành viên.' : result.message,
      ),
    );
    return result;
  }

  Future<AdminAccountsState> _load(String query) async {
    final repository = ref.read(adminRepositoryProvider);
    final session = await repository.fetchSession();
    if (!session.isAdmin) {
      return AdminAccountsState(session: session, accounts: const [], query: query);
    }
    if (!session.hasPermission(AdminPermissions.usersWrite)) {
      return AdminAccountsState(session: session, accounts: const [], query: query);
    }
    final accounts = await repository.searchAccounts(query: query);
    return AdminAccountsState(session: session, accounts: accounts, query: query);
  }

  String _idempotency(String action, String target) {
    return '$action-$target-${DateTime.now().microsecondsSinceEpoch}';
  }
}

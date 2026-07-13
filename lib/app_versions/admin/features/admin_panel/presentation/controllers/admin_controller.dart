import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

class AdminLoginFailure implements Exception {
  final String message;

  const AdminLoginFailure._(this.message);

  const AdminLoginFailure.noActiveAdminRole()
    : this._(
        'Tài khoản đã đăng nhập nhưng chưa được cấp quyền quản trị đang hoạt động.',
      );

  const AdminLoginFailure.sessionCheckFailed()
    : this._(
        'Nabi chưa thể kiểm tra quyền quản trị lúc này. Bạn thử lại sau nhé.',
      );

  @override
  String toString() => message;
}

class AdminPanelState {
  final AdminSession session;
  final AdminPanelSection section;
  final List<AdminDashboardMetric> metrics;
  final List<AdminWorkItem> items;
  final List<AdminAuditEvent> auditEvents;
  final String query;
  final String? deniedPermission;
  final String? lastMessage;

  const AdminPanelState({
    required this.session,
    required this.section,
    required this.metrics,
    required this.items,
    required this.auditEvents,
    required this.query,
    this.deniedPermission,
    this.lastMessage,
  });

  bool get isPermissionDenied => deniedPermission != null;

  AdminPanelState copyWith({
    AdminSession? session,
    AdminPanelSection? section,
    List<AdminDashboardMetric>? metrics,
    List<AdminWorkItem>? items,
    List<AdminAuditEvent>? auditEvents,
    String? query,
    String? deniedPermission,
    String? lastMessage,
  }) {
    return AdminPanelState(
      session: session ?? this.session,
      section: section ?? this.section,
      metrics: metrics ?? this.metrics,
      items: items ?? this.items,
      auditEvents: auditEvents ?? this.auditEvents,
      query: query ?? this.query,
      deniedPermission: deniedPermission ?? this.deniedPermission,
      lastMessage: lastMessage,
    );
  }
}

class AdminController extends AsyncNotifier<AdminPanelState> {
  AdminRepository get _repository => ref.read(adminRepositoryProvider);

  @override
  Future<AdminPanelState> build() async {
    return _load(AdminPanelSection.dashboard, query: '');
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _repository.signInWithEmail(email: email, password: password);

    AdminSession session;
    try {
      session = await _repository.fetchSession();
    } catch (_) {
      await _signOutSilently();
      throw const AdminLoginFailure.sessionCheckFailed();
    }

    if (!session.isAdmin) {
      await _signOutSilently();
      throw const AdminLoginFailure.noActiveAdminRole();
    }
  }

  Future<void> signOut() {
    return _repository.signOut();
  }

  Future<void> _signOutSilently() async {
    try {
      await _repository.signOut();
    } catch (_) {
      // Keep the original login failure visible to the user.
    }
  }

  Future<void> selectSection(AdminPanelSection section) async {
    final currentQuery = state.asData?.value.query ?? '';
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(section, query: currentQuery));
  }

  Future<void> search(String query) async {
    final section = state.asData?.value.section ?? AdminPanelSection.dashboard;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(section, query: query));
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _load(
        current?.section ?? AdminPanelSection.dashboard,
        query: current?.query ?? '',
      ),
    );
  }

  Future<void> runMutation({
    required AdminPanelSection section,
    required String action,
    required String targetId,
    required String reason,
    Map<String, Object?> payload = const {},
  }) async {
    final current = state.asData?.value;
    if (reason.trim().isEmpty) {
      throw StateError('Cần lý do cho thao tác quản trị.');
    }

    final command = AdminMutationCommand(
      section: section,
      action: action,
      targetId: targetId,
      reason: reason.trim(),
      idempotencyKey:
          '${section.value}-$targetId-${DateTime.now().microsecondsSinceEpoch}',
      payload: payload,
    );

    final session = current?.session ?? await _repository.fetchSession();
    if (!session.canRunMutation(command)) {
      final denied = _permissionDeniedState(
        session: session,
        section: current?.section ?? section,
        query: current?.query ?? '',
        permission: adminPermissionForMutation(command),
        lastMessage: _permissionDeniedMessage(
          adminPermissionForMutation(command),
        ),
      );
      state = AsyncData(denied);
      return;
    }

    final result = await _repository.runMutation(command);

    final next = await _load(section, query: current?.query ?? '');
    state = AsyncData(
      next.copyWith(
        lastMessage: result.message.isEmpty
            ? (result.success ? 'Đã cập nhật.' : 'Chưa cập nhật được.')
            : _adminUiMessage(result.message),
      ),
    );
  }

  Future<AdminPanelState> _load(
    AdminPanelSection section, {
    required String query,
  }) async {
    final session = await _repository.fetchSession();
    if (!session.isAdmin) {
      return AdminPanelState(
        session: session,
        section: section,
        metrics: const [],
        items: const [],
        auditEvents: const [],
        query: query,
      );
    }

    final requiredPermission = adminPermissionForSection(section);
    if (!session.canAccessSection(section)) {
      return _permissionDeniedState(
        session: session,
        section: section,
        query: query,
        permission: requiredPermission,
      );
    }

    final metrics = section == AdminPanelSection.dashboard
        ? await _fetchDashboardMetrics()
        : const <AdminDashboardMetric>[];
    final items =
        section == AdminPanelSection.dashboard ||
            section == AdminPanelSection.audit
        ? const <AdminWorkItem>[]
        : await _repository.fetchSectionItems(section: section, query: query);
    final auditEvents = section == AdminPanelSection.audit
        ? await _repository.fetchAuditEvents(query: query)
        : const <AdminAuditEvent>[];

    return AdminPanelState(
      session: session,
      section: section,
      metrics: metrics,
      items: items,
      auditEvents: auditEvents,
      query: query,
    );
  }

  Future<List<AdminDashboardMetric>> _fetchDashboardMetrics() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    return _repository.fetchDashboardSummary(
      from: from,
      to: now,
      scope: 'global',
      timeZone: AdminTimeDefaults.vietnamTimeZone,
    );
  }

  AdminPanelState _permissionDeniedState({
    required AdminSession session,
    required AdminPanelSection section,
    required String query,
    required String permission,
    String? lastMessage,
  }) {
    return AdminPanelState(
      session: session,
      section: section,
      metrics: const [],
      items: const [],
      auditEvents: const [],
      query: query,
      deniedPermission: permission,
      lastMessage: lastMessage,
    );
  }

  String _permissionDeniedMessage(String _) {
    return 'Tài khoản quản trị chưa được cấp quyền thực hiện thao tác này.';
  }

  String _adminUiMessage(String message) {
    return switch (message) {
      'Da cap nhat trang thai nguoi dung.' =>
        'Đã cập nhật trạng thái người dùng.',
      'Da xu ly payment.' => 'Đã xử lý thanh toán.',
      'Da xu ly hoan huy trong cua so 24 gio.' =>
        'Đã xử lý hoàn/hủy trong cửa sổ 24 giờ.',
      'Da cap nhat Sale.' => 'Đã cập nhật cộng tác viên.',
      'Da luu phien ban cau hinh.' => 'Đã lưu phiên bản cấu hình.',
      'Da tao yeu cau xuat bao cao.' => 'Đã tạo yêu cầu xuất báo cáo.',
      'Da ghi dieu chinh diem Sale.' => 'Đã ghi điều chỉnh điểm cộng tác viên.',
      'Da tao phien doi soat.' => 'Đã tạo phiên đối soát.',
      'Da cap nhat doi soat.' => 'Đã cập nhật đối soát.',
      'Da cap nhat yeu cau quy doi diem Sale.' =>
        'Đã cập nhật yêu cầu quy đổi điểm cộng tác viên.',
      _ => vietnameseSystemUiText(
        message,
        fallback: 'Thao tác chưa hoàn tất. Bạn thử lại sau nhé.',
      ),
    };
  }
}

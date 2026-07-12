import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart';

class AdminAccessController extends AsyncNotifier<AdminAccessState> {
  @override
  Future<AdminAccessState> build() async {
    final availability = ref.watch(adminBackendAvailabilityProvider);
    if (!availability.isReady) {
      return const AdminAccessState.error(
        'Khu vực quản trị chưa kết nối được dịch vụ đăng nhập. '
        'Vui lòng kiểm tra cấu hình và thử lại.',
      );
    }

    ref.watch(adminAuthChangesProvider);
    return _evaluate();
  }

  Future<AdminAccessState> refresh() async {
    final availability = ref.read(adminBackendAvailabilityProvider);
    if (!availability.isReady) {
      const next = AdminAccessState.error(
        'Khu vực quản trị chưa kết nối được dịch vụ đăng nhập. '
        'Vui lòng kiểm tra cấu hình và thử lại.',
      );
      state = const AsyncData(next);
      return next;
    }

    state = const AsyncData(AdminAccessState.checking());
    final next = await _evaluate();
    state = AsyncData(next);
    return next;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final availability = ref.read(adminBackendAvailabilityProvider);
    if (!availability.isReady) {
      throw const AdminAccessFailure(
        'Đăng nhập quản trị chưa sẵn sàng. Vui lòng kiểm tra cấu hình ứng dụng.',
      );
    }

    state = const AsyncData(AdminAccessState.checking());
    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.signInWithEmail(email: email.trim(), password: password);
      final next = await _evaluate();
      if (next.status == AdminAccessStatus.error) {
        state = AsyncData(next);
        throw AdminAccessFailure(
          next.safeMessage ??
              'Chưa thể kiểm tra quyền quản trị. Vui lòng thử lại.',
        );
      }
      if (!next.isAuthorized) {
        state = const AsyncData(AdminAccessState.unauthorized());
        throw const AdminAccessFailure(
          'Tài khoản này không có quyền quản trị đang hoạt động.',
        );
      }
      state = AsyncData(next);
    } on AdminAccessFailure {
      rethrow;
    } catch (_) {
      state = const AsyncData(
        AdminAccessState.error(
          'Chưa thể đăng nhập quản trị lúc này. Vui lòng kiểm tra kết nối và thử lại.',
        ),
      );
      throw const AdminAccessFailure(
        'Chưa thể đăng nhập quản trị lúc này. Vui lòng kiểm tra thông tin và thử lại.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(adminRepositoryProvider).signOut();
    } finally {
      state = const AsyncData(AdminAccessState.unauthorized());
    }
  }

  Future<AdminAccessState> _evaluate() async {
    final repository = ref.read(adminRepositoryProvider);
    if (!repository.hasValidSession) {
      return const AdminAccessState.unauthorized();
    }

    try {
      final session = await repository.fetchSession();
      if (!session.isAdmin) {
        await _signOutSilently();
        return const AdminAccessState.unauthorized();
      }
      return AdminAccessState.authorized(session);
    } on AdminAccessRevokedException {
      await _signOutSilently();
      return const AdminAccessState.unauthorized();
    } catch (_) {
      return const AdminAccessState.error(
        'Chưa thể kiểm tra quyền quản trị. Phiên hiện tại chưa được dùng để mở dữ liệu quản trị.',
      );
    }
  }

  Future<void> _signOutSilently() async {
    try {
      await ref.read(adminRepositoryProvider).signOut();
    } catch (_) {
      // Preserve the safe access result.
    }
  }
}

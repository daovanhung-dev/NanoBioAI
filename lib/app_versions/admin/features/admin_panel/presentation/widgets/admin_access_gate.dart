import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app/app_surface_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/app_versions/admin/theme/admin_workspace_theme.dart';
import 'package:nano_app/core/theme/theme.dart';

class AdminAccessGate extends ConsumerStatefulWidget {
  final Widget child;

  const AdminAccessGate({super.key, required this.child});

  @override
  ConsumerState<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends ConsumerState<AdminAccessGate> {
  @override
  void initState() {
    super.initState();
    final current = ref.read(adminAccessControllerProvider).asData?.value;
    if (current?.isAuthorized != true) {
      unawaited(ref.read(adminAccessControllerProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessControllerProvider);
    return AppStateSwitcher(
      child: access.when(
        loading: () => const KeyedSubtree(
          key: ValueKey('admin-access-loading'),
          child: _AccessChecking(),
        ),
        error: (_, __) => _AccessMessage(
          key: const ValueKey('admin-access-provider-error'),
          icon: Icons.cloud_off_rounded,
          title: 'Chưa kiểm tra được quyền',
          message:
              'Kết nối chưa ổn định. Khu vực quản trị chưa được mở và dữ liệu chưa bị thay đổi.',
          primaryLabel: 'Thử lại',
          onPrimary: _retry,
          secondaryLabel: 'Về ứng dụng người dùng',
          onSecondary: _showUserApp,
        ),
        data: (value) {
          return switch (value.status) {
            AdminAccessStatus.checking => const KeyedSubtree(
              key: ValueKey('admin-access-checking'),
              child: _AccessChecking(),
            ),
            AdminAccessStatus.authorized => KeyedSubtree(
              key: const ValueKey('admin-access-authorized'),
              child: widget.child,
            ),
            AdminAccessStatus.unauthorized => _AccessMessage(
              key: const ValueKey('admin-access-unauthorized'),
              icon: Icons.lock_person_outlined,
              title: 'Bạn chưa đăng nhập quản trị',
              message:
                  'Đăng nhập bằng tài khoản đã được cấp quyền hoặc trở lại ứng dụng dành cho người dùng.',
              primaryLabel: 'Đăng nhập quản trị',
              onPrimary: () => context.go(AdminRoutePaths.login),
              secondaryLabel: 'Về ứng dụng người dùng',
              onSecondary: _showUserApp,
            ),
            AdminAccessStatus.error => _AccessMessage(
              key: const ValueKey('admin-access-error'),
              icon: Icons.shield_outlined,
              title: 'Khu vực quản trị chưa sẵn sàng',
              message:
                  value.safeMessage ??
                  'Chưa thể xác nhận quyền quản trị. Vui lòng thử lại.',
              primaryLabel: 'Thử lại',
              onPrimary: _retry,
              secondaryLabel: 'Về ứng dụng người dùng',
              onSecondary: _showUserApp,
            ),
          };
        },
      ),
    );
  }

  Future<void> _retry() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    try {
      final access = await ref
          .read(adminAccessControllerProvider.notifier)
          .refresh();
      if (!mounted) return;
      AppFeedbackService.instance.emit(
        access.isAuthorized ? AppFeedbackType.success : AppFeedbackType.warning,
      );
    } catch (_) {
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.error);
    }
  }

  void _showUserApp() {
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    ref.read(appSurfaceControllerProvider.notifier).showUser();
  }
}

class _AccessChecking extends StatelessWidget {
  const _AccessChecking();

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 38,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 16),
              Text('Đang kiểm tra quyền truy cập'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _AccessMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.selected,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.blueStrong, size: 27),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3.copyWith(color: colors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

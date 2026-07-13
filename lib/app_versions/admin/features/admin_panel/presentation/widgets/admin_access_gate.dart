import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
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
    unawaited(ref.read(adminAccessControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessControllerProvider);
    return access.when(
      loading: () => const _AdminChecking(),
      error: (_, __) => _AdminSupport(
        message: 'Chưa thể kiểm tra quyền quản trị. Vui lòng thử lại.',
        onRetry: () => ref.read(adminAccessControllerProvider.notifier).refresh(),
      ),
      data: (value) {
        switch (value.status) {
          case AdminAccessStatus.checking:
            return const _AdminChecking();
          case AdminAccessStatus.authorized:
            return widget.child;
          case AdminAccessStatus.unauthorized:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AdminRoutePaths.login);
            });
            return const _AdminChecking();
          case AdminAccessStatus.error:
            return _AdminSupport(
              message: value.safeMessage ??
                  'Khu vực quản trị chưa sẵn sàng. Vui lòng thử lại.',
              onRetry: () =>
                  ref.read(adminAccessControllerProvider.notifier).refresh(),
            );
        }
      },
    );
  }
}

class _AdminChecking extends StatelessWidget {
  const _AdminChecking();

  @override
  Widget build(BuildContext context) {
    return const MedicalPageScaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AdminSupport extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminSupport({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 56),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

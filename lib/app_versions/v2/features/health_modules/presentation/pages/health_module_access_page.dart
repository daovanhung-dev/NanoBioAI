import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/health_modules/domain/health_module_access_resolver.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

class HealthModuleAccessPage extends ConsumerWidget {
  final String moduleId;

  const HealthModuleAccessPage({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = healthFeatureByModuleId(moduleId);
    if (item == null) {
      return const _HealthModuleSupportPage.notFound();
    }

    final access = ref.watch(effectiveAccessProvider);
    return access.when(
      loading: () => const _HealthModuleSupportPage.loading(),
      error: (_, __) => _HealthModuleSupportPage.accessUnavailable(
        onRetry: () => ref.invalidate(effectiveAccessProvider),
      ),
      data: (effectiveAccess) {
        final destination = HealthModuleAccessResolver.resolve(
          item: item,
          access: effectiveAccess,
        );

        return switch (destination) {
          HealthModuleAccessDestination.loginRequired =>
            const _HealthModuleRouteForwarder(
              location: V2RoutePaths.login,
              message: 'Đang mở trang đăng nhập an toàn...',
            ),
          HealthModuleAccessDestination.upgradeRequired =>
            const _HealthModuleRouteForwarder(
              location: V2RoutePaths.payments,
              message: 'Đang mở lựa chọn nâng cấp gói...',
            ),
          HealthModuleAccessDestination.comingSoon => MedicalComingSoonPage(
            title: item.title,
            message: item.comingSoonMessage,
            eyebrow: item.comingSoonEyebrow,
            icon: item.icon,
            color: item.color,
            previewItems: item.previewItems,
          ),
          HealthModuleAccessDestination.unavailable =>
            _HealthModuleSupportPage.accessUnavailable(
              onRetry: () => ref.invalidate(effectiveAccessProvider),
            ),
        };
      },
    );
  }
}

class _HealthModuleRouteForwarder extends StatefulWidget {
  final String location;
  final String message;

  const _HealthModuleRouteForwarder({
    required this.location,
    required this.message,
  });

  @override
  State<_HealthModuleRouteForwarder> createState() =>
      _HealthModuleRouteForwarderState();
}

class _HealthModuleRouteForwarderState
    extends State<_HealthModuleRouteForwarder> {
  var _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _HealthModuleSupportPage(
      title: 'Đang chuyển tiếp',
      message: widget.message,
      icon: Icons.arrow_forward_rounded,
      showProgress: true,
    );
  }
}

class _HealthModuleSupportPage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool showProgress;

  const _HealthModuleSupportPage({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    this.showProgress = false,
  });

  const _HealthModuleSupportPage.loading()
    : this(
        title: 'Đang kiểm tra quyền truy cập',
        message: 'Nabi đang xác nhận gói của bạn từ hệ thống an toàn.',
        icon: Icons.verified_user_outlined,
        showProgress: true,
      );

  const _HealthModuleSupportPage.notFound()
    : this(
        title: 'Không tìm thấy chức năng',
        message: 'Mục bạn vừa mở không nằm trong danh mục sức khỏe hiện tại.',
        icon: Icons.search_off_rounded,
      );

  const _HealthModuleSupportPage.accessUnavailable({
    required VoidCallback onRetry,
  }) : this(
         title: 'Chưa kiểm tra được quyền truy cập',
         message:
             'Nabi chưa xác nhận được gói của bạn nên chức năng vẫn được khóa an toàn.',
         icon: Icons.lock_clock_outlined,
         onRetry: onRetry,
       );

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'TRUY CẬP AN TOÀN',
      title: title,
      subtitle: message,
      icon: icon,
      children: [
        MedicalEmptyState(
          icon: icon,
          title: title,
          message: message,
          action: showProgress
              ? const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : onRetry == null
              ? null
              : FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
        ),
      ],
    );
  }
}

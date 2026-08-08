import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  var _confirmedExistingCloudWarning = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(v2AuthControllerProvider);
    final syncState = ref.watch(userDataSyncControllerProvider);
    final controller = ref.read(v2AuthControllerProvider.notifier);

    if (syncState.status == UserDataSyncStatus.awaitingConsent) {
      return AppStateSwitcher(
        child: _GuestConsentState(
          key: const ValueKey('auth-gate-consent'),
          cloudHasData: syncState.cloudHasMeaningfulData,
          secondConfirmation: _confirmedExistingCloudWarning,
          loading: false,
          onContinueWarning: () {
            AppFeedbackService.instance.emit(AppFeedbackType.warning);
            setState(() => _confirmedExistingCloudWarning = true);
          },
          onMergeNow: () => _applyGuestAction(GuestMergeAction.mergeNow),
          onUseCloud: () =>
              _applyGuestAction(GuestMergeAction.useExistingCloud),
          onDefer: () {
            AppFeedbackService.instance.emit(AppFeedbackType.warning);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Dữ liệu khách vẫn được giữ trên thiết bị. '
                  'Bạn cần quyết định trước khi vào phần tài khoản.',
                ),
              ),
            );
          },
          onSignOut: _signOut,
        ),
      );
    }

    if (syncState.status == UserDataSyncStatus.syncing) {
      return const AppStateSwitcher(
        child: _AuthLoading(key: ValueKey('auth-gate-syncing')),
      );
    }

    return AppStateSwitcher(
      child: authState.when(
        loading: () => const _AuthLoading(key: ValueKey('auth-gate-loading')),
        error: (_, __) => _AuthSupportState(
          key: const ValueKey('auth-gate-error'),
          title: 'Nabi chưa mở được tài khoản',
          message:
              'Mình chưa kiểm tra được phiên đăng nhập. Bạn thử lại sau một chút nhé.',
          onRetry: () {
            AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
            controller.refresh();
          },
        ),
        data: (routeState) {
          final target = _targetFor(routeState);
          if (target != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(target);
            });
            return const _AuthLoading(key: ValueKey('auth-gate-forwarding'));
          }

          if (routeState.status ==
              AuthRouteStatus.profileBootstrapUnavailable) {
            return _AuthSupportState(
              key: const ValueKey('auth-gate-bootstrap'),
              title: 'Hồ sơ đang được chuẩn bị',
              message: 'Hồ sơ chưa sẵn sàng. Hãy thử lại sau.',
              onRetry: () {
                AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
                controller.refresh();
              },
            );
          }

          return _AuthSupportState(
            key: const ValueKey('auth-gate-support'),
            title: 'Nabi cần kiểm tra thêm',
            message:
                routeState.message ??
                'Trạng thái tài khoản chưa rõ ràng. Mình thử làm mới lại nhé.',
            onRetry: () {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              controller.refresh();
            },
          );
        },
      ),
    );
  }

  Future<void> _applyGuestAction(GuestMergeAction action) async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    final outcome = await ref
        .read(userDataSyncControllerProvider.notifier)
        .sync(AuthSyncReason.manualRetry, guestAction: action);
    if (!mounted) return;

    if (outcome.status == UserDataSyncStatus.success) {
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      await ref.read(v2AuthControllerProvider.notifier).refresh();
      return;
    }

    AppFeedbackService.instance.emit(AppFeedbackType.error);
    final message =
        outcome.safeError ??
        'Chưa thể đồng bộ. Dữ liệu trên thiết bị vẫn được giữ nguyên.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    final controller = ref.read(v2AuthControllerProvider.notifier);
    var result = await controller.signOut();
    if (!mounted) return;

    if (result.requiresForce) {
      final force = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vẫn đăng xuất?'),
          content: Text(result.message ?? 'Còn dữ liệu chưa đồng bộ.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vẫn đăng xuất'),
            ),
          ],
        ),
      );
      if (force == true) result = await controller.signOut(force: true);
    }

    if (mounted && result.signedOut) {
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      context.go(V2RoutePaths.login);
    }
  }

  String? _targetFor(AuthRouteState state) {
    switch (state.status) {
      case AuthRouteStatus.unauthenticated:
        return V2RoutePaths.login;
      case AuthRouteStatus.emailVerificationRequired:
        final email = Uri.encodeComponent(state.email ?? '');
        return '${V2RoutePaths.verifyEmail}?email=$email';
      case AuthRouteStatus.onboardingRequired:
        return V1RoutePaths.onboarding;
      case AuthRouteStatus.authenticatedReady:
        return V1RoutePaths.menu;
      case AuthRouteStatus.initializing:
      case AuthRouteStatus.profileBootstrapUnavailable:
      case AuthRouteStatus.failure:
        return null;
    }
  }
}

class _GuestConsentState extends StatelessWidget {
  final bool cloudHasData;
  final bool secondConfirmation;
  final bool loading;
  final VoidCallback onContinueWarning;
  final VoidCallback onMergeNow;
  final VoidCallback onUseCloud;
  final VoidCallback onDefer;
  final VoidCallback onSignOut;

  const _GuestConsentState({
    super.key,
    required this.cloudHasData,
    required this.secondConfirmation,
    required this.loading,
    required this.onContinueWarning,
    required this.onMergeNow,
    required this.onUseCloud,
    required this.onDefer,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isEstablishedWarning = cloudHasData && !secondConfirmation;
    final colors = context.semanticColors;
    final title = cloudHasData
        ? isEstablishedWarning
              ? 'Tài khoản đã có dữ liệu'
              : 'Xác nhận dùng dữ liệu tài khoản'
        : 'Đồng bộ dữ liệu khách?';
    final message = cloudHasData
        ? isEstablishedWarning
              ? 'Dữ liệu trên thiết bị là dữ liệu khách, còn tài khoản này đã có '
                    'dữ liệu riêng. Không có dữ liệu nào bị xóa nếu bạn chưa xác nhận.'
              : 'Khi tiếp tục, dữ liệu khách trên thiết bị sẽ được thay bằng dữ liệu '
                    'của tài khoản. Hãy chắc chắn bạn muốn dùng dữ liệu tài khoản.'
        : 'Tài khoản mới chưa có dữ liệu sức khỏe. Chọn “Đồng bộ ngay” để chuyển '
              'dữ liệu khách hiện tại vào tài khoản.';

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.cloud_sync_rounded, size: 56),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      if (cloudHasData && isEstablishedWarning)
                        FilledButton(
                          onPressed: loading ? null : onContinueWarning,
                          child: const Text('Tôi đã hiểu, tiếp tục'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: loading
                              ? null
                              : cloudHasData
                              ? onUseCloud
                              : onMergeNow,
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(
                            cloudHasData
                                ? 'Dùng dữ liệu tài khoản'
                                : 'Đồng bộ ngay',
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: loading ? null : onDefer,
                        child: const Text('Để sau'),
                      ),
                      TextButton(
                        onPressed: loading ? null : onSignOut,
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AuthSupportState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _AuthSupportState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: AppDecoration.circle(
                      gradient: AppGradients.primary,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppColors.textInverse,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
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
      ),
    );
  }
}

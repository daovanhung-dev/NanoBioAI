import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(v2AuthControllerProvider);
    final controller = ref.read(v2AuthControllerProvider.notifier);

    return state.when(
      loading: () => const _AuthLoading(),
      error: (_, __) => _AuthSupportState(
        title: 'Nabichưa mở được tài khoản',
        message:
            'Mình chưa kiểm tra được phiên đăng nhập. Bạn thử lại sau một chút nhé.',
        onRetry: () => controller.refresh(),
      ),
      data: (routeState) {
        final target = _targetFor(routeState);
        if (target != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(target);
          });
          return const _AuthLoading();
        }

        if (routeState.status == AuthRouteStatus.profileBootstrapUnavailable) {
          return _AuthSupportState(
            title: 'Hồ sơ đang được chuẩn bị',
            message:
                'Nabiđã thấy phiên đăng nhập, nhưng hồ sơ nền chưa sẵn sàng. Bạn thử lại sau một chút hoặc liên hệ hỗ trợ nhé.',
            onRetry: () => controller.refresh(),
          );
        }

        return _AuthSupportState(
          title: 'Nabicần kiểm tra thêm',
          message:
              routeState.message ??
              'Trạng thái tài khoản chưa rõ ràng. Mình thử làm mới lại nhé.',
          onRetry: () => controller.refresh(),
        );
      },
    );
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

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AuthSupportState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _AuthSupportState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }
}

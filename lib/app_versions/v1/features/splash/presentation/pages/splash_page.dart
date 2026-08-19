import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../domain/services/splash_route_decision.dart';
import '../../providers/splash_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.title = 'Nabi',
    this.subtitle = 'Lắng nghe cơ thể và chăm thói quen mỗi ngày.',
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _loading = true;
  bool _hasNavigated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (_hasNavigated) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final onboardingFuture = AppPrefs.isOnboardingCompleted();
      await Future.wait<void>([
        ref.read(splashProvider.notifier).initialize(),
        Future<void>.delayed(AppDuration.loading),
      ]);
      final onboardingCompleted = await onboardingFuture;
      if (!mounted || _hasNavigated) return;

      final target = const SplashRouteDecision().resolve(
        hasAuthenticatedSession: currentSupabaseUserIdOrNull() != null,
        onboardingCompleted: onboardingCompleted,
      );
      _navigate(target);
    } catch (_) {
      if (!mounted || _hasNavigated) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      setState(() {
        _loading = false;
        _errorMessage =
            'Nabi chưa đọc được trạng thái ứng dụng. Dữ liệu của bạn vẫn được giữ nguyên.';
      });
    }
  }

  void _navigate(SplashRouteTarget target) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    switch (target) {
      case SplashRouteTarget.authGate:
        V1AppNavigator.goAuthGate(context);
        break;
      case SplashRouteTarget.onboardingEntry:
        V1AppNavigator.goOnboardingEntry(context);
        break;
      case SplashRouteTarget.menu:
        V1AppNavigator.goMenu(context);
        break;
      case SplashRouteTarget.onboarding:
        V1AppNavigator.goOnboarding(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: colors.background,
      body: NabiAmbientBackground(
        strong: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NabiCompanionAvatar(
                      size: 136,
                      mood: NabiOnboardingMood.welcome,
                      showStatus: false,
                      hero: true,
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    AnimatedSwitcher(
                      duration: AppMotionScope.duration(
                        context,
                        AppDuration.normal,
                      ),
                      child: _loading
                          ? const _SplashLoading(key: ValueKey('loading'))
                          : _SplashBootstrapError(
                              key: const ValueKey('error'),
                              message:
                                  _errorMessage ?? 'Nabi chưa thể tiếp tục lúc này.',
                              onRetry: _bootstrap,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 30,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Đang chuẩn bị không gian của bạn…',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.semanticColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SplashBootstrapError extends StatelessWidget {
  const _SplashBootstrapError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_problem_rounded,
            size: 38,
            color: context.semanticColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa thể xác định điểm bắt đầu',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.semanticColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingEntryPage extends StatelessWidget {
  const OnboardingEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecoration.card(
                  radius: AppRadius.xxl,
                  shadows: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: AppDecoration.circle(
                        gradient: AppGradients.primary,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Bắt đầu cùng Nami',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Bạn có thể đăng nhập để đồng bộ hồ sơ ngay, hoặc trải nghiệm onboarding trước. Nami sẽ giữ mọi thứ thật nhẹ nhàng cho bạn.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      key: const Key('onboarding_entry_login_cta'),
                      onPressed: () => context.go(AuthRoutePaths.login),
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Đăng nhập hoặc tạo tài khoản'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      key: const Key('onboarding_entry_guest_cta'),
                      onPressed: () => context.go(V1RoutePaths.onboarding),
                      icon: const Icon(Icons.spa_rounded),
                      label: const Text('Onboarding ngay'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Nếu onboarding trước, sau này khi đăng ký Nami sẽ đồng bộ dữ liệu vào tài khoản của bạn.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.45,
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

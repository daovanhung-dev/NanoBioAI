import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class GuestAccountAccessCard extends StatelessWidget {
  const GuestAccountAccessCard({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        container: true,
        label: 'Đăng nhập để đồng bộ và giữ dữ liệu khi đổi thiết bị',
        child: MedicalSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          borderColor: context.semanticColors.borderLight,
          elevated: false,
          radius: AppRadius.xxl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useHorizontalActions = constraints.maxWidth >= 520;

              final loginButton = SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('settings_guest_login_button'),
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Đăng nhập'),
                ),
              );
              final registerButton = SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('settings_guest_register_button'),
                  onPressed: onRegister,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tạo tài khoản mới'),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MedicalIconBadge(
                        icon: Icons.cloud_done_rounded,
                        color: AppColors.primaryDark,
                        backgroundColor: AppColors.primarySoft,
                        size: 52,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng nhập để giữ hành trình lâu dài',
                              style: AppTextStyles.heading3.copyWith(
                                color: context.semanticColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Liên kết dữ liệu trên thiết bị, đồng bộ khi đổi máy và dùng các tính năng thành viên.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.semanticColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  if (useHorizontalActions)
                    Row(
                      children: [
                        Expanded(child: loginButton),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: registerButton),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        loginButton,
                        const SizedBox(height: AppSpacing.sm),
                        registerButton,
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

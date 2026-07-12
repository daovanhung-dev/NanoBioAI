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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đăng nhập để giữ hành trình lâu dài',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Liên kết dữ liệu đang có trên thiết bị, đồng bộ khi đổi máy và mở '
            'các tính năng dành cho thành viên.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('settings_guest_login_button'),
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('settings_guest_register_button'),
              onPressed: onRegister,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Tạo tài khoản mới'),
            ),
          ),
        ],
      ),
    );
  }
}

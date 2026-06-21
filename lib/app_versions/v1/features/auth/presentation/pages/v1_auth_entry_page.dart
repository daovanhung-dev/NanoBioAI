import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

enum V1AuthEntryIntent { login, register }

class V1AuthEntryPage extends StatelessWidget {
  const V1AuthEntryPage({required this.intent, super.key});

  final V1AuthEntryIntent intent;

  bool get _isRegister => intent == V1AuthEntryIntent.register;

  @override
  Widget build(BuildContext context) {
    final title = _isRegister ? 'Tạo tài khoản BioAI' : 'Đăng nhập BioAI';
    final body = _isRegister
        ? 'Nami sẽ đưa bạn sang khu vực tài khoản để lưu hồ sơ và mở rộng '
              'các tính năng thành viên.'
        : 'Nami sẽ đưa bạn sang khu vực tài khoản để đồng bộ hồ sơ và kiểm '
              'tra quyền thành viên an toàn.';
    final actionLabel = _isRegister ? 'Tạo tài khoản' : 'Đăng nhập';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openV2Auth(context),
                  child: Text(actionLabel),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _openV2Auth(BuildContext context) {
    final destination = _isRegister
        ? AuthRoutePaths.register
        : AuthRoutePaths.login;

    try {
      context.go(destination);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khu vực tài khoản chưa sẵn sàng trong phiên bản này.'),
        ),
      );
    }
  }
}

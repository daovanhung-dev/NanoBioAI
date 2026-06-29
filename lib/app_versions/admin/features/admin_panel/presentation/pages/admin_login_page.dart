import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final horizontalPadding = wide ? AppSpacing.xl : AppSpacing.md;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: AnimatedSwitcher(
                      duration: AppDuration.normal,
                      child: wide
                          ? Row(
                              key: const ValueKey('wide-login'),
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(child: _LoginIntroPanel()),
                                const SizedBox(width: AppSpacing.xl),
                                SizedBox(
                                  width: 420,
                                  child: _LoginFormCard(
                                    formKey: _formKey,
                                    email: _email,
                                    password: _password,
                                    loading: _loading,
                                    obscure: _obscure,
                                    onToggleObscure: () {
                                      setState(() => _obscure = !_obscure);
                                    },
                                    onSubmit: _submit,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('compact-login'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _LoginIntroPanel(compact: true),
                                const SizedBox(height: AppSpacing.lg),
                                _LoginFormCard(
                                  formKey: _formKey,
                                  email: _email,
                                  password: _password,
                                  loading: _loading,
                                  obscure: _obscure,
                                  onToggleObscure: () {
                                    setState(() => _obscure = !_obscure);
                                  },
                                  onSubmit: _submit,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(adminControllerProvider.notifier)
          .signInWithEmail(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go(AdminRoutePaths.dashboard);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nabi chưa đăng nhập được. Hãy kiểm tra lại email, mật khẩu hoặc quyền Admin.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _LoginIntroPanel extends StatelessWidget {
  final bool compact;

  const _LoginIntroPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: AppShadows.darkLg,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.info,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.info,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.textInverse,
                size: 30,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            Text(
              'NanoBio Admin',
              style: (compact ? AppTextStyles.heading2 : AppTextStyles.heading1)
                  .copyWith(color: AppColors.textInverse),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Không gian vận hành dành cho đội ngũ được phân quyền, tập trung vào duyệt thanh toán, quản lý Sale, đối soát và audit.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                _LoginFeatureChip(
                  icon: Icons.verified_user_rounded,
                  label: 'Phân quyền rõ ràng',
                ),
                _LoginFeatureChip(
                  icon: Icons.fact_check_rounded,
                  label: 'Audit đầy đủ',
                ),
                _LoginFeatureChip(
                  icon: Icons.bolt_rounded,
                  label: 'Xử lý nhanh',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LoginFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: .16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.secondaryLight, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginFormCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Đăng nhập Admin', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nabi chỉ mở khu quản trị khi tài khoản có quyền phù hợp.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email Admin',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Nhập email hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: password,
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!loading) onSubmit();
                },
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'Mật khẩu cần tối thiểu 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: loading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppSpacing.buttonMinHeight,
                  ),
                ),
                icon: AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: loading
                      ? const SizedBox.square(
                          key: ValueKey('loading'),
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded, key: ValueKey('icon')),
                ),
                label: const Text('Vào khu quản trị'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.floating,
  );
}

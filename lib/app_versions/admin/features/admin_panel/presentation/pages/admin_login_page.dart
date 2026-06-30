import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Màn hình đăng nhập dành riêng cho khu vực quản trị.
///
/// Giữ nguyên luồng nghiệp vụ:
/// [AdminLoginPage] -> [adminControllerProvider.signInWithEmail] -> dashboard.
///
/// Phần UI tập trung vào:
/// - responsive desktop/mobile;
/// - thao tác bàn phím và autofill;
/// - validation sớm, rõ ràng;
/// - chống submit trùng;
/// - phản hồi lỗi thân thiện, không lộ lỗi kỹ thuật.
class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  var _isSubmitting = false;
  var _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
        child: SafeArea(
          child: AnimatedPadding(
            duration: AppDuration.normal,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideLayout = constraints.maxWidth >= 940;
                final horizontalPadding = isWideLayout
                    ? AppSpacing.xl
                    : AppSpacing.md;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: AnimatedSwitcher(
                        duration: AppDuration.normal,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              alignment: Alignment.topCenter,
                              scale: Tween<double>(
                                begin: .985,
                                end: 1,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: isWideLayout
                            ? _WideLoginLayout(
                                key: const ValueKey('wide-login'),
                                form: _buildLoginForm(compact: false),
                              )
                            : _CompactLoginLayout(
                                key: const ValueKey('compact-login'),
                                form: _buildLoginForm(compact: true),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool compact}) {
    return _LoginFormCard(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      passwordFocusNode: _passwordFocusNode,
      compact: compact,
      isSubmitting: _isSubmitting,
      isPasswordObscured: _isPasswordObscured,
      onEmailSubmitted: () => _passwordFocusNode.requestFocus(),
      onTogglePasswordVisibility: () {
        setState(() => _isPasswordObscured = !_isPasswordObscured);
      },
      onSubmit: _submit,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(adminControllerProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            // Không trim mật khẩu vì khoảng trắng có thể là một phần mật khẩu.
            password: _passwordController.text,
          );

      if (!mounted) return;
      context.go(AdminRoutePaths.dashboard);
    } catch (_) {
      if (!mounted) return;
      _showLoginError();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showLoginError() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(AppSpacing.md),
          content: Text(
            'Không thể đăng nhập. Hãy kiểm tra email, mật khẩu hoặc quyền quản trị.',
          ),
        ),
      );
  }
}

class _WideLoginLayout extends StatelessWidget {
  final Widget form;

  const _WideLoginLayout({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: _LoginIntroPanel()),
        const SizedBox(width: AppSpacing.xl),
        SizedBox(width: 420, child: form),
      ],
    );
  }
}

class _CompactLoginLayout extends StatelessWidget {
  final Widget form;

  const _CompactLoginLayout({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LoginIntroPanel(compact: true),
        const SizedBox(height: AppSpacing.lg),
        form,
      ],
    );
  }
}

class _LoginIntroPanel extends StatelessWidget {
  final bool compact;

  const _LoginIntroPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? AppTextStyles.heading2
        : AppTextStyles.heading1;

    return Semantics(
      container: true,
      label: 'Giới thiệu khu vực quản trị NanoBio',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.darkBorder),
          boxShadow: AppShadows.darkLg,
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IntroBrandMark(),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
              Text(
                'NanoBio Admin',
                style: titleStyle.copyWith(color: AppColors.textInverse),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Trung tâm vận hành dành cho đội ngũ được phân quyền: duyệt thanh toán, quản lý Sale, đối soát và theo dõi lịch sử xử lý.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.darkTextSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _LoginFeatureChip(
                    icon: Icons.verified_user_rounded,
                    label: 'Phân quyền rõ ràng',
                  ),
                  _LoginFeatureChip(
                    icon: Icons.fact_check_rounded,
                    label: 'Theo dõi đầy đủ',
                  ),
                  _LoginFeatureChip(
                    icon: Icons.bolt_rounded,
                    label: 'Xử lý tập trung',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBrandMark extends StatelessWidget {
  const _IntroBrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.info,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.info,
      ),
      child: const SizedBox.square(
        dimension: 56,
        child: Icon(
          Icons.admin_panel_settings_rounded,
          color: AppColors.textInverse,
          size: 30,
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
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final bool compact;
  final bool isSubmitting;
  final bool isPasswordObscured;
  final VoidCallback onEmailSubmitted;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.compact,
    required this.isSubmitting,
    required this.isPasswordObscured,
    required this.onEmailSubmitted,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FormHeader(),
                const SizedBox(height: AppSpacing.xl),
                _EmailInput(
                  controller: emailController,
                  enabled: !isSubmitting,
                  onSubmitted: onEmailSubmitted,
                ),
                const SizedBox(height: AppSpacing.md),
                _PasswordInput(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  enabled: !isSubmitting,
                  obscureText: isPasswordObscured,
                  onToggleVisibility: onTogglePasswordVisibility,
                  onSubmitted: onSubmit,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SubmitButton(isSubmitting: isSubmitting, onPressed: onSubmit),
                const SizedBox(height: AppSpacing.md),
                const _FormFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const SizedBox.square(
            dimension: 48,
            child: Icon(Icons.lock_person_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Đăng nhập quản trị', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Chỉ tài khoản có quyền phù hợp mới có thể tiếp tục.',
          style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  const _EmailInput({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: const InputDecoration(
        labelText: 'Email quản trị',
        hintText: 'admin@nanobio.vn',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: _validateEmail,
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmitted;

  const _PasswordInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: 'Mật khẩu',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: enabled ? onToggleVisibility : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
          ),
        ),
      ),
      validator: _validatePassword,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonMinHeight),
      ),
      icon: AnimatedSwitcher(
        duration: AppDuration.fast,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isSubmitting
            ? const SizedBox.square(
                key: ValueKey('login-loading'),
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login_rounded, key: ValueKey('login-icon')),
      ),
      label: Text(isSubmitting ? 'Đang xác thực...' : 'Vào khu quản trị'),
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Liên hệ quản trị hệ thống khi bạn chưa được cấp quyền.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Nhập email quản trị';
  }

  final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

  return isValid ? null : 'Nhập email hợp lệ';
}

String? _validatePassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return 'Nhập mật khẩu';
  }

  if (password.length < 6) {
    return 'Mật khẩu cần tối thiểu 6 ký tự';
  }

  return null;
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.floating,
  );
}

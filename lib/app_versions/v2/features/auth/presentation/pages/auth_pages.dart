import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class V2LoginPage extends ConsumerStatefulWidget {
  const V2LoginPage({super.key});

  @override
  ConsumerState<V2LoginPage> createState() => _V2LoginPageState();
}

class _V2LoginPageState extends ConsumerState<V2LoginPage> {
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
    return _AuthScaffold(
      title: 'Mừng bạn quay lại',
      subtitle:
          'Nabisẽ kiểm tra tài khoản rồi đưa bạn về đúng nơi cần tiếp tục.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AuthTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => AuthValidators.email(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _password,
              label: 'Mật khẩu',
              obscureText: _obscure,
              validator: (value) => AuthValidators.password(value ?? ''),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.go(V2RoutePaths.forgotPassword),
                child: const Text('Bạn quên mật khẩu à?'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryAuthButton(
              label: 'Mình tiếp tục nhé',
              loading: _loading,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => context.go(V2RoutePaths.register),
              child: const Text('Tạo tài khoản mới'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .signInWithEmail(
            LoginCommand(email: _email.text, password: _password.text),
          );
      if (mounted) context.go(V2RoutePaths.authGate);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class V2RegisterPage extends ConsumerStatefulWidget {
  const V2RegisterPage({super.key});

  @override
  ConsumerState<V2RegisterPage> createState() => _V2RegisterPageState();
}

class _V2RegisterPageState extends ConsumerState<V2RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _acceptedTerms = false;
  var _loading = false;
  var _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Tạo tài khoản NanoBio',
      subtitle:
          'Nabisẽ dùng email để bảo vệ hồ sơ sức khỏe và đồng bộ hành trình của bạn.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AuthTextField(
              controller: _fullName,
              label: 'Họ và tên',
              validator: (value) => AuthValidators.fullName(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _phone,
              label: 'Số điện thoại',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => AuthValidators.email(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _password,
              label: 'Mật khẩu',
              obscureText: _obscure,
              validator: (value) => AuthValidators.password(value ?? ''),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _confirmPassword,
              label: 'Nhập lại mật khẩu',
              obscureText: true,
              validator: (value) =>
                  AuthValidators.confirmPassword(_password.text, value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _acceptedTerms = value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryAuthButton(
              label: 'Tạo tài khoản',
              loading: _loading,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: _loading ? null : () => context.go(V2RoutePaths.login),
              child: const Text('Mình đã có tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final termsError = AuthValidators.acceptedTerms(_acceptedTerms);
    if (termsError != null) {
      _showError(
        context,
        AuthFailure(code: AuthFailureCode.validation, userMessage: termsError),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(v2AuthControllerProvider.notifier)
          .signUpWithEmail(
            RegisterCommand(
              email: _email.text,
              password: _password.text,
              confirmPassword: _confirmPassword.text,
              fullName: _fullName.text,
              phone: _phone.text,
              acceptedTerms: _acceptedTerms,
            ),
          );
      if (!mounted) return;
      if (result == RegistrationResult.verificationRequired) {
        context.go(
          '${V2RoutePaths.verifyEmail}?email=${Uri.encodeComponent(_email.text.trim())}',
        );
      } else {
        context.go(V2RoutePaths.authGate);
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class V2VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;

  const V2VerifyEmailPage({super.key, required this.email});

  @override
  ConsumerState<V2VerifyEmailPage> createState() => _V2VerifyEmailPageState();
}

class _V2VerifyEmailPageState extends ConsumerState<V2VerifyEmailPage> {
  Timer? _timer;
  var _cooldown = 0;
  var _loading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Kiểm tra email nhé',
      subtitle:
          'Nabiđã gửi liên kết xác thực tới ${widget.email.isEmpty ? 'email của bạn' : widget.email}. Sau khi mở liên kết, mình sẽ đưa bạn đến bước tiếp theo.',
      child: Column(
        children: [
          _PrimaryAuthButton(
            label: 'Tôi đã xác thực email',
            loading: _loading,
            onPressed: () => context.go(V2RoutePaths.authGate),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _cooldown > 0 || _loading || widget.email.isEmpty
                ? null
                : _resend,
            icon: const Icon(Icons.mark_email_read_rounded),
            label: Text(
              _cooldown > 0
                  ? 'Gửi lại sau $_cooldown giây'
                  : 'Gửi lại email xác thực',
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => context.go(V2RoutePaths.login),
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .resendEmailConfirmation(widget.email);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nabiđã gửi lại email xác thực.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }
}

class V2ForgotPasswordPage extends ConsumerStatefulWidget {
  const V2ForgotPasswordPage({super.key});

  @override
  ConsumerState<V2ForgotPasswordPage> createState() =>
      _V2ForgotPasswordPageState();
}

class _V2ForgotPasswordPageState extends ConsumerState<V2ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _loading = false;
  var _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Lấy lại mật khẩu',
      subtitle:
          'Bạn nhập email, Nabisẽ gửi một liên kết an toàn để đặt mật khẩu mới.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_sent)
              const _InfoBox(
                message:
                    'Nếu email phù hợp với tài khoản, bạn sẽ nhận được liên kết đặt lại mật khẩu.',
              ),
            if (_sent) const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => AuthValidators.email(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryAuthButton(
              label: 'Gửi liên kết',
              loading: _loading,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: _loading ? null : () => context.go(V2RoutePaths.login),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .sendPasswordRecovery(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class V2ResetPasswordPage extends ConsumerStatefulWidget {
  const V2ResetPasswordPage({super.key});

  @override
  ConsumerState<V2ResetPasswordPage> createState() =>
      _V2ResetPasswordPageState();
}

class _V2ResetPasswordPageState extends ConsumerState<V2ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Đặt mật khẩu mới',
      subtitle: 'Chọn một mật khẩu đủ an toàn để Nabibảo vệ hồ sơ của bạn.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AuthTextField(
              controller: _password,
              label: 'Mật khẩu mới',
              obscureText: true,
              validator: (value) => AuthValidators.password(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _confirm,
              label: 'Nhập lại mật khẩu mới',
              obscureText: true,
              validator: (value) =>
                  AuthValidators.confirmPassword(_password.text, value ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryAuthButton(
              label: 'Cập nhật mật khẩu',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .updatePassword(
            UpdatePasswordCommand(
              newPassword: _password.text,
              confirmPassword: _confirm.text,
            ),
          );
      if (mounted) context.go(V2RoutePaths.authGate);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class V2AuthCallbackPage extends ConsumerStatefulWidget {
  final Uri uri;

  const V2AuthCallbackPage({super.key, required this.uri});

  @override
  ConsumerState<V2AuthCallbackPage> createState() => _V2AuthCallbackPageState();
}

class _V2AuthCallbackPageState extends ConsumerState<V2AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_recover);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _recover() async {
    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .recoverSessionFromUri(widget.uri);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) context.go(V2RoutePaths.authGate);
    }
  }
}

class _AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
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
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: AppDecoration.circle(
                        gradient: AppGradients.primary,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
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
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    child,
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

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;

  const _InfoBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(message, style: AppTextStyles.bodyMedium),
    );
  }
}

void _showError(BuildContext context, Object error) {
  final message = error is AuthFailure
      ? error.userMessage
      : 'Nabichưa thể xử lý yêu cầu lúc này. Mình thử lại sau một chút nhé.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

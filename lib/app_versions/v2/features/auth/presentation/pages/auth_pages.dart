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
import 'package:nano_app/sale_referral/domain/services/sale_referral_code_validator.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

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
  var _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authBackendAvailability = ref.watch(authBackendAvailabilityProvider);
    final authBackendFailure = authBackendAvailability.isReady
        ? null
        : authBackendUnavailableFailure(authBackendAvailability);

    return _AuthScaffold(
      eyebrow: 'TÀI KHOẢN NANOBIO',
      heroIcon: Icons.waving_hand_rounded,
      title: 'Mừng bạn quay lại',
      subtitle:
          'Nabi sẽ kiểm tra tài khoản rồi đưa bạn về đúng hành trình đang tiếp tục.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthSectionLabel(
                title: 'Đăng nhập an toàn',
                subtitle:
                    'Dùng email đã liên kết với tài khoản NanoBio của bạn.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _AuthTextField(
                controller: _email,
                label: 'Địa chỉ email',
                hintText: 'ban@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: (value) =>
                    _authValidationText(AuthValidators.email(value ?? '')),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _password,
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    _authValidationText(AuthValidators.password(value ?? '')),
                suffixIcon: _PasswordVisibilityButton(
                  obscure: _obscurePassword,
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: _AuthTextButton(
                  label: 'Quên mật khẩu?',
                  icon: Icons.help_outline_rounded,
                  onPressed: _loading
                      ? null
                      : () => context.go(V2RoutePaths.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (authBackendFailure != null) ...[
                _InfoBox(
                  icon: Icons.info_outline_rounded,
                  title: 'Đăng nhập chưa sẵn sàng',
                  message: authBackendFailure.userMessage,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _PrimaryAuthButton(
                key: const Key('login_submit_button'),
                label: 'Tiếp tục',
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: authBackendAvailability.isReady ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AuthDivider(label: 'hoặc'),
              const SizedBox(height: AppSpacing.sm),
              _RoutePrompt(
                prompt: 'Bạn mới đến với NanoBio?',
                actionLabel: 'Tạo tài khoản',
                onPressed: _loading
                    ? null
                    : () => context.go(V2RoutePaths.register),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!ref.read(authBackendAvailabilityProvider).isReady) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);

    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .signInWithEmail(
            LoginCommand(email: _email.text.trim(), password: _password.text),
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
  final _referralCode = TextEditingController();
  final _referralCodeValidator = const SaleReferralCodeValidator();

  var _acceptedTerms = false;
  var _loading = false;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _referralCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      eyebrow: 'BẮT ĐẦU CÙNG NABI',
      heroIcon: Icons.auto_awesome_rounded,
      title: 'Tạo tài khoản NanoBio',
      subtitle:
          'Hồ sơ của bạn sẽ được bảo vệ để Nabi có thể đồng hành xuyên suốt hành trình khỏe mạnh.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthSectionLabel(
                title: 'Thông tin tài khoản',
                subtitle:
                    'Bạn có thể cập nhật thêm thông tin cá nhân bất cứ lúc nào.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _AuthTextField(
                controller: _fullName,
                label: 'Họ và tên',
                hintText: 'Ví dụ: Nguyễn Minh Anh',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    _authValidationText(AuthValidators.fullName(value ?? '')),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _phone,
                label: 'Số điện thoại',
                hintText: 'Không bắt buộc',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _email,
                label: 'Địa chỉ email',
                hintText: 'ban@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: (value) =>
                    _authValidationText(AuthValidators.email(value ?? '')),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _password,
                label: 'Mật khẩu',
                hintText: 'Tạo mật khẩu đủ mạnh',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    _authValidationText(AuthValidators.password(value ?? '')),
                suffixIcon: _PasswordVisibilityButton(
                  obscure: _obscurePassword,
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _confirmPassword,
                label: 'Nhập lại mật khẩu',
                hintText: 'Nhập lại để xác nhận',
                prefixIcon: Icons.verified_user_outlined,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    AuthValidators.confirmPassword(_password.text, value ?? ''),
                suffixIcon: _PasswordVisibilityButton(
                  obscure: _obscureConfirmPassword,
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthTextField(
                controller: _referralCode,
                label: 'Mã giới thiệu',
                hintText: 'Không bắt buộc',
                prefixIcon: Icons.card_giftcard_rounded,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    _referralCodeValidator.validate(value ?? ''),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthLegalConsent(
                value: _acceptedTerms,
                enabled: !_loading,
                onChanged: (value) {
                  setState(() => _acceptedTerms = value ?? false);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrimaryAuthButton(
                label: 'Tạo tài khoản',
                icon: Icons.person_add_alt_1_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoutePrompt(
                prompt: 'Bạn đã có tài khoản?',
                actionLabel: 'Đăng nhập',
                onPressed: _loading
                    ? null
                    : () => context.go(V2RoutePaths.login),
              ),
            ],
          ),
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

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);

    try {
      final result = await ref
          .read(v2AuthControllerProvider.notifier)
          .signUpWithEmail(
            RegisterCommand(
              email: _email.text.trim(),
              password: _password.text,
              confirmPassword: _confirmPassword.text,
              fullName: _fullName.text.trim(),
              phone: _phone.text.trim(),
              acceptedTerms: _acceptedTerms,
              referralCode: _referralCodeValidator.normalize(_referralCode.text),
            ),
          );

      if (!mounted) return;
      if (result == RegistrationResult.verificationRequired) {
        context.go(
          '${V2RoutePaths.verifyEmail}'
          '?email=${Uri.encodeComponent(_email.text.trim())}',
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
    final email = widget.email.isEmpty ? 'email của bạn' : widget.email;

    return _AuthScaffold(
      eyebrow: 'XÁC THỰC TÀI KHOẢN',
      heroIcon: Icons.mark_email_read_rounded,
      title: 'Kiểm tra email nhé',
      subtitle:
          'Nabi đã gửi một liên kết xác thực tới $email. Mở liên kết đó rồi quay lại đây để tiếp tục.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoBox(
            icon: Icons.mail_lock_outlined,
            title: 'Bước nhỏ để bảo vệ hồ sơ của bạn',
            message:
                'Hãy kiểm tra cả mục Thư rác hoặc Quảng cáo nếu bạn chưa thấy email sau vài phút.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryAuthButton(
            label: 'Tôi đã xác thực email',
            icon: Icons.check_circle_outline_rounded,
            loading: _loading,
            onPressed: () => context.go(V2RoutePaths.authGate),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SecondaryAuthButton(
            label: _cooldown > 0
                ? 'Gửi lại sau $_cooldown giây'
                : 'Gửi lại email xác thực',
            icon: Icons.refresh_rounded,
            onPressed: _cooldown > 0 || _loading || widget.email.isEmpty
                ? null
                : _resend,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RoutePrompt(
            prompt: 'Muốn dùng email khác?',
            actionLabel: 'Quay lại đăng nhập',
            onPressed: _loading ? null : () => context.go(V2RoutePaths.login),
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            content: const Text('Nabi đã gửi lại email xác thực.'),
          ),
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
      eyebrow: 'KHÔI PHỤC TÀI KHOẢN',
      heroIcon: Icons.key_rounded,
      title: 'Lấy lại mật khẩu',
      subtitle:
          'Nhập email đã đăng ký, Nabi sẽ gửi một liên kết an toàn để bạn đặt mật khẩu mới.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent) ...[
              const _InfoBox(
                icon: Icons.mark_email_read_outlined,
                title: 'Kiểm tra hộp thư của bạn',
                message:
                    'Nếu email phù hợp với tài khoản, bạn sẽ nhận được liên kết đặt lại mật khẩu.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _AuthTextField(
              controller: _email,
              label: 'Địa chỉ email',
              hintText: 'ban@example.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: (value) =>
                  _authValidationText(AuthValidators.email(value ?? '')),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryAuthButton(
              label: _sent ? 'Gửi lại liên kết' : 'Gửi liên kết',
              icon: Icons.send_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoutePrompt(
              prompt: 'Bạn đã nhớ mật khẩu?',
              actionLabel: 'Quay lại đăng nhập',
              onPressed: _loading ? null : () => context.go(V2RoutePaths.login),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);

    try {
      await ref
          .read(v2AuthControllerProvider.notifier)
          .sendPasswordRecovery(_email.text.trim());

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
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      eyebrow: 'CẬP NHẬT BẢO MẬT',
      heroIcon: Icons.lock_reset_rounded,
      title: 'Đặt mật khẩu mới',
      subtitle:
          'Chọn một mật khẩu đủ an toàn để Nabi tiếp tục bảo vệ hồ sơ của bạn.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InfoBox(
              icon: Icons.shield_outlined,
              title: 'Mẹo bảo mật',
              message:
                  'Nên dùng mật khẩu riêng, đủ dài và không chia sẻ với bất kỳ ai.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _AuthTextField(
              controller: _password,
              label: 'Mật khẩu mới',
              hintText: 'Tạo mật khẩu mới',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  _authValidationText(AuthValidators.password(value ?? '')),
              suffixIcon: _PasswordVisibilityButton(
                obscure: _obscurePassword,
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextField(
              controller: _confirm,
              label: 'Nhập lại mật khẩu mới',
              hintText: 'Xác nhận mật khẩu mới',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  AuthValidators.confirmPassword(_password.text, value ?? ''),
              suffixIcon: _PasswordVisibilityButton(
                obscure: _obscureConfirmPassword,
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryAuthButton(
              label: 'Cập nhật mật khẩu',
              icon: Icons.check_circle_outline_rounded,
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

    FocusManager.instance.primaryFocus?.unfocus();
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
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_recover);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      eyebrow: _error == null ? 'ĐANG XÁC THỰC' : 'CẦN THỬ LẠI',
      heroIcon: _error == null
          ? Icons.verified_user_rounded
          : Icons.support_agent_rounded,
      title: _error == null
          ? 'Nabi đang kiểm tra liên kết'
          : 'Liên kết chưa hoàn tất',
      subtitle: _error == null
          ? 'Chỉ mất một chút thời gian để hoàn tất bước bảo mật này cho bạn.'
          : 'Dữ liệu tài khoản chưa bị thay đổi. Bạn có thể thử lại bằng liên kết mới nhất trong email.',
      child: _error == null
          ? const _AuthCallbackLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBox(
                  icon: Icons.info_outline_rounded,
                  title: 'Chưa thể xác thực',
                  message: _safeErrorMessage(_error!),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PrimaryAuthButton(
                  label: 'Thử lại',
                  icon: Icons.refresh_rounded,
                  loading: _loading,
                  onPressed: _recover,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SecondaryAuthButton(
                  label: 'Về đăng nhập',
                  icon: Icons.login_rounded,
                  onPressed: _loading
                      ? null
                      : () => context.go(V2RoutePaths.login),
                ),
              ],
            ),
    );
  }

  Future<void> _recover() async {
    if (_loading && _error != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(v2AuthControllerProvider.notifier)
          .recoverSessionFromUri(widget.uri);
      if (!mounted) return;
      context.go(
        result.isPasswordRecovery
            ? V2RoutePaths.resetPassword
            : V2RoutePaths.authGate,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

String _safeErrorMessage(Object error) {
  if (error is AuthFailure) return error.userMessage;
  return 'Nabi chưa thể xử lý yêu cầu này. Bạn hãy thử lại sau một chút.';
}

class _AuthScaffold extends StatelessWidget {
  final String eyebrow;
  final IconData heroIcon;
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthScaffold({
    required this.eyebrow,
    required this.heroIcon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return MedicalPageScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;
            final pagePadding = constraints.maxWidth >= 560
                ? AppSpacing.xl
                : AppSpacing.md;

            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  AppSpacing.md,
                  pagePadding,
                  AppSpacing.xl + keyboardBottomInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 980 : 560),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: AppShadows.soft,
                      ),
                      child: isWide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 350,
                                    child: _AuthBrandPanel(
                                      eyebrow: eyebrow,
                                      icon: heroIcon,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.xl),
                                      child: _AuthFormContent(
                                        title: title,
                                        subtitle: subtitle,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.all(
                                constraints.maxWidth < 380
                                    ? AppSpacing.md
                                    : AppSpacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _AuthHero(
                                    eyebrow: eyebrow,
                                    icon: heroIcon,
                                    title: title,
                                    subtitle: subtitle,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  child,
                                  const SizedBox(height: AppSpacing.lg),
                                  const _AuthTrustNote(),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthFormContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthFormContent({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.heading1),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.55)),
        const SizedBox(height: AppSpacing.xl),
        child,
        const SizedBox(height: AppSpacing.lg),
        const _AuthTrustNote(),
      ],
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  final String eyebrow;
  final IconData icon;

  const _AuthBrandPanel({required this.eyebrow, required this.icon});

  @override
  Widget build(BuildContext context) {
    const benefits = [
      ('Dữ liệu được bảo vệ', Icons.shield_outlined),
      ('Tiếp tục hành trình trên nhiều thiết bị', Icons.devices_rounded),
      ('Bạn chủ động kiểm soát thông tin', Icons.manage_accounts_outlined),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.hero),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthPanelPattern(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalStatusPill(
                  label: eyebrow,
                  icon: Icons.verified_user_outlined,
                  foregroundColor: AppColors.textInverse,
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  borderColor: Colors.white.withValues(alpha: .22),
                ),
                const Spacer(),
                MedicalIconBadge(
                  icon: icon,
                  color: AppColors.textInverse,
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nabi đồng hành\ncùng bạn mỗi ngày',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textInverse,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final benefit in benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          benefit.$2,
                          color: AppColors.textInverse.withValues(alpha: .92),
                          size: 19,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            benefit.$1,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textInverse.withValues(alpha: .88),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPanelPattern extends StatelessWidget {
  const _AuthPanelPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .10),
                  width: 32,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;

  const _AuthHero({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            eyebrow,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.7,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.textInverse, size: 34),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _AuthSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthSectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  const _AuthTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.primary, size: 21),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 52),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        helperStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        errorStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.error,
          fontSize: 12,
          height: 1.3,
        ),
        errorMaxLines: 2,
        border: _inputBorder(AppColors.borderLight),
        enabledBorder: _inputBorder(AppColors.borderLight),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onPressed;

  const _PasswordVisibilityButton({
    required this.obscure,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _AuthLegalConsent extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _AuthLegalConsent({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đồng ý với điều khoản sử dụng và chính sách bảo mật',
      child: Container(
        decoration: BoxDecoration(
          color: value ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.borderLight,
          ),
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: enabled ? onChanged : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          activeColor: AppColors.primary,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          title: Text(
            'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    final disabled = loading || onPressed == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: disabled
                ? AppGradients.primarySoft
                : AppGradients.primary,
            borderRadius: borderRadius,
            boxShadow: disabled
                ? const []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: disabled ? null : onPressed,
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: loading
                      ? const SizedBox.square(
                          key: ValueKey('auth_loading'),
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : Row(
                          key: const ValueKey('auth_label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(icon, color: AppColors.textInverse, size: 20),
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

class _SecondaryAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SecondaryAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.36)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AuthTextButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _AuthTextButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        textStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoutePrompt extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _RoutePrompt({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text(
          prompt,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: const Size(48, 40),
            textStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _AuthDivider extends StatelessWidget {
  final String label;

  const _AuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTrustNote extends StatelessWidget {
  const _AuthTrustNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'NanoBio luôn ưu tiên sự riêng tư của bạn.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCallbackLoading extends StatelessWidget {
  const _AuthCallbackLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.3),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Nabi đang hoàn tất xác thực an toàn cho bạn.')),
        ],
      ),
    );
  }
}

String? _authValidationText(String? raw) {
  if (raw == null) return null;
  return vietnameseSystemUiText(raw, fallback: 'Thông tin chưa hợp lệ.');
}

void _showError(BuildContext context, Object error) {
  final message = error is AuthFailure
      ? error.userMessage
      : 'Nabi chưa thể xử lý yêu cầu lúc này. Mình thử lại sau một chút nhé.';

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textInverse,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

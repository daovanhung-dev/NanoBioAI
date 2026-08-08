import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/app_versions/admin/theme/admin_workspace_theme.dart';
import 'package:nano_app/core/theme/theme.dart';

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

  bool _submitting = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminAccessControllerProvider, (_, next) {
      final access = next.asData?.value;
      if (access?.isAuthorized == true && context.mounted) {
        context.go(AdminRoutePaths.dashboard);
      }
    });

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colors = context.adminColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 18,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _LoginIntroduction()),
                              const SizedBox(width: 28),
                              SizedBox(width: 390, child: _buildForm()),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _LoginIntroduction(compact: true),
                              const SizedBox(height: 18),
                              _buildForm(),
                            ],
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

  Widget _buildForm() {
    final colors = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đăng nhập quản trị',
                style: AppTextStyles.heading3.copyWith(color: colors.text),
              ),
              const SizedBox(height: 6),
              Text(
                'Sử dụng tài khoản đã được cấp quyền quản trị.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ten@congty.vn',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                enabled: !_submitting,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: _submitting
                        ? null
                        : () {
                            AppFeedbackService.instance.emit(
                              AppFeedbackType.selection,
                            );
                            setState(() => _hidePassword = !_hidePassword);
                          },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.topCenter,
                child: _errorMessage == null
                    ? const SizedBox(height: 18)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 4),
                        child: _InlineError(message: _errorMessage!),
                      ),
              ),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 19),
                  label: Text(_submitting ? 'Đang kiểm tra' : 'Đăng nhập'),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 17,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Chỉ những khu vực được cấp quyền mới xuất hiện sau khi đăng nhập.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);

    try {
      await ref
          .read(adminAccessControllerProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.success);
      // Điều hướng chỉ được thực hiện bởi listener phía trên để tránh chuyển
      // trang hai lần khi trạng thái quyền cập nhật.
    } catch (error) {
      if (!mounted) return;
      final message = error is AdminAccessFailure
          ? error.message
          : 'Chưa thể đăng nhập lúc này. Vui lòng kiểm tra thông tin và thử lại.';
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return valid ? null : 'Email chưa đúng định dạng.';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    return null;
  }
}

class _LoginIntroduction extends StatelessWidget {
  final bool compact;

  const _LoginIntroduction({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 32),
      decoration: BoxDecoration(
        color: colors.brandSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          SizedBox(height: compact ? 15 : 26),
          Text(
            'NanoBio Quản trị',
            style: (compact ? AppTextStyles.heading2 : AppTextStyles.heading1)
                .copyWith(color: Colors.white),
          ),
          const SizedBox(height: 9),
          Text(
            'Một không gian tập trung để theo dõi, kiểm tra và xử lý công việc vận hành.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: colors.onBrandSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IntroFeature(
                icon: Icons.verified_user_outlined,
                label: 'Phân quyền rõ ràng',
              ),
              _IntroFeature(
                icon: Icons.fact_check_outlined,
                label: 'Dễ kiểm tra lại',
              ),
              _IntroFeature(
                icon: Icons.speed_rounded,
                label: 'Thao tác tập trung',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IntroFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colors.brandHighlight),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.dangerContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 19, color: colors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.onDangerContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

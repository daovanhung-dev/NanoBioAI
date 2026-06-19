import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          context.go('/menu');
        },
        error: (e, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nami chưa thể đăng nhập lúc này. Bạn kiểm tra lại thông tin rồi thử thêm một lần nhé.',
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 420;
          final isVerySmall = width < 360;

          final horizontalPadding = isVerySmall
              ? 12.0
              : (isCompact ? 16.0 : 24.0);
          final cardPadding = isCompact ? 20.0 : 28.0;
          final cardMaxWidth = width >= 600 ? 460.0 : double.infinity;
          final radius = isCompact ? 24.0 : 28.0;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA),
                  Color(0xFFF8FBFF),
                  Color(0xFFEFFBFF),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (!isVerySmall) const _BackgroundOrbs(),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: isCompact ? 14 : 18,
                              sigmaY: isCompact ? 14 : 18,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(cardPadding),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(radius),
                                border: Border.all(color: Colors.white70),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    _BrandMark(compact: isCompact),
                                    SizedBox(height: isCompact ? 20 : 24),
                                    Text(
                                      'Mừng bạn quay lại',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isCompact ? 22 : 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mình vẫn ở đây và sẵn sàng tiếp tục hành trình sức khỏe cùng bạn.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isCompact ? 13 : 14,
                                        color: Colors.grey,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: isCompact ? 24 : 32),
                                    _InputField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hintText: 'yourname@example.com',
                                      prefixIcon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      compact: isCompact,
                                      validator: (value) {
                                        final email = value?.trim() ?? '';

                                        if (email.isEmpty) {
                                          return 'Bạn cho mình xin email nhé.';
                                        }

                                        if (!email.contains('@')) {
                                          return 'Email này có vẻ chưa đúng, bạn kiểm tra lại giúp mình nhé.';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _InputField(
                                      controller: _passwordController,
                                      label: 'Mật khẩu',
                                      hintText: 'Mật khẩu của bạn',
                                      prefixIcon: Icons.lock_rounded,
                                      obscureText: _obscurePassword,
                                      compact: isCompact,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                      validator: (value) {
                                        final password = value ?? '';

                                        if (password.isEmpty) {
                                          return 'Bạn chưa nhập mật khẩu rồi.';
                                        }

                                        if (password.length < 6) {
                                          return 'Mật khẩu cần ít nhất 6 ký tự nhé.';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.scale(
                                              scale: isCompact ? 0.95 : 1.0,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe =
                                                        value ?? false;
                                                  });
                                                },
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                            const Text(
                                              'Nhớ mình trên thiết bị này',
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {},
                                          child: const Text(
                                            'Bạn quên mật khẩu à?',
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: loginState.isLoading
                                            ? null
                                            : () async {
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();

                                                if (!(_formKey.currentState
                                                        ?.validate() ??
                                                    false)) {
                                                  return;
                                                }

                                                await ref
                                                    .read(
                                                      loginControllerProvider
                                                          .notifier,
                                                    )
                                                    .login(
                                                      email: _emailController
                                                          .text
                                                          .trim(),
                                                      password:
                                                          _passwordController
                                                              .text,
                                                    );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF00B8D4,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: loginState.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Mình tiếp tục nhé',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 64.0 : 80.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00B8D4), Color(0xFF4DD0E1)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: compact ? 34 : 42,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'BioAI',
          style: TextStyle(
            fontSize: compact ? 24 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.compact = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffixIcon,
            isDense: compact,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 14 : 16,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF00B8D4),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        _Orb(top: -80, left: -40, size: 220, color: Color(0x5539D2FF)),
        _Orb(bottom: -100, right: -50, size: 260, color: Color(0x334DD0E1)),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}

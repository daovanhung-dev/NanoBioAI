import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminCreateAccountPage extends ConsumerStatefulWidget {
  const AdminCreateAccountPage({super.key});

  @override
  ConsumerState<AdminCreateAccountPage> createState() => _AdminCreateAccountPageState();
}

class _AdminCreateAccountPageState extends ConsumerState<AdminCreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _reason = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _createdUserId;
  String? _createdEmail;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAccountsControllerProvider);
    final canCreate = state.asData?.value.canCreateAccount ?? false;

    return AdminSimpleShell(
      selectedPath: AdminRoutePaths.createAccount,
      title: 'Tạo tài khoản',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo tài khoản', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Tạo tài khoản người dùng thật qua hệ thống xác thực của NanoBio.'),
            const SizedBox(height: 18),
            if (state.isLoading)
              const LinearProgressIndicator()
            else if (!canCreate)
              const AdminPermissionView(
                message: 'Chỉ Super Admin hoặc Support Admin được tạo tài khoản mới.',
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.trim().length < 2
                              ? 'Vui lòng nhập họ và tên.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            return text.contains('@') && text.contains('.')
                                ? null
                                : 'Email chưa đúng định dạng.';
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại (không bắt buộc)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu ban đầu',
                            helperText: 'Tối thiểu 8 ký tự.',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8
                              ? 'Mật khẩu cần ít nhất 8 ký tự.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _reason,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Lý do tạo tài khoản',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập lý do.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(_submitting ? 'Đang tạo...' : 'Tạo tài khoản'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_createdUserId != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded),
                            SizedBox(width: 8),
                            Text('Tạo tài khoản thành công'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_createdEmail ?? ''),
                        const SizedBox(height: 4),
                        SelectableText('ID: $_createdUserId'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.go(AdminRoutePaths.accounts),
                          child: const Text('Mở quản trị tài khoản'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tạo tài khoản'),
        content: Text('Tạo tài khoản cho ${_email.text.trim()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tạo tài khoản')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(adminAccountsControllerProvider.notifier).createAccount(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        reason: _reason.text,
      );
      if (!mounted) return;
      setState(() {
        _createdUserId = result.userId;
        _createdEmail = result.email;
        _password.clear();
      });
      showAdminNotice(context, 'Đã tạo tài khoản ${result.email}.');
    } catch (error) {
      if (mounted) showAdminNotice(context, adminSafeError(error), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

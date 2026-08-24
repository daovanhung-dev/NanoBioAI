import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_account_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminUpgradeAccountPage extends ConsumerStatefulWidget {
  const AdminUpgradeAccountPage({super.key});

  @override
  ConsumerState<AdminUpgradeAccountPage> createState() => _AdminUpgradeAccountPageState();
}

class _AdminUpgradeAccountPageState extends ConsumerState<AdminUpgradeAccountPage> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  Timer? _debounce;
  String? _selectedUserId;
  String _planCode = 'plus';
  int _durationMonths = 1;
  bool _submitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminAccountsControllerProvider);
    return AdminSimpleShell(
      selectedPath: AdminRoutePaths.upgradeAccount,
      title: 'Nâng cấp tài khoản',
      child: asyncState.when(
        loading: () => const AdminLoadingView(),
        error: (_, __) => AdminErrorView(
          onRetry: () => ref.read(adminAccountsControllerProvider.notifier).refresh(),
        ),
        data: (state) {
          if (!state.canGrantMembership) {
            return const AdminPermissionView(
              message: 'Chỉ Super Admin được cấp Plus/FamilyPlus thủ công.',
            );
          }
          AdminAccountSummary? selected;
          for (final account in state.accounts) {
            if (account.id == _selectedUserId) {
              selected = account;
              break;
            }
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nâng cấp tài khoản', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text('Cấp Plus hoặc FamilyPlus thủ công. Thay đổi chỉ có hiệu lực sau khi backend xác nhận.'),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Tìm tài khoản cần nâng cấp',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 320), () {
                      if (!mounted) return;
                      ref.read(adminAccountsControllerProvider.notifier).search(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (state.accounts.isNotEmpty)
                  Card(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.accounts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final account = state.accounts[index];
                          return RadioListTile<String>(
                            value: account.id,
                            groupValue: _selectedUserId,
                            onChanged: (value) => setState(() => _selectedUserId = value),
                            title: Text(account.displayName),
                            subtitle: Text('${account.email} • ${adminPlanLabel(account.planCode)}'),
                          );
                        },
                      ),
                    ),
                  )
                else
                  const AdminEmptyView(
                    title: 'Chưa chọn được tài khoản',
                    message: 'Nhập tên hoặc email để tìm người dùng cần cấp gói.',
                  ),
                if (selected != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Tài khoản đã chọn', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(selected.displayName),
                          Text(selected.email),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AdminStatusChip(label: 'Hiện tại: ${adminPlanLabel(selected.planCode)}'),
                              if (selected.subscriptionEndsAt != null)
                                AdminStatusChip(
                                  label: 'Hết hạn: ${adminFormatDate(selected.subscriptionEndsAt)}',
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _planCode,
                            decoration: const InputDecoration(
                              labelText: 'Gói mới',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'plus', child: Text('Plus')),
                              DropdownMenuItem(value: 'family_plus', child: Text('FamilyPlus')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _planCode = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          Text('Thời hạn', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final months in const [1, 3, 6, 12])
                                ChoiceChip(
                                  label: Text('$months tháng'),
                                  selected: _durationMonths == months,
                                  onSelected: (_) => setState(() => _durationMonths = months),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _reason,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Lý do cấp gói',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _submitting ? null : () => _submit(selected!),
                            icon: _submitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.workspace_premium_rounded),
                            label: Text(_submitting ? 'Đang cập nhật...' : 'Xác nhận nâng cấp'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(AdminAccountSummary account) async {
    if (_reason.text.trim().isEmpty) {
      showAdminNotice(context, 'Vui lòng nhập lý do cấp gói.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nâng cấp'),
        content: Text(
          'Cấp ${adminPlanLabel(_planCode)} trong $_durationMonths tháng cho ${account.email}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(adminAccountsControllerProvider.notifier).grantMembership(
        userId: account.id,
        planCode: _planCode,
        durationMonths: _durationMonths,
        reason: _reason.text,
      );
      if (mounted) {
        _reason.clear();
        showAdminNotice(context, 'Đã cập nhật gói thành viên từ backend.');
      }
    } catch (error) {
      if (mounted) showAdminNotice(context, adminSafeError(error), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

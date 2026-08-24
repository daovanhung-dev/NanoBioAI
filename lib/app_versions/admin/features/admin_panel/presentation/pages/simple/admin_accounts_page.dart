import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_account_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminAccountsPage extends ConsumerStatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  ConsumerState<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends ConsumerState<AdminAccountsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminAccountsControllerProvider);
    return AdminSimpleShell(
      selectedPath: AdminRoutePaths.accounts,
      title: 'Quản trị tài khoản',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Quản trị tài khoản',
            description: 'Tìm người dùng, xem gói hiện tại và khóa hoặc mở lại tài khoản.',
            trailing: IconButton.filledTonal(
              tooltip: 'Làm mới',
              onPressed: () => ref.read(adminAccountsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tìm theo tên, email hoặc số điện thoại',
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
          const SizedBox(height: 18),
          Expanded(
            child: asyncState.when(
              loading: () => const AdminLoadingView(),
              error: (_, __) => AdminErrorView(
                onRetry: () => ref.read(adminAccountsControllerProvider.notifier).refresh(),
              ),
              data: (state) {
                if (!state.canManageAccounts) {
                  return const AdminPermissionView(
                    message: 'Tài khoản quản trị hiện tại chưa được cấp quyền quản lý người dùng.',
                  );
                }
                if (state.accounts.isEmpty) {
                  return AdminEmptyView(
                    title: state.query.isEmpty ? 'Chưa có tài khoản để hiển thị' : 'Không tìm thấy tài khoản',
                    message: state.query.isEmpty
                        ? 'Danh sách sẽ xuất hiện khi dữ liệu người dùng sẵn sàng.'
                        : 'Thử từ khóa khác hoặc xóa nội dung tìm kiếm.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminAccountsControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = state.accounts[index];
                      return _AccountCard(account: account);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AdminAccountSummary account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suspended = account.accountStatus.toLowerCase() == 'suspended';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.displayName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(account.email),
                if (account.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(account.phone!),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminStatusChip(
                      label: adminPlanLabel(account.planCode),
                      positive: account.planCode != 'free',
                    ),
                    AdminStatusChip(
                      label: adminAccountStatusLabel(account.accountStatus),
                      positive: !suspended,
                      warning: suspended,
                    ),
                    if (account.saleStatus != 'none')
                      AdminStatusChip(
                        label: 'Sale: ${adminSaleStatusLabel(account.saleStatus)}',
                        warning: account.saleStatus == 'pending',
                      ),
                  ],
                ),
              ],
            );

            final action = FilledButton.tonalIcon(
              onPressed: () async {
                final reason = await showAdminReasonDialog(
                  context,
                  title: suspended ? 'Mở lại tài khoản' : 'Tạm khóa tài khoản',
                );
                if (reason == null || !context.mounted) return;
                try {
                  await ref.read(adminAccountsControllerProvider.notifier).updateAccountStatus(
                    userId: account.id,
                    status: suspended ? 'active' : 'suspended',
                    reason: reason,
                  );
                  if (context.mounted) {
                    showAdminNotice(
                      context,
                      suspended ? 'Đã mở lại tài khoản.' : 'Đã tạm khóa tài khoản.',
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    showAdminNotice(context, adminSafeError(error), error: true);
                  }
                }
              },
              icon: Icon(suspended ? Icons.lock_open_rounded : Icons.lock_rounded),
              label: Text(suspended ? 'Mở lại' : 'Tạm khóa'),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const SizedBox(height: 14), action],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Expanded(child: info), const SizedBox(width: 16), action],
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String description;
  final Widget? trailing;

  const _PageHeader({
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

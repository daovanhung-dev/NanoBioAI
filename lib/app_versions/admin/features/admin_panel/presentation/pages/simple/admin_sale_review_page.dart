import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminSaleReviewPage extends ConsumerStatefulWidget {
  const AdminSaleReviewPage({super.key});

  @override
  ConsumerState<AdminSaleReviewPage> createState() => _AdminSaleReviewPageState();
}

class _AdminSaleReviewPageState extends ConsumerState<AdminSaleReviewPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminSalesControllerProvider);
    return AdminSimpleShell(
      selectedPath: AdminRoutePaths.saleReview,
      title: 'Duyệt Sale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duyệt Sale', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Tập trung vào hồ sơ chờ duyệt. Duyệt hoặc từ chối với lý do rõ ràng.'),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tìm theo tên, email hoặc mã giới thiệu',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 320), () {
                if (mounted) {
                  ref.read(adminSalesControllerProvider.notifier).searchSales(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: asyncState.when(
              loading: () => const AdminLoadingView(),
              error: (_, __) => AdminErrorView(
                onRetry: () => ref.read(adminSalesControllerProvider.notifier).refresh(),
              ),
              data: (state) {
                if (!state.canManageSales) {
                  return const AdminPermissionView(
                    message: 'Tài khoản quản trị hiện tại chưa được cấp quyền xử lý Sale.',
                  );
                }
                final items = state.saleReviews
                    .where((item) => item.status.toLowerCase().contains('pending'))
                    .toList(growable: false);
                if (items.isEmpty) {
                  return const AdminEmptyView(
                    title: 'Không có hồ sơ Sale chờ duyệt',
                    message: 'Khi có hồ sơ mới, chúng sẽ xuất hiện tại đây.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminSalesControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _SaleReviewCard(item: items[index]),
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

class _SaleReviewCard extends ConsumerWidget {
  final AdminWorkItem item;

  const _SaleReviewCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(item.title.trim().isEmpty ? '?' : item.title.trim()[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                      if (item.subtitle.isNotEmpty) Text(item.subtitle),
                    ],
                  ),
                ),
                const AdminStatusChip(label: 'Chờ duyệt', warning: true),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _run(context, ref, 'approve'),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Duyệt Sale'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _run(context, ref, 'reject'),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Từ chối'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, String decision) async {
    final reason = await showAdminReasonDialog(
      context,
      title: decision == 'approve' ? 'Duyệt hồ sơ Sale' : 'Từ chối hồ sơ Sale',
      confirmLabel: decision == 'approve' ? 'Duyệt' : 'Từ chối',
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(adminSalesControllerProvider.notifier).reviewSale(
        userId: item.id,
        decision: decision,
        reason: reason,
      );
      if (context.mounted) {
        showAdminNotice(
          context,
          decision == 'approve' ? 'Đã duyệt hồ sơ Sale.' : 'Đã từ chối hồ sơ Sale.',
        );
      }
    } catch (error) {
      if (context.mounted) showAdminNotice(context, adminSafeError(error), error: true);
    }
  }
}

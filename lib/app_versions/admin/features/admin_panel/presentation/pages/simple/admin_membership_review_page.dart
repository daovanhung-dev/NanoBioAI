import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminMembershipReviewPage extends ConsumerStatefulWidget {
  const AdminMembershipReviewPage({super.key});

  @override
  ConsumerState<AdminMembershipReviewPage> createState() =>
      _AdminMembershipReviewPageState();
}

class _AdminMembershipReviewPageState
    extends ConsumerState<AdminMembershipReviewPage> {
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
    final asyncState = ref.watch(adminMembershipControllerProvider);
    return AdminSimpleShell(
      selectedPath: AdminRoutePaths.membershipReview,
      title: 'Duyệt nâng cấp gói',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duyệt nâng cấp gói', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Đối chiếu giao dịch Vietcombank trước khi duyệt Plus hoặc FamilyPlus.'),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tìm yêu cầu thanh toán',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 320), () {
                if (mounted) {
                  ref.read(adminMembershipControllerProvider.notifier).search(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: asyncState.when(
              loading: () => const AdminLoadingView(),
              error: (_, __) => AdminErrorView(
                onRetry: () =>
                    ref.read(adminMembershipControllerProvider.notifier).refresh(),
              ),
              data: (state) {
                if (!state.canReview) {
                  return const AdminPermissionView(
                    message: 'Chỉ Finance Admin hoặc Super Admin được duyệt thanh toán thành viên.',
                  );
                }
                final items = state.payments
                    .where((item) => adminPaymentStatusCanBeReviewed(item.status))
                    .toList(growable: false);
                if (items.isEmpty) {
                  return const AdminEmptyView(
                    title: 'Không có yêu cầu chờ duyệt',
                    message: 'Khi người dùng xác nhận đã chuyển khoản, yêu cầu sẽ xuất hiện tại đây.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminMembershipControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _MembershipPaymentCard(item: items[index]),
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

class _MembershipPaymentCard extends ConsumerWidget {
  final AdminWorkItem item;

  const _MembershipPaymentCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = item.paymentReconciliation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                      if (item.subtitle.isNotEmpty) Text(item.subtitle),
                    ],
                  ),
                ),
                const AdminStatusChip(label: 'Chờ đối chiếu', warning: true),
              ],
            ),
            if (details != null && details.hasDetails) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Wrap(
                  runSpacing: 8,
                  spacing: 22,
                  children: [
                    _Detail(label: 'Người chuyển', value: details.payerFullName ?? '—'),
                    _Detail(label: 'Mã giao dịch', value: details.transferReference ?? '—'),
                    _Detail(label: 'Nội dung', value: details.transferMemo ?? '—'),
                    _Detail(label: 'Chu kỳ', value: details.billingCycle ?? '—'),
                    if (details.amountCents != null)
                      _Detail(
                        label: 'Số tiền',
                        value: '${details.amountCents} ${details.currency ?? 'VND'}',
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _approve(context, ref),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Đối chiếu & duyệt'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reject(context, ref),
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

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    var verified = false;
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đối chiếu và duyệt thanh toán'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: verified,
                  onChanged: (value) =>
                      setDialogState(() => verified = value == true),
                  title: const Text('Tôi đã đối chiếu giao dịch trên Vietcombank'),
                  subtitle: const Text('Mã giao dịch, số tiền và nội dung chuyển khoản đều khớp.'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reason,
                  onChanged: (_) => setDialogState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú duyệt',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            FilledButton(
              onPressed: verified && reason.text.trim().isNotEmpty
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Duyệt nâng cấp'),
            ),
          ],
        ),
      ),
    );
    final note = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminMembershipControllerProvider.notifier).reviewPayment(
        paymentId: item.id,
        decision: 'approve',
        reason: note,
        transferVerified: true,
      );
      if (context.mounted) showAdminNotice(context, 'Đã duyệt nâng cấp gói thành viên.');
    } catch (error) {
      if (context.mounted) showAdminNotice(context, adminSafeError(error), error: true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showAdminReasonDialog(
      context,
      title: 'Từ chối yêu cầu nâng cấp gói',
      confirmLabel: 'Từ chối',
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(adminMembershipControllerProvider.notifier).reviewPayment(
        paymentId: item.id,
        decision: 'reject',
        reason: reason,
        transferVerified: false,
      );
      if (context.mounted) showAdminNotice(context, 'Đã từ chối yêu cầu nâng cấp gói.');
    } catch (error) {
      if (context.mounted) showAdminNotice(context, adminSafeError(error), error: true);
    }
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}

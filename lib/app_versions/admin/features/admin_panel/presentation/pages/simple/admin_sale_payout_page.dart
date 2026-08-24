import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_payout_proof_provider.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

import 'admin_simple_shell.dart';
import 'admin_simple_widgets.dart';

class AdminSalePayoutPage extends ConsumerStatefulWidget {
  const AdminSalePayoutPage({super.key});

  @override
  ConsumerState<AdminSalePayoutPage> createState() => _AdminSalePayoutPageState();
}

class _AdminSalePayoutPageState extends ConsumerState<AdminSalePayoutPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _busyId;

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
      selectedPath: AdminRoutePaths.salePayouts,
      title: 'Thanh toán Sale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thanh toán Sale', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Duyệt yêu cầu quy đổi trước, sau đó chỉ xác nhận đã chi trả khi có ảnh bằng chứng.'),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Tìm yêu cầu thanh toán Sale',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 320), () {
                if (mounted) {
                  ref.read(adminSalesControllerProvider.notifier).searchPayouts(value);
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
                    message: 'Tài khoản quản trị hiện tại chưa được cấp quyền xử lý thanh toán Sale.',
                  );
                }
                final items = state.payouts.where((item) {
                  final status = item.status.toLowerCase();
                  return !status.contains('paid') && !status.contains('rejected');
                }).toList(growable: false);
                if (items.isEmpty) {
                  return const AdminEmptyView(
                    title: 'Không có yêu cầu cần xử lý',
                    message: 'Các yêu cầu chờ duyệt hoặc chờ chi trả sẽ xuất hiện tại đây.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminSalesControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _PayoutCard(
                      item: items[index],
                      busy: _busyId == items[index].id,
                      onBusyChanged: (value) => setState(() => _busyId = value),
                    ),
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

class _PayoutCard extends ConsumerWidget {
  final AdminWorkItem item;
  final bool busy;
  final ValueChanged<String?> onBusyChanged;

  const _PayoutCard({
    required this.item,
    required this.busy,
    required this.onBusyChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = item.status.toLowerCase().contains('approved');
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
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.subtitle),
                      ],
                    ],
                  ),
                ),
                AdminStatusChip(
                  label: approved ? 'Chờ chi trả' : 'Chờ duyệt',
                  warning: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (busy)
              const LinearProgressIndicator()
            else if (approved)
              FilledButton.icon(
                onPressed: () => _markPaid(context, ref),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Xác nhận đã chi trả'),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _review(context, ref, 'approve'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Duyệt'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _review(context, ref, 'reject'),
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

  Future<void> _review(BuildContext context, WidgetRef ref, String decision) async {
    final reason = await showAdminReasonDialog(
      context,
      title: decision == 'approve' ? 'Duyệt yêu cầu quy đổi' : 'Từ chối yêu cầu quy đổi',
    );
    if (reason == null || !context.mounted) return;
    onBusyChanged(item.id);
    try {
      await ref.read(adminSalesControllerProvider.notifier).reviewPayout(
        conversionId: item.id,
        decision: decision,
        reason: reason,
      );
      if (context.mounted) showAdminNotice(context, 'Đã cập nhật yêu cầu thanh toán Sale.');
    } catch (error) {
      if (context.mounted) showAdminNotice(context, adminSafeError(error), error: true);
    } finally {
      onBusyChanged(null);
    }
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh xác nhận'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !context.mounted) return;

    final reason = await showAdminReasonDialog(
      context,
      title: 'Xác nhận đã chuyển tiền',
      hint: 'Ví dụ: Đã chuyển khoản và đối chiếu đúng người nhận',
      confirmLabel: 'Xác nhận chi trả',
    );
    if (reason == null || !context.mounted) return;

    onBusyChanged(item.id);
    try {
      final bytes = await image.readAsBytes();
      final lower = image.name.toLowerCase();
      final contentType = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final proofPath = await ref.read(adminPayoutProofRepositoryProvider).uploadSalePayoutProof(
        conversionId: item.id,
        fileName: image.name,
        contentType: contentType,
        bytes: bytes,
      );
      await ref.read(adminSalesControllerProvider.notifier).reviewPayout(
        conversionId: item.id,
        decision: 'mark_paid',
        reason: reason,
        paymentProofPath: proofPath,
      );
      if (context.mounted) showAdminNotice(context, 'Đã xác nhận chi trả cho Sale.');
    } catch (error) {
      if (context.mounted) showAdminNotice(context, adminSafeError(error), error: true);
    } finally {
      onBusyChanged(null);
    }
  }
}

import 'package:flutter/material.dart';

Future<String?> showAdminReasonDialog(
  BuildContext context, {
  required String title,
  String hint = 'Nhập lý do để lưu vào lịch sử quản trị',
  String confirmLabel = 'Xác nhận',
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String adminSafeError(Object error) {
  final message = error.toString().replaceFirst('Bad state: ', '').trim();
  if (message.contains('FunctionsHttpError') ||
      message.contains('PostgrestException') ||
      message.contains('AuthException')) {
    return 'Thao tác chưa hoàn tất. Vui lòng kiểm tra kết nối và thử lại.';
  }
  return message.isEmpty
      ? 'Thao tác chưa hoàn tất. Vui lòng thử lại.'
      : message;
}

void showAdminNotice(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
}

class AdminPermissionView extends StatelessWidget {
  final String message;

  const AdminPermissionView({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Chưa có quyền thực hiện',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminLoadingView extends StatelessWidget {
  const AdminLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class AdminErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const AdminErrorView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text('Chưa tải được dữ liệu quản trị.'),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class AdminEmptyView extends StatelessWidget {
  final String title;
  final String message;

  const AdminEmptyView({required this.title, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final bool positive;
  final bool warning;

  const AdminStatusChip({
    required this.label,
    this.positive = false,
    this.warning = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = positive
        ? scheme.primaryContainer
        : warning
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = positive
        ? scheme.onPrimaryContainer
        : warning
        ? scheme.onTertiaryContainer
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

String adminPlanLabel(String code) {
  return switch (code.toLowerCase()) {
    'plus' => 'Plus',
    'family_plus' => 'FamilyPlus',
    _ => 'Free',
  };
}

String adminAccountStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'suspended' => 'Tạm khóa',
    'closed' => 'Đã đóng',
    _ => 'Hoạt động',
  };
}

String adminSaleStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'pending' => 'Chờ duyệt',
    'active' => 'Đang hoạt động',
    'suspended' => 'Tạm dừng',
    'closed' => 'Đã đóng',
    _ => 'Không tham gia',
  };
}

String adminFormatDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

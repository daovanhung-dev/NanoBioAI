part of 'admin_workspace_page.dart';

class _AdminActionConfirmation {
  final String reason;
  final bool transferVerified;

  const _AdminActionConfirmation({
    required this.reason,
    this.transferVerified = false,
  });
}

class _AdminReasonDialog extends StatefulWidget {
  final AdminActionPresentation action;
  final String itemTitle;
  final bool requiresTransferVerification;

  const _AdminReasonDialog({
    required this.action,
    required this.itemTitle,
    this.requiresTransferVerification = false,
  });

  @override
  State<_AdminReasonDialog> createState() => _AdminReasonDialogState();
}

class _AdminReasonDialogState extends State<_AdminReasonDialog> {
  final _controller = TextEditingController();
  var _transferVerified = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid =
        _controller.text.trim().isNotEmpty &&
        (!widget.requiresTransferVerification || _transferVerified);
    final danger = widget.action.danger;
    final colors = context.adminColors;
    final media = MediaQuery.of(context);
    final maxDialogHeight =
        (media.size.height - media.viewInsets.bottom - 96).clamp(280.0, 640.0);

    return AlertDialog(
      title: Row(
        children: [
          _IconTile(
            icon: widget.action.icon,
            color: danger ? colors.danger : colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.action.label)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.itemTitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(color: colors.text),
              ),
              const SizedBox(height: 7),
              Text(
                danger
                    ? 'Thao tác này có ảnh hưởng trực tiếp. Hãy kiểm tra lại thông tin trước khi tiếp tục.'
                    : 'Hãy ghi lý do ngắn gọn để người khác có thể xem lại quyết định.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Lý do bắt buộc',
                  hintText: 'Ví dụ: Đã kiểm tra thông tin và đối chiếu đầy đủ.',
                  alignLabelWithHint: true,
                ),
              ),
              if (widget.requiresTransferVerification) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _transferVerified,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => _transferVerified = value ?? false);
                  },
                  title: Text(
                    'Đã đối chiếu giao dịch trong ứng dụng VCB',
                    style: AppTextStyles.labelLarge.copyWith(color: colors.text),
                  ),
                  subtitle: Text(
                    'Tôi xác nhận mã NB, số tiền và nội dung chuyển khoản khớp yêu cầu này.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: colors.onAccent,
                )
              : null,
          onPressed: valid
              ? () => Navigator.of(context).pop(
                    _AdminActionConfirmation(
                      reason: _controller.text.trim(),
                      transferVerified: _transferVerified,
                    ),
                  )
              : null,
          icon: Icon(widget.action.icon, size: 18),
          label: Text(widget.action.confirmLabel),
        ),
      ],
    );
  }
}

class _AdminGuideDialog extends StatelessWidget {
  const _AdminGuideDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  _IconTile(
                    icon: Icons.help_outline_rounded,
                    color: colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn nhanh',
                          style: AppTextStyles.heading3.copyWith(
                            color: colors.text,
                          ),
                        ),
                        Text(
                          'Các nguyên tắc giúp thao tác an toàn và dễ kiểm tra lại.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _GuideCard(
                        icon: Icons.search_rounded,
                        title: 'Tìm và kiểm tra',
                        text:
                            'Tìm theo thông tin dễ nhận biết. Đọc đầy đủ trạng thái và thông tin đối chiếu trước khi chọn hành động.',
                      ),
                      _GuideCard(
                        icon: Icons.fact_check_outlined,
                        title: 'Ghi lý do rõ ràng',
                        text:
                            'Chỉ ghi thông tin cần thiết để người khác hiểu quyết định. Không nhập mật khẩu hoặc dữ liệu nhạy cảm.',
                      ),
                      _GuideCard(
                        icon: Icons.payments_outlined,
                        title: 'Thanh toán và chi trả',
                        text:
                            'Đối chiếu số tiền, nội dung và người nhận trước khi duyệt hoặc xác nhận đã chi trả.',
                      ),
                      _GuideCard(
                        icon: Icons.history_rounded,
                        title: 'Xem lại lịch sử',
                        text:
                            'Khi có sai lệch, mở Lịch sử thao tác để kiểm tra quyết định trước đó và lý do đã ghi.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _WorkspacePanel(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: icon, color: colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBlockingState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  const _AdminBlockingState({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _WorkspacePanel(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox.square(
                              dimension: 56,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                            Icon(icon, size: 22, color: colors.blue),
                          ],
                        )
                      else
                        _IconTile(icon: icon, color: colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        ),
                      ],
                      if (secondaryLabel != null &&
                          onSecondaryAction != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onSecondaryAction,
                          child: Text(secondaryLabel!),
                        ),
                      ],
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

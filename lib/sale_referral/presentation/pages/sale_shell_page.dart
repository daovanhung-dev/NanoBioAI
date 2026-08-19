import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/services/sale_conversion_policy_service.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';

class SaleShellPage extends ConsumerStatefulWidget {
  const SaleShellPage({super.key});

  @override
  ConsumerState<SaleShellPage> createState() => _SaleShellPageState();
}

class _SaleShellPageState extends ConsumerState<SaleShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final saleStateAsync = ref.watch(saleStateProvider);
    return AppStateSwitcher(
      child: saleStateAsync.when(
        loading: () => const _CenteredProgress(
          key: ValueKey('sale-shell-loading'),
        ),
        error: (_, __) => _SupportState(
          key: const ValueKey('sale-shell-error'),
          title: 'Chưa mở được không gian cộng tác viên',
          message:
              'Nabi chưa kiểm tra được trạng thái của bạn. Hãy thử làm mới sau một chút.',
          onRetry: _refreshAll,
        ),
        data: (state) {
          if (!state.isActive) {
            return _SupportState(
              key: ValueKey('sale-shell-${state.status.name}'),
              title: _inactiveTitle(state.status),
              message: _inactiveMessage(state.status),
              onRetry: _refreshAll,
            );
          }
          if (!state.payoutProfileComplete) {
            return _PayoutProfileGate(onSaved: _refreshAll);
          }
          return MedicalPageScaffold(
            backgroundColor: context.semanticColors.background,
            appBar: AppBar(
              title: const Text('NanoBio Cộng tác viên'),
              actions: [
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: IndexedStack(
              index: _index,
              children: [
                _OverviewTab(state: state),
                const _DirectCustomersTab(),
                const _PointLedgerTab(),
                _ConversionToolsTab(state: state),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) {
                AppFeedbackService.instance.emit(AppFeedbackType.selection);
                setState(() => _index = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_rounded),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_rounded),
                  label: 'Khách hàng',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Điểm',
                ),
                NavigationDestination(
                  icon: Icon(Icons.published_with_changes_rounded),
                  label: 'Quy đổi',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAll() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    ref.invalidate(saleStateProvider);
    ref.invalidate(saleDashboardProvider);
    ref.invalidate(saleDirectCustomersProvider);
    ref.invalidate(salePointLedgerProvider);
    ref.invalidate(saleConversionsProvider);
    ref.invalidate(salePayoutProfileProvider);
    try {
      await ref.read(saleStateProvider.future);
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.success);
    } catch (_) {
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.error);
    }
  }

  String _inactiveTitle(SaleStatus status) => switch (status) {
    SaleStatus.pending => 'Yêu cầu đang chờ duyệt',
    SaleStatus.suspended => 'Quyền cộng tác viên đang tạm dừng',
    SaleStatus.closed => 'Quyền cộng tác viên đã đóng',
    SaleStatus.none || SaleStatus.active => 'Bạn chưa có quyền cộng tác viên',
  };

  String _inactiveMessage(SaleStatus status) => switch (status) {
    SaleStatus.pending => 'Mã giới thiệu sẽ mở sau khi yêu cầu được duyệt.',
    SaleStatus.suspended =>
      'Vui lòng liên hệ hỗ trợ để kiểm tra trạng thái trước khi tiếp tục.',
    SaleStatus.closed =>
      'Vui lòng liên hệ hỗ trợ nếu bạn cần xem xét lại trạng thái.',
    SaleStatus.none || SaleStatus.active =>
      'Vào Cài đặt để đọc điều lệ và gửi yêu cầu tham gia.',
  };
}

class _PayoutProfileGate extends ConsumerStatefulWidget {
  const _PayoutProfileGate({required this.onSaved});

  final VoidCallback onSaved;

  @override
  ConsumerState<_PayoutProfileGate> createState() => _PayoutProfileGateState();
}

class _PayoutProfileGateState extends ConsumerState<_PayoutProfileGate> {
  final _formKey = GlobalKey<FormState>();
  final _citizenId = TextEditingController();
  final _bankBin = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankAccountName = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _citizenId.dispose();
    _bankBin.dispose();
    _bankName.dispose();
    _bankAccountNumber.dispose();
    _bankAccountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Hồ sơ nhận tiền')),
      body: _SaleScroll(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: MedicalSurfaceCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hoàn tất thông tin nhận tiền',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Cập nhật căn cước và tài khoản ngân hàng trước khi xem tổng quan hoặc gửi yêu cầu quy đổi.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    _Field(
                      controller: _citizenId,
                      label: 'Số căn cước công dân',
                      icon: Icons.badge_rounded,
                      digitsOnly: true,
                      validator: (value) => _required(value, minimumLength: 9),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      controller: _bankBin,
                      label: 'Mã ngân hàng/BIN',
                      icon: Icons.account_balance_rounded,
                      digitsOnly: true,
                      validator: (value) => _required(value, minimumLength: 3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      controller: _bankName,
                      label: 'Tên ngân hàng',
                      icon: Icons.business_rounded,
                      validator: _required,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      controller: _bankAccountNumber,
                      label: 'Số tài khoản',
                      icon: Icons.numbers_rounded,
                      digitsOnly: true,
                      validator: (value) => _required(value, minimumLength: 4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      controller: _bankAccountName,
                      label: 'Tên chủ tài khoản',
                      icon: Icons.person_pin_rounded,
                      validator: _required,
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Đang lưu...' : 'Lưu thông tin'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() => _saving = true);
    try {
      await ref.read(saleRepositoryProvider).upsertPayoutProfile(
            SalePayoutProfileCommand(
              citizenId: _citizenId.text.trim(),
              bankBin: _bankBin.text.trim(),
              bankName: _bankName.text.trim(),
              bankAccountNumber: _bankAccountNumber.text.trim(),
              bankAccountName: _bankAccountName.text.trim().toUpperCase(),
            ),
          );
      ref.invalidate(saleStateProvider);
      ref.invalidate(salePayoutProfileProvider);
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin nhận tiền.')),
      );
      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa lưu được thông tin. Bạn thử lại sau nhé.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value, {int minimumLength = 1}) {
    return (value?.trim().length ?? 0) < minimumLength
        ? 'Cần nhập đầy đủ thông tin.'
        : null;
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.digitsOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.state});

  final SaleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(saleDashboardProvider);
    return _SaleScroll(
      child: summaryAsync.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptyState(
          title: 'Chưa tải được tổng quan',
          message: 'Bạn thử làm mới lại sau nhé.',
        ),
        data: (summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              title: 'Tổng quan cộng tác viên',
              subtitle: state.referralCode == null
                  ? 'Mã giới thiệu sẽ hiển thị sau khi được duyệt.'
                  : 'Mã giới thiệu: ${state.referralCode}',
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            _MetricWrap(
              metrics: [
                _Metric('Khách hàng trực tiếp', '${summary.directCustomers}', Icons.group_rounded),
                _Metric('Thanh toán hợp lệ', '${summary.successfulPayments}', Icons.verified_rounded),
                _Metric('Điểm đang chờ', _money(summary.pendingPointCents, summary.currency), Icons.schedule_rounded),
                _Metric('Điểm khả dụng', _money(summary.availablePointCents, summary.currency), Icons.account_balance_wallet_rounded),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            _Notice(
              icon: summary.conversionPolicy.enabled
                  ? Icons.published_with_changes_rounded
                  : Icons.lock_clock_rounded,
              title: summary.conversionPolicy.enabled
                  ? 'Quy đổi điểm đang mở'
                  : 'Quy đổi điểm chưa mở',
              message: summary.conversionPolicy.enabled
                  ? 'Mức tối thiểu: ${_money(summary.conversionPolicy.minimumPointCents, summary.conversionPolicy.currency)}.'
                  : 'Nabi sẽ hiển thị nút gửi yêu cầu khi tính năng sẵn sàng.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectCustomersTab extends ConsumerWidget {
  const _DirectCustomersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(saleDirectCustomersProvider);
    return _SaleScroll(
      child: customersAsync.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptyState(
          title: 'Chưa tải được khách hàng',
          message: 'Bạn thử làm mới lại sau nhé.',
        ),
        data: (customers) {
          if (customers.isEmpty) {
            return const _EmptyState(
              title: 'Chưa có khách hàng trực tiếp',
              message: 'Danh sách sẽ xuất hiện khi có người dùng hợp lệ.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Khách hàng trực tiếp', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),
              for (final customer in customers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MedicalSurfaceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_rounded),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.displayName, style: AppTextStyles.labelLarge),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${customer.successfulPayments} thanh toán hợp lệ • ${_money(customer.approvedPointCents, customer.currency)} điểm',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PointLedgerTab extends ConsumerWidget {
  const _PointLedgerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(salePointLedgerProvider);
    return _SaleScroll(
      child: ledgerAsync.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptyState(
          title: 'Chưa tải được lịch sử điểm',
          message: 'Bạn thử làm mới lại sau nhé.',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyState(
              title: 'Chưa có điểm nào được ghi nhận',
              message: 'Lịch sử điểm sẽ xuất hiện tại đây.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Lịch sử điểm', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MedicalSurfaceCard(
                    child: Row(
                      children: [
                        const Icon(Icons.toll_rounded),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.customerName, style: AppTextStyles.labelLarge),
                              Text(
                                '${_statusLabel(entry.status)} • ${entry.planCode.isEmpty ? 'Thanh toán' : entry.planCode}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _money(entry.pointAmountCents, entry.currency),
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConversionToolsTab extends ConsumerStatefulWidget {
  const _ConversionToolsTab({required this.state});

  final SaleState state;

  @override
  ConsumerState<_ConversionToolsTab> createState() => _ConversionToolsTabState();
}

class _ConversionToolsTabState extends ConsumerState<_ConversionToolsTab> {
  final _pointController = TextEditingController();
  bool _submitting = false;
  String? _pendingIdempotencyKey;

  @override
  void dispose() {
    _pointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(saleDashboardProvider);
    final conversionsAsync = ref.watch(saleConversionsProvider);
    return _SaleScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReferralCodePanel(referralCode: widget.state.referralCode),
          const SizedBox(height: AppSpacing.sectionSpacing),
          summaryAsync.when(
            loading: () => const _CenteredProgress(),
            error: (_, __) => const _EmptyState(
              title: 'Chưa tải được thông tin quy đổi',
              message: 'Bạn thử làm mới lại sau nhé.',
            ),
            data: _buildRequestPanel,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          conversionsAsync.when(
            loading: () => const _CenteredProgress(),
            error: (_, __) => const _EmptyState(
              title: 'Chưa tải được các yêu cầu trước đây',
              message: 'Bạn thử làm mới lại sau nhé.',
            ),
            data: (items) => _ConversionHistory(items: items),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPanel(SaleDashboard summary) {
    final requested = int.tryParse(_pointController.text.trim()) ?? 0;
    final money = summary.conversionPolicy.estimateMoneyCents(requested);
    final error = const SaleConversionPolicyService().validateRequest(
      policy: summary.conversionPolicy,
      availablePointCents: summary.availablePointCents,
      requestedPointCents: requested,
    );
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yêu cầu quy đổi điểm', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.conversionPolicy.enabled
                ? 'Điểm khả dụng: ${_money(summary.availablePointCents, summary.currency)}'
                : 'Quy đổi điểm hiện chưa sẵn sàng.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pointController,
            enabled: summary.conversionPolicy.enabled && !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _pendingIdempotencyKey = null),
            decoration: const InputDecoration(labelText: 'Số điểm muốn quy đổi'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            requested <= 0
                ? 'Nhập số điểm bạn muốn quy đổi.'
                : 'Giá trị ước tính: ${_money(money, summary.conversionPolicy.currency)}',
            style: AppTextStyles.bodySmall,
          ),
          if (requested > 0 && error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.semanticColors.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: error == null && !_submitting
                ? () => _submitConversion(summary)
                : null,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitConversion(SaleDashboard summary) async {
    if (_submitting) return;
    final requested = int.tryParse(_pointController.text.trim()) ?? 0;
    final error = const SaleConversionPolicyService().validateRequest(
      policy: summary.conversionPolicy,
      availablePointCents: summary.availablePointCents,
      requestedPointCents: requested,
    );
    if (error != null) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      _showSnack(error);
      return;
    }
    final idempotencyKey = _pendingIdempotencyKey ??=
        'sale-conversion-${DateTime.now().microsecondsSinceEpoch}';
    setState(() => _submitting = true);
    try {
      await ref.read(saleRepositoryProvider).requestConversion(
            SaleConversionCommand(
              pointCents: requested,
              idempotencyKey: idempotencyKey,
            ),
          );
      ref.invalidate(saleDashboardProvider);
      ref.invalidate(saleConversionsProvider);
      if (!mounted) return;
      _pointController.clear();
      _pendingIdempotencyKey = null;
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      _showSnack('Đã gửi yêu cầu quy đổi điểm.');
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      _showSnack('Chưa gửi được yêu cầu. Bạn thử lại sau nhé.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ConversionHistory extends StatelessWidget {
  const _ConversionHistory({required this.items});

  final List<SaleConversionRequest> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        title: 'Chưa có yêu cầu quy đổi',
        message: 'Các yêu cầu bạn đã gửi sẽ xuất hiện tại đây.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Yêu cầu đã gửi', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.md),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MedicalSurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _statusLabel(item.status),
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                  Text(
                    _money(item.requestedPointCents, item.currency),
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReferralCodePanel extends StatelessWidget {
  const _ReferralCodePanel({required this.referralCode});

  final String? referralCode;

  @override
  Widget build(BuildContext context) {
    final code = referralCode?.trim();
    return MedicalSurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã giới thiệu', style: AppTextStyles.labelLarge),
                Text(
                  code == null || code.isEmpty
                      ? 'Chưa có mã giới thiệu.'
                      : code,
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
          ),
          if (code != null && code.isNotEmpty)
            IconButton(
              tooltip: 'Sao chép mã giới thiệu',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã giới thiệu.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final minWidth = scale >= 1.45 ? 230.0 : 180.0;
        final columns = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: MedicalSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(metric.icon),
                      const SizedBox(height: AppSpacing.sm),
                      Text(metric.label, style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(metric.value, style: AppTextStyles.heading4),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: AppDecoration.gradient(
      colors: AppGradients.ai.colors,
      radius: AppRadius.xxl,
      shadows: AppShadows.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(color: AppColors.textInverse),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textInverse.withValues(alpha: .9),
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => MedicalSurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.semanticColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SupportState extends StatelessWidget {
  const _SupportState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => MedicalPageScaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _EmptyState(
              title: title,
              message: message,
              actionLabel: 'Thử lại',
              onAction: onRetry,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) => MedicalSurfaceCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline_rounded, size: 38),
        const SizedBox(height: AppSpacing.md),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => onAction!(),
            child: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: CircularProgressIndicator(),
    ),
  );
}

class _SaleScroll extends StatelessWidget {
  const _SaleScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      AppSpacing.pagePadding,
      AppSpacing.pagePadding,
      AppSpacing.pagePadding,
      AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: child,
      ),
    ),
  );
}

String _money(int cents, String currency) {
  final absolute = cents.abs();
  final sign = cents < 0 ? '-' : '';
  final digits = absolute.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$sign${buffer.toString()} ${currency.trim().isEmpty ? 'VND' : currency}';
}

String _statusLabel(String raw) => switch (raw.trim().toLowerCase()) {
  'pending' || 'requested' => 'Đang chờ',
  'approved' || 'confirmed' => 'Đã xác nhận',
  'paid' || 'completed' => 'Đã hoàn tất',
  'rejected' || 'declined' => 'Không được duyệt',
  'reversed' => 'Đã hoàn tác',
  _ => 'Đang xử lý',
};

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nano_app/core/payments/viet_qr_payload_builder.dart';

import '../../domain/entities/membership_payment_models.dart';
import '../../providers/membership_payment_providers.dart';
import '../../domain/entities/store_membership_purchase.dart';
import '../../providers/membership_store_billing_providers.dart';

/// Consumer membership checkout for Android Play-distributed builds.
///
/// Manual bank-transfer requests remain in the data layer for controlled
/// back-office/non-Play use, but are intentionally not reachable here.
class MembershipPaymentPage extends ConsumerStatefulWidget {
  final String? initialPlanCode;

  const MembershipPaymentPage({super.key, this.initialPlanCode});

  @override
  ConsumerState<MembershipPaymentPage> createState() =>
      _MembershipPaymentPageState();
}

class _MembershipPaymentPageState extends ConsumerState<MembershipPaymentPage>
    with WidgetsBindingObserver {
  late String _planCode;
  String _billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    _planCode = _normalizePlanCode(widget.initialPlanCode);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant MembershipPaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPlan = _normalizePlanCode(widget.initialPlanCode);
    if (nextPlan != _planCode) setState(() => _planCode = nextPlan);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(membershipStoreBillingControllerProvider.notifier)
            .loadStorefront(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebMembershipPaymentPage(initialPlanCode: _planCode);
    }
    final state = ref.watch(membershipStoreBillingControllerProvider);
    final selectedProduct = StoreMembershipProduct.fromSelection(
      planCode: _planCode,
      billingCycle: _billingCycle,
    );
    final selectedDetails = selectedProduct == null
        ? null
        : state.storefront?.productFor(selectedProduct);
    final isBusy = switch (state.status) {
      MembershipStoreBillingStatus.loading ||
      MembershipStoreBillingStatus.purchasing ||
      MembershipStoreBillingStatus.restoring ||
      MembershipStoreBillingStatus.awaitingVerification ||
      MembershipStoreBillingStatus.pending => true,
      _ => false,
    };
    final canPurchase =
        selectedProduct != null &&
        selectedDetails != null &&
        state.status == MembershipStoreBillingStatus.ready;

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        title: const Text('Nâng cấp thành viên'),
        backgroundColor: context.semanticColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: isBusy
                ? null
                : () => ref
                      .read(membershipStoreBillingControllerProvider.notifier)
                      .loadStorefront(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        children: [
          Text('Chọn gói phù hợp với bạn', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Thanh toán được xử lý an toàn qua Google Play. Gói chỉ được cập nhật sau khi giao dịch được xác minh.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _PlanSelector(
            planCode: _planCode,
            billingCycle: _billingCycle,
            isDisabled: isBusy,
            onPlanChanged: (value) {
              if (value != null) setState(() => _planCode = value);
            },
            onBillingCycleChanged: (value) {
              if (value != null) setState(() => _billingCycle = value);
            },
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          if (state.status == MembershipStoreBillingStatus.loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            const _StatusCard(message: 'Đang tải các gói đăng ký…'),
          ] else if (state.status ==
              MembershipStoreBillingStatus.unavailable) ...[
            _StatusCard(
              message:
                  state.message ??
                  'Google Play chưa sẵn sàng trên thiết bị này.',
              isError: true,
              action: state.retryable
                  ? TextButton(
                      onPressed: () => ref
                          .read(
                            membershipStoreBillingControllerProvider.notifier,
                          )
                          .loadStorefront(),
                      child: const Text('Thử lại'),
                    )
                  : null,
            ),
          ] else if (state.message != null && !canPurchase) ...[
            _StatusCard(
              message: state.message!,
              isError: state.status == MembershipStoreBillingStatus.error,
              action: state.retryable
                  ? TextButton(
                      onPressed: () => ref
                          .read(
                            membershipStoreBillingControllerProvider.notifier,
                          )
                          .loadStorefront(),
                      child: const Text('Thử lại'),
                    )
                  : null,
            ),
          ],
          if (selectedDetails != null) ...[
            _StoreProductCard(details: selectedDetails),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canPurchase
                  ? () => ref
                        .read(membershipStoreBillingControllerProvider.notifier)
                        .purchase(selectedProduct)
                  : null,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_bag_outlined),
              label: Text(
                selectedDetails == null
                    ? 'Gói chưa sẵn sàng'
                    : 'Đăng ký ${selectedDetails.displayPrice}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => ref
                        .read(membershipStoreBillingControllerProvider.notifier)
                        .restorePurchases(),
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Khôi phục giao dịch'),
            ),
          ),
          if (state.status == MembershipStoreBillingStatus.success) ...[
            const SizedBox(height: AppSpacing.md),
            const _StatusCard(
              message:
                  'Giao dịch đã được xác minh. Gói của bạn sẽ được cập nhật ngay.',
            ),
          ],
        ],
      ),
    );
  }
}

class _WebMembershipPaymentPage extends ConsumerStatefulWidget {
  const _WebMembershipPaymentPage({required this.initialPlanCode});

  final String initialPlanCode;

  @override
  ConsumerState<_WebMembershipPaymentPage> createState() =>
      _WebMembershipPaymentPageState();
}

class _WebMembershipPaymentPageState
    extends ConsumerState<_WebMembershipPaymentPage>
    with WidgetsBindingObserver {
  late String _planCode = _normalizePlanCode(widget.initialPlanCode);
  String _billingCycle = 'monthly';
  String? _actionError;
  bool _busy = false;
  bool _polling = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final request = ref
          .read(membershipPaymentControllerProvider)
          .asData
          ?.value
          .request;
      if (request?.isPendingReview == true && mounted) {
        unawaited(_refreshStatus());
      }
    });
  }

  @override
  void didUpdateWidget(covariant _WebMembershipPaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPlanCode != widget.initialPlanCode) {
      _planCode = _normalizePlanCode(widget.initialPlanCode);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipPaymentControllerProvider);
    final viewState = state.asData?.value;
    final request = viewState?.request;
    final hasActiveRequest = request?.isActive == true;
    final qrPayload = request?.canRenderVietQr == true
        ? VietQrPayloadBuilder.build(
            bankBin: request!.bankBin,
            accountNumber: request.bankAccountNumber,
            accountName: request.bankAccountName,
            amount: request.amountCents,
            transferMemo: request.transferMemoForPayment,
          )
        : null;

    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        title: const Text('Nâng cấp thành viên'),
        backgroundColor: context.semanticColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _busy
                ? null
                : () => ref
                      .read(membershipPaymentControllerProvider.notifier)
                      .refresh(preserveVisibleStateOnError: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        children: [
          Text('Chọn gói phù hợp với bạn', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chuyển khoản theo thông tin do máy chủ cung cấp. Thành viên chỉ được kích hoạt sau khi giao dịch được nhân viên xác minh.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          _PlanSelector(
            planCode: request?.isActive == true ? request!.planCode : _planCode,
            billingCycle: request?.isActive == true
                ? request!.billingCycle
                : _billingCycle,
            isDisabled: hasActiveRequest || _busy,
            onPlanChanged: (value) {
              if (value != null) setState(() => _planCode = value);
            },
            onBillingCycleChanged: (value) {
              if (value != null) setState(() => _billingCycle = value);
            },
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          if (state.isLoading && viewState == null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            const _StatusCard(message: 'Đang tải yêu cầu thanh toán…'),
          ] else if (state.hasError && viewState == null) ...[
            _StatusCard(
              message: 'Chưa tải được yêu cầu thanh toán. Bạn thử lại nhé.',
              isError: true,
              action: TextButton(
                onPressed: () => ref
                    .read(membershipPaymentControllerProvider.notifier)
                    .refresh(),
                child: const Text('Thử lại'),
              ),
            ),
          ],
          if (_actionError != null) ...[
            _StatusCard(message: _actionError!, isError: true),
            const SizedBox(height: AppSpacing.md),
          ],
          if (request == null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || state.isLoading
                    ? null
                    : () => _createRequest(),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_outlined),
                label: const Text('Tạo yêu cầu chuyển khoản'),
              ),
            ),
          ] else if (request.isAwaitingTransfer && qrPayload != null) ...[
            _WebTransferCard(request: request, qrPayload: qrPayload),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _confirmTransfer,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Tôi đã chuyển khoản'),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _cancelRequest,
              child: const Text('Hủy yêu cầu'),
            ),
            const _StatusCard(
              message:
                  'Sau khi xác nhận đã chuyển, yêu cầu sẽ được đối chiếu. Thao tác này chưa kích hoạt gói thành viên.',
            ),
          ] else if (request.isPendingReview) ...[
            const _StatusCard(
              message:
                  'Yêu cầu đang chờ đối chiếu. Gói thành viên sẽ được cập nhật sau khi giao dịch được nhân viên xác minh.',
            ),
            const SizedBox(height: AppSpacing.md),
          ] else if (request.isSucceeded) ...[
            const _StatusCard(
              message:
                  'Giao dịch đã được xác minh. Gói thành viên đang được đồng bộ vào tài khoản.',
            ),
          ] else if (request.isTerminal) ...[
            _StatusCard(
              message: request.reviewReason?.trim().isNotEmpty == true
                  ? 'Yêu cầu đã kết thúc: ${request.reviewReason}'
                  : 'Yêu cầu thanh toán đã kết thúc. Bạn có thể tạo yêu cầu mới.',
              isError:
                  request.normalizedStatus == 'failed' ||
                  request.normalizedStatus == 'rejected',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _createRequest(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tạo yêu cầu mới'),
              ),
            ),
          ] else if (request.isAwaitingTransfer) ...[
            const _StatusCard(
              message:
                  'Máy chủ chưa trả đủ thông tin chuyển khoản. Hãy làm mới hoặc liên hệ hỗ trợ.',
              isError: true,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createRequest() async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .createRequest(planCode: _planCode, billingCycle: _billingCycle);
    } catch (error) {
      _setActionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus() async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .refresh(preserveVisibleStateOnError: true);
    } catch (_) {
      // Keep the visible backend status and let the next poll or manual refresh retry.
    } finally {
      _polling = false;
    }
  }

  Future<void> _confirmTransfer() async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .confirmTransfer();
    } catch (error) {
      _setActionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRequest() async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .cancelRequest();
    } catch (error) {
      _setActionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setActionError(Object error) {
    final message = error is MembershipPaymentException
        ? error.safeMessage
        : 'Chưa hoàn tất được thao tác thanh toán. Bạn kiểm tra kết nối rồi thử lại.';
    if (mounted) setState(() => _actionError = message);
  }
}

class _WebTransferCard extends StatelessWidget {
  const _WebTransferCard({required this.request, required this.qrPayload});

  final MembershipPaymentRequest request;
  final String qrPayload;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(request.amountCents);
    final memo = request.transferMemoForPayment!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quét mã để chuyển $amount', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: QrImageView(
                data: qrPayload,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PaymentDetailRow(
              label: 'Ngân hàng',
              value: request.bankName ?? request.bankCode ?? '—',
            ),
            _PaymentDetailRow(
              label: 'Chủ tài khoản',
              value:
                  request.bankAccountDisplayName ??
                  request.bankAccountName ??
                  '—',
            ),
            _PaymentDetailRow(
              label: 'Số tài khoản',
              value: request.bankAccountNumber ?? '—',
            ),
            _PaymentDetailRow(label: 'Số tiền', value: amount),
            _PaymentDetailRow(label: 'Nội dung', value: memo),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: memo));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép nội dung chuyển khoản.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Sao chép nội dung'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  const _PaymentDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: SelectableText(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  final String planCode;
  final String billingCycle;
  final bool isDisabled;
  final ValueChanged<String?> onPlanChanged;
  final ValueChanged<String?> onBillingCycleChanged;

  const _PlanSelector({
    required this.planCode,
    required this.billingCycle,
    required this.isDisabled,
    required this.onPlanChanged,
    required this.onBillingCycleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: planCode,
          decoration: const InputDecoration(labelText: 'Gói thành viên'),
          items: const [
            DropdownMenuItem(value: 'plus', child: Text('Plus')),
            DropdownMenuItem(value: 'family_plus', child: Text('FamilyPlus')),
          ],
          onChanged: isDisabled ? null : onPlanChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: billingCycle,
          decoration: const InputDecoration(labelText: 'Chu kỳ'),
          items: const [
            DropdownMenuItem(value: 'monthly', child: Text('Hằng tháng')),
            DropdownMenuItem(value: 'yearly', child: Text('Hằng năm')),
          ],
          onChanged: isDisabled ? null : onBillingCycleChanged,
        ),
      ],
    );
  }
}

class _StoreProductCard extends StatelessWidget {
  final StoreProductDetails details;

  const _StoreProductCard({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details.title, style: AppTextStyles.labelLarge),
          if (details.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(details.description, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(details.displayPrice, style: AppTextStyles.heading3),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;
  final bool isError;
  final Widget? action;

  const _StatusCard({required this.message, this.isError = false, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isError ? colors.errorSoft : colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.check_circle_outline,
            color: isError ? colors.error : colors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

String _normalizePlanCode(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == 'family_plus' ? 'family_plus' : 'plus';
}

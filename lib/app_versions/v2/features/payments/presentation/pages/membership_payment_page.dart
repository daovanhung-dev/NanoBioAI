import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/payments/viet_qr_payload_builder.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/membership_payment_models.dart';
import '../../providers/membership_payment_providers.dart';

class MembershipPaymentPage extends ConsumerStatefulWidget {
  final String? initialPlanCode;

  const MembershipPaymentPage({super.key, this.initialPlanCode});

  @override
  ConsumerState<MembershipPaymentPage> createState() =>
      _MembershipPaymentPageState();
}

class _MembershipPaymentPageState extends ConsumerState<MembershipPaymentPage>
    with WidgetsBindingObserver {
  String _planCode = 'plus';
  String _billingCycle = 'monthly';
  bool _submitting = false;
  bool _pendingReviewRefreshInFlight = false;
  String? _message;
  String? _lastObservedRequestId;
  String? _lastObservedRequestStatus;
  Timer? _pendingReviewTimer;

  @override
  void initState() {
    super.initState();
    _planCode = normalizeMembershipPaymentPlanCode(widget.initialPlanCode);
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<AsyncValue<MembershipPaymentViewState>>(
      membershipPaymentControllerProvider,
      (_, next) => _handlePaymentRequestState(next.value?.request),
      fireImmediately: true,
    );
  }

  @override
  void didUpdateWidget(covariant MembershipPaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousPlan = normalizeMembershipPaymentPlanCode(
      oldWidget.initialPlanCode,
    );
    final nextPlan = normalizeMembershipPaymentPlanCode(widget.initialPlanCode);
    if (previousPlan == nextPlan ||
        ref
                .read(membershipPaymentControllerProvider)
                .value
                ?.request
                ?.isActive ==
            true) {
      return;
    }
    setState(() => _planCode = nextPlan);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPendingReview());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingReviewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(membershipPaymentControllerProvider);
    final colors = context.semanticColors;
    final viewState = paymentState.value;
    final request = viewState?.request;
    final isInitialLoading = paymentState.isLoading && viewState == null;
    final hasPayerName = viewState?.hasPayerFullName == true;
    final hasActiveRequest = request?.isActive == true;

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Thanh toán gói thành viên'),
        backgroundColor: colors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _submitting ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: ListView(
          key: ValueKey(
            'payment-${paymentState.isLoading}-${paymentState.hasError}-${request?.status ?? 'none'}-${_message ?? ''}',
          ),
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          children: [
            Text('Nâng cấp gói của bạn', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Quét mã QR, chuyển đúng số tiền và nội dung. Gói chỉ được mở sau khi yêu cầu được duyệt.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
            ),
            if (isInitialLoading) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
            if (paymentState.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              _FeedbackCard(
                message:
                    'Chưa tải được yêu cầu thanh toán. Bạn hãy thử làm mới.',
                isError: true,
              ),
            ],
            if (!isInitialLoading && !hasPayerName) ...[
              const SizedBox(height: AppSpacing.md),
              const _FeedbackCard(
                message:
                    'Bạn cần cập nhật họ và tên trong hồ sơ trước khi tạo mã thanh toán.',
                isError: true,
              ),
            ],
            if (!hasActiveRequest) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              _PlanSelector(
                planCode: _planCode,
                billingCycle: _billingCycle,
                isDisabled: _submitting || isInitialLoading || !hasPayerName,
                onPlanChanged: (value) {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  setState(() => _planCode = value ?? _planCode);
                },
                onBillingCycleChanged: (value) {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  setState(() => _billingCycle = value ?? _billingCycle);
                },
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              FilledButton.icon(
                onPressed: _submitting || isInitialLoading || !hasPayerName
                    ? null
                    : _createRequest,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_rounded),
                label: const Text('Tạo mã thanh toán'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              _FeedbackCard(message: _message!, isError: false),
            ],
            if (request != null) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              _PaymentRequestPanel(
                request: request,
                payerFullName: viewState?.payerFullNameForDisplay,
                isSubmitting: _submitting,
                onConfirmTransfer: _confirmTransfer,
                onCancelRequest: _cancelRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (_submitting) return;
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(membershipPaymentControllerProvider.notifier).refresh();
    } on MembershipPaymentException catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) setState(() => _message = error.safeMessage);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(
          () => _message = 'Chưa tải được yêu cầu thanh toán. Bạn hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createRequest() async {
    if (_submitting) return;
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      final request = await ref
          .read(membershipPaymentControllerProvider.notifier)
          .createRequest(planCode: _planCode, billingCycle: _billingCycle);
      if (mounted) {
        setState(() {
          _message = request.isAwaitingTransfer
              ? 'Mã thanh toán đã sẵn sàng. Bạn hãy chuyển khoản rồi xác nhận.'
              : 'Yêu cầu thanh toán đã được cập nhật.';
        });
      }
    } on MembershipPaymentException catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) setState(() => _message = error.safeMessage);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(
          () => _message = 'Chưa tạo được mã thanh toán. Bạn hãy thử lại sau.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmTransfer() async {
    if (_submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đã chuyển khoản'),
        content: const Text(
          'Bạn đã chuyển đúng số tiền và đúng nội dung hiển thị ở trên?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đã chuyển khoản'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .confirmTransfer();
      if (mounted) {
        setState(
          () => _message =
              'Đã gửi yêu cầu duyệt. Gói sẽ được mở sau khi được duyệt.',
        );
      }
    } on MembershipPaymentException catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) setState(() => _message = error.safeMessage);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(
          () => _message = 'Chưa gửi được yêu cầu duyệt. Bạn hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelRequest() async {
    if (_submitting) return;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy yêu cầu thanh toán'),
        content: const Text(
          'Bạn có chắc muốn hủy yêu cầu này? Bạn chỉ có thể hủy trước khi xác nhận đã chuyển khoản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ yêu cầu'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );
    if (shouldCancel != true || !mounted) return;

    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .cancelRequest();
      if (mounted) {
        AppFeedbackService.instance.emit(AppFeedbackType.success);
        setState(
          () => _message =
              'Yêu cầu thanh toán đã được hủy. Bạn có thể tạo yêu cầu mới khi sẵn sàng.',
        );
      }
    } on MembershipPaymentException catch (error) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) setState(() => _message = error.safeMessage);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      if (mounted) {
        setState(
          () => _message = 'Chưa hủy được yêu cầu thanh toán. Bạn hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _syncPendingReviewPolling(MembershipPaymentRequest? request) {
    if (request?.isPendingReview != true) {
      _pendingReviewTimer?.cancel();
      _pendingReviewTimer = null;
      return;
    }
    if (_pendingReviewTimer != null) return;
    _pendingReviewTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshPendingReview()),
    );
  }

  void _handlePaymentRequestState(MembershipPaymentRequest? request) {
    final requestId = request?.id.trim();
    final status = request?.normalizedStatus;
    final changedToSucceeded =
        requestId != null &&
        requestId.isNotEmpty &&
        requestId == _lastObservedRequestId &&
        status == 'succeeded' &&
        _lastObservedRequestStatus != 'succeeded';
    _lastObservedRequestId = requestId;
    _lastObservedRequestStatus = status;
    if (changedToSucceeded) {
      AppFeedbackService.instance.emit(AppFeedbackType.success);
    }
    _syncPendingReviewPolling(request);
  }

  Future<void> _refreshPendingReview() async {
    if (!mounted || _submitting || _pendingReviewRefreshInFlight) return;
    final request = ref
        .read(membershipPaymentControllerProvider)
        .value
        ?.request;
    if (request?.isPendingReview != true) {
      _syncPendingReviewPolling(request);
      return;
    }

    _pendingReviewRefreshInFlight = true;
    try {
      await ref
          .read(membershipPaymentControllerProvider.notifier)
          .refresh(preserveVisibleStateOnError: true);
    } catch (_) {
      // Background refresh intentionally preserves the usable payment state.
    } finally {
      _pendingReviewRefreshInFlight = false;
    }
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

class _PaymentRequestPanel extends StatelessWidget {
  final MembershipPaymentRequest request;
  final String? payerFullName;
  final bool isSubmitting;
  final Future<void> Function() onConfirmTransfer;
  final Future<void> Function() onCancelRequest;

  const _PaymentRequestPanel({
    required this.request,
    required this.payerFullName,
    required this.isSubmitting,
    required this.onConfirmTransfer,
    required this.onCancelRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final transferMemo = request.transferMemoForPayment;
    final qrPayload = request.hasTransferDetails
        ? VietQrPayloadBuilder.build(
            bankBin: request.bankBin,
            accountNumber: request.bankAccountNumber,
            accountName: request.bankAccountName,
            amount: request.amountCents,
            transferMemo: transferMemo,
          )
        : null;
    final accountOwner =
        request.bankAccountDisplayName ?? request.bankAccountName;
    final bankName = _bankLabel(request);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yêu cầu ${_paymentStatusLabel(request.status)}',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_planLabel(request.planCode)} / '
            '${_billingCycleLabel(request.billingCycle)}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Số tiền: ${_formatMoney(request.amountCents, request.currency)}',
            style: AppTextStyles.heading4,
          ),
          if (payerFullName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(label: 'Họ và tên', value: payerFullName!),
          ],
          if (transferMemo != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(label: 'Mã đối soát', value: transferMemo),
          ],
          if (request.isAwaitingTransfer) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bạn hãy chuyển đúng số tiền và nội dung dưới đây, rồi nhấn “Đã chuyển khoản”.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
            ),
          ],
          if (request.isPendingReview) ...[
            const SizedBox(height: AppSpacing.md),
            const _FeedbackCard(
              message:
                  'Yêu cầu của bạn đang chờ duyệt. Gói sẽ được mở sau khi được duyệt.',
              isError: false,
            ),
          ],
          if (request.isSucceeded) ...[
            const SizedBox(height: AppSpacing.md),
            const _FeedbackCard(
              message: 'Yêu cầu đã được duyệt. Gói của bạn đã được cập nhật.',
              isError: false,
            ),
          ],
          if (request.reviewReason != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FeedbackCard(
              message: request.reviewReason!,
              isError:
                  request.normalizedStatus == 'failed' ||
                  request.normalizedStatus == 'rejected',
            ),
          ],
          if (request.isAwaitingTransfer && qrPayload != null) ...[
            const SizedBox(height: AppSpacing.sectionSpacing),
            Center(
              child: Semantics(
                label: 'Mã QR thanh toán',
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  color: Colors.white,
                  child: QrImageView(
                    data: qrPayload,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            if (bankName != null)
              _DetailRow(label: 'Ngân hàng', value: bankName),
            if (request.bankAccountNumber != null)
              _DetailRow(
                label: 'Số tài khoản',
                value: request.bankAccountNumber!,
              ),
            if (accountOwner != null)
              _DetailRow(label: 'Chủ tài khoản', value: accountOwner),
            if (transferMemo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Nội dung chuyển khoản', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                transferMemo,
                style: AppTextStyles.heading4.copyWith(letterSpacing: 0.7),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () => _copyTransferMemo(context, transferMemo),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Sao chép nội dung'),
              ),
            ],
          ] else if (request.isAwaitingTransfer) ...[
            const SizedBox(height: AppSpacing.md),
            const _FeedbackCard(
              message:
                  'Chưa tải đủ thông tin nhận tiền. Bạn hãy làm mới trước khi chuyển khoản.',
              isError: true,
            ),
          ],
          if (request.canCancel) ...[
            const SizedBox(height: AppSpacing.sectionSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : onCancelRequest,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy yêu cầu'),
              ),
            ),
          ],
          if (request.canConfirmTransfer && qrPayload != null) ...[
            const SizedBox(height: AppSpacing.sectionSpacing),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onConfirmTransfer,
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: const Text('Đã chuyển khoản'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyTransferMemo(BuildContext context, String memo) async {
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    await Clipboard.setData(ClipboardData(text: memo));
    if (context.mounted) {
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản.')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: SelectableText(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final color = isError ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: color, height: 1.4),
      ),
    );
  }
}

String _planLabel(String code) {
  switch (code.trim().toLowerCase()) {
    case 'plus':
      return 'Plus';
    case 'family_plus':
    case 'familyplus':
      return 'FamilyPlus';
    default:
      return 'Gói thành viên';
  }
}

String _billingCycleLabel(String code) {
  switch (code.trim().toLowerCase()) {
    case 'monthly':
      return 'Hằng tháng';
    case 'yearly':
      return 'Hằng năm';
    default:
      return 'Chu kỳ chưa xác định';
  }
}

String _paymentStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'awaiting_transfer':
      return 'chờ chuyển khoản';
    case 'pending_review':
      return 'chờ duyệt';
    case 'succeeded':
    case 'approved':
      return 'đã được duyệt';
    case 'paid':
      return 'đã thanh toán';
    case 'failed':
    case 'rejected':
      return 'bị từ chối';
    case 'cancelled':
    case 'canceled':
      return 'đã hủy';
    case 'refunded':
      return 'đã hoàn tiền';
    case 'pending':
    case 'requested':
      return 'đang xử lý';
    default:
      return 'đang được xử lý';
  }
}

String? _bankLabel(MembershipPaymentRequest request) {
  final bankName = request.bankName?.trim();
  final bankCode = request.bankCode?.trim();
  if (bankName == null || bankName.isEmpty) return bankCode;
  if (bankCode == null || bankCode.isEmpty || bankCode == bankName) {
    return bankName;
  }
  return '$bankName ($bankCode)';
}

String _formatMoney(int amount, String currency) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '$sign$buffer ${currency.trim().isEmpty ? 'VND' : currency}';
}

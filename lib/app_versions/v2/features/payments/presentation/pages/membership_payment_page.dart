import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/membership_payment_models.dart';
import '../../providers/membership_payment_providers.dart';

class MembershipPaymentPage extends ConsumerStatefulWidget {
  const MembershipPaymentPage({super.key});

  @override
  ConsumerState<MembershipPaymentPage> createState() =>
      _MembershipPaymentPageState();
}

class _MembershipPaymentPageState extends ConsumerState<MembershipPaymentPage> {
  String _planCode = 'plus';
  String _billingCycle = 'monthly';
  bool _submitting = false;
  MembershipPaymentRequest? _request;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh toán gói thành viên'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Chọn gói cần nâng cấp', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yêu cầu sẽ ở trạng thái chờ xác nhận cho đến khi hệ thống quản trị xác nhận thanh toán hợp lệ.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _planCode,
            decoration: const InputDecoration(labelText: 'Gói thành viên'),
            items: const [
              DropdownMenuItem(value: 'plus', child: Text('Plus')),
              DropdownMenuItem(value: 'family_plus', child: Text('FamilyPlus')),
            ],
            onChanged: _submitting
                ? null
                : (value) => setState(() => _planCode = value ?? _planCode),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _billingCycle,
            decoration: const InputDecoration(labelText: 'Chu kỳ'),
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Hằng tháng')),
              DropdownMenuItem(value: 'yearly', child: Text('Hằng năm')),
            ],
            onChanged: _submitting
                ? null
                : (value) =>
                      setState(() => _billingCycle = value ?? _billingCycle),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment_rounded),
            label: const Text('Tạo yêu cầu thanh toán'),
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(_message!, style: AppTextStyles.bodyMedium),
          ],
          if (_request != null) ...[
            const SizedBox(height: AppSpacing.md),
            _PaymentRequestPanel(request: _request!),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _message = null;
    });

    final command = CreateMembershipPaymentRequestCommand(
      planCode: _planCode,
      billingCycle: _billingCycle,
      idempotencyKey:
          'membership-$_planCode-$_billingCycle-${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      final request = await ref
          .read(createMembershipPaymentRequestProvider)
          .execute(command);
      setState(() {
        _request = request;
        _message =
            'Đã tạo yêu cầu chờ xác nhận. Gói sẽ không được cấp trước khi được duyệt.';
      });
    } on MembershipPaymentException catch (error) {
      setState(() => _message = error.safeMessage);
    } catch (_) {
      setState(
        () => _message = 'Chưa tạo được yêu cầu thanh toán. Bạn thử lại sau.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    case 'pending':
    case 'requested':
    case 'pending_review':
      return 'đang chờ xác nhận';
    case 'approved':
      return 'đã được duyệt';
    case 'paid':
    case 'succeeded':
      return 'đã thanh toán';
    case 'rejected':
      return 'bị từ chối';
    case 'cancelled':
    case 'canceled':
      return 'đã hủy';
    case 'refunded':
      return 'đã hoàn tiền';
    case 'failed':
      return 'không thành công';
    default:
      return 'đang được xử lý';
  }
}

class _PaymentRequestPanel extends StatelessWidget {
  final MembershipPaymentRequest request;

  const _PaymentRequestPanel({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yêu cầu ${_paymentStatusLabel(request.status)}', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_planLabel(request.planCode)} / ${_billingCycleLabel(request.billingCycle)} - ${request.amountCents} ${request.currency}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

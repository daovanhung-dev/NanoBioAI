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
        title: const Text('Thanh toan goi thanh vien'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Chon goi can nang cap', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yeu cau se o trang thai pending cho den khi he thong/Admin xac nhan thanh toan hop le.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _planCode,
            decoration: const InputDecoration(labelText: 'Goi thanh vien'),
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
            decoration: const InputDecoration(labelText: 'Chu ky'),
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Hang thang')),
              DropdownMenuItem(value: 'yearly', child: Text('Hang nam')),
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
            label: const Text('Tao yeu cau thanh toan'),
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
            'Da tao yeu cau pending. Goi se khong duoc cap truoc khi duyet.';
      });
    } on MembershipPaymentException catch (error) {
      setState(() => _message = error.safeMessage);
    } catch (_) {
      setState(
        () => _message = 'Chua tao duoc yeu cau thanh toan. Ban thu lai sau.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          Text('Yeu cau ${request.status}', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${request.planCode} / ${request.billingCycle} - ${request.amountCents} ${request.currency}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

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

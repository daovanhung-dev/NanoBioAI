import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/sale_referral/domain/entities/sale_models.dart';
import 'package:nano_app/sale_referral/domain/services/sale_commission_calculator.dart';
import 'package:nano_app/sale_referral/domain/services/sale_conversion_policy_service.dart';
import 'package:nano_app/sale_referral/providers/sale_providers.dart';
import 'package:nano_app/services/supabase/sale/sale_terms.dart';

class SaleShellPage extends ConsumerStatefulWidget {
  const SaleShellPage({super.key});

  @override
  ConsumerState<SaleShellPage> createState() => _SaleShellPageState();
}

class _SaleShellPageState extends ConsumerState<SaleShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleStateProvider);

    return state.when(
      loading: () => const _SaleLoading(),
      error: (_, __) => _SaleSupportPage(
        title: 'Chua mo duoc khong gian Sale',
        message:
            'He thong chua kiem tra duoc trang thai Sale. Ban thu lam moi lai.',
        onRetry: _refreshAll,
      ),
      data: (saleState) {
        if (!saleState.isActive) {
          return _SaleSupportPage(
            title: _inactiveTitle(saleState.status),
            message: _inactiveMessage(saleState.status),
            onRetry: _refreshAll,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('NanoBio Sale'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Lam moi',
                onPressed: _refreshAll,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              _OverviewTab(state: saleState),
              const _DirectCustomersTab(),
              const _PointLedgerTab(),
              _ConversionToolsTab(state: saleState),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_rounded),
                label: 'Tong quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_rounded),
                label: 'Khach',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Diem',
              ),
              NavigationDestination(
                icon: Icon(Icons.handyman_rounded),
                label: 'Cong cu',
              ),
            ],
          ),
        );
      },
    );
  }

  void _refreshAll() {
    ref.invalidate(saleStateProvider);
    ref.invalidate(saleDashboardProvider);
    ref.invalidate(saleDirectCustomersProvider);
    ref.invalidate(salePointLedgerProvider);
    ref.invalidate(saleConversionsProvider);
  }

  String _inactiveTitle(SaleStatus status) {
    return switch (status) {
      SaleStatus.pending => 'Ho so Sale dang cho Admin duyet',
      SaleStatus.suspended => 'Tai khoan Sale dang tam dung',
      SaleStatus.closed => 'Tai khoan Sale da dong',
      SaleStatus.none || SaleStatus.active => 'Ban chua co quyen Sale',
    };
  }

  String _inactiveMessage(SaleStatus status) {
    return switch (status) {
      SaleStatus.pending =>
        'Yeu cau cua ban da duoc ghi nhan. Khi Admin duyet, ma gioi thieu va dashboard se duoc mo.',
      SaleStatus.suspended =>
        'Ban can lien he ho tro de kiem tra ly do tam dung truoc khi tiep tuc.',
      SaleStatus.closed =>
        'Trang thai Sale da dong. Vui long lien he ho tro neu can xem xet lai.',
      SaleStatus.none || SaleStatus.active =>
        'Vao Cai dat > Cung NanoBio phat trien de doc va chap nhan dieu le Sale.',
    };
  }
}

class _OverviewTab extends ConsumerWidget {
  final SaleState state;

  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(saleDashboardProvider);
    return _SaleScroll(
      child: summary.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptySaleState(
          title: 'Chua tai duoc tong quan',
          message:
              'Du lieu Sale duoc doc tu he thong. Ban thu lam moi lai sau.',
        ),
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroPanel(
                title: 'Tong quan Sale',
                subtitle: state.referralCode == null
                    ? 'Ma gioi thieu se hien thi sau khi Admin duyet.'
                    : 'Ma gioi thieu: ${state.referralCode}',
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.22,
                children: [
                  _MetricTile(
                    label: 'Khach truc tiep',
                    value: data.directCustomers.toString(),
                    icon: Icons.group_rounded,
                  ),
                  _MetricTile(
                    label: 'Payment hop le',
                    value: data.successfulPayments.toString(),
                    icon: Icons.verified_rounded,
                  ),
                  _MetricTile(
                    label: 'Diem da duyet',
                    value: _money(data.approvedPointCents, data.currency),
                    icon: Icons.stars_rounded,
                  ),
                  _MetricTile(
                    label: 'Diem kha dung',
                    value: _money(data.availablePointCents, data.currency),
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ListTilePanel(
                icon: data.conversionPolicy.enabled
                    ? Icons.published_with_changes_rounded
                    : Icons.lock_clock_rounded,
                title: data.conversionPolicy.enabled
                    ? 'Quy doi diem dang mo'
                    : 'Quy doi diem chua mo',
                subtitle: data.conversionPolicy.enabled
                    ? 'Toi thieu ${_money(data.conversionPolicy.minimumPointCents, data.conversionPolicy.currency)} moi yeu cau quy doi.'
                    : 'He thong se hien thi nut yeu cau khi Admin bat cau hinh sale_point_conversion.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DirectCustomersTab extends ConsumerWidget {
  const _DirectCustomersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(saleDirectCustomersProvider);
    return _SaleScroll(
      child: customers.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptySaleState(
          title: 'Chua tai duoc khach truc tiep',
          message: 'He thong chi hien thi khach duoc gan truc tiep voi ban.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptySaleState(
              title: 'Chua co khach truc tiep',
              message:
                  'Khi khach nhap ma gioi thieu hop le, danh sach se hien thi tai day.',
            );
          }

          return Column(
            children: [
              const _HeroPanel(
                title: 'Khach truc tiep',
                subtitle:
                    'Ban duoc xem ten khach va so lieu tong hop; khong hien email, so dien thoai hay du lieu suc khoe.',
              ),
              const SizedBox(height: AppSpacing.lg),
              ...items.map(
                (item) => _ListTilePanel(
                  icon: Icons.person_rounded,
                  title: item.displayName,
                  subtitle:
                      '${item.successfulPayments} payment hop le - ${_money(item.approvedPointCents, item.currency)} diem da duyet',
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
    final ledger = ref.watch(salePointLedgerProvider);
    return _SaleScroll(
      child: ledger.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptySaleState(
          title: 'Chua tai duoc diem Sale',
          message:
              'Diem Sale chi duoc tao tu payment hop le da duoc he thong tin cay ghi nhan.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptySaleState(
              title: 'Chua co diem Sale',
              message:
                  'Khi khach truc tiep co payment duoc duyet, diem se hien thi tai day.',
            );
          }

          return Column(
            children: [
              const _HeroPanel(
                title: 'Ledger diem Sale',
                subtitle:
                    'Moi dong lien ket voi mot payment hop le va khong duoc tao tu client.',
              ),
              const SizedBox(height: AppSpacing.lg),
              ...items.map(
                (item) => _ListTilePanel(
                  icon: Icons.receipt_long_rounded,
                  title:
                      '${item.customerName} - ${_money(item.pointAmountCents, item.currency)}',
                  subtitle:
                      '${item.planCode} - ${_money(item.paymentAmountCents, item.currency)} - ${_statusLabel(item.status)}',
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
  final SaleState state;

  const _ConversionToolsTab({required this.state});

  @override
  ConsumerState<_ConversionToolsTab> createState() =>
      _ConversionToolsTabState();
}

class _ConversionToolsTabState extends ConsumerState<_ConversionToolsTab> {
  final _pointController = TextEditingController();
  final _amountController = TextEditingController(text: '99000');
  final _directController = TextEditingController(text: '1');
  var _submitting = false;

  @override
  void dispose() {
    _pointController.dispose();
    _amountController.dispose();
    _directController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(saleDashboardProvider);
    final conversions = ref.watch(saleConversionsProvider);
    final estimate = SaleCommissionCalculator.estimate(
      planAmountCents: _parseInt(_amountController.text),
      directSuccessfulPayments: _parseInt(_directController.text),
    );

    return _SaleScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferralCodePanel(referralCode: widget.state.referralCode),
          const SizedBox(height: AppSpacing.lg),
          dashboard.when(
            loading: () => const _CenteredProgress(),
            error: (_, __) => const _EmptySaleState(
              title: 'Chua tai duoc cau hinh quy doi',
              message: 'Ban thu lam moi lai sau.',
            ),
            data: (data) => _ConversionRequestPanel(
              dashboard: data,
              pointController: _pointController,
              submitting: _submitting,
              onChanged: () => setState(() {}),
              onSubmit: _submitConversion,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CommissionEstimator(
            amountController: _amountController,
            directController: _directController,
            estimate: estimate,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          conversions.when(
            loading: () => const _CenteredProgress(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => _ConversionHistory(items: items),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ListTilePanel(
            icon: Icons.policy_rounded,
            title: 'Dieu le phien ban ${SaleTerms.currentVersion}',
            subtitle: SaleTerms.bullets.first,
          ),
        ],
      ),
    );
  }

  Future<void> _submitConversion(SaleDashboard dashboard) async {
    final requested = _parseInt(_pointController.text);
    final error = const SaleConversionPolicyService().validateRequest(
      policy: dashboard.conversionPolicy,
      availablePointCents: dashboard.availablePointCents,
      requestedPointCents: requested,
    );
    if (error != null) {
      _showSnack(error);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(saleRepositoryProvider)
          .requestConversion(
            SaleConversionCommand(
              pointCents: requested,
              idempotencyKey:
                  'sale-conversion-${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
      ref.invalidate(saleDashboardProvider);
      ref.invalidate(saleConversionsProvider);
      _pointController.clear();
      _showSnack('Da gui yeu cau quy doi diem Sale.');
    } catch (_) {
      _showSnack('Chua gui duoc yeu cau quy doi. Ban thu lai sau.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReferralCodePanel extends StatelessWidget {
  final String? referralCode;

  const _ReferralCodePanel({required this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ma gioi thieu', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            referralCode ?? 'Chua co ma dang hoat dong',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: referralCode == null
                ? null
                : () => Clipboard.setData(ClipboardData(text: referralCode!)),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Sao chep ma'),
          ),
        ],
      ),
    );
  }
}

class _ConversionRequestPanel extends StatelessWidget {
  final SaleDashboard dashboard;
  final TextEditingController pointController;
  final bool submitting;
  final VoidCallback onChanged;
  final ValueChanged<SaleDashboard> onSubmit;

  const _ConversionRequestPanel({
    required this.dashboard,
    required this.pointController,
    required this.submitting,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final requested = _parseInt(pointController.text);
    final money = dashboard.conversionPolicy.estimateMoneyCents(requested);
    final canSubmit =
        dashboard.conversionPolicy.canRequest(dashboard.availablePointCents) &&
        requested > 0 &&
        !submitting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yeu cau quy doi diem', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dashboard.conversionPolicy.enabled
                ? 'Diem kha dung: ${_money(dashboard.availablePointCents, dashboard.currency)}'
                : 'Quy doi diem Sale chua duoc Admin mo cau hinh.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: pointController,
            enabled: dashboard.conversionPolicy.enabled && !submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'So diem muon quy doi',
              prefixIcon: Icon(Icons.stars_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _EstimateLine(
            label: 'Gia tri uoc tinh',
            value: _money(money, dashboard.conversionPolicy.currency),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSubmit ? () => onSubmit(dashboard) : null,
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Gui yeu cau quy doi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionHistory extends StatelessWidget {
  final List<SaleConversionRequest> items;

  const _ConversionHistory({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _ListTilePanel(
        icon: Icons.history_rounded,
        title: 'Chua co yeu cau quy doi',
        subtitle: 'Cac yeu cau quy doi diem Sale se hien thi tai day.',
      );
    }

    return Column(
      children: items
          .map(
            (item) => _ListTilePanel(
              icon: Icons.history_rounded,
              title:
                  '${_money(item.requestedPointCents, item.currency)} - ${_statusLabel(item.status)}',
              subtitle:
                  'Gia tri: ${_money(item.moneyAmountCents, item.currency)}',
            ),
          )
          .toList(),
    );
  }
}

class _CommissionEstimator extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController directController;
  final SaleCommissionEstimate estimate;
  final VoidCallback onChanged;

  const _CommissionEstimator({
    required this.amountController,
    required this.directController,
    required this.estimate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uoc tinh diem Sale', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cong cu nay chi giup ban hinh dung. Diem chinh thuc do he thong tinh tu payment duoc duyet.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Gia tri payment hop le',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: directController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'So payment truc tiep',
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Truc tiep 10%',
            value: _money(estimate.directCommissionCents, 'VND'),
          ),
          const Divider(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Tong uoc tinh',
            value: _money(estimate.totalCommissionCents, 'VND'),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _EstimateLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _EstimateLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.labelLarge.copyWith(color: AppColors.primary)
        : AppTextStyles.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _SaleScroll extends StatelessWidget {
  final Widget child;

  const _SaleScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: .9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ListTilePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ListTilePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySaleState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptySaleState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights_rounded,
              color: AppColors.textHint,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SaleLoading extends StatelessWidget {
  const _SaleLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SaleSupportPage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _SaleSupportPage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: AppDecoration.circle(
                      color: AppColors.primarySoft,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Kiem tra lai'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.borderLight),
  );
}

int _parseInt(String value) {
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _money(int amount, String currency) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '$sign$buffer $currency';
}

String _statusLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'approved':
    case 'points_credited':
      return 'Da duyet';
    case 'paid':
      return 'Da chi tra';
    case 'requested':
    case 'pending':
    case 'pending_review':
      return 'Dang cho';
    case 'rejected':
      return 'Tu choi';
    case 'reversed':
    case 'points_reversed':
      return 'Da dao';
    default:
      return value;
  }
}

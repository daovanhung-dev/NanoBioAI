import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/sale_referral/domain/services/sale_commission_calculator.dart';
import 'package:nano_app/services/supabase/sale/sale_participation_service.dart';
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
        title: 'Chua mo duoc giao dien Sale',
        message:
            'Nabi chua kiem tra duoc trang thai Sale. Ban thu lam moi lai nhe.',
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
            title: const Text('NabiSale'),
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
              const _NetworkTab(),
              const _LeaderboardTab(),
              _ToolsTab(state: saleState),
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
                icon: Icon(Icons.person_add_alt_1_rounded),
                label: 'Truc tiep',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_rounded),
                label: 'Xep hang',
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
    ref.invalidate(saleReferralTreeProvider);
    ref.invalidate(saleLeaderboardProvider);
  }

  String _inactiveTitle(SaleStatus status) {
    return switch (status) {
      SaleStatus.pending => 'Ho so Sale dang duoc cap nhat',
      SaleStatus.suspended => 'Tai khoan Sale dang tam khoa',
      SaleStatus.closed => 'Tai khoan Sale da dong',
      SaleStatus.none || SaleStatus.active => 'Ban chua co quyen Sale',
    };
  }

  String _inactiveMessage(SaleStatus status) {
    return switch (status) {
      SaleStatus.pending =>
        'Nabi dang cap nhat quyen Sale cua ban. Hay lam moi lai sau it phut.',
      SaleStatus.suspended =>
        'Ban can lien he ho tro de kiem tra ly do tam khoa truoc khi tiep tuc.',
      SaleStatus.closed =>
        'Trang thai Sale da dong. Vui long lien he ho tro neu can mo lai.',
      SaleStatus.none || SaleStatus.active =>
        'Vao Cai dat > Cung Nabi phat trien de doc va chap nhan dieu le Sale.',
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
              'Du lieu Sale duoc doc truc tiep tu Supabase. Ban thu lam moi lai nhe.',
        ),
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroPanel(
                title: 'Tong quan Sale',
                subtitle: state.referralCode == null
                    ? 'Ma gioi thieu se hien thi sau khi he thong cap.'
                    : 'Ma gioi thieu: ${state.referralCode}',
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.25,
                children: [
                  _MetricTile(
                    label: 'Truc tiep',
                    value: data.directReferrals.toString(),
                    icon: Icons.group_rounded,
                  ),
                  _MetricTile(
                    label: 'Dang cho',
                    value: _money(data.pendingCommissionCents, data.currency),
                    icon: Icons.pending_actions_rounded,
                  ),
                  _MetricTile(
                    label: 'Da duyet',
                    value: _money(data.approvedCommissionCents, data.currency),
                    icon: Icons.verified_rounded,
                  ),
                  _MetricTile(
                    label: 'Da chi tra',
                    value: _money(data.paidCommissionCents, data.currency),
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NetworkTab extends ConsumerWidget {
  const _NetworkTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(saleReferralTreeProvider);
    return _SaleScroll(
      child: tree.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptySaleState(
          title: 'Chua tai duoc danh sach truc tiep',
          message: 'Nabi chi hien thi du lieu referral duoc Supabase cho phep.',
        ),
        data: (nodes) {
          if (nodes.isEmpty) {
            return const _EmptySaleState(
              title: 'Chua co khach truc tiep',
              message:
                  'Khi co khach duoc gioi thieu truc tiep hop le, danh sach se hien thi tai day.',
            );
          }

          return Column(
            children: nodes
                .map(
                  (node) => _ListTilePanel(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Truc tiep - ${node.displayName}',
                    subtitle:
                        '${node.successfulPayments} thanh toan hop le duoc ghi nhan',
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(saleLeaderboardProvider);
    return _SaleScroll(
      child: leaderboard.when(
        loading: () => const _CenteredProgress(),
        error: (_, __) => const _EmptySaleState(
          title: 'Chua tai duoc xep hang',
          message:
              'Bang xep hang duoc tinh tu Supabase va co the gioi han theo chinh sach hien thi.',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptySaleState(
              title: 'Chua co du lieu xep hang',
              message:
                  'Bang xep hang se hien thi khi he thong co du lieu Sale hop le.',
            );
          }

          return Column(
            children: entries
                .map(
                  (entry) => _ListTilePanel(
                    icon: Icons.emoji_events_rounded,
                    title: '#${entry.rank} - ${entry.displayName}',
                    subtitle:
                        '${entry.directReferrals} gioi thieu truc tiep - ${_money(entry.approvedCommissionCents, entry.currency)} da duyet',
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _ToolsTab extends StatefulWidget {
  final SaleState state;

  const _ToolsTab({required this.state});

  @override
  State<_ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<_ToolsTab> {
  final _amountController = TextEditingController(text: '99000');
  final _directController = TextEditingController(text: '0');

  @override
  void dispose() {
    _amountController.dispose();
    _directController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final referralCode = widget.state.referralCode;
    final estimate = SaleCommissionCalculator.estimate(
      planAmountCents: _parseAmountToCents(_amountController.text),
      directSuccessfulPayments: _parseInt(_directController.text),
    );

    return _SaleScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Cong cu Sale',
            subtitle:
                'Du lieu Sale duoc doc truc tiep tu Supabase va khong luu vao SQLite.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
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
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: referralCode == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: referralCode),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Sao chep ma'),
                ),
              ],
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
          _ListTilePanel(
            icon: Icons.policy_rounded,
            title: 'Dieu le phien ban ${SaleTerms.currentVersion}',
            subtitle: SaleTerms.bullets.first,
          ),
        ],
      ),
    );
  }
}

int _parseInt(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

int _parseAmountToCents(String value) => _parseInt(value);

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
          Text('Uoc tinh hoa hong', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cong cu nay chi giup ban hinh dung. So chinh thuc do Supabase doi soat tu giao dich hop le.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Gia tri mot thanh toan hop le (VND)',
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
              labelText: 'So thanh toan truc tiep hop le',
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Truc tiep (10%)',
            value: _money(estimate.directCommissionCents, 'VND'),
          ),
          const Divider(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Tong uoc tinh',
            value: _money(estimate.totalCommissionCents, 'VND'),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Khong phai cam ket thu nhap. Hoa hong co the thay doi hoac dao nguoc khi hoan tien, tranh chap hay vi pham dieu le.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
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

String _money(int cents, String currency) {
  final amount = cents / 100;
  return '${amount.toStringAsFixed(0)} $currency';
}

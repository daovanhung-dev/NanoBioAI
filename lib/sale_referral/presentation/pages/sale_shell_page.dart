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
        title: 'Chưa mở được giao diện Sale',
        message:
            'Nami chưa kiểm tra được trạng thái Sale của bạn. Vui lòng thử lại sau.',
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
          backgroundColor: const Color(0xFFF7FAFC),
          appBar: AppBar(
            title: const Text('Nami Sale'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
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
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_tree_rounded),
                label: 'Mạng lưới',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_rounded),
                label: 'Xếp hạng',
              ),
              NavigationDestination(
                icon: Icon(Icons.handyman_rounded),
                label: 'Công cụ',
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
    switch (status) {
      case SaleStatus.pending:
        return 'Hồ sơ Sale đang được cập nhật';
      case SaleStatus.suspended:
        return 'Tài khoản Sale đang tạm khóa';
      case SaleStatus.closed:
        return 'Tài khoản Sale đã đóng';
      case SaleStatus.none:
      case SaleStatus.active:
        return 'Bạn chưa có quyền Sale';
    }
  }

  String _inactiveMessage(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return 'Nami đang cập nhật quyền Sale của bạn. Hãy làm mới lại sau ít phút.';
      case SaleStatus.suspended:
        return 'Bạn cần liên hệ hỗ trợ để kiểm tra lý do tạm khóa trước khi tiếp tục.';
      case SaleStatus.closed:
        return 'Trạng thái Sale đã đóng. Vui lòng liên hệ hỗ trợ nếu cần mở lại.';
      case SaleStatus.none:
      case SaleStatus.active:
        return 'Vào Cài đặt > Cùng Nami phát triển để đọc và chấp nhận điều lệ Sale.';
    }
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
          title: 'Chưa tải được tổng quan',
          message:
              'Dữ liệu Sale được đọc trực tiếp từ Supabase. Bạn thử làm mới lại nhé.',
        ),
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroPanel(
                title: 'Tổng quan Sale',
                subtitle: state.referralCode == null
                    ? 'Mã giới thiệu sẽ hiển thị sau khi hệ thống cấp.'
                    : 'Mã giới thiệu: ${state.referralCode}',
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
                    label: 'Tầng 1',
                    value: data.directReferrals.toString(),
                    icon: Icons.group_rounded,
                  ),
                  _MetricTile(
                    label: 'Tầng 2',
                    value: data.secondLevelReferrals.toString(),
                    icon: Icons.hub_rounded,
                  ),
                  _MetricTile(
                    label: 'Đang chờ',
                    value: _money(data.pendingCommissionCents, data.currency),
                    icon: Icons.pending_actions_rounded,
                  ),
                  _MetricTile(
                    label: 'Đã duyệt',
                    value: _money(data.approvedCommissionCents, data.currency),
                    icon: Icons.verified_rounded,
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
          title: 'Chưa tải được mạng lưới',
          message: 'Nami chỉ hiển thị dữ liệu referral được Supabase cho phép.',
        ),
        data: (nodes) {
          if (nodes.isEmpty) {
            return const _EmptySaleState(
              title: 'Chưa có người trong mạng lưới',
              message:
                  'Khi có người dùng hợp lệ trong tầng 1 hoặc tầng 2, danh sách sẽ xuất hiện tại đây.',
            );
          }

          return Column(
            children: nodes
                .map(
                  (node) => _ListTilePanel(
                    icon: node.level == 1
                        ? Icons.person_add_alt_1_rounded
                        : Icons.groups_2_rounded,
                    title: 'Tầng ${node.level} · ${node.displayName}',
                    subtitle:
                        '${node.successfulPayments} thanh toán hợp lệ được ghi nhận',
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
          title: 'Chưa tải được xếp hạng',
          message:
              'Bảng xếp hạng được tính từ Supabase và có thể được giới hạn theo chính sách hiển thị.',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptySaleState(
              title: 'Chưa có dữ liệu xếp hạng',
              message:
                  'Bảng xếp hạng sẽ xuất hiện khi hệ thống có dữ liệu Sale hợp lệ.',
            );
          }

          return Column(
            children: entries
                .map(
                  (entry) => _ListTilePanel(
                    icon: Icons.emoji_events_rounded,
                    title: '#${entry.rank} · ${entry.displayName}',
                    subtitle:
                        '${entry.directReferrals} giới thiệu trực tiếp · ${_money(entry.approvedCommissionCents, entry.currency)} đã duyệt',
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
  final _secondController = TextEditingController(text: '0');

  @override
  void dispose() {
    _amountController.dispose();
    _directController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final referralCode = widget.state.referralCode;
    final estimate = SaleCommissionCalculator.estimate(
      planAmountCents: _parseAmountToCents(_amountController.text),
      directSuccessfulPayments: _parseInt(_directController.text),
      secondLevelSuccessfulPayments: _parseInt(_secondController.text),
    );
    return _SaleScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPanel(
            title: 'Công cụ Sale',
            subtitle:
                'Dữ liệu Sale được đọc trực tiếp từ Supabase và không lưu vào SQLite.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã giới thiệu', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  referralCode ?? 'Chưa có mã đang hoạt động',
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
                  label: const Text('Sao chép mã'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CommissionEstimator(
            amountController: _amountController,
            directController: _directController,
            secondController: _secondController,
            estimate: estimate,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ListTilePanel(
            icon: Icons.policy_rounded,
            title: 'Điều lệ phiên bản ${SaleTerms.currentVersion}',
            subtitle: SaleTerms.bullets.first,
          ),
        ],
      ),
    );
  }
}

int _parseInt(String value) => int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

int _parseAmountToCents(String value) => _parseInt(value);

class _CommissionEstimator extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController directController;
  final TextEditingController secondController;
  final SaleCommissionEstimate estimate;
  final VoidCallback onChanged;

  const _CommissionEstimator({
    required this.amountController,
    required this.directController,
    required this.secondController,
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
          Text('Ước tính hoa hồng', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Công cụ này chỉ giúp bạn hình dung. Số chính thức do Supabase đối soát từ giao dịch hợp lệ.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Giá trị một thanh toán hợp lệ (VND)',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: directController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Tầng 1',
                    prefixIcon: Icon(Icons.looks_one_rounded),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: secondController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Tầng 2',
                    prefixIcon: Icon(Icons.looks_two_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Tầng 1 (10%)',
            value: _money(estimate.directCommissionCents, 'VND'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _EstimateLine(
            label: 'Tầng 2 (5%)',
            value: _money(estimate.secondLevelCommissionCents, 'VND'),
          ),
          const Divider(height: AppSpacing.lg),
          _EstimateLine(
            label: 'Tổng ước tính',
            value: _money(estimate.totalCommissionCents, 'VND'),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không phải cam kết thu nhập. Hoa hồng có thể thay đổi hoặc đảo ngược khi hoàn tiền, tranh chấp hay vi phạm điều lệ.',
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
      backgroundColor: Color(0xFFF7FAFC),
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
      backgroundColor: const Color(0xFFF7FAFC),
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
                    label: const Text('Kiểm tra lại'),
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
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.borderLight),
  );
}

String _money(int cents, String currency) {
  final amount = cents / 100;
  return '${amount.toStringAsFixed(0)} $currency';
}

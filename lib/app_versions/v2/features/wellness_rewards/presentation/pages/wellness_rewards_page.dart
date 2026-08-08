import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/localization/vietnam_time.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/wellness_reward_models.dart';
import '../../providers/wellness_rewards_providers.dart';

class WellnessRewardsPage extends ConsumerStatefulWidget {
  const WellnessRewardsPage({super.key});

  @override
  ConsumerState<WellnessRewardsPage> createState() =>
      _WellnessRewardsPageState();
}

class _WellnessRewardsPageState extends ConsumerState<WellnessRewardsPage> {
  final Map<String, String> _voucherCodes = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessRewardsControllerProvider);
    final colors = context.semanticColors;
    return DefaultTabController(
      length: 3,
      child: MedicalPageScaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Điểm chăm sóc và ưu đãi'),
          backgroundColor: colors.background,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: state.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ưu đãi', icon: Icon(Icons.redeem_rounded)),
              Tab(text: 'Lịch sử điểm', icon: Icon(Icons.history_rounded)),
              Tab(text: 'Voucher của tôi', icon: Icon(Icons.confirmation_num)),
            ],
          ),
        ),
        body: AppStateSwitcher(
          child: state.when(
            loading: () => const Center(
              key: ValueKey<String>('wellness-rewards-loading'),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => _RewardsError(
              key: const ValueKey<String>('wellness-rewards-error'),
              message: error is WellnessRewardException
                  ? error.safeMessage
                  : 'Nabi chưa tải được Điểm chăm sóc. Bạn vui lòng thử lại.',
              onRetry: _refresh,
              onSignIn: () => context.push(V2RoutePaths.login),
              showSignIn:
                  error is WellnessRewardException &&
                  error.code == 'auth_required',
            ),
            data: (dashboard) => Column(
              key: const ValueKey<String>('wellness-rewards-ready'),
              children: [
                _RewardSummary(summary: dashboard.summary),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OffersTab(
                        dashboard: dashboard,
                        onRefresh: _refresh,
                        onRedeem: _confirmRedeem,
                      ),
                      _PointHistoryTab(
                        entries: dashboard.pointHistory,
                        onRefresh: _refresh,
                      ),
                      _RedemptionsTab(
                        entries: dashboard.redemptions,
                        onRefresh: _refresh,
                        onOpen: _showVoucher,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    try {
      await ref.read(wellnessRewardsControllerProvider.notifier).refresh();
      if (mounted) {
        AppFeedbackService.instance.emit(AppFeedbackType.success);
      }
    } catch (_) {
      if (mounted) {
        AppFeedbackService.instance.emit(AppFeedbackType.error);
      }
      rethrow;
    }
  }

  Future<void> _confirmRedeem(WellnessRewardOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đổi ưu đãi'),
        content: Text(
          'Bạn sẽ dùng ${offer.costPoints} Điểm chăm sóc để nhận “${_offerTitle(offer)}”. '
          'Mã đã cấp không thể tự hủy trong ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đổi ưu đãi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);

    try {
      final redemption = await ref
          .read(wellnessRewardsControllerProvider.notifier)
          .redeem(offer.id);
      if (!mounted) return;
      final code = redemption.voucherCode;
      if (code != null && code.isNotEmpty) {
        _voucherCodes[redemption.id] = code;
      }
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi ưu đãi thành công.')),
      );
      await _showVoucher(redemption);
    } on WellnessRewardException catch (error) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.safeMessage)));
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đổi được ưu đãi. Bạn vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _showVoucher(WellnessRewardRedemption redemption) async {
    if (redemption.isCancelled) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voucher này đã được hủy.')));
      return;
    }
    if (!_isIssuedStatus(redemption.status)) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher này chưa sẵn sàng để hiển thị.')),
      );
      return;
    }

    var code = redemption.voucherCode ?? _voucherCodes[redemption.id];
    if (code == null || code.isEmpty) {
      AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
      try {
        code = await ref
            .read(wellnessRewardsControllerProvider.notifier)
            .loadVoucherCode(redemption.id);
      } on WellnessRewardException catch (error) {
        if (mounted) {
          AppFeedbackService.instance.emit(AppFeedbackType.error);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.safeMessage)));
        }
        return;
      }
    }
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã voucher đang được đồng bộ. Bạn thử lại sau.'),
        ),
      );
      return;
    }
    _voucherCodes[redemption.id] = code;
    AppFeedbackService.instance.emit(AppFeedbackType.selection);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VoucherSheet(redemption: redemption, code: code!),
    );
  }
}

class _RewardSummary extends StatelessWidget {
  final WellnessRewardSummary summary;

  const _RewardSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.card, colors.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: colors.borderLight)),
      ),
      child: Row(
        children: [
          MedicalIconBadge(
            icon: Icons.favorite_rounded,
            color: colors.primaryDark,
            backgroundColor: colors.surface,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.availablePoints} điểm khả dụng',
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.pendingPoints} điểm đang chờ · '
                  '${summary.expiringSoonPoints} điểm sắp hết hạn',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (summary.nextExpiryAt != null)
            MedicalStatusPill(
              label: 'Hạn gần nhất ${_dateLabel(summary.nextExpiryAt)}',
              icon: Icons.schedule_rounded,
              foregroundColor: colors.warning,
              backgroundColor: colors.warningSoft,
            ),
        ],
      ),
    );
  }
}

class _OffersTab extends StatelessWidget {
  final WellnessRewardsDashboard dashboard;
  final Future<void> Function() onRefresh;
  final ValueChanged<WellnessRewardOffer> onRedeem;

  const _OffersTab({
    required this.dashboard,
    required this.onRefresh,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final offers = dashboard.offers;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        children: [
          const MedicalSectionHeader(
            title: 'Ưu đãi dành cho bạn',
            subtitle:
                'Điểm được dùng theo khoản sắp hết hạn trước. Mỗi mã chỉ được cấp một lần.',
            icon: Icons.card_giftcard_rounded,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          if (offers.isEmpty)
            const MedicalEmptyState(
              icon: Icons.redeem_outlined,
              title: 'Chưa có ưu đãi đang mở',
              message:
                  'Nabi sẽ hiển thị tại đây khi kho voucher mới được cập nhật.',
            )
          else
            for (final offer in offers) ...[
              _OfferCard(
                offer: offer,
                availablePoints: dashboard.summary.availablePoints,
                onRedeem: () => onRedeem(offer),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final WellnessRewardOffer offer;
  final int availablePoints;
  final VoidCallback onRedeem;

  const _OfferCard({
    required this.offer,
    required this.availablePoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final enoughPoints = availablePoints >= offer.costPoints;
    final canRedeem = offer.isInStock && enoughPoints;
    final colors = context.semanticColors;
    return MedicalSurfaceCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalIconBadge(
                icon: Icons.local_activity_rounded,
                color: colors.tertiary,
                backgroundColor: colors.tertiarySoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_offerTitle(offer), style: AppTextStyles.heading5),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _providerName(offer.providerName),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              MedicalStatusPill(
                label: '${offer.costPoints} điểm',
                icon: Icons.favorite_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_offerDescription(offer), style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MedicalStatusPill(
                label: offer.isInStock
                    ? 'Còn ${offer.availableCodes} mã'
                    : 'Đã hết mã',
                icon: offer.isInStock
                    ? Icons.inventory_2_outlined
                    : Icons.inventory_outlined,
                foregroundColor: offer.isInStock
                    ? colors.success
                    : colors.error,
                backgroundColor: offer.isInStock
                    ? colors.successSoft
                    : colors.errorSoft,
              ),
              if (offer.availableUntil != null)
                MedicalStatusPill(
                  label: 'Đổi đến ${_dateLabel(offer.availableUntil)}',
                  icon: Icons.event_rounded,
                  foregroundColor: colors.warning,
                  backgroundColor: colors.warningSoft,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canRedeem ? onRedeem : null,
              icon: const Icon(Icons.redeem_rounded),
              label: Text(
                !offer.isInStock
                    ? 'Đã hết mã'
                    : enoughPoints
                    ? 'Đổi ưu đãi'
                    : 'Chưa đủ điểm',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointHistoryTab extends StatelessWidget {
  final List<WellnessPointHistoryEntry> entries;
  final Future<void> Function() onRefresh;

  const _PointHistoryTab({required this.entries, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        children: [
          const MedicalSectionHeader(
            title: 'Lịch sử Điểm chăm sóc',
            subtitle:
                'Điểm cũ vẫn được lưu trong lịch sử nhưng không dùng để đổi voucher.',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          if (entries.isEmpty)
            const MedicalEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có lịch sử điểm',
              message:
                  'Hoàn thành nhiệm vụ hợp lệ và tải ảnh lên đúng giờ để nhận điểm.',
            )
          else
            for (final entry in entries) ...[
              _PointHistoryCard(entry: entry),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _PointHistoryCard extends StatelessWidget {
  final WellnessPointHistoryEntry entry;

  const _PointHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final positive = entry.pointsDelta >= 0;
    final colors = context.semanticColors;
    final color = positive ? colors.success : colors.error;
    return MedicalSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          MedicalIconBadge(
            icon: positive ? Icons.add_rounded : Icons.remove_rounded,
            color: color,
            backgroundColor: positive ? colors.successSoft : colors.errorSoft,
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_historyTitle(entry), style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_historyStatusLabel(entry)} · ${_dateLabel(entry.createdAt)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${entry.pointsDelta}',
            style: AppTextStyles.heading4.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RedemptionsTab extends StatelessWidget {
  final List<WellnessRewardRedemption> entries;
  final Future<void> Function() onRefresh;
  final ValueChanged<WellnessRewardRedemption> onOpen;

  const _RedemptionsTab({
    required this.entries,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        children: [
          const MedicalSectionHeader(
            title: 'Voucher của tôi',
            subtitle:
                'Mã đã cấp có thể xem lại. Trạng thái không phản ánh việc sử dụng tại đối tác.',
            icon: Icons.confirmation_num_rounded,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          if (entries.isEmpty)
            const MedicalEmptyState(
              icon: Icons.confirmation_num_outlined,
              title: 'Bạn chưa đổi voucher',
              message:
                  'Khi đủ điểm, hãy chọn một ưu đãi để nhận mã dùng một lần.',
            )
          else
            for (final entry in entries) ...[
              MedicalSurfaceCard(
                onTap: () => onOpen(entry),
                semanticLabel: 'Mở voucher ${_redemptionTitle(entry)}',
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    MedicalIconBadge(
                      icon: entry.isCancelled
                          ? Icons.cancel_outlined
                          : Icons.qr_code_2_rounded,
                      color: entry.isCancelled ? colors.error : colors.tertiary,
                      backgroundColor: entry.isCancelled
                          ? colors.errorSoft
                          : colors.tertiarySoft,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _redemptionTitle(entry),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${_providerName(entry.providerName)} · ${entry.pointsSpent} điểm',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    MedicalStatusPill(
                      label: _redemptionStatusLabel(entry.status),
                      foregroundColor: entry.isCancelled
                          ? colors.error
                          : _isIssuedStatus(entry.status)
                          ? colors.success
                          : colors.textMuted,
                      backgroundColor: entry.isCancelled
                          ? colors.errorSoft
                          : _isIssuedStatus(entry.status)
                          ? colors.successSoft
                          : colors.surfaceSoft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _VoucherSheet extends StatelessWidget {
  final WellnessRewardRedemption redemption;
  final String code;

  const _VoucherSheet({required this.redemption, required this.code});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_redemptionTitle(redemption), style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _providerName(redemption.providerName),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            Semantics(
              label: 'Mã QR của voucher ${_redemptionTitle(redemption)}',
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                color: Colors.white,
                child: QrImageView(
                  data: code,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading4.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () async {
                AppFeedbackService.instance.emit(AppFeedbackType.selection);
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  AppFeedbackService.instance.emit(AppFeedbackType.success);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã voucher.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Sao chép mã'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              redemption.voucherExpiresAt == null
                  ? 'Hạn sử dụng theo điều kiện của ưu đãi.'
                  : 'Hạn sử dụng: ${_dateLabel(redemption.voucherExpiresAt)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;
  final bool showSignIn;

  const _RewardsError({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSignIn,
    required this.showSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: MedicalEmptyState(
          icon: showSignIn ? Icons.login_rounded : Icons.cloud_off_rounded,
          title: showSignIn ? 'Cần đăng nhập' : 'Chưa tải được ưu đãi',
          message: message,
          action: FilledButton(
            onPressed: showSignIn ? onSignIn : onRetry,
            child: Text(showSignIn ? 'Đăng nhập' : 'Thử lại'),
          ),
        ),
      ),
    );
  }
}

String _historyStatusLabel(WellnessPointHistoryEntry entry) {
  if (!entry.isRedeemable) return 'Điểm lịch sử';
  return switch (entry.status.trim().toLowerCase()) {
    'pending' => 'Đang chờ',
    'available' => 'Khả dụng',
    'spent' => 'Đã dùng',
    'expired' => 'Đã hết hạn',
    'reversed' => 'Đã hoàn tác',
    'refunded' => 'Đã hoàn điểm',
    _ => 'Đã ghi nhận',
  };
}

String _offerTitle(WellnessRewardOffer offer) {
  return vietnameseSystemUiText(offer.title, fallback: 'Ưu đãi NanoBio');
}

String _offerDescription(WellnessRewardOffer offer) {
  return vietnameseSystemUiText(
    offer.description,
    fallback: 'Thông tin ưu đãi đang được cập nhật.',
  );
}

String _providerName(String value) {
  return vietnameseUiText(value, fallback: 'NanoBio');
}

String _historyTitle(WellnessPointHistoryEntry entry) {
  final fallback = switch (entry.eventType.trim().toLowerCase()) {
    'schedule_award' => 'Hoàn thành nhiệm vụ chăm sóc',
    'schedule_reversal' => 'Hoàn tác nhiệm vụ chăm sóc',
    'redemption' => 'Đổi ưu đãi',
    'refund' => 'Hoàn Điểm chăm sóc',
    'expiry' => 'Điểm chăm sóc đã hết hạn',
    'legacy_history' => 'Lịch sử điểm nhiệm vụ cũ',
    _ => 'Giao dịch Điểm chăm sóc',
  };
  const supportedEventTypes = {
    'schedule_award',
    'schedule_reversal',
    'redemption',
    'refund',
    'expiry',
    'legacy_history',
  };
  if (!supportedEventTypes.contains(entry.eventType.trim().toLowerCase())) {
    return fallback;
  }
  return vietnameseSystemUiText(entry.title, fallback: fallback);
}

String _redemptionTitle(WellnessRewardRedemption redemption) {
  return vietnameseSystemUiText(redemption.title, fallback: 'Voucher NanoBio');
}

bool _isIssuedStatus(String status) => status.trim().toLowerCase() == 'issued';

String _redemptionStatusLabel(String status) {
  return switch (status.trim().toLowerCase()) {
    'issued' => 'Đã cấp',
    'cancelled' || 'canceled' => 'Đã hủy',
    _ => 'Chưa xác định',
  };
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'chưa xác định';
  final local = VietnamTime.wallClock(value);
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

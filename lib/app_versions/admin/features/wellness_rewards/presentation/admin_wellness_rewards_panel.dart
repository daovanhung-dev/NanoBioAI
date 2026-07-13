import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/localization/vietnam_time.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../domain/entities/admin_wellness_reward_models.dart';
import '../providers/admin_wellness_rewards_providers.dart';

class AdminWellnessRewardsPanel extends ConsumerStatefulWidget {
  final bool canWrite;

  const AdminWellnessRewardsPanel({required this.canWrite, super.key});

  @override
  ConsumerState<AdminWellnessRewardsPanel> createState() =>
      _AdminWellnessRewardsPanelState();
}

class _AdminWellnessRewardsPanelState
    extends ConsumerState<AdminWellnessRewardsPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminWellnessRewardsControllerProvider);
    return state.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => MedicalEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Chưa tải được Điểm chăm sóc',
        message: error is AdminWellnessRewardException
            ? error.safeMessage
            : 'Nabi chưa tải được dữ liệu quản trị ưu đãi.',
        action: FilledButton(onPressed: _refresh, child: const Text('Thử lại')),
      ),
      data: _buildContent,
    );
  }

  Widget _buildContent(AdminWellnessRewardsSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicalSectionHeader(
          title: 'Điểm chăm sóc và kho voucher',
          subtitle:
              'Quản lý ưu đãi, nhập mã dùng một lần và xử lý giao dịch đã cấp.',
          icon: Icons.redeem_rounded,
          action: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: !widget.canWrite || snapshot.offers.isEmpty
                    ? null
                    : () => _importCodes(snapshot.offers),
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Nhập kho mã'),
              ),
              FilledButton.icon(
                onPressed: widget.canWrite ? () => _editOffer() : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo ưu đãi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminRewardMetrics(snapshot: snapshot),
        const SizedBox(height: AppSpacing.xl),
        const MedicalSectionHeader(
          title: 'Danh mục ưu đãi',
          subtitle:
              'Mã chưa cấp luôn được ẩn. Chỉ số tồn kho dùng để vận hành.',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.offers.isEmpty)
          const MedicalEmptyState(
            icon: Icons.card_giftcard_outlined,
            title: 'Chưa có ưu đãi',
            message: 'Tạo ưu đãi đầu tiên trước khi nhập kho mã voucher.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width >= 900
                  ? (width - AppSpacing.md) / 2
                  : width;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final offer in snapshot.offers)
                    SizedBox(
                      width: cardWidth,
                      child: _AdminOfferCard(
                        offer: offer,
                        onEdit: widget.canWrite
                            ? () => _editOffer(offer)
                            : null,
                        onImport: widget.canWrite
                            ? () => _importCodes(
                                snapshot.offers,
                                selectedOffer: offer,
                              )
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: AppSpacing.xl),
        const MedicalSectionHeader(
          title: 'Giao dịch voucher',
          subtitle:
              'Chỉ hủy sau khi đã xác nhận mã không còn hiệu lực ở bên cung cấp.',
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.redemptions.isEmpty)
          const MedicalEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch đổi',
            message:
                'Giao dịch mới sẽ xuất hiện tại đây sau khi người dùng đổi điểm.',
          )
        else
          for (final redemption in snapshot.redemptions) ...[
            _AdminRedemptionCard(
              redemption: redemption,
              onCancel: widget.canWrite && redemption.canCancel
                  ? () => _cancelRedemption(redemption)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _refresh() {
    return ref.read(adminWellnessRewardsControllerProvider.notifier).refresh();
  }

  Future<void> _editOffer([AdminWellnessRewardOffer? offer]) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: offer?.title);
    final description = TextEditingController(text: offer?.description);
    final provider = TextEditingController(
      text: offer?.providerName ?? 'NanoBio',
    );
    final cost = TextEditingController(
      text: offer == null ? '' : offer.costPoints.toString(),
    );
    final reason = TextEditingController(
      text: offer == null ? 'Tạo ưu đãi mới' : 'Cập nhật ưu đãi',
    );
    var selectedPlans = <String>{...?offer?.eligiblePlanCodes};
    if (selectedPlans.isEmpty) {
      selectedPlans = {'free', 'plus', 'family_plus'};
    }
    var isActive = offer?.isActive ?? true;
    var availableFrom = offer?.availableFrom;
    var availableUntil = offer?.availableUntil;
    var voucherExpiresAt = offer?.voucherExpiresAt;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(offer == null ? 'Tạo ưu đãi' : 'Sửa ưu đãi'),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Tên ưu đãi bằng tiếng Việt',
                      ),
                      validator: _vietnameseCopyValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: description,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả bằng tiếng Việt',
                      ),
                      validator: _vietnameseCopyValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: provider,
                            decoration: const InputDecoration(
                              labelText: 'Nhà cung cấp',
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: cost,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá điểm',
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value?.trim() ?? '');
                              return parsed == null || parsed <= 0
                                  ? 'Giá điểm phải lớn hơn 0.'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gói được áp dụng',
                        style: AppTextStyles.labelLarge,
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final entry in const {
                          'free': 'Miễn phí',
                          'plus': 'Plus',
                          'family_plus': 'FamilyPlus',
                        }.entries)
                          FilterChip(
                            label: Text(entry.value),
                            selected: selectedPlans.contains(entry.key),
                            onSelected: (selected) => setDialogState(() {
                              if (selected) {
                                selectedPlans.add(entry.key);
                              } else {
                                selectedPlans.remove(entry.key);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DateRow(
                      label: 'Ngày bắt đầu',
                      value: availableFrom,
                      onPick: () async {
                        final value = await _pickDate(context, availableFrom);
                        if (value != null) {
                          setDialogState(() => availableFrom = value);
                        }
                      },
                    ),
                    _DateRow(
                      label: 'Ngày kết thúc đổi',
                      value: availableUntil,
                      onPick: () async {
                        final value = await _pickDate(context, availableUntil);
                        if (value != null) {
                          setDialogState(() => availableUntil = value);
                        }
                      },
                    ),
                    _DateRow(
                      label: 'Hạn voucher mặc định',
                      value: voucherExpiresAt,
                      onPick: () async {
                        final value = await _pickDate(
                          context,
                          voucherExpiresAt,
                        );
                        if (value != null) {
                          setDialogState(() => voucherExpiresAt = value);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang mở đổi ưu đãi'),
                      value: isActive,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                    ),
                    TextFormField(
                      controller: reason,
                      decoration: const InputDecoration(
                        labelText: 'Lý do thay đổi',
                      ),
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                if (selectedPlans.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hãy chọn ít nhất một gói thành viên.'),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Lưu ưu đãi'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      try {
        final result = await ref
            .read(adminWellnessRewardsControllerProvider.notifier)
            .upsertOffer(
              AdminRewardOfferCommand(
                offerId: offer?.id,
                title: title.text,
                description: description.text,
                providerName: provider.text,
                costPoints: int.parse(cost.text.trim()),
                eligiblePlanCodes: selectedPlans.toList(growable: false),
                availableFrom: availableFrom,
                availableUntil: availableUntil,
                voucherExpiresAt: voucherExpiresAt,
                isActive: isActive,
                reason: reason.text,
              ),
            );
        _showMessage(result.message);
      } on AdminWellnessRewardException catch (error) {
        _showMessage(error.safeMessage);
      }
    }
    title.dispose();
    description.dispose();
    provider.dispose();
    cost.dispose();
    reason.dispose();
  }

  Future<void> _importCodes(
    List<AdminWellnessRewardOffer> offers, {
    AdminWellnessRewardOffer? selectedOffer,
  }) async {
    var offerId = selectedOffer?.id ?? offers.first.id;
    var voucherExpiresAt = selectedOffer?.voucherExpiresAt;
    final codes = TextEditingController();
    final reason = TextEditingController(text: 'Nhập kho mã voucher');
    final formKey = GlobalKey<FormState>();

    final imported = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nhập kho mã voucher'),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: offerId,
                      decoration: const InputDecoration(labelText: 'Ưu đãi'),
                      items: [
                        for (final offer in offers)
                          DropdownMenuItem(
                            value: offer.id,
                            child: Text(_adminOfferTitle(offer)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => offerId = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: codes,
                      minLines: 6,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Mỗi dòng một mã dùng một lần',
                        hintText: 'MAVOUCHER001\nMAVOUCHER002',
                      ),
                      validator: (value) => _parseCodes(value).isEmpty
                          ? 'Hãy nhập ít nhất một mã hợp lệ.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DateRow(
                      label: 'Hạn riêng của lô mã',
                      value: voucherExpiresAt,
                      onPick: () async {
                        final value = await _pickDate(
                          context,
                          voucherExpiresAt,
                        );
                        if (value != null) {
                          setDialogState(() => voucherExpiresAt = value);
                        }
                      },
                    ),
                    TextFormField(
                      controller: reason,
                      decoration: const InputDecoration(
                        labelText: 'Lý do nhập',
                      ),
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Nhập kho'),
            ),
          ],
        ),
      ),
    );

    if (imported == true && mounted) {
      try {
        final result = await ref
            .read(adminWellnessRewardsControllerProvider.notifier)
            .importCodes(
              AdminRewardCodeImportCommand(
                offerId: offerId,
                codes: _parseCodes(codes.text),
                voucherExpiresAt: voucherExpiresAt,
                reason: reason.text,
              ),
            );
        _showMessage(
          '${result.message} Nhận ${result.acceptedCount}, trùng ${result.duplicateCount}, từ chối ${result.rejectedCount}.',
        );
      } on AdminWellnessRewardException catch (error) {
        _showMessage(error.safeMessage);
      }
    }
    codes.dispose();
    reason.dispose();
  }

  Future<void> _cancelRedemption(
    AdminWellnessRewardRedemption redemption,
  ) async {
    final reason = TextEditingController();
    var confirmed = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hủy voucher đã cấp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mã ${redemption.maskedCode} sẽ bị loại vĩnh viễn và điểm được hoàn đúng một lần.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reason,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Lý do hủy bắt buộc',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: confirmed,
                onChanged: (value) =>
                    setDialogState(() => confirmed = value ?? false),
                title: const Text(
                  'Tôi xác nhận mã đã được vô hiệu hóa ở bên cung cấp.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Giữ giao dịch'),
            ),
            FilledButton(
              onPressed: confirmed && reason.text.trim().isNotEmpty
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Hủy và hoàn điểm'),
            ),
          ],
        ),
      ),
    );

    if (accepted == true && mounted) {
      try {
        final result = await ref
            .read(adminWellnessRewardsControllerProvider.notifier)
            .cancelRedemption(redemptionId: redemption.id, reason: reason.text);
        _showMessage(result.message);
      } on AdminWellnessRewardException catch (error) {
        _showMessage(error.safeMessage);
      }
    }
    reason.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final safeMessage = vietnameseSystemUiText(
      message,
      fallback: 'Đã xử lý yêu cầu quản trị ưu đãi.',
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(safeMessage)));
  }
}

class _AdminRewardMetrics extends StatelessWidget {
  final AdminWellnessRewardsSnapshot snapshot;

  const _AdminRewardMetrics({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final stock = snapshot.offers.fold<int>(
      0,
      (total, offer) => total + offer.availableCodes,
    );
    final issued = snapshot.redemptions
        .where((entry) => entry.status == 'issued')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - AppSpacing.md * 2) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: width,
              child: MedicalMetricCard(
                label: 'Ưu đãi',
                value: '${snapshot.offers.length}',
                icon: Icons.card_giftcard_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: MedicalMetricCard(
                label: 'Mã còn trong kho',
                value: '$stock',
                icon: Icons.inventory_2_rounded,
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: width,
              child: MedicalMetricCard(
                label: 'Voucher đang được cấp',
                value: '$issued',
                icon: Icons.confirmation_num_rounded,
                color: AppColors.tertiary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminOfferCard extends StatelessWidget {
  final AdminWellnessRewardOffer offer;
  final VoidCallback? onEdit;
  final VoidCallback? onImport;

  const _AdminOfferCard({
    required this.offer,
    required this.onEdit,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _adminOfferTitle(offer),
                  style: AppTextStyles.heading5,
                ),
              ),
              MedicalStatusPill(
                label: offer.isActive ? 'Đang mở' : 'Đã tắt',
                foregroundColor: offer.isActive
                    ? AppColors.success
                    : AppColors.textMuted,
                backgroundColor: offer.isActive
                    ? AppColors.successSoft
                    : AppColors.surfaceSoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _adminProviderName(offer.providerName),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_adminOfferDescription(offer), style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${offer.costPoints} điểm · Còn ${offer.availableCodes} mã · Đã cấp ${offer.issuedCodes}',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Sửa'),
              ),
              FilledButton.tonalIcon(
                onPressed: onImport,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Nhập mã'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminRedemptionCard extends StatelessWidget {
  final AdminWellnessRewardRedemption redemption;
  final VoidCallback? onCancel;

  const _AdminRedemptionCard({required this.redemption, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = redemption.status.trim().toLowerCase();
    final isIssued = normalizedStatus == 'issued';
    final isCancelled =
        normalizedStatus == 'cancelled' || normalizedStatus == 'canceled';
    return MedicalSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const MedicalIconBadge(
            icon: Icons.confirmation_num_rounded,
            color: AppColors.tertiary,
            backgroundColor: AppColors.tertiarySoft,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adminRedemptionTitle(redemption),
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${redemption.userLabel} · ${redemption.pointsSpent} điểm · ${redemption.maskedCode}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          MedicalStatusPill(
            label: isIssued
                ? 'Đã cấp'
                : isCancelled
                ? 'Đã hủy'
                : 'Chưa xác định',
            foregroundColor: isIssued
                ? AppColors.success
                : isCancelled
                ? AppColors.error
                : AppColors.textMuted,
            backgroundColor: isIssued
                ? AppColors.successSoft
                : isCancelled
                ? AppColors.errorSoft
                : AppColors.surfaceSoft,
          ),
          if (onCancel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? 'Không giới hạn' : _dateLabel(value!)),
      trailing: OutlinedButton(
        onPressed: onPick,
        child: const Text('Chọn ngày'),
      ),
    );
  }
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 10),
    initialDate: initial ?? now,
    helpText: 'Chọn ngày',
    cancelText: 'Hủy',
    confirmText: 'Chọn',
  );
}

String? _requiredValidator(String? value) {
  return value == null || value.trim().isEmpty
      ? 'Thông tin này không được để trống.'
      : null;
}

String? _vietnameseCopyValidator(String? value) {
  final required = _requiredValidator(value);
  if (required != null) return required;
  final text = value!.trim();
  final hasVietnameseMark = RegExp(
    r'[ăâđêôơưáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    caseSensitive: false,
  ).hasMatch(text);
  return hasVietnameseMark ? null : 'Nội dung phải là tiếng Việt có dấu.';
}

List<String> _parseCodes(String? value) {
  if (value == null) return const [];
  final seen = <String>{};
  return value
      .split(RegExp(r'[\r\n,;]+'))
      .map((entry) => entry.trim())
      .where((entry) => entry.length >= 4 && entry.length <= 128)
      .where(seen.add)
      .toList(growable: false);
}

String _adminOfferTitle(AdminWellnessRewardOffer offer) {
  return vietnameseSystemUiText(offer.title, fallback: 'Ưu đãi NanoBio');
}

String _adminOfferDescription(AdminWellnessRewardOffer offer) {
  return vietnameseSystemUiText(
    offer.description,
    fallback: 'Thông tin ưu đãi đang được cập nhật.',
  );
}

String _adminProviderName(String value) {
  return vietnameseUiText(value, fallback: 'NanoBio');
}

String _adminRedemptionTitle(AdminWellnessRewardRedemption redemption) {
  return vietnameseSystemUiText(redemption.title, fallback: 'Voucher NanoBio');
}

String _dateLabel(DateTime value) {
  final local = VietnamTime.wallClock(value);
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_controller.dart';
import 'schedule_proof_gallery_page.dart';

class LifestyleScheduleItemDetailPage extends ConsumerStatefulWidget {
  const LifestyleScheduleItemDetailPage({
    super.key,
    required this.initialItem,
  });

  final LifestyleScheduleItemEntity initialItem;

  @override
  ConsumerState<LifestyleScheduleItemDetailPage> createState() =>
      _LifestyleScheduleItemDetailPageState();
}

class _LifestyleScheduleItemDetailPageState
    extends ConsumerState<LifestyleScheduleItemDetailPage> {
  Timer? _boundaryTimer;
  DateTime? _scheduledBoundary;
  late LifestyleScheduleItemEntity _lastItem;
  ScheduleCompletionProofEntity? _lastProof;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _lastItem = widget.initialItem;
  }

  @override
  void dispose() {
    _boundaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);
    final scheduleState = scheduleAsync.whenOrNull(data: (value) => value);
    if (scheduleState != null) {
      final current = _currentItem(scheduleState.summary.items);
      if (current != null) _lastItem = current;
      _lastProof = _activeProofFor(
        _lastItem.id,
        scheduleState.completionProofs,
      );
    }
    final item = _lastItem;
    final proof = _lastProof;
    final now = ref.watch(lifestyleScheduleClockProvider)();
    _queueBoundaryRefresh(item, now);

    return MedicalPageScaffold(
      ambientBackground: false,
      appBar: AppBar(title: const Text('Chi tiết nhiệm vụ')),
      body: LifestyleScheduleItemDetailContent(
        item: item,
        proof: proof,
        now: now,
        isSubmitting: _submitting,
        onComplete: item.canCompleteAt(now) && !_submitting
            ? () => _complete(item)
            : null,
      ),
    );
  }

  LifestyleScheduleItemEntity? _currentItem(
    List<LifestyleScheduleItemEntity>? items,
  ) {
    if (items == null) return null;
    for (final item in items) {
      if (item.id == widget.initialItem.id) return item;
    }
    return null;
  }

  ScheduleCompletionProofEntity? _activeProofFor(
    String itemId,
    List<ScheduleCompletionProofEntity> proofs,
  ) {
    for (final proof in proofs) {
      if (proof.scheduleItemId == itemId && !proof.isReversed) return proof;
    }
    return null;
  }

  Future<void> _complete(LifestyleScheduleItemEntity item) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);
    if (!mounted) return;
    setState(() => _submitting = false);

    final message = switch (result) {
      LifestyleScheduleToggleResult.pendingRewardSync =>
        'Nhiệm vụ đã hoàn thành. Điểm chăm sóc đang chờ đồng bộ.',
      LifestyleScheduleToggleResult.blocked => ref
          .read(lifestyleScheduleControllerProvider)
          .whenOrNull(data: (value) => value.lastErrorMessage),
      LifestyleScheduleToggleResult.completed => null,
      LifestyleScheduleToggleResult.cancelled => null,
      LifestyleScheduleToggleResult.ignored => null,
      LifestyleScheduleToggleResult.undone => null,
    };
    if (message != null && message.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _queueBoundaryRefresh(
    LifestyleScheduleItemEntity item,
    DateTime now,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || item.isCompleted) return;
      final boundaries = <DateTime>[];
      final start = item.scheduledAt;
      final deadline = item.completionDeadline;
      if (start != null && start.isAfter(now)) boundaries.add(start);
      if (deadline != null && deadline.isAfter(now)) boundaries.add(deadline);
      boundaries.sort();
      final next = boundaries.isEmpty ? null : boundaries.first;
      if (next == _scheduledBoundary && _boundaryTimer?.isActive == true) {
        return;
      }
      _boundaryTimer?.cancel();
      _scheduledBoundary = next;
      if (next == null) return;
      _boundaryTimer = Timer(
        next.difference(now) + const Duration(milliseconds: 50),
        () {
          if (!mounted) return;
          _scheduledBoundary = null;
          setState(() {});
        },
      );
    });
  }
}

class LifestyleScheduleItemDetailContent extends StatelessWidget {
  const LifestyleScheduleItemDetailContent({
    super.key,
    required this.item,
    required this.proof,
    required this.now,
    required this.isSubmitting,
    required this.onComplete,
  });

  final LifestyleScheduleItemEntity item;
  final ScheduleCompletionProofEntity? proof;
  final DateTime now;
  final bool isSubmitting;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final status = item.completionStatusAt(now);
    final meta = _DetailCategoryMeta.from(item.category, item.sourceType);
    final safeTitle = vietnameseSystemUiText(
      item.title,
      fallback: 'Nhiệm vụ chăm sóc sức khỏe',
    );
    final description = vietnameseSystemUiText(
      item.description,
      fallback: 'Thực hiện mốc chăm sóc này theo hướng dẫn của Nabi.',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacingTokens.pagePadding,
        AppSpacingTokens.itemSpacingLarge,
        AppSpacingTokens.pagePadding,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroStatusCard(
                item: item,
                title: safeTitle,
                meta: meta,
                status: status,
              ),
              const SizedBox(height: AppSpacingTokens.sectionSpacing),
              _DetailSection(
                title: 'Thông tin nhiệm vụ',
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày thực hiện',
                    value: _formatDate(item.scheduleDate),
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Thời gian',
                    value: _timeRange(item),
                  ),
                  _InfoRow(
                    icon: meta.icon,
                    label: 'Loại nhiệm vụ',
                    value: meta.label,
                  ),
                  const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
                  Text('Mô tả', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacingTokens.itemSpacing),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              _ProgressSection(item: item),
              if (item.encouragement.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
                _NabiGuidanceCard(message: item.encouragement),
              ],
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              _CompletionWindowCard(item: item, status: status),
              if (proof != null) ...[
                const SizedBox(height: AppSpacingTokens.sectionSpacing),
                ScheduleRewardStatusSummary(proof: proof!),
                const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
                ScheduleProofPreviewSection(proofs: [proof!]),
              ],
              const SizedBox(height: AppSpacingTokens.sectionSpacing),
              _CompletionCta(
                item: item,
                status: status,
                isSubmitting: isSubmitting,
                onComplete: onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({
    required this.item,
    required this.title,
    required this.meta,
    required this.status,
  });

  final LifestyleScheduleItemEntity item;
  final String title;
  final _DetailCategoryMeta meta;
  final CompletionWindowStatus status;

  @override
  Widget build(BuildContext context) {
    final visual = _DetailStatusVisual.from(context, status);
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: visual.color.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meta.color.withValues(alpha: .12),
            ),
            child: Icon(meta.icon, color: meta.color),
          ),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Wrap(
                  spacing: AppSpacingTokens.itemSpacing,
                  runSpacing: AppSpacingTokens.itemSpacing,
                  children: [
                    _StatusChip(visual: visual),
                    Text(
                      _timeRange(item),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacingTokens.itemSpacingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.item});

  final LifestyleScheduleItemEntity item;

  @override
  Widget build(BuildContext context) {
    if (!item.isQuantitative) {
      return _DetailSection(
        title: 'Tiến độ',
        children: [
          _InfoRow(
            icon: item.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            label: 'Trạng thái',
            value: item.isCompleted ? 'Đã hoàn thành' : 'Chưa hoàn thành',
          ),
        ],
      );
    }

    final percent = (item.progressRatio * 100).round();
    return _DetailSection(
      title: 'Mục tiêu và tiến độ',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_number(item.currentValue)} / ${_number(item.targetValue)} ${_friendlyUnit(item.unit)}',
                style: AppTextStyles.labelLarge,
              ),
            ),
            Text('$percent%', style: AppTextStyles.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        LinearProgressIndicator(value: item.progressRatio),
      ],
    );
  }
}

class _NabiGuidanceCard extends StatelessWidget {
  const _NabiGuidanceCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: AppColorTokens.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: AppColorTokens.primary.withValues(alpha: .18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: AppColorTokens.primary),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gợi ý từ Nabi', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Text(
                  vietnameseSystemUiText(
                    message,
                    fallback: 'Nabi sẽ đồng hành cùng bạn ở mốc chăm sóc này.',
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionWindowCard extends StatelessWidget {
  const _CompletionWindowCard({
    required this.item,
    required this.status,
  });

  final LifestyleScheduleItemEntity item;
  final CompletionWindowStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      CompletionWindowStatus.waiting =>
        'Bạn có thể xác nhận từ ${_formatTime(item.scheduledAt)} đến ${_formatTime(item.completionDeadline)}.',
      CompletionWindowStatus.open =>
        'Nhiệm vụ đang trong thời gian xác nhận. Bạn có thể hoàn thành đến ${_formatTime(item.completionDeadline)}.',
      CompletionWindowStatus.locked =>
        'Cửa sổ xác nhận đã kết thúc lúc ${_formatTime(item.completionDeadline)}.',
      CompletionWindowStatus.completed => item.completedAt == null
          ? 'Nhiệm vụ đã được ghi nhận hoàn thành.'
          : 'Đã hoàn thành lúc ${_formatDateTime(item.completedAt!)}.',
    };
    final visual = _DetailStatusVisual.from(context, status);
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(visual.icon, color: visual.color),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời gian xác nhận', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacingTokens.itemSpacing),
                Text(message, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleRewardStatusSummary extends StatelessWidget {
  const ScheduleRewardStatusSummary({super.key, required this.proof});

  final ScheduleCompletionProofEntity proof;

  @override
  Widget build(BuildContext context) {
    final status = _RewardVisual.from(proof.rewardStatus);
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(color: status.color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Điểm chăm sóc', style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(status.message, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCta extends StatelessWidget {
  const _CompletionCta({
    required this.item,
    required this.status,
    required this.isSubmitting,
    required this.onComplete,
  });

  final LifestyleScheduleItemEntity item;
  final CompletionWindowStatus status;
  final bool isSubmitting;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    if (item.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        decoration: BoxDecoration(
          color: AppColorTokens.success.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColorTokens.success),
            const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
            Expanded(
              child: Text(
                'Nhiệm vụ đã hoàn thành.',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ),
      );
    }

    final label = switch (status) {
      CompletionWindowStatus.open => 'Hoàn thành nhiệm vụ',
      CompletionWindowStatus.waiting => 'Chưa đến giờ thực hiện',
      CompletionWindowStatus.locked => 'Đã hết thời gian xác nhận',
      CompletionWindowStatus.completed => 'Nhiệm vụ đã hoàn thành',
    };

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('schedule-detail-complete-button'),
        onPressed: onComplete,
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                switch (status) {
                  CompletionWindowStatus.open => Icons.camera_alt_rounded,
                  CompletionWindowStatus.waiting => Icons.schedule_rounded,
                  CompletionWindowStatus.locked => Icons.lock_clock_rounded,
                  CompletionWindowStatus.completed => Icons.verified_rounded,
                },
              ),
        label: Text(isSubmitting ? 'Đang xử lý...' : label),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.visual});

  final _DetailStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 14, color: visual.color),
          const SizedBox(width: 4),
          Text(
            visual.label,
            style: AppTextStyles.caption.copyWith(color: visual.color),
          ),
        ],
      ),
    );
  }
}

class _DetailCategoryMeta {
  const _DetailCategoryMeta({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  factory _DetailCategoryMeta.from(String category, String sourceType) {
    if (sourceType == LifestyleScheduleSourceTypes.mealPlan ||
        category == LifestyleScheduleCategories.meal) {
      return const _DetailCategoryMeta(
        icon: Icons.restaurant_rounded,
        color: AppColorTokens.secondary,
        label: 'Bữa ăn',
      );
    }
    return switch (category) {
      LifestyleScheduleCategories.water => const _DetailCategoryMeta(
        icon: Icons.water_drop_rounded,
        color: AppColorTokens.info,
        label: 'Uống nước',
      ),
      LifestyleScheduleCategories.body => const _DetailCategoryMeta(
        icon: Icons.directions_run_rounded,
        color: AppColorTokens.success,
        label: 'Vận động',
      ),
      LifestyleScheduleCategories.mind => const _DetailCategoryMeta(
        icon: Icons.self_improvement_rounded,
        color: AppColorTokens.tertiary,
        label: 'Tinh thần',
      ),
      LifestyleScheduleCategories.brain => const _DetailCategoryMeta(
        icon: Icons.psychology_rounded,
        color: AppColorTokens.warning,
        label: 'Trí não',
      ),
      LifestyleScheduleCategories.sleep => const _DetailCategoryMeta(
        icon: Icons.bedtime_rounded,
        color: AppColorTokens.primaryHover,
        label: 'Giấc ngủ',
      ),
      _ => const _DetailCategoryMeta(
        icon: Icons.checklist_rounded,
        color: AppColorTokens.primary,
        label: 'Chăm sóc',
      ),
    };
  }
}

class _DetailStatusVisual {
  const _DetailStatusVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _DetailStatusVisual.from(
    BuildContext context,
    CompletionWindowStatus status,
  ) {
    return switch (status) {
      CompletionWindowStatus.waiting => const _DetailStatusVisual(
        label: 'Sắp tới',
        icon: Icons.schedule_rounded,
        color: AppColorTokens.info,
      ),
      CompletionWindowStatus.open => const _DetailStatusVisual(
        label: 'Đang đến giờ',
        icon: Icons.bolt_rounded,
        color: AppColorTokens.primary,
      ),
      CompletionWindowStatus.locked => _DetailStatusVisual(
        label: 'Đã kết thúc',
        icon: Icons.lock_clock_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      CompletionWindowStatus.completed => const _DetailStatusVisual(
        label: 'Đã hoàn thành',
        icon: Icons.verified_rounded,
        color: AppColorTokens.success,
      ),
    };
  }
}

class _RewardVisual {
  const _RewardVisual({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  factory _RewardVisual.from(String rewardStatus) {
    return switch (rewardStatus) {
      ScheduleProofRewardStatuses.confirmed => const _RewardVisual(
        message: '+10 Điểm chăm sóc đã được đồng bộ.',
        icon: Icons.stars_rounded,
        color: AppColorTokens.success,
      ),
      ScheduleProofRewardStatuses.pending => const _RewardVisual(
        message: '10 Điểm chăm sóc đang chờ đồng bộ.',
        icon: Icons.sync_rounded,
        color: AppColorTokens.info,
      ),
      ScheduleProofRewardStatuses.reversed => const _RewardVisual(
        message: 'Điểm chăm sóc của nhiệm vụ này đã được hoàn tác.',
        icon: Icons.undo_rounded,
        color: AppColorTokens.warning,
      ),
      ScheduleProofRewardStatuses.legacyNonRedeemable => const _RewardVisual(
        message: 'Bản ghi cũ này không dùng để đổi quà.',
        icon: Icons.history_rounded,
        color: AppColorTokens.warning,
      ),
      _ => const _RewardVisual(
        message: 'Nhiệm vụ đã lưu trên thiết bị và không có điểm thưởng.',
        icon: Icons.phone_android_rounded,
        color: AppColorTokens.info,
      ),
    };
  }
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String _timeRange(LifestyleScheduleItemEntity item) {
  final start = _formatTime(item.scheduledAt);
  final end = item.endTime.trim().isEmpty
      ? null
      : LifestyleScheduleWindowPolicy.parseScheduledAt(
          scheduleDate: item.scheduleDate,
          startTime: item.endTime,
        );
  return end == null ? start : '$start – ${_formatTime(end)}';
}

String _formatTime(DateTime? value) {
  if (value == null) return '--:--';
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute, $day/$month/${parsed.year}';
}

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String _friendlyUnit(String value) {
  return switch (value.trim().toLowerCase()) {
    'lan' => 'lần',
    'phut' || 'minute' || 'minutes' => 'phút',
    _ => value,
  };
}

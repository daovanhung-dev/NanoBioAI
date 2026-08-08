import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';

class ScheduleItemCard extends StatelessWidget {
  const ScheduleItemCard({
    super.key,
    required this.item,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryLabel,
    required this.status,
    required this.canToggle,
    required this.highlighted,
    required this.onToggle,
  });

  final LifestyleScheduleItemEntity item;
  final IconData categoryIcon;
  final Color categoryColor;
  final String categoryLabel;
  final CompletionWindowStatus status;
  final bool canToggle;
  final bool highlighted;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final statusVisual = _StatusVisual.from(context, status);
    final completed = status == CompletionWindowStatus.completed;
    final muted = status == CompletionWindowStatus.locked;
    final surface = completed
        ? AppColorTokens.success.withValues(alpha: .08)
        : Theme.of(context).colorScheme.surface;
    final borderColor = highlighted
        ? AppColorTokens.warning
        : status == CompletionWindowStatus.open
        ? AppColorTokens.primary
        : statusVisual.color.withValues(alpha: .22);

    final safeTitle = vietnameseSystemUiText(
      item.title,
      fallback: 'Nhiệm vụ chăm sóc sức khỏe',
    );

    return Semantics(
      container: true,
      label: '${_timeLabel(item.startTime)}. $safeTitle. ${statusVisual.label}.',
      child: AnimatedContainer(
        duration: AppMotionScope.duration(context, AppMotionTokens.card),
        curve: AppMotionTokens.defaultCurve,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          border: Border.all(
            color: borderColor,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeColumn(item: item, color: statusVisual.color),
              const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(categoryIcon, size: 18, color: categoryColor),
                        const SizedBox(width: AppSpacingTokens.itemSpacing),
                        Expanded(
                          child: Text(
                            safeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: muted
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacingTokens.itemSpacing),
                    Wrap(
                      spacing: AppSpacingTokens.itemSpacing,
                      runSpacing: AppSpacingTokens.itemSpacing / 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusPill(visual: statusVisual),
                        Text(
                          categoryLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(
                        height: AppSpacingTokens.itemSpacingLarge,
                      ),
                      Text(
                        vietnameseSystemUiText(
                          item.description,
                          fallback:
                              'Thực hiện mốc chăm sóc này theo hướng dẫn của Nabi.',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (status == CompletionWindowStatus.waiting) ...[
                      const SizedBox(
                        height: AppSpacingTokens.itemSpacingLarge,
                      ),
                      const _CompactHint(
                        icon: Icons.schedule_rounded,
                        text: 'Bạn có thể xác nhận khi đến giờ.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacingTokens.itemSpacing),
              _CompletionAction(
                checked: completed,
                enabled: canToggle,
                color: statusVisual.color,
                onTap: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.item, required this.color});

  final LifestyleScheduleItemEntity item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final start = _timeLabel(item.startTime);
    final end = _optionalTimeLabel(item.endTime);

    return SizedBox(
      width: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            start,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
          if (end != null) ...[
            const SizedBox(height: 2),
            Text(
              end,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.visual});

  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 13, color: visual.color),
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

class _CompactHint extends StatelessWidget {
  const _CompactHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacingTokens.itemSpacing),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionAction extends StatelessWidget {
  const _CompletionAction({
    required this.checked,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final bool checked;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: checked ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành',
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: AppMotionScope.duration(context, AppMotionTokens.button),
        opacity: enabled ? 1 : .45,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadiusTokens.avatar),
          child: AnimatedContainer(
            duration: AppMotionScope.duration(context, AppMotionTokens.card),
            curve: AppMotionTokens.defaultCurve,
            width: AppSpacingTokens.touchTargetMin,
            height: AppSpacingTokens.touchTargetMin,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked
                  ? AppColorTokens.success
                  : color.withValues(alpha: .08),
              border: Border.all(
                color: checked
                    ? AppColorTokens.success
                    : color.withValues(alpha: .28),
              ),
            ),
            child: Icon(
              checked
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: checked ? AppColorTokens.textInverse : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _StatusVisual.from(
    BuildContext context,
    CompletionWindowStatus status,
  ) {
    return switch (status) {
      CompletionWindowStatus.waiting => const _StatusVisual(
        label: 'Sắp tới',
        icon: Icons.schedule_rounded,
        color: AppColorTokens.info,
      ),
      CompletionWindowStatus.open => const _StatusVisual(
        label: 'Đang đến giờ',
        icon: Icons.bolt_rounded,
        color: AppColorTokens.primary,
      ),
      CompletionWindowStatus.locked => _StatusVisual(
        label: 'Đã kết thúc',
        icon: Icons.lock_clock_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      CompletionWindowStatus.completed => const _StatusVisual(
        label: 'Đã hoàn thành',
        icon: Icons.verified_rounded,
        color: AppColorTokens.success,
      ),
    };
  }
}

String _timeLabel(String value) {
  return _optionalTimeLabel(value) ?? '--:--';
}

String? _optionalTimeLabel(String value) {
  final parsed = LifestyleScheduleWindowPolicy.parseScheduledAt(
    scheduleDate: '2000-01-01',
    startTime: value,
  );
  if (parsed == null) return null;
  return '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}

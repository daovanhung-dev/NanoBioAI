import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
import 'package:nano_app/features/dashboard/domain/services/dashboard_companion_service.dart';

typedef TimelineActionCallback =
    Future<void> Function(DashboardTimelineItem item);

class DashboardDailySummaryCard extends StatelessWidget {
  final String summary;

  const DashboardDailySummaryCard({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    return _CompanionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(icon: Icons.auto_awesome_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nami nhìn nhanh hôm nay',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSlowDayBanner extends StatelessWidget {
  const DashboardSlowDayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _CompanionCard(
      color: AppColors.secondary.withValues(alpha: 0.08),
      borderColor: AppColors.secondary.withValues(alpha: 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SoftIcon(
            icon: Icons.self_improvement_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Hôm nay mình đi chậm lại cũng được. Nami sẽ chỉ nhắc những điều thật nhẹ thôi.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardNextActionSection extends StatelessWidget {
  final DashboardTimelineItem? item;
  final bool isSlowDay;
  final TimelineActionCallback onComplete;
  final VoidCallback onLater;

  const DashboardNextActionSection({
    required this.item,
    required this.isSlowDay,
    required this.onComplete,
    required this.onLater,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final action = item;
    return _CompanionCard(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderColor: AppColors.primary.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(icon: Icons.favorite_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Việc nhỏ tiếp theo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (action == null)
            Text(
              DashboardCompanionService.nextActionMessage(null),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Text(
              action.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (action.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DashboardCompanionService.nextActionMessage(action),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            if (isSlowDay) ...[
              const SizedBox(height: AppSpacing.xs),
              const _InlineHint(
                icon: Icons.spa_rounded,
                label: 'Nami đang ưu tiên những việc nhẹ cho bạn.',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onComplete(action),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Đã làm'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(onPressed: onLater, child: const Text('Để lát nữa')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardDailyCheckInCard extends StatelessWidget {
  final String? selectedMood;
  final Future<void> Function(String mood) onSelectMood;

  const DashboardDailyCheckInCard({
    required this.selectedMood,
    required this.onSelectMood,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _CompanionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(icon: Icons.chat_bubble_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nami muốn hỏi nhẹ một chút...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hôm nay bạn thấy cơ thể mình thế nào?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (selectedMood != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineHint(
              icon: Icons.favorite_rounded,
              label: DashboardCompanionService.moodResponse(selectedMood!),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DashboardMoodCodes.all.map((mood) {
              final selected = mood == selectedMood;
              return ChoiceChip(
                selected: selected,
                label: Text(DashboardCompanionService.moodLabel(mood)),
                onSelected: (_) => onSelectMood(mood),
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DashboardPlanStatusCard extends StatelessWidget {
  final DashboardPlanStatus planStatus;

  const DashboardPlanStatusCard({required this.planStatus, super.key});

  @override
  Widget build(BuildContext context) {
    final hasPlan = planStatus.hasPlan;
    final title = hasPlan
        ? 'Kế hoạch hiện có đến ${_formatDate(planStatus.lastPlanDate!)}'
        : 'Nami có thể chuẩn bị nhịp 7 ngày đầu tiên cho bạn.';
    final message = !hasPlan
        ? 'Khi sẵn sàng, bạn có thể để Nami sắp nhẹ thực đơn, vận động và nhắc nhở.'
        : planStatus.remainingDays > 0
        ? 'Còn ${planStatus.remainingDays} ngày trong kế hoạch. Kế hoạch của bạn vẫn còn đủ dùng, mình cứ đi nhẹ từng ngày nhé.'
        : 'Kế hoạch hiện tại đã đến hạn, Nami có thể chuẩn bị thêm nhịp mới cho bạn.';

    return _CompanionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SoftIcon(icon: Icons.event_available_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSelfCareStreakCard extends StatelessWidget {
  final DashboardSelfCareStreak streak;

  const DashboardSelfCareStreakCard({required this.streak, super.key});

  @override
  Widget build(BuildContext context) {
    final hasData = streak.hasAnyCareDay;
    final hasCurrentStreak = streak.currentStreak > 0;
    final title = hasCurrentStreak
        ? 'Bạn đã chăm mình ${streak.currentStreak} ngày liên tiếp'
        : hasData
        ? 'Tuần này bạn đã có những lần quay lại với bản thân'
        : 'Mình bắt đầu chuỗi đầu tiên từ hôm nay nhé.';
    final message = hasCurrentStreak
        ? 'Nami rất vui vì bạn vẫn quay lại với bản thân mỗi ngày.'
        : hasData
        ? 'Chỉ cần hôm nay thêm một ghi nhận nhỏ là mình nối lại nhịp được rồi.'
        : 'Chỉ cần một ghi nhận nhỏ cũng đủ để bắt đầu.';

    return _CompanionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(icon: Icons.local_florist_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (streak.days.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: streak.days
                  .map(
                    (day) => Expanded(
                      child: _StreakDot(
                        day: _weekdayLabel(day.date),
                        active: day.hasCareSignal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardHealthScoreBreakdownSheet extends StatelessWidget {
  final List<DashboardScoreBreakdownItem> items;

  const DashboardHealthScoreBreakdownSheet({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Điểm hôm nay được Nami tổng hợp từ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.map((item) => _BreakdownRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class DashboardWaterUpdateSheet extends StatefulWidget {
  final int currentWaterMl;
  final Future<void> Function(int amountMl) onAddWater;
  final Future<void> Function(int waterMl) onSetWater;

  const DashboardWaterUpdateSheet({
    required this.currentWaterMl,
    required this.onAddWater,
    required this.onSetWater,
    super.key,
  });

  @override
  State<DashboardWaterUpdateSheet> createState() =>
      _DashboardWaterUpdateSheetState();
}

class _DashboardWaterUpdateSheetState extends State<DashboardWaterUpdateSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật nước hôm nay',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              widget.currentWaterMl > 0
                  ? 'Hiện tại bạn đã ghi nhận ${widget.currentWaterMl} ml.'
                  : 'Mình thêm từng cốc nhỏ thôi nhé.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _addAndClose(context, 250),
                    child: const Text('+250 ml'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _addAndClose(context, 500),
                    child: const Text('+500 ml'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nhập tổng lượng nước',
                suffixText: 'ml',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _setAndClose(context),
                child: const Text('Lưu lượng nước'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAndClose(BuildContext context, int amount) async {
    await widget.onAddWater(amount);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _setAndClose(BuildContext context) async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) return;
    await widget.onSetWater(value);
    if (context.mounted) Navigator.pop(context);
  }
}

class DashboardWeightUpdateSheet extends StatefulWidget {
  final double? currentWeightKg;
  final Future<void> Function(double weightKg) onSaveWeight;

  const DashboardWeightUpdateSheet({
    required this.currentWeightKg,
    required this.onSaveWeight,
    super.key,
  });

  @override
  State<DashboardWeightUpdateSheet> createState() =>
      _DashboardWeightUpdateSheetState();
}

class _DashboardWeightUpdateSheetState
    extends State<DashboardWeightUpdateSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentWeightKg == null || widget.currentWeightKg! <= 0
          ? ''
          : widget.currentWeightKg!.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật cân nặng hôm nay',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Nami sẽ dùng ghi nhận hôm nay để dashboard phản ánh sát hơn.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cân nặng hôm nay',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _saveAndClose(context),
                child: const Text('Lưu cân nặng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndClose(BuildContext context) async {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 400) return;
    await widget.onSaveWeight(value);
    if (context.mounted) Navigator.pop(context);
  }
}

class _BreakdownRow extends StatelessWidget {
  final DashboardScoreBreakdownItem item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: item.progress.clamp(0, 1).toDouble(),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  final String day;
  final bool active;

  const _StreakDot({required this.day, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: AppDuration.normal,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.textHint.withValues(alpha: 0.24),
            ),
          ),
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 4),
        Text(day, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _InlineHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SoftIcon({required this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const _CompanionCard({required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _weekdayLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '';
  switch (parsed.weekday) {
    case DateTime.monday:
      return 'T2';
    case DateTime.tuesday:
      return 'T3';
    case DateTime.wednesday:
      return 'T4';
    case DateTime.thursday:
      return 'T5';
    case DateTime.friday:
      return 'T6';
    case DateTime.saturday:
      return 'T7';
    default:
      return 'CN';
  }
}

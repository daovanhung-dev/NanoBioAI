import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/core/theme/theme.dart';

class GeneratedPlanProgressPanel extends StatefulWidget {
  final GeneratedPlanProgress progress;

  const GeneratedPlanProgressPanel({super.key, required this.progress});

  @override
  State<GeneratedPlanProgressPanel> createState() =>
      _GeneratedPlanProgressPanelState();
}

class _GeneratedPlanProgressPanelState
    extends State<GeneratedPlanProgressPanel> {
  final ScrollController _eventScrollController = ScrollController();

  @override
  void didUpdateWidget(covariant GeneratedPlanProgressPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress.events.length != oldWidget.progress.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_eventScrollController.hasClients) {
          _eventScrollController.animateTo(
            _eventScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _eventScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final progress = widget.progress;
    final completedEvents = progress.completedEvents;
    final totalEvents = progress.totalEvents;
    final percent = progress.percentComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: colors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiến độ tạo lịch',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Đã lưu $completedEvents / $totalEvents sự kiện',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$percent%',
                  key: const ValueKey('generated-plan-progress-percent'),
                  style: AppTextStyles.heading4.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Tiến độ tạo lịch',
              value:
                  '$percent phần trăm hoàn tất. Đã lưu $completedEvents trên $totalEvents sự kiện.',
              liveRegion: true,
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    color: colors.primary,
                    backgroundColor: colors.primarySoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sự kiện theo ngày',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (progress.events.isEmpty)
              Text(
                'Các sự kiện đã lưu sẽ xuất hiện ở đây theo thứ tự thời gian.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else
              SizedBox(
                height: 300,
                child: _GeneratedPlanEventList(
                  events: progress.events,
                  controller: _eventScrollController,
                ),
              ),
            if (progress.pendingMealProposal case final proposal?) ...[
              const SizedBox(height: AppSpacing.md),
              _PendingMealProposalCard(proposal: proposal),
            ],
            const SizedBox(height: AppSpacing.md),
            _FilteredMealCandidatesPanel(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPlanEventList extends StatelessWidget {
  final List<GeneratedPlanEventProgress> events;
  final ScrollController controller;

  const _GeneratedPlanEventList({
    required this.events,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<GeneratedPlanEventProgress>>{};
    for (final event in events) {
      byDay.putIfAbsent(event.day, () => []).add(event);
    }
    final days = byDay.keys.toList()..sort();
    return ListView.builder(
      controller: controller,
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEvents = [...byDay[day]!]
          ..sort((a, b) => a.time.compareTo(b.time));
        return ExpansionTile(
          key: PageStorageKey<String>('generated-plan-day-$day'),
          initiallyExpanded: day == days.last,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: AppSpacing.sm),
          title: Text('Ngày thứ $day (${dayEvents.length} sự kiện)'),
          children: [
            for (final event in dayEvents) _GeneratedPlanEventRow(event: event),
          ],
        );
      },
    );
  }
}

class _GeneratedPlanEventRow extends StatelessWidget {
  final GeneratedPlanEventProgress event;

  const _GeneratedPlanEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final isAccepted = event.isAccepted;
    final isPending = event.status == 'awaiting_approval';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAccepted
                ? Icons.check_circle_rounded
                : isPending
                ? Icons.hourglass_top_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: isAccepted ? colors.success : colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${event.time} · ${isPending
                  ? 'Chờ bạn duyệt'
                  : isAccepted
                  ? 'Đã lưu'
                  : 'Đang xử lý'} ${event.title}',
              softWrap: true,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMealProposalCard extends StatelessWidget {
  final GeneratedCustomMealProposal proposal;

  const _PendingMealProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Món chờ bạn duyệt · Ngày thứ ${proposal.day}',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(proposal.name, style: AppTextStyles.heading5),
          if (proposal.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(proposal.description, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Khẩu phần: ${proposal.servingSize}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Nguyên liệu: ${proposal.ingredients.join(', ')}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Cách chế biến: ${proposal.cookingSteps.join(' · ')}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Dinh dưỡng và dị ứng chưa được xác minh; món chưa được đưa vào lịch.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showGeneratedCustomMealDecisionDialog(
  BuildContext context, {
  required GeneratedCustomMealProposal proposal,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Món chờ bạn duyệt · Ngày thứ ${proposal.day}'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(proposal.name, style: AppTextStyles.heading5),
          const SizedBox(height: AppSpacing.xs),
          Text(proposal.description),
          const SizedBox(height: AppSpacing.sm),
          Text('Khẩu phần: ${proposal.servingSize}'),
          const SizedBox(height: AppSpacing.xs),
          Text('Nguyên liệu: ${proposal.ingredients.join(', ')}'),
          const SizedBox(height: AppSpacing.xs),
          Text('Cách chế biến: ${proposal.cookingSteps.join(' · ')}'),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Dinh dưỡng và dị ứng chưa được xác minh. Món chỉ vào lịch sau khi bạn duyệt.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Tạo món khác'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Duyệt món'),
        ),
      ],
    ),
  );
}

class _FilteredMealCandidatesPanel extends StatelessWidget {
  final GeneratedPlanProgress progress;

  const _FilteredMealCandidatesPanel({required this.progress});

  static const _periods = [
    (MealSchedulePeriod.morning, 'Sáng'),
    (MealSchedulePeriod.midday, 'Trưa'),
    (MealSchedulePeriod.evening, 'Chiều/Tối'),
  ];
  static const _roles = [
    (MealScheduleRole.main, 'Chính'),
    (MealScheduleRole.side, 'Phụ'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final candidates = progress.filteredMealCandidates;
    final isComplete =
        progress.mealFilterState == GeneratedPlanMealFilterState.complete;
    final firstPeriod = candidates.isEmpty
        ? null
        : _periods
              .firstWhere(
                (entry) =>
                    candidates.any((candidate) => candidate.period == entry.$1),
              )
              .$1;
    final firstRole = firstPeriod == null
        ? null
        : _roles
              .firstWhere(
                (entry) => candidates.any(
                  (candidate) =>
                      candidate.period == firstPeriod &&
                      candidate.role == entry.$1,
                ),
              )
              .$1;
    int countForPeriod(MealSchedulePeriod period) =>
        candidates.where((candidate) => candidate.period == period).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Món còn lại sau lọc',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (progress.mealFilterState ==
                GeneratedPlanMealFilterState.filtering)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                switch (progress.mealFilterState) {
                  GeneratedPlanMealFilterState.notStarted => 'Chưa lọc',
                  GeneratedPlanMealFilterState.filtering => 'Đang lọc',
                  GeneratedPlanMealFilterState.complete =>
                    '${candidates.length} / ${progress.catalogMealCount} món',
                },
                key: const ValueKey('filtered-meal-candidate-count'),
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          switch (progress.mealFilterState) {
            GeneratedPlanMealFilterState.notStarted =>
              'Danh sách món sẽ xuất hiện sau khi bộ lọc cục bộ bắt đầu.',
            GeneratedPlanMealFilterState.filtering =>
              'Đang kiểm tra các món trong danh mục theo nhãn và hồ sơ của bạn.',
            GeneratedPlanMealFilterState.complete =>
              'Danh sách đầy đủ sau lọc cục bộ. Mỗi lượt AI có thể dùng shortlist nhỏ hơn để vừa giới hạn ngữ cảnh.',
          },
          key: const ValueKey('filtered-meal-candidate-status'),
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        if (isComplete)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Tối thiểu ${progress.minimumCandidatesPerPeriod} món mỗi khung: '
              'Sáng ${countForPeriod(MealSchedulePeriod.morning)} · '
              'Trưa ${countForPeriod(MealSchedulePeriod.midday)} · '
              'Chiều/Tối ${countForPeriod(MealSchedulePeriod.evening)}',
              key: const ValueKey('filtered-meal-period-counts'),
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (isComplete && candidates.any((meal) => meal.isGeneralWellnessOnly))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Danh sách có gợi ý sức khỏe chung; dữ liệu dinh dưỡng và mức độ phù hợp với tình trạng sức khỏe chưa được xác minh.',
              key: const ValueKey('filtered-meal-general-wellness-note'),
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        if (isComplete && candidates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Danh mục hiện chưa có món đủ dữ liệu đã xác minh phù hợp với hồ sơ. Nabi sẽ không dùng món chưa được xác minh.',
              key: const ValueKey('filtered-meal-candidates-empty'),
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else if (isComplete)
          for (final (period, label) in _periods)
            _PeriodExpansion(
              candidates: candidates,
              period: period,
              label: label,
              roles: _roles,
              initiallyExpanded: period == firstPeriod,
              initiallyExpandedRole: firstRole,
            ),
      ],
    );
  }
}

class _PeriodExpansion extends StatelessWidget {
  final List<MealCandidateClassification> candidates;
  final MealSchedulePeriod period;
  final String label;
  final List<(MealScheduleRole, String)> roles;
  final bool initiallyExpanded;
  final MealScheduleRole? initiallyExpandedRole;

  const _PeriodExpansion({
    required this.candidates,
    required this.period,
    required this.label,
    required this.roles,
    required this.initiallyExpanded,
    required this.initiallyExpandedRole,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final periodCandidates = candidates
        .where((candidate) => candidate.period == period)
        .toList(growable: false);
    return ExpansionTile(
      key: PageStorageKey<String>('filtered-meal-period-${period.name}'),
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: AppSpacing.sm),
      title: Text(
        '$label · ${periodCandidates.length}',
        style: AppTextStyles.labelMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        for (final (role, roleLabel) in roles)
          _RoleExpansion(
            candidates: periodCandidates
                .where((candidate) => candidate.role == role)
                .toList(growable: false),
            period: period,
            role: role,
            label: roleLabel,
            initiallyExpanded:
                initiallyExpanded && role == initiallyExpandedRole,
          ),
      ],
    );
  }
}

class _RoleExpansion extends StatelessWidget {
  final List<MealCandidateClassification> candidates;
  final MealSchedulePeriod period;
  final MealScheduleRole role;
  final String label;
  final bool initiallyExpanded;

  const _RoleExpansion({
    required this.candidates,
    required this.period,
    required this.role,
    required this.label,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final listHeight = math.min(
      240.0,
      math.max(56.0, candidates.length * 52.0),
    );
    return ExpansionTile(
      key: PageStorageKey<String>(
        'filtered-meal-role-${period.name}-${role.name}',
      ),
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        '$label · ${candidates.length} món',
        style: AppTextStyles.bodySmall.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        if (candidates.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Chưa có món trong nhóm này.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              key: PageStorageKey<String>(
                'filtered-meal-list-${period.name}-${role.name}',
              ),
              primary: false,
              itemCount: candidates.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  role == MealScheduleRole.main
                      ? Icons.restaurant_rounded
                      : Icons.local_cafe_rounded,
                  size: 17,
                  color: colors.primary,
                ),
                title: Text(
                  candidates[index].name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

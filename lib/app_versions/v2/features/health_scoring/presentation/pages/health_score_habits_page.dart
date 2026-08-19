import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../domain/entities/health_score_habits_models.dart';
import '../../providers/health_score_habits_providers.dart';

class HealthScoreHabitsPage extends ConsumerWidget {
  const HealthScoreHabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthScoreHabitsSummaryProvider);
    final colors = context.semanticColors;

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text('Điểm sức khỏe'),
      ),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: state.when(
          skipLoadingOnRefresh: true,
          loading: () =>
              const _HealthScoreLoading(key: ValueKey('health-score-loading')),
          error: (_, __) => _HealthScoreSupportState(
            key: const ValueKey('health-score-error'),
            icon: Icons.error_outline_rounded,
            title: 'Chưa tải được điểm sức khỏe',
            message: 'Bạn thử lại sau ít phút.',
            actionLabel: 'Thử lại',
            onAction: () {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              ref.invalidate(healthScoreHabitsSummaryProvider);
            },
          ),
          data: (viewModel) {
            return KeyedSubtree(
              key: ValueKey('health-score-${viewModel.status.name}'),
              child: switch (viewModel.status) {
                HealthScoreHabitsViewStatus.authRequired =>
                  _HealthScoreSupportState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Cần đăng nhập',
                    message: vietnameseSystemUiText(
                      viewModel.message,
                      fallback: 'Đăng nhập để tiếp tục.',
                    ),
                    actionLabel: 'Đăng nhập',
                    onAction: () {
                      AppFeedbackService.instance.emit(
                        AppFeedbackType.primaryAction,
                      );
                      context.push(V2RoutePaths.login);
                    },
                  ),
                HealthScoreHabitsViewStatus.empty => _HealthScoreSupportState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Chưa có lịch sử chăm sóc',
                  message: vietnameseSystemUiText(
                    viewModel.message,
                    fallback:
                        'Hoàn thành lịch chăm sóc hằng ngày để Nabi tính điểm.',
                  ),
                  actionLabel: 'Làm mới',
                  onAction: () {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    ref.invalidate(healthScoreHabitsSummaryProvider);
                  },
                ),
                HealthScoreHabitsViewStatus.failure => _HealthScoreSupportState(
                  icon: Icons.error_outline_rounded,
                  title: 'Chưa tải được điểm sức khỏe',
                  message: vietnameseSystemUiText(
                    viewModel.message,
                    fallback: 'Bạn thử lại sau ít phút.',
                  ),
                  actionLabel: 'Thử lại',
                  onAction: () {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    ref.invalidate(healthScoreHabitsSummaryProvider);
                  },
                ),
                HealthScoreHabitsViewStatus.ready => _HealthScoreReady(
                  result: viewModel.result!,
                  refreshing: state.isRefreshing,
                  onRefresh: () => _refresh(context, ref),
                ),
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    try {
      // ignore: unused_result
      await ref.refresh(healthScoreHabitsSummaryProvider.future);
      AppFeedbackService.instance.emit(AppFeedbackType.success);
    } catch (_) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nabi chưa cập nhật được điểm mới. Thông tin gần nhất vẫn được giữ lại.',
            ),
          ),
        );
    }
  }
}

class _HealthScoreLoading extends StatelessWidget {
  const _HealthScoreLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _HealthScoreReady extends StatelessWidget {
  final HealthScoreHabitsResult result;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  const _HealthScoreReady({
    required this.result,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (refreshing) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.sm),
          ],
          _ScoreHeader(result: result),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Thành phần điểm',
            children: result.breakdown
                .map((item) => _BreakdownRow(item: item))
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Tiến độ thói quen',
            children: result.habitProgress.isEmpty
                ? const [
                    _EmptyInline(
                      message: 'Chưa có thói quen đến hạn trong giai đoạn này.',
                    ),
                  ]
                : result.habitProgress
                      .map((item) => _HabitProgressRow(item: item))
                      .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final HealthScoreHabitsResult result;
  const _ScoreHeader({required this.result});
  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: _cardDecoration(colors),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: result.score.toDouble()),
            duration: AppMotionScope.duration(context, AppDuration.progress),
            curve: AppAnimations.emphasizedCurve,
            builder: (context, score, _) => Text(
              score.round().toString(),
              style: AppTextStyles.heading1.copyWith(
                color: colors.primary,
                fontSize: 56,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('/100', style: AppTextStyles.bodyLarge),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text('${result.period.startDate} đến ${result.period.endDate}',
            style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text(_healthScoreDisclaimer,
            style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary, height: 1.35)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _cardDecoration(colors),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ]),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final HealthScoreBreakdownItem item;
  const _BreakdownRow({required this.item});
  @override
  Widget build(BuildContext context) => _ProgressRow(
      title: vietnameseUiText(item.label),
      subtitle: '${item.completedCount}/${item.totalCount} tín hiệu',
      value: item.score / 100,
      trailing: '${item.score}');
}

class _HabitProgressRow extends StatelessWidget {
  final HealthScoreHabitProgressItem item;
  const _HabitProgressRow({required this.item});
  @override
  Widget build(BuildContext context) => _ProgressRow(
      title: vietnameseUiText(item.label),
      subtitle: '${item.completedCount}/${item.dueCount} đã xong',
      value: item.progress.clamp(0, 1).toDouble(),
      trailing: '${(item.progress * 100).round()}%');
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final String trailing;
  const _ProgressRow({required this.title, required this.subtitle,
      required this.value, required this.trailing});
  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700))),
          Text(trailing, style: AppTextStyles.bodyMedium),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.caption.copyWith(color: colors.textHint)),
        const SizedBox(height: AppSpacing.tiny),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value),
          duration: AppMotionScope.duration(context, AppDuration.progress),
          curve: AppAnimations.emphasizedCurve,
          builder: (context, progress, _) => LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ]),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;
  const _EmptyInline({required this.message});
  @override
  Widget build(BuildContext context) => Text(message,
      style: AppTextStyles.bodyMedium.copyWith(
          color: context.semanticColors.textSecondary));
}

class _HealthScoreSupportState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _HealthScoreSupportState({super.key, required this.icon,
      required this.title, required this.message, required this.actionLabel,
      required this.onAction});
  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: colors.primary, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45)),
              const SizedBox(height: AppSpacing.sectionSpacing),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ]),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(AppSemanticColors colors) => BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: colors.border));

const _healthScoreDisclaimer =
    'Điểm sức khỏe chỉ để theo dõi xu hướng chăm sóc hằng ngày, không thay thế chẩn đoán y khoa.';

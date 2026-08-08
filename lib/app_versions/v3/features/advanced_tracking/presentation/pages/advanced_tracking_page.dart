import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/advanced_tracking_models.dart';
import '../../providers/advanced_tracking_providers.dart';

class AdvancedTrackingPage extends ConsumerWidget {
  const AdvancedTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advancedTrackingSummaryProvider);
    final colors = context.semanticColors;

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text('Lộ trình nâng cao'),
      ),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: state.when(
          loading: () => const Center(
            key: ValueKey('advanced-tracking-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => _SupportState(
            key: const ValueKey('advanced-tracking-error'),
            icon: Icons.error_outline_rounded,
            title: 'Nabi chưa tải được lộ trình',
            message: 'Mình thử lại sau một chút nhé.',
            actionLabel: 'Thử lại',
            onAction: () async {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              ref.invalidate(advancedTrackingSummaryProvider);
            },
          ),
          data: (viewModel) {
            return KeyedSubtree(
              key: ValueKey('advanced-tracking-${viewModel.status.name}'),
              child: switch (viewModel.status) {
                AdvancedTrackingViewStatus.authRequired => _SupportState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cần đăng nhập',
                  message:
                      viewModel.message ?? 'Bạn cần đăng nhập để xem lộ trình.',
                  actionLabel: 'Đăng nhập',
                  onAction: () async {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    context.push(V2RoutePaths.login);
                  },
                ),
                AdvancedTrackingViewStatus.locked => _SupportState(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Chưa mở cho tài khoản này',
                  message:
                      viewModel.message ??
                      'Nabi sẽ mở lộ trình nâng cao khi gói của bạn sẵn sàng.',
                  actionLabel: 'Làm mới',
                  onAction: () async {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    ref.invalidate(advancedTrackingSummaryProvider);
                  },
                ),
                AdvancedTrackingViewStatus.empty => _EmptyGoalState(
                  result: viewModel.result!,
                  message: viewModel.message,
                  onCreate: () async {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    try {
                      await ref.read(
                        advancedTrackingCreateHydrationGoalProvider,
                      )();
                      await ref.read(advancedTrackingSummaryProvider.future);
                      AppFeedbackService.instance.emit(AppFeedbackType.success);
                    } catch (_) {
                      AppFeedbackService.instance.emit(AppFeedbackType.error);
                      rethrow;
                    }
                  },
                ),
                AdvancedTrackingViewStatus.ready => _RoadmapReady(
                  result: viewModel.result!,
                  onRefresh: () async {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    ref.invalidate(advancedTrackingSummaryProvider);
                    await ref.read(advancedTrackingSummaryProvider.future);
                    AppFeedbackService.instance.emit(AppFeedbackType.success);
                  },
                ),
                AdvancedTrackingViewStatus.failure => _SupportState(
                  icon: Icons.error_outline_rounded,
                  title: 'Nabi chưa tải được lộ trình',
                  message:
                      viewModel.message ?? 'Mình thử lại sau một chút nhé.',
                  actionLabel: 'Thử lại',
                  onAction: () async {
                    AppFeedbackService.instance.emit(
                      AppFeedbackType.primaryAction,
                    );
                    ref.invalidate(advancedTrackingSummaryProvider);
                  },
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyGoalState extends StatelessWidget {
  final AdvancedTrackingRoadmapResult result;
  final String? message;
  final Future<void> Function() onCreate;

  const _EmptyGoalState({
    required this.result,
    required this.onCreate,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _HydrationIntro(result: result),
        const SizedBox(height: AppSpacing.md),
        Text(
          message ?? 'Mình bắt đầu nhẹ nhàng với mục tiêu uống đủ nước nhé.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        FilledButton.icon(
          onPressed: () async => onCreate(),
          icon: const Icon(Icons.water_drop_rounded),
          label: const Text('Bắt đầu mục tiêu nước'),
        ),
      ],
    );
  }
}

class _RoadmapReady extends StatelessWidget {
  final AdvancedTrackingRoadmapResult result;
  final Future<void> Function() onRefresh;

  const _RoadmapReady({required this.result, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _HydrationIntro(result: result),
          const SizedBox(height: AppSpacing.md),
          _ProgressPanel(result: result),
          const SizedBox(height: AppSpacing.md),
          _RoadmapSteps(steps: result.steps),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đây là gợi ý chăm sóc sức khỏe hằng ngày, không thay thế tư vấn y tế.',
            style: AppTextStyles.caption.copyWith(
              color: colors.textHint,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationIntro extends StatelessWidget {
  final AdvancedTrackingRoadmapResult result;

  const _HydrationIntro({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: _panelDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.water_drop_rounded, color: colors.info, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(
            advancedTrackingHydrationGoalName,
            style: AppTextStyles.heading2.copyWith(
              color: colors.textPrimary,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${result.targetMl} ml/ngày, ${result.period.startDate} - ${result.period.endDate}.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final AdvancedTrackingRoadmapResult result;

  const _ProgressPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final percent = (result.progress * 100).round();
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _panelDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ tuần này',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: result.progress.clamp(0, 1).toDouble()),
            duration: AppMotionScope.duration(context, AppDuration.progress),
            curve: AppAnimations.emphasizedCurve,
            builder: (context, progress, _) => LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              backgroundColor: colors.info.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation<Color>(colors.info),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$percent% • ${result.completedDays}/${result.totalDays} ngày • TB ${result.averageWaterMl} ml/ngày.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapSteps extends StatelessWidget {
  final List<AdvancedTrackingRoadmapStep> steps;

  const _RoadmapSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _panelDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Từng ngày một',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final step in steps) _StepRow(step: step),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final AdvancedTrackingRoadmapStep step;

  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final color = step.isComplete ? colors.success : colors.info;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            step.isComplete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.date,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                LinearProgressIndicator(
                  value: step.progress,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  backgroundColor: color.withValues(alpha: .12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${step.waterMl} ml',
            style: AppTextStyles.caption.copyWith(color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

class _SupportState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function()? onAction;

  const _SupportState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colors.info, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                FilledButton(
                  onPressed: onAction == null ? null : () async => onAction!(),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration(AppSemanticColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: colors.border),
  );
}

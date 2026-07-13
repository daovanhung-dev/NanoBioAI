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

    return MedicalPageScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lộ trình nâng cao'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _SupportState(
          icon: Icons.error_outline_rounded,
          title: 'Nabi chưa tải được lộ trình',
          message: 'Mình thử lại sau một chút nhé.',
          actionLabel: 'Thử lại',
          onAction: () async {
            ref.invalidate(advancedTrackingSummaryProvider);
          },
        ),
        data: (viewModel) {
          return switch (viewModel.status) {
            AdvancedTrackingViewStatus.authRequired => _SupportState(
              icon: Icons.lock_outline_rounded,
              title: 'Cần đăng nhập',
              message:
                  viewModel.message ?? 'Bạn cần đăng nhập để xem lộ trình.',
              actionLabel: 'Đăng nhập',
              onAction: () async => context.go(V2RoutePaths.login),
            ),
            AdvancedTrackingViewStatus.locked => _SupportState(
              icon: Icons.workspace_premium_rounded,
              title: 'Chưa mở cho tài khoản này',
              message:
                  viewModel.message ??
                  'Nabi sẽ mở lộ trình nâng cao khi gói của bạn sẵn sàng.',
              actionLabel: 'Làm mới',
              onAction: () async {
                ref.invalidate(advancedTrackingSummaryProvider);
              },
            ),
            AdvancedTrackingViewStatus.empty => _EmptyGoalState(
              result: viewModel.result!,
              message: viewModel.message,
              onCreate: () async {
                await ref.read(advancedTrackingCreateHydrationGoalProvider)();
                await ref.read(advancedTrackingSummaryProvider.future);
              },
            ),
            AdvancedTrackingViewStatus.ready => _RoadmapReady(
              result: viewModel.result!,
              onRefresh: () async {
                ref.invalidate(advancedTrackingSummaryProvider);
                await ref.read(advancedTrackingSummaryProvider.future);
              },
            ),
            AdvancedTrackingViewStatus.failure => _SupportState(
              icon: Icons.error_outline_rounded,
              title: 'Nabi chưa tải được lộ trình',
              message: viewModel.message ?? 'Mình thử lại sau một chút nhé.',
              actionLabel: 'Thử lại',
              onAction: () async {
                ref.invalidate(advancedTrackingSummaryProvider);
              },
            ),
          };
        },
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _HydrationIntro(result: result),
        const SizedBox(height: AppSpacing.md),
        Text(
          message ?? 'Mình bắt đầu nhẹ nhàng với mục tiêu uống đủ nước nhé.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
              color: AppColors.textHint,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.water_drop_rounded, color: AppColors.info, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(
            advancedTrackingHydrationGoalName,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mục tiêu dịu nhẹ: ${result.targetMl} ml mỗi ngày trong giai đoạn ${result.period.startDate} - ${result.period.endDate}.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
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
          LinearProgressIndicator(
            value: result.progress.clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.info.withValues(alpha: .12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$percent% - ${result.completedDays}/${result.totalDays} ngày đạt mục tiêu, trung bình ${result.averageWaterMl} ml/ngày.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.formulaVersion,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
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
    final color = step.isComplete ? AppColors.success : AppColors.info;
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
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: step.progress,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: color.withValues(alpha: .12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${step.waterMl} ml',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
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
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.info, size: 48),
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
                const SizedBox(height: AppSpacing.lg),
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

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
  );
}

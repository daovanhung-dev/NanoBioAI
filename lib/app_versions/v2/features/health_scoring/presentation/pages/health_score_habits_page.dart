import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../domain/entities/health_score_habits_models.dart';
import '../../providers/health_score_habits_providers.dart';

class HealthScoreHabitsPage extends ConsumerWidget {
  const HealthScoreHabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthScoreHabitsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Diem suc khoe'),
      ),
      body: state.when(
        loading: () => const _HealthScoreLoading(),
        error: (_, __) => _HealthScoreSupportState(
          icon: Icons.error_outline_rounded,
          title: 'Chua tai duoc diem suc khoe',
          message: 'Ban thu lai sau it phut.',
          actionLabel: 'Thu lai',
          onAction: () => ref.invalidate(healthScoreHabitsSummaryProvider),
        ),
        data: (viewModel) {
          return switch (viewModel.status) {
            HealthScoreHabitsViewStatus.authRequired =>
              _HealthScoreSupportState(
                icon: Icons.lock_outline_rounded,
                title: 'Can dang nhap',
                message: viewModel.message ?? 'Dang nhap de tiep tuc.',
                actionLabel: 'Dang nhap',
                onAction: () => context.go(V2RoutePaths.login),
              ),
            HealthScoreHabitsViewStatus.empty => _HealthScoreSupportState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Chua co lich su cham soc',
              message:
                  viewModel.message ??
                  'Hoan thanh lich cham soc hang ngay de Nabi tinh diem.',
              actionLabel: 'Lam moi',
              onAction: () => ref.invalidate(healthScoreHabitsSummaryProvider),
            ),
            HealthScoreHabitsViewStatus.failure => _HealthScoreSupportState(
              icon: Icons.error_outline_rounded,
              title: 'Chua tai duoc diem suc khoe',
              message: viewModel.message ?? 'Ban thu lai sau it phut.',
              actionLabel: 'Thu lai',
              onAction: () => ref.invalidate(healthScoreHabitsSummaryProvider),
            ),
            HealthScoreHabitsViewStatus.ready => _HealthScoreReady(
              result: viewModel.result!,
              onRefresh: () async {
                ref.invalidate(healthScoreHabitsSummaryProvider);
                await ref.read(healthScoreHabitsSummaryProvider.future);
              },
            ),
          };
        },
      ),
    );
  }
}

class _HealthScoreLoading extends StatelessWidget {
  const _HealthScoreLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HealthScoreReady extends StatelessWidget {
  final HealthScoreHabitsResult result;
  final Future<void> Function() onRefresh;

  const _HealthScoreReady({required this.result, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _ScoreHeader(result: result),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Thanh phan diem',
            children: result.breakdown
                .map((item) => _BreakdownRow(item: item))
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Tien do thoi quen',
            children: result.habitProgress.isEmpty
                ? const [
                    _EmptyInline(
                      message: 'Chua co thoi quen den han trong giai doan nay.',
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.score.toString(),
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('/100', style: AppTextStyles.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${result.period.startDate} den ${result.period.endDate}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.formulaVersion,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _healthScoreDisclaimer,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final HealthScoreBreakdownItem item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ProgressRow(
      title: item.label,
      subtitle: '${item.completedCount}/${item.totalCount} tin hieu',
      value: item.score / 100,
      trailing: '${item.score}',
    );
  }
}

class _HabitProgressRow extends StatelessWidget {
  final HealthScoreHabitProgressItem item;

  const _HabitProgressRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ProgressRow(
      title: item.label,
      subtitle: '${item.completedCount}/${item.dueCount} da xong',
      value: item.progress.clamp(0, 1).toDouble(),
      trailing: '${(item.progress * 100).round()}%',
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final String trailing;

  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(trailing, style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;

  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _HealthScoreSupportState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _HealthScoreSupportState({
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
                Icon(icon, color: AppColors.primary, size: 48),
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
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
  );
}

const _healthScoreDisclaimer =
    'Diem suc khoe chi de theo doi xu huong cham soc hang ngay, khong thay the chan doan y khoa.';

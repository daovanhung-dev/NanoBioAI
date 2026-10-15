import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/wellness_rank/domain/entities/wellness_rank_summary.dart';
import 'package:nano_app/shared/wellness_rank/providers/wellness_rank_providers.dart';

class WellnessRankCard extends ConsumerWidget {
  const WellnessRankCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(wellnessRankUserIdProvider);
    if (userIdAsync.isLoading) return const _RankLoadingCard();
    final userId = userIdAsync.value?.trim();
    if (userId == null || userId.isEmpty) {
      return _RankGuestCard(
        onLogin: () => context.push(AuthRoutePaths.login),
        onRegister: () => context.push(AuthRoutePaths.register),
      );
    }

    final summaryAsync = ref.watch(wellnessRankSummaryProvider(userId));
    return summaryAsync.when(
      loading: () => const _RankLoadingCard(),
      error: (_, _) => _RankErrorCard(
        onRetry: () => ref.invalidate(wellnessRankSummaryProvider(userId)),
      ),
      data: (summary) => summary == null
          ? _RankErrorCard(
              onRetry: () =>
                  ref.invalidate(wellnessRankSummaryProvider(userId)),
            )
          : _RankSummaryCard(summary: summary),
    );
  }
}

class _RankSummaryCard extends StatelessWidget {
  final WellnessRankSummary summary;

  const _RankSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final progress = summary.rankProgressTarget <= 0
        ? 1.0
        : (summary.rankProgressExp / summary.rankProgressTarget)
              .clamp(0.0, 1.0)
              .toDouble();
    return Card(
      key: const Key('wellness_rank_card'),
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Hạng cá nhân',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('Hạng ${summary.rankLevel}'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary.title,
              key: const Key('wellness_rank_title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${summary.experiencePoints} EXP'),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary.nextRankThreshold == null
                  ? 'Bạn đã đạt hạng cao nhất.'
                  : 'Còn ${summary.experienceToNextRank} EXP để lên hạng tiếp theo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (summary.nextDecayAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lần điều chỉnh EXP tiếp theo: ${_formatDate(summary.nextDecayAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (summary.isStale) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đang hiển thị dữ liệu gần nhất, cập nhật ${_formatDateTime(summary.lastSyncedAt)}.',
                key: const Key('wellness_rank_stale'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankGuestCard extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _RankGuestCard({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('wellness_rank_guest_card'),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theo dõi hạng chăm sóc',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Đăng nhập để lưu EXP và hạng của bạn trên các thiết bị.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(onPressed: onLogin, child: const Text('Đăng nhập')),
                TextButton(
                  onPressed: onRegister,
                  child: const Text('Tạo tài khoản'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankLoadingCard extends StatelessWidget {
  const _RankLoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
    key: Key('wellness_rank_loading_card'),
    elevation: 0,
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      child: LinearProgressIndicator(),
    ),
  );
}

class _RankErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _RankErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('wellness_rank_error_card'),
    elevation: 0,
    child: ListTile(
      leading: const Icon(Icons.sync_problem_rounded),
      title: const Text('Chưa thể cập nhật hạng lúc này'),
      subtitle: const Text('Bạn có thể thử lại sau.'),
      trailing: IconButton(
        onPressed: onRetry,
        tooltip: 'Thử lại',
        icon: const Icon(Icons.refresh_rounded),
      ),
    ),
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year} lúc $hour:$minute';
}

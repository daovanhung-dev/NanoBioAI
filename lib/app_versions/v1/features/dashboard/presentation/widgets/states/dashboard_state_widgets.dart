import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/cloud_sync/cloud_sync.dart';

class DashboardUserDataSyncBanner extends ConsumerWidget {
  final UserDataSyncState state;

  const DashboardUserDataSyncBanner({required this.state, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = state.status == UserDataSyncStatus.pendingUpload;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.semanticColors.warning.withValues(alpha: .28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending ? Icons.cloud_upload_outlined : Icons.cloud_off_outlined,
            color: context.semanticColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              pending
                  ? '${state.pendingCount} thay đổi đang chờ cập nhật. '
                        'Dữ liệu vẫn an toàn trên thiết bị.'
                  : state.safeError ??
                        'Chưa thể cập nhật dữ liệu. Thông tin vẫn được giữ trên thiết bị.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: () =>
                ref.read(userDataSyncControllerProvider.notifier).retry(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class DashboardSyncBanner extends StatelessWidget {
  const DashboardSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Nabi đang cập nhật những tín hiệu mới nhất...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardInlineErrorBanner extends StatelessWidget {
  final String message;

  const DashboardInlineErrorBanner({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      borderColor: context.semanticColors.error.withValues(alpha: .18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.semanticColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _Skeleton(height: 120),
            SizedBox(height: AppSpacing.md),
            _Skeleton(height: 188),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _Skeleton(height: 88)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _Skeleton(height: 88)),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _Skeleton(height: 88)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _Skeleton(height: 88)),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _Skeleton(height: 176),
          ],
        ),
      ),
    );
  }
}

class DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DashboardErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.semanticColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: context.semanticColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chưa thể mở trang chủ',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.semanticColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateSurface extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _StateSurface({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor ?? context.semanticColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;

  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.semanticColors.primarySoft.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

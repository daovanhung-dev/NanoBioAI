import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';

class SchedulePageFrame extends StatelessWidget {
  const SchedulePageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: false, child: child);
  }
}

class ScheduleLoadingState extends StatelessWidget {
  const ScheduleLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppCard(
            variant: CardVariant.outlined,
            padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingState(variant: LoadingVariant.spinner),
                const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
                Text(
                  'Nabi đang chuẩn bị lịch trình của bạn...',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleErrorState extends StatelessWidget {
  const ScheduleErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AppCard(
            variant: CardVariant.outlined,
            padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
            child: ErrorState(
              message:
                  'Nabi chưa mở được lịch trình. Bạn kiểm tra kết nối rồi thử lại nhé.',
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/design_system.dart';

class ScheduleRegenerationCard extends StatelessWidget {
  const ScheduleRegenerationCard({
    super.key,
    required this.remainingDays,
    required this.isLoading,
    required this.hasError,
    required this.isGenerating,
    required this.onGenerate,
  });

  final int? remainingDays;
  final bool isLoading;
  final bool hasError;
  final bool isGenerating;
  final VoidCallback onGenerate;

  bool get _canGenerate =>
      remainingDays != null &&
      remainingDays! < 2 &&
      !isLoading &&
      !hasError &&
      !isGenerating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      key: const ValueKey('schedule-regeneration-card'),
      variant: CardVariant.defaultCard,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColorTokens.primary.withValues(alpha: .12),
                foregroundColor: AppColorTokens.primary,
                child: const Icon(Icons.auto_awesome_rounded),
              ),
              const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch trình tiếp theo',
                      style: AppTextStyles.heading4.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacingTokens.itemSpacing),
                    Text(
                      _statusMessage(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          FilledButton.icon(
            key: const ValueKey('schedule-regeneration-button'),
            onPressed: _canGenerate ? onGenerate : null,
            icon: isGenerating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              isGenerating ? 'Nabi đang tạo lịch...' : 'Tạo lịch trình mới',
            ),
          ),
          if (!isLoading &&
              !hasError &&
              remainingDays != null &&
              remainingDays! >= 2) ...[
            const SizedBox(height: AppSpacingTokens.itemSpacing),
            Text(
              'Nút sẽ mở khi lịch hiện tại còn dưới 2 ngày.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusMessage() {
    if (isLoading) {
      return 'Nabi đang kiểm tra thời gian còn lại của lịch hiện tại.';
    }
    if (hasError) {
      return 'Nabi chưa đọc được thời gian còn lại. Bạn kéo xuống để thử lại nhé.';
    }

    final days = remainingDays;
    if (days != null && days < 2) {
      return days == 1
          ? 'Lịch hiện tại chỉ còn 1 ngày. Bạn có thể tạo lịch trình mới cho 7 ngày tiếp theo.'
          : 'Lịch hiện tại đã hết ngày. Bạn có thể tạo lịch trình mới ngay bây giờ.';
    }
    if (days != null) {
      return 'Lịch hiện tại còn $days ngày. Mình tiếp tục theo lịch này trước nhé.';
    }
    return 'Nabi chưa xác định được thời gian còn lại. Bạn kéo xuống để kiểm tra lại nhé.';
  }
}

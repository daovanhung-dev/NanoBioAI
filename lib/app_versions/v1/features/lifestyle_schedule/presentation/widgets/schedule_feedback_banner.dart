import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../providers/lifestyle_schedule_provider.dart';

class ScheduleEncouragementBanner extends ConsumerWidget {
  const ScheduleEncouragementBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ScheduleBanner(
      icon: Icons.favorite_rounded,
      color: AppColorTokens.success,
      backgroundColor: AppColorTokens.success.withValues(alpha: .08),
      message: vietnameseSystemUiText(
        message,
        fallback: 'Bạn vừa hoàn thành thêm một mốc chăm sóc.',
      ),
      semanticsLabel: 'Lời nhắn của Nabi',
      onDismiss: () => ref
          .read(lifestyleScheduleControllerProvider.notifier)
          .dismissEncouragement(),
    );
  }
}

class ScheduleActionErrorBanner extends ConsumerWidget {
  const ScheduleActionErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ScheduleBanner(
      icon: Icons.info_outline_rounded,
      color: AppColorTokens.warning,
      backgroundColor: AppColorTokens.warning.withValues(alpha: .08),
      message: vietnameseSystemUiText(
        message,
        fallback: 'Nabi chưa thể cập nhật nhiệm vụ lúc này. Bạn thử lại nhé.',
      ),
      semanticsLabel: 'Thông báo lịch trình',
      onDismiss: () => ref
          .read(lifestyleScheduleControllerProvider.notifier)
          .dismissError(),
    );
  }
}

class _ScheduleBanner extends StatelessWidget {
  const _ScheduleBanner({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.message,
    required this.semanticsLabel,
    required this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String message;
  final String semanticsLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: AnimatedContainer(
        duration: AppMotionScope.duration(context, AppMotionTokens.card),
        curve: AppMotionTokens.defaultCurve,
        padding: const EdgeInsets.all(AppSpacingTokens.itemSpacingLarge),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

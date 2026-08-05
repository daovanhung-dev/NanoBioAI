import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class HeaderStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const HeaderStatPill({
    required this.icon,
    required this.label,
    this.active = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: active ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: active ? 0.4 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.surface, size: 13),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.surface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

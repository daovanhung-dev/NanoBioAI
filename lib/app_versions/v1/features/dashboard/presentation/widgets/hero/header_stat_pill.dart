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
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(
          color: Colors.white.withValues(alpha: active ? 0.4 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

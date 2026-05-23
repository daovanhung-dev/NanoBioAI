import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class ScoreMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ScoreMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}

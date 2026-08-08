import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

class DashboardError extends StatelessWidget {
  final String error;

  const DashboardError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.semanticColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: context.semanticColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.heading3.copyWith(
                color: context.semanticColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.semanticColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

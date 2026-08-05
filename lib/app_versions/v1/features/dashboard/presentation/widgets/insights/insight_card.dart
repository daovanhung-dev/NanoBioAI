import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../enums/insight_type.dart';
import 'insight_data.dart';

class InsightCard extends StatelessWidget {
  final InsightData data;

  const InsightCard({required this.data, super.key});

  Color get _accentColor {
    switch (data.type) {
      case InsightType.recommendation:
        return AppColors.primary;
      case InsightType.warning:
        return AppColors.warning;
      case InsightType.tip:
        return AppColors.tertiary;
    }
  }

  Color get _bgColor {
    switch (data.type) {
      case InsightType.recommendation:
        return AppColors.primarySoft;
      case InsightType.warning:
        return AppColors.warningSoft;
      case InsightType.tip:
        return AppColors.tertiarySoft;
    }
  }

  List<Color> get _gradientColors {
    switch (data.type) {
      case InsightType.recommendation:
        return const [AppColors.primaryDark, AppColors.primary];
      case InsightType.warning:
        return const [AppColors.error, AppColors.warning];
      case InsightType.tip:
        return const [AppColors.tertiary, AppColors.tertiary];
    }
  }

  String get _typeLabel {
    switch (data.type) {
      case InsightType.recommendation:
        return 'Nabi';
      case InsightType.warning:
        return 'Lưu ý';
      case InsightType.tip:
        return 'Gợi ý';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: AppColors.surface, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        _typeLabel,
                        style: AppTextStyles.overline.copyWith(
                          color: _accentColor,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

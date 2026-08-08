import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../enums/insight_type.dart';
import 'insight_data.dart';

class InsightCard extends StatelessWidget {
  final InsightData data;

  const InsightCard({required this.data, super.key});

  Color _accentColor(AppSemanticColors colors) {
    switch (data.type) {
      case InsightType.recommendation:
        return colors.primary;
      case InsightType.warning:
        return colors.warning;
      case InsightType.tip:
        return colors.tertiary;
    }
  }

  Color _bgColor(AppSemanticColors colors) {
    switch (data.type) {
      case InsightType.recommendation:
        return colors.primarySoft;
      case InsightType.warning:
        return colors.warningSoft;
      case InsightType.tip:
        return colors.tertiarySoft;
    }
  }

  List<Color> _gradientColors(AppSemanticColors colors) {
    switch (data.type) {
      case InsightType.recommendation:
        return [colors.primaryDark, colors.primary];
      case InsightType.warning:
        return [colors.error, colors.warning];
      case InsightType.tip:
        return [colors.tertiary, colors.tertiary];
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
    final colors = context.semanticColors;
    final accentColor = _accentColor(colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors(colors),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: colors.textInverse, size: 20),
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
                        color: colors.textPrimary,
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
                        color: _bgColor(colors),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        _typeLabel,
                        style: AppTextStyles.overline.copyWith(
                          color: accentColor,
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
                    color: colors.textSecondary,
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

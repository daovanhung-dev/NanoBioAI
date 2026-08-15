import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';
import 'package:nano_app/core/theme/theme.dart';

class MealPhoto extends StatelessWidget {
  const MealPhoto({
    super.key,
    required this.meal,
    this.height = 164,
    this.borderRadius = AppRadius.xl,
  });

  final MealPlanEntity meal;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final assetPath = MealImageResolver.assetPathFor(meal);
    final radius = BorderRadius.circular(borderRadius);

    return Semantics(
      image: true,
      label: 'Ảnh món ${meal.mealName}',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _MealPhotoFallback(
              mealName: meal.mealName,
            ),
          ),
        ),
      ),
    );
  }
}

class _MealPhotoFallback extends StatelessWidget {
  const _MealPhotoFallback({required this.mealName});

  final String mealName;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.semanticColors.primarySoft,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  color: context.semanticColors.primary,
                  size: 34,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Chưa có ảnh món ăn',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

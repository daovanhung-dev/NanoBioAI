import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';
import 'package:nano_app/core/theme/theme.dart';

class MealPhoto extends StatelessWidget {
  const MealPhoto({
    super.key,
    required this.meal,
    this.height = 164,
    this.width,
    this.borderRadius = AppRadius.xl,
  }) : catalogCode = null,
       mealName = null;

  const MealPhoto.catalogItem({
    super.key,
    required this.catalogCode,
    required this.mealName,
    this.height = 164,
    this.width,
    this.borderRadius = AppRadius.xl,
  }) : meal = null;

  final MealPlanEntity? meal;
  final String? catalogCode;
  final String? mealName;
  final double height;
  final double? width;
  final double borderRadius;

  String get _resolvedCode => meal?.catalogCode ?? catalogCode ?? '';
  String get _resolvedMealName => meal?.mealName ?? mealName ?? '';

  @override
  Widget build(BuildContext context) {
    final assetPathsFuture = MealImageResolver.assetPathsForCatalogItem(
      catalogCode: _resolvedCode,
      mealName: _resolvedMealName,
    );
    final radius = BorderRadius.circular(borderRadius);

    return FutureBuilder<List<String>>(
      future: assetPathsFuture,
      builder: (context, snapshot) {
        final assetPaths = snapshot.data;
        if (snapshot.hasError || assetPaths == null || assetPaths.isEmpty) {
          return _buildFramedPhoto(
            radius: radius,
            child: _MealPhotoFallback(mealName: _resolvedMealName),
          );
        }

        return Semantics(
          image: true,
          label: 'Ảnh món $_resolvedMealName',
          child: _buildFramedPhoto(
            radius: radius,
            child: _buildImageCandidate(assetPaths, 0),
          ),
        );
      },
    );
  }

  Widget _buildImageCandidate(List<String> assetPaths, int index) {
    return Image.asset(
      assetPaths[index],
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        final nextIndex = index + 1;
        if (nextIndex < assetPaths.length) {
          return _buildImageCandidate(assetPaths, nextIndex);
        }
        return _MealPhotoFallback(mealName: _resolvedMealName);
      },
    );
  }

  Widget _buildFramedPhoto({
    required BorderRadius radius,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: child,
      ),
    );
  }
}

class _MealPhotoFallback extends StatelessWidget {
  const _MealPhotoFallback({required this.mealName});

  final String mealName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chưa có ảnh món $mealName',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: context.semanticColors.primarySoft),
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
      ),
    );
  }
}

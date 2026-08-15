#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

PAGE = Path('lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart')
RESOLVER = Path('lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart')
TEST = Path('test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart')

IMPORT_ANCHOR = (
    "import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';\n"
)
IMPORT_LINE = (
    "import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';\n"
)

CARD_ANCHOR = """                          children: [
                            // Header row
"""
CARD_REPLACEMENT = """                          children: [
                            _MealPhoto(meal: meal),

                            SizedBox(height: ui.cardGap),

                            // Header row
"""

DETAIL_ANCHOR = """                children: [
                  Row(
"""
DETAIL_REPLACEMENT = """                children: [
                  _MealPhoto(meal: meal, radius: AppRadius.xl),
                  const SizedBox(height: AppSpacing.md),

                  Row(
"""

PHOTO_WIDGETS = r'''
class _MealPhoto extends StatelessWidget {
  const _MealPhoto({
    required this.meal,
    this.aspectRatio = 16 / 9,
    this.radius = AppRadius.lg,
  });

  final MealPlanEntity meal;
  final double aspectRatio;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final assetPath = MealImageResolver.resolveAssetPath(meal.mealName);

    return Semantics(
      image: assetPath != null,
      label: assetPath == null ? null : 'Hình ảnh món ${meal.mealName}',
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: assetPath == null
              ? _MealPhotoPlaceholder(mealName: meal.mealName)
              : Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) =>
                      _MealPhotoPlaceholder(mealName: meal.mealName),
                ),
        ),
      ),
    );
  }
}

class _MealPhotoPlaceholder extends StatelessWidget {
  const _MealPhotoPlaceholder({required this.mealName});

  final String mealName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.semanticColors.primarySoft,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_rounded,
            color: context.semanticColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chưa có ảnh cho $mealName',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

'''
DETAIL_CLASS_ANCHOR = 'class _MealDetailSheet extends StatefulWidget {'


def replace_exact_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f'{label}: expected exactly one source anchor, found {count}. '
            'The repository source may have changed; no ambiguous edit was made.'
        )
    return text.replace(old, new, 1)


def apply_page_changes(page: Path) -> None:
    text = page.read_text(encoding='utf-8')
    original = text

    if IMPORT_LINE not in text:
        text = replace_exact_once(
            text,
            IMPORT_ANCHOR,
            IMPORT_ANCHOR + IMPORT_LINE,
            'resolver import',
        )

    if '_MealPhoto(meal: meal),' not in text:
        text = replace_exact_once(
            text,
            CARD_ANCHOR,
            CARD_REPLACEMENT,
            'meal-card image',
        )

    if 'class _MealPhoto extends StatelessWidget' not in text:
        text = replace_exact_once(
            text,
            DETAIL_CLASS_ANCHOR,
            PHOTO_WIDGETS + DETAIL_CLASS_ANCHOR,
            'meal-photo widgets',
        )

    detail_state_marker = 'class _MealDetailSheetState extends State<_MealDetailSheet> {'
    detail_pos = text.find(detail_state_marker)
    if detail_pos < 0:
        raise RuntimeError('meal-detail state class was not found')
    prefix, detail = text[:detail_pos], text[detail_pos:]
    if '_MealPhoto(meal: meal, radius: AppRadius.xl)' not in detail:
        detail = replace_exact_once(
            detail,
            DETAIL_ANCHOR,
            DETAIL_REPLACEMENT,
            'meal-detail hero image',
        )
        text = prefix + detail

    if text != original:
        page.write_text(text, encoding='utf-8')
        print(f'updated {page}')
    else:
        print(f'already patched {page}')


def copy_new_files(bundle_root: Path, repo_root: Path) -> None:
    for relative in (RESOLVER, TEST):
        source = bundle_root / relative
        destination = repo_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        print(f'copied {destination}')


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Apply the NanoBio Meal Plan exact health-book image integration.'
    )
    parser.add_argument(
        'repo_root',
        nargs='?',
        default='.',
        help='NanoBioAI repository root (default: current directory)',
    )
    args = parser.parse_args()

    bundle_root = Path(__file__).resolve().parent
    repo_root = Path(args.repo_root).resolve()
    page = repo_root / PAGE
    if not page.is_file():
        raise SystemExit(f'NanoBio Meal Plan page not found: {page}')

    apply_page_changes(page)
    copy_new_files(bundle_root, repo_root)
    print('Meal Plan exact-image integration applied successfully.')


if __name__ == '__main__':
    main()

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart';

const _sourcePath =
    'docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md';
const _mealAssetRoot = 'assets/images/meals/pdf_health_book';

void main() {
  test('all source recipes resolve to non-empty bundled WebP assets', () {
    final source = File(_sourcePath);
    expect(source.existsSync(), isTrue, reason: _sourcePath);

    final recipeNames = source
        .readAsLinesSync()
        .where((line) => line.trimLeft().startsWith('#### '))
        .map(_recipeTitleFromHeading)
        .toList(growable: false);

    // Source contract documented by the canonical Markdown and SQL sync tool.
    expect(recipeNames.length, 163);

    final missing = <String>[];
    final canonicalSlugs = <String>{};
    final resolvedAssetPaths = <String>{};

    for (final recipeName in recipeNames) {
      final slug = MealImageResolver.canonicalSlug(recipeName);
      canonicalSlugs.add(slug);

      final assetPath = MealImageResolver.resolveAssetPath(recipeName);
      if (assetPath == null) {
        missing.add('$recipeName -> resolver:null');
        continue;
      }

      final image = File(assetPath);
      if (!image.existsSync()) {
        missing.add('$recipeName -> $assetPath (missing)');
        continue;
      }
      if (image.lengthSync() <= 0) {
        missing.add('$recipeName -> $assetPath (empty)');
        continue;
      }
      resolvedAssetPaths.add(assetPath);
    }

    expect(
      missing,
      isEmpty,
      reason: 'Every canonical recipe must have an exact local image:\n'
          '${missing.join('\n')}',
    );
    expect(resolvedAssetPaths.length, canonicalSlugs.length);
  });

  test('pubspec explicitly bundles the nested meal image directory', () {
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue);
    expect(
      pubspec.readAsStringSync(),
      contains('    - $_mealAssetRoot/'),
    );
  });
}

String _recipeTitleFromHeading(String line) {
  final heading = line.trim().substring('#### '.length).trim();
  return heading
      .replaceFirst(RegExp(r'^\d+\s*[.\-:]?\s*'), '')
      .trim();
}

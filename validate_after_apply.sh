#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

dart format \
  lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart \
  lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart \
  test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart

flutter analyze lib/app_versions/v1/features/meal_plan
flutter test test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart

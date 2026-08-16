#!/usr/bin/env python3
"""Validate NanoBio meal source -> SQL -> local-image synchronization.

Run from the repository root:

    python tools/validate_meal_sync.py

The validator is intentionally read-only. It reuses the canonical Markdown
parser/SQL renderer from sync_meal_catalog_sql.py, then proves that every
canonical recipe name resolves to a non-empty WebP file allowed by the Dart
MealImageResolver and that Flutter explicitly bundles the nested asset folder.
"""
from __future__ import annotations

import re
from pathlib import Path

from sync_meal_catalog_sql import build_seed, parse_markdown, slugify

SOURCE = Path("docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md")
SEED = Path("docs/supabase/seed_data.sql")
ASSET_ROOT = Path("assets/images/meals/pdf_health_book")
RESOLVER = Path(
    "lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart"
)
PUBSPEC = Path("pubspec.yaml")
EXPECTED_RECIPES = 163
PUBSPEC_ASSET_ENTRY = "    - assets/images/meals/pdf_health_book/"


def _resolver_asset_files(source: str) -> set[str]:
    match = re.search(
        r"_knownAssetFiles\s*=\s*<String>\{(?P<body>.*?)\n\s*\};",
        source,
        flags=re.S,
    )
    if match is None:
        raise ValueError("Cannot locate MealImageResolver._knownAssetFiles")
    return set(re.findall(r"'([^']+\.webp)'", match.group("body")))


def main() -> None:
    required = (SOURCE, SEED, ASSET_ROOT, RESOLVER, PUBSPEC)
    missing_paths = [str(path) for path in required if not path.exists()]
    if missing_paths:
        raise SystemExit("Missing required paths:\n- " + "\n- ".join(missing_paths))

    recipes = parse_markdown(SOURCE)
    if len(recipes) != EXPECTED_RECIPES:
        raise SystemExit(
            f"Recipe count mismatch: expected {EXPECTED_RECIPES}, found {len(recipes)}"
        )

    seed_text = SEED.read_text(encoding="utf-8")
    canonical_seed = build_seed(seed_text, recipes)
    if canonical_seed != seed_text:
        raise SystemExit(
            "seed_data.sql is out of sync with the canonical Markdown. "
            "Run: python tools/sync_meal_catalog_sql.py"
        )

    expected_assets = {f"{slugify(recipe.meal_name)}.webp" for recipe in recipes}
    disk_assets = {
        path.name for path in ASSET_ROOT.iterdir() if path.is_file() and path.suffix.lower() == ".webp"
    }
    resolver_assets = _resolver_asset_files(RESOLVER.read_text(encoding="utf-8"))

    missing_on_disk = sorted(expected_assets - disk_assets)
    missing_in_resolver = sorted(expected_assets - resolver_assets)
    resolver_missing_on_disk = sorted(resolver_assets - disk_assets)
    empty_assets = sorted(
        path.name
        for path in ASSET_ROOT.iterdir()
        if path.is_file() and path.suffix.lower() == ".webp" and path.stat().st_size <= 0
    )

    errors: list[str] = []
    if missing_on_disk:
        errors.append("Canonical recipes missing WebP files: " + ", ".join(missing_on_disk))
    if missing_in_resolver:
        errors.append(
            "Canonical recipes missing resolver allow-list entries: "
            + ", ".join(missing_in_resolver)
        )
    if resolver_missing_on_disk:
        errors.append(
            "Resolver references missing WebP files: " + ", ".join(resolver_missing_on_disk)
        )
    if empty_assets:
        errors.append("Empty WebP files: " + ", ".join(empty_assets))

    pubspec_text = PUBSPEC.read_text(encoding="utf-8")
    if PUBSPEC_ASSET_ENTRY not in pubspec_text:
        errors.append(
            "pubspec.yaml does not explicitly bundle assets/images/meals/pdf_health_book/"
        )

    if errors:
        raise SystemExit("Meal synchronization validation failed:\n- " + "\n- ".join(errors))

    print(
        "PASS meal synchronization: "
        f"{len(recipes)} recipe entries / "
        f"{len(expected_assets)} canonical image names / "
        f"{len(disk_assets)} WebP assets"
    )


if __name__ == "__main__":
    main()

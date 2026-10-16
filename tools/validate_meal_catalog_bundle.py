#!/usr/bin/env python3
"""Validate a reviewed, licensed meal-catalog package before integration."""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
from pathlib import Path
from urllib.parse import urlparse

REQUIRED_RECIPE_FIELDS = {
    "code",
    "meal_type",
    "meal_name",
    "description",
    "ingredients",
    "cooking_steps",
    "benefits",
    "serving_size",
    "calories",
    "protein",
    "carbs",
    "fat",
    "fiber",
    "water_ml",
    "allergen_tags",
    "avoid_condition_tags",
    "nutrition_status",
    "metadata_status",
    "is_plan_eligible",
    "source_name",
    "source_page",
    "source_hash",
    "version",
    "is_active",
}
REQUIRED_NEW_RECIPE_FIELDS = {
    "allergen_verification_status",
    "allergen_evidence_source",
    "nutrition_evidence_source",
    "nutrition_evidence_date",
    "nutrition_evidence_version",
    "nutrition_food_ids",
    "verified_nutrients",
    "constraint_metadata_status",
    "serving_size",
}
REQUIRED_TEXT_FIELDS = {
    "meal_name",
    "description",
    "benefits",
    "nutrition_status",
    "metadata_status",
    "source_name",
}
REQUIRED_NUTRIENT_FIELDS = {
    "calories",
    "protein",
    "carbs",
    "fat",
    "fiber",
    "water_ml",
}
REQUIRED_RIGHTS_FIELDS = {
    "code",
    "recipe_source_url",
    "recipe_license",
    "recipe_attribution",
    "nutrition_source_url",
    "nutrition_evidence_date",
    "nutrition_evidence_version",
}
SAFE_CODE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]{0,179}$")
SHA256 = re.compile(r"^[a-fA-F0-9]{64}$")
MEAL_TYPES = {
    "breakfast",
    "morning_snack",
    "lunch",
    "afternoon_snack",
    "dinner",
}


def _is_http_url(value: str) -> bool:
    parsed = urlparse(value.strip())
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def _load_rights(path: Path, errors: list[str]) -> dict[str, dict[str, str]]:
    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            headers = set(reader.fieldnames or [])
            missing = REQUIRED_RIGHTS_FIELDS.difference(headers)
            if missing:
                errors.append(f"rights CSV missing columns: {sorted(missing)}")
                return {}
            rights: dict[str, dict[str, str]] = {}
            for row_number, row in enumerate(reader, start=2):
                code = (row.get("code") or "").strip()
                if not code:
                    errors.append(f"rights CSV row {row_number} has no code")
                    continue
                if code in rights:
                    errors.append(f"duplicate rights CSV code: {code}")
                    continue
                rights[code] = {
                    key: (row.get(key) or "").strip()
                    for key in REQUIRED_RIGHTS_FIELDS
                }
                for field in (
                    "recipe_source_url",
                    "nutrition_source_url",
                ):
                    if not _is_http_url(rights[code][field]):
                        errors.append(
                            f"rights CSV row {row_number} has invalid {field}"
                        )
                for field in (
                    "recipe_license",
                    "recipe_attribution",
                    "nutrition_evidence_date",
                    "nutrition_evidence_version",
                ):
                    if not rights[code][field]:
                        errors.append(
                            f"rights CSV row {row_number} has empty {field}"
                        )
            return rights
    except (OSError, csv.Error) as error:
        errors.append(f"cannot read rights CSV {path}: {error}")
        return {}


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check catalog identity, review status, nutrition evidence, "
            "and per-recipe recipe/nutrition rights."
        )
    )
    parser.add_argument("catalog", type=Path)
    parser.add_argument("--rights-csv", type=Path, required=True)
    parser.add_argument("--license-dir", type=Path, required=True)
    parser.add_argument("--base-catalog", type=Path, default=Path("assets/data/meal_catalog_v1.json"))
    parser.add_argument("--expected-new-count", type=int, default=3000)
    parser.add_argument("--expected-total-count", type=int, default=3163)
    args = parser.parse_args()

    errors: list[str] = []
    try:
        payload = json.loads(args.catalog.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"cannot read candidate catalog: {error}") from error
    if not isinstance(payload, dict):
        raise SystemExit("catalog root must be an object")
    recipes = payload.get("recipes")
    if not isinstance(recipes, list):
        raise SystemExit("catalog recipes must be a list")
    if len(recipes) != args.expected_total_count:
        errors.append(
            f"expected exactly {args.expected_total_count} merged recipes, found {len(recipes)}"
        )

    base_codes: set[str] = set()
    try:
        base_payload = json.loads(args.base_catalog.read_text(encoding="utf-8"))
        base_recipes = base_payload.get("recipes", [])
        base_codes = {
            row["code"]
            for row in base_recipes
            if isinstance(row, dict) and isinstance(row.get("code"), str)
        }
    except (OSError, json.JSONDecodeError, AttributeError) as error:
        errors.append(f"cannot read base catalog {args.base_catalog}: {error}")

    codes: set[str] = set()
    recipe_rows: dict[str, dict[str, object]] = {}
    for index, recipe in enumerate(recipes):
        if not isinstance(recipe, dict):
            errors.append(f"recipe row {index + 1} is not an object")
            continue
        code_value = recipe.get("code")
        code = code_value.strip() if isinstance(code_value, str) else ""
        is_new_recipe = code not in base_codes
        required_fields = REQUIRED_RECIPE_FIELDS | (
            REQUIRED_NEW_RECIPE_FIELDS if is_new_recipe else set()
        )
        missing = required_fields.difference(recipe)
        if missing:
            errors.append(f"recipe row {index + 1} missing fields: {sorted(missing)}")
        if not SAFE_CODE.fullmatch(code):
            errors.append(f"recipe row {index + 1} has an unsafe or empty code")
            continue
        if code in codes:
            errors.append(f"duplicate recipe code: {code}")
        codes.add(code)
        recipe_rows[code] = recipe

        meal_type = recipe.get("meal_type")
        if is_new_recipe and meal_type not in MEAL_TYPES:
            errors.append(f"{code} has unsupported meal_type: {meal_type!r}")
        required_text_fields = REQUIRED_TEXT_FIELDS | (
            {"serving_size"} if is_new_recipe else set()
        )
        for field in required_text_fields:
            value = recipe.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{code} has empty or invalid {field}")
        for field in ("ingredients", "cooking_steps"):
            values = recipe.get(field)
            if (
                not isinstance(values, list)
                or not values
                or any(not isinstance(value, str) or not value.strip() for value in values)
            ):
                errors.append(f"{code} has incomplete {field}")
        for field in ("allergen_tags", "avoid_condition_tags"):
            values = recipe.get(field)
            if not isinstance(values, list) or any(
                not isinstance(value, str) or not value.strip() for value in values
            ):
                errors.append(f"{code} has invalid {field}")
        for field in ("is_plan_eligible", "is_active"):
            if not isinstance(recipe.get(field), bool):
                errors.append(f"{code} has invalid {field}")
        if is_new_recipe:
            for field in REQUIRED_NUTRIENT_FIELDS:
                value = recipe.get(field)
                if (
                    isinstance(value, bool)
                    or not isinstance(value, (int, float))
                    or not math.isfinite(value)
                    or value < 0
                ):
                    errors.append(f"{code} has missing or invalid nutrient {field}")
                elif field in {"calories", "water_ml"} and not isinstance(value, int):
                    errors.append(f"{code} nutrient {field} must be an integer")
            if recipe.get("is_active") is not True:
                errors.append(f"{code} is not active")
            if recipe.get("is_plan_eligible") is not True:
                errors.append(f"{code} is not plan eligible")
            if recipe.get("metadata_status") != "source_verified":
                errors.append(f"{code} metadata is not source_verified")
            if recipe.get("nutrition_status") != "verified":
                errors.append(f"{code} nutrition is not verified")
            if recipe.get("constraint_metadata_status") != "verified":
                errors.append(f"{code} constraint metadata is not verified")
            if recipe.get("allergen_verification_status") not in {
                "verified_none",
                "verified_present",
            }:
                errors.append(f"{code} allergen metadata is not verified")
            for field in (
                "allergen_evidence_source",
                "nutrition_evidence_source",
                "nutrition_evidence_date",
                "nutrition_evidence_version",
            ):
                value = recipe.get(field)
                if not isinstance(value, str) or not value.strip():
                    errors.append(f"{code} has empty or invalid {field}")
            nutrition_food_ids = recipe.get("nutrition_food_ids")
            if not isinstance(nutrition_food_ids, list) or not nutrition_food_ids:
                errors.append(f"{code} has no nutrition food evidence IDs")
            verified_nutrients = recipe.get("verified_nutrients")
            if not isinstance(verified_nutrients, dict) or not verified_nutrients:
                errors.append(f"{code} has no verified nutrient profile")
        source_hash = recipe.get("source_hash")
        if not isinstance(source_hash, str) or not SHA256.fullmatch(source_hash):
            errors.append(f"{code} has invalid source_hash")

    missing_base_codes = base_codes.difference(codes)
    if missing_base_codes:
        errors.append(
            f"candidate catalog dropped {len(missing_base_codes)} existing codes"
        )

    new_codes = codes.difference(base_codes)
    if len(new_codes) != args.expected_new_count:
        errors.append(
            f"expected exactly {args.expected_new_count} new codes, found {len(new_codes)}"
        )
    rights = _load_rights(args.rights_csv, errors)
    missing_rights = new_codes.difference(rights)
    unknown_rights = set(rights).difference(new_codes)
    if missing_rights:
        errors.append(f"rights CSV missing {len(missing_rights)} recipe codes")
    if unknown_rights:
        errors.append(f"rights CSV has {len(unknown_rights)} unknown recipe codes")

    if not args.license_dir.is_dir() or not any(
        path.is_file() and path.stat().st_size > 0
        for path in args.license_dir.rglob("*")
    ):
        errors.append(f"license evidence directory is empty: {args.license_dir}")

    statistics = payload.get("statistics")
    if isinstance(statistics, dict) and statistics.get("recipe_count") != len(recipes):
        errors.append("statistics.recipe_count does not match recipes length")

    if errors:
        print(f"FAIL: {len(errors)} catalog-package issue(s)")
        for error in errors[:100]:
            print(f"- {error}")
        if len(errors) > 100:
            print(f"- ... {len(errors) - 100} additional issue(s)")
        return 1

    print(
        f"PASS: {len(recipes)} recipes, {len(codes)} unique codes, "
        f"{len(new_codes)} reviewed new recipes, complete nutrition evidence, "
        "and recipe/nutrition rights"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

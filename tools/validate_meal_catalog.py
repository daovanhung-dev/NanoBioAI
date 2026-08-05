#!/usr/bin/env python3
"""Validate the generated source recipe catalog without Flutter tooling."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

REQUIRED_KEYS = {
    "code",
    "meal_type",
    "meal_name",
    "health_topic_code",
    "health_topic_name",
    "ingredients",
    "cooking_steps",
    "benefits",
    "metadata_status",
    "is_plan_eligible",
    "source_name",
    "source_page",
    "source_hash",
    "version",
    "is_active",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("catalog", type=Path, nargs="?", default=Path("assets/data/meal_catalog_v1.json"))
    parser.add_argument("--source", type=Path, default=Path("docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md"))
    args = parser.parse_args()

    payload = json.loads(args.catalog.read_text(encoding="utf-8"))
    recipes = payload.get("recipes")
    if not isinstance(recipes, list):
        raise SystemExit("recipes must be a list")
    if len(recipes) != 163:
        raise SystemExit(f"expected 163 recipes, found {len(recipes)}")
    topics = {recipe["health_topic_code"] for recipe in recipes}
    if len(topics) != 64:
        raise SystemExit(f"expected 64 topics, found {len(topics)}")
    codes = [recipe["code"] for recipe in recipes]
    if len(codes) != len(set(codes)):
        raise SystemExit("recipe codes are not unique")
    for index, recipe in enumerate(recipes):
        missing = REQUIRED_KEYS.difference(recipe)
        if missing:
            raise SystemExit(f"recipe {index} missing keys: {sorted(missing)}")
        if not recipe["ingredients"] or not recipe["cooking_steps"] or not recipe["benefits"]:
            raise SystemExit(f"recipe {recipe['code']} has incomplete source content")
        if recipe["is_plan_eligible"]:
            raise SystemExit(f"unapproved source recipe unexpectedly eligible: {recipe['code']}")
        if recipe["meal_type"] != "unclassified":
            raise SystemExit(f"meal type was inferred for {recipe['code']}")
        if any(recipe[field] is not None for field in ("calories", "protein", "carbs", "fat", "fiber", "water_ml")):
            raise SystemExit(f"nutrition data was inferred for {recipe['code']}")
    source_hash = hashlib.sha256(args.source.read_bytes()).hexdigest()
    if payload.get("source_sha256") != source_hash:
        raise SystemExit("source SHA-256 does not match")
    print(f"PASS: {len(recipes)} recipes, {len(topics)} topics, source fidelity verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

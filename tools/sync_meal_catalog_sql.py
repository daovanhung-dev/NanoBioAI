#!/usr/bin/env python3
"""Synchronize docs/supabase/seed_data.sql meal source rows with the canonical Markdown.

This tool is deliberately source-faithful. It never infers nutrition, allergens,
meal type, serving size, or contraindications. NanoBio's SQL/SQLite contract uses
zero as a technical sentinel for unavailable numeric nutrition values; the rows
remain explicitly marked nutrition_status='missing_source_data' and
is_plan_eligible=false.

Default paths assume execution from the NanoBioAI repository root.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

SOURCE_NAME = "Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md"
DEFAULT_SOURCE = Path("docs/note") / SOURCE_NAME
DEFAULT_SEED = Path("docs/supabase/seed_data.sql")
EXPECTED_RECIPES = 163
EXPECTED_TOPICS = 64
EXPECTED_CHAPTERS = 11

CHAPTER_RE = re.compile(r"^##\s+Chương\s+(?P<number>\d+)\s*:\s*(?P<title>.+?)\s*$", re.I)
TOPIC_RE = re.compile(r"^###\s+(?P<title>.+?)\s*$")
RECIPE_RE = re.compile(r"^####\s+(?:(?P<number>\d+)\s*[.\-:]?\s*)?(?P<title>.+?)\s*$")
PAGE_RE = re.compile(r"^\*Trang PDF:\s*(?P<page>\d+)\*\s*$", re.I)
LIST_ITEM_RE = re.compile(r"^[-*]\s+(?P<text>.+?)\s*$")
STEP_RE = re.compile(r"^\d+[.)]\s+(?P<text>.+?)\s*$")
INSERT_PREFIX = "insert into public.meal_catalog ("
SOURCE_MARKER = f"'{SOURCE_NAME}'"

COLUMNS = (
    "code,meal_type,meal_name,description,cooking_instructions,calories,protein,carbs,fat,fiber,water_ml,"
    "health_topic_code,health_topic_name,health_topic_description,chapter_number,chapter_name,ingredients_json,"
    "cooking_steps_json,benefits,serving_size,allergen_tags_json,avoid_condition_tags_json,nutrition_status,"
    "constraint_metadata_status,metadata_status,is_plan_eligible,source_name,source_page,source_chapter,source_topic,"
    "source_recipe_order,source_hash,version,is_active"
)

UPDATE_FIELDS = (
    "meal_type", "meal_name", "description", "cooking_instructions", "calories", "protein", "carbs", "fat",
    "fiber", "water_ml", "health_topic_code", "health_topic_name", "health_topic_description", "chapter_number",
    "chapter_name", "ingredients_json", "cooking_steps_json", "benefits", "serving_size", "allergen_tags_json",
    "avoid_condition_tags_json", "nutrition_status", "constraint_metadata_status", "metadata_status",
    "is_plan_eligible", "source_name", "source_page", "source_chapter", "source_topic", "source_recipe_order",
    "source_hash", "version", "is_active",
)


@dataclass(frozen=True)
class Recipe:
    code: str
    meal_name: str
    topic_code: str
    topic_name: str
    topic_description: str
    chapter_number: int
    chapter_name: str
    ingredients: list[str]
    cooking_steps: list[str]
    benefits: str
    source_page: int | None
    source_recipe_order: int
    source_hash: str


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value)
    ascii_value = "".join(ch for ch in normalized if unicodedata.category(ch) != "Mn")
    ascii_value = ascii_value.replace("đ", "d").replace("Đ", "D")
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", ascii_value).strip("_").lower()
    return slug or "khong_ten"


def clean_heading(value: str) -> str:
    value = re.sub(r"^\s*\d+\s*[.\-:]?\s*", "", value).strip()
    return re.sub(r"\s+", " ", value)


def nonempty(lines: Iterable[str]) -> list[str]:
    return [line.strip() for line in lines if line.strip() and line.strip() != "---"]


def parse_markdown(source: Path) -> list[Recipe]:
    lines = source.read_text(encoding="utf-8").splitlines()
    recipes: list[Recipe] = []
    chapter_number = 0
    chapter_name = ""
    topic_name = ""
    topic_description = ""
    topic_recipe_order = 0
    index = 0

    while index < len(lines):
        line = lines[index].strip()
        chapter_match = CHAPTER_RE.match(line)
        if chapter_match:
            chapter_number = int(chapter_match.group("number"))
            chapter_name = clean_heading(chapter_match.group("title"))
            topic_name = ""
            topic_description = ""
            topic_recipe_order = 0
            index += 1
            continue

        topic_match = TOPIC_RE.match(line)
        if topic_match:
            topic_name = clean_heading(topic_match.group("title"))
            topic_recipe_order = 0
            description_parts: list[str] = []
            cursor = index + 1
            while cursor < len(lines):
                candidate = lines[cursor].strip()
                if candidate.startswith(("#### ", "### ", "## ")):
                    break
                if candidate.startswith(">"):
                    description_parts.append(candidate.lstrip("> ").strip())
                cursor += 1
            topic_description = " ".join(description_parts).strip()
            index += 1
            continue

        recipe_match = RECIPE_RE.match(line)
        if not recipe_match:
            index += 1
            continue
        if not chapter_number or not topic_name:
            raise ValueError(f"Recipe outside chapter/topic at line {index + 1}: {line}")

        title = clean_heading(recipe_match.group("title"))
        topic_recipe_order += 1
        page: int | None = None
        ingredients: list[str] = []
        steps: list[str] = []
        benefits_parts: list[str] = []
        section: str | None = None
        cursor = index + 1

        while cursor < len(lines):
            candidate = lines[cursor].strip()
            if candidate.startswith(("#### ", "### ", "## ")):
                break
            page_match = PAGE_RE.match(candidate)
            if page_match:
                page = int(page_match.group("page"))
            elif candidate == "**Nguyên liệu**":
                section = "ingredients"
            elif candidate == "**Cách làm**":
                section = "steps"
            elif candidate == "**Công dụng**":
                section = "benefits"
            elif candidate == "---":
                pass
            elif section == "ingredients":
                item = LIST_ITEM_RE.match(candidate)
                if item:
                    ingredients.append(item.group("text").strip())
            elif section == "steps":
                step = STEP_RE.match(candidate)
                if step:
                    steps.append(step.group("text").strip())
                elif candidate and not candidate.startswith("*"):
                    # Keep malformed source lines instead of silently fixing them.
                    steps.append(candidate)
            elif section == "benefits" and candidate:
                benefits_parts.append(candidate)
            cursor += 1

        if not ingredients or not steps:
            raise ValueError(f"Incomplete recipe source: {title} (line {index + 1})")
        benefits = " ".join(nonempty(benefits_parts)).strip()
        if not benefits:
            raise ValueError(f"Missing benefits: {title} (line {index + 1})")

        topic_code = f"c{chapter_number:02d}_{slugify(topic_name)}"
        code = f"src_c{chapter_number:02d}_{slugify(topic_name)}_{topic_recipe_order:02d}_{slugify(title)}"
        fidelity_payload = {
            "chapter_number": chapter_number,
            "chapter_name": chapter_name,
            "topic_name": topic_name,
            "topic_description": topic_description,
            "title": title,
            "page": page,
            "ingredients": ingredients,
            "steps": steps,
            "benefits": benefits,
            "order": topic_recipe_order,
        }
        source_hash = hashlib.sha256(
            json.dumps(fidelity_payload, ensure_ascii=False, sort_keys=True).encode("utf-8")
        ).hexdigest()
        recipes.append(
            Recipe(
                code=code,
                meal_name=title,
                topic_code=topic_code,
                topic_name=topic_name,
                topic_description=topic_description,
                chapter_number=chapter_number,
                chapter_name=chapter_name,
                ingredients=ingredients,
                cooking_steps=steps,
                benefits=benefits,
                source_page=page,
                source_recipe_order=topic_recipe_order,
                source_hash=source_hash,
            )
        )
        index = cursor

    codes = [r.code for r in recipes]
    if len(codes) != len(set(codes)):
        raise ValueError("Duplicate generated meal_catalog codes")
    return recipes


def sql_text(value: str | None) -> str:
    if value is None:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def sql_json(value: object) -> str:
    return sql_text(json.dumps(value, ensure_ascii=False)) + "::jsonb"


def render_insert(recipe: Recipe) -> str:
    # Numeric nutrition values are intentionally 0 sentinels in SQL/SQLite.
    values = [
        sql_text(recipe.code),
        sql_text("unclassified"),
        sql_text(recipe.meal_name),
        sql_text(recipe.topic_description),
        sql_text("\n".join(recipe.cooking_steps)),
        "0", "0", "0", "0", "0", "0",
        sql_text(recipe.topic_code),
        sql_text(recipe.topic_name),
        sql_text(recipe.topic_description),
        str(recipe.chapter_number),
        sql_text(recipe.chapter_name),
        sql_json(recipe.ingredients),
        sql_json(recipe.cooking_steps),
        sql_text(recipe.benefits),
        "null",
        sql_json([]),
        sql_json([]),
        sql_text("missing_source_data"),
        sql_text("awaiting_professional_review"),
        sql_text("source_imported"),
        "false",
        sql_text(SOURCE_NAME),
        "null" if recipe.source_page is None else str(recipe.source_page),
        sql_text(f"Chương {recipe.chapter_number}: {recipe.chapter_name}"),
        sql_text(recipe.topic_name),
        str(recipe.source_recipe_order),
        sql_text(recipe.source_hash),
        "1",
        "true",
    ]
    updates = ", ".join(f"{field}=excluded.{field}" for field in UPDATE_FIELDS)
    return (
        f"insert into public.meal_catalog ({COLUMNS}) values ({','.join(values)}) "
        f"on conflict (code) do update set {updates}, updated_at=now();"
    )


def validate_counts(recipes: list[Recipe], expected_recipes: int, expected_topics: int, expected_chapters: int) -> None:
    topics = {r.topic_code for r in recipes}
    chapters = {r.chapter_number for r in recipes}
    if len(recipes) != expected_recipes:
        raise ValueError(f"Expected {expected_recipes} recipes, found {len(recipes)}")
    if len(topics) != expected_topics:
        raise ValueError(f"Expected {expected_topics} topics, found {len(topics)}")
    if len(chapters) != expected_chapters:
        raise ValueError(f"Expected {expected_chapters} chapters, found {len(chapters)}")


def build_seed(seed_text: str, recipes: list[Recipe], expected_recipes: int) -> str:
    insert_start = seed_text.find(INSERT_PREFIX)
    if insert_start < 0:
        raise ValueError("Could not locate meal_catalog source block in seed_data.sql")
    commit_pos = seed_text.rfind("\ncommit;")
    if commit_pos < insert_start:
        raise ValueError("Could not locate final commit after meal_catalog source block")

    old_block = seed_text[insert_start:commit_pos]
    old_inserts = old_block.count(INSERT_PREFIX)
    if old_inserts != expected_recipes:
        raise ValueError(
            f"Refusing unsafe replacement: existing meal block has {old_inserts} inserts, expected {expected_recipes}"
        )
    if old_block.count(SOURCE_MARKER) < expected_recipes:
        raise ValueError("Refusing replacement: meal block source_name markers are incomplete")

    generated = "\n\n".join(render_insert(recipe) for recipe in recipes)
    header = (
        "-- ---------------------------------------------------------------------------\n"
        "-- Canonical meal catalog generated from docs/note/"
        f"{SOURCE_NAME}\n"
        "-- DO NOT hand-edit source-derived fields. Run tools/sync_meal_catalog_sql.py.\n"
        "-- ---------------------------------------------------------------------------\n\n"
    )
    header_start = seed_text.rfind(
        "-- ---------------------------------------------------------------------------\n-- Canonical meal catalog generated from docs/note/",
        0,
        insert_start,
    )
    replace_start = header_start if header_start >= 0 else insert_start
    return seed_text[:replace_start] + header + generated + seed_text[commit_pos:]


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", newline="", delete=False, dir=path.parent) as tmp:
        tmp.write(text)
        tmp_path = Path(tmp.name)
    tmp_path.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--seed", type=Path, default=DEFAULT_SEED)
    parser.add_argument("--check", action="store_true", help="Fail if seed_data.sql differs from deterministic output")
    parser.add_argument("--expected-recipes", type=int, default=EXPECTED_RECIPES)
    parser.add_argument("--expected-topics", type=int, default=EXPECTED_TOPICS)
    parser.add_argument("--expected-chapters", type=int, default=EXPECTED_CHAPTERS)
    args = parser.parse_args()

    if not args.source.is_file():
        raise SystemExit(f"Source not found: {args.source}")
    if not args.seed.is_file():
        raise SystemExit(f"Seed not found: {args.seed}")

    recipes = parse_markdown(args.source)
    validate_counts(recipes, args.expected_recipes, args.expected_topics, args.expected_chapters)
    before = args.seed.read_text(encoding="utf-8")
    after = build_seed(before, recipes, args.expected_recipes)

    if args.check:
        if before != after:
            raise SystemExit("FAIL: seed_data.sql meal catalog is not in canonical generated form")
        print(
            f"PASS: SQL source fidelity verified ({len(recipes)} recipes, "
            f"{len({r.topic_code for r in recipes})} topics, {len({r.chapter_number for r in recipes})} chapters)"
        )
        return 0

    if before == after:
        print("No changes: seed_data.sql is already canonical")
        return 0

    atomic_write(args.seed, after)
    print(
        f"Updated {args.seed}: {len(recipes)} recipes / "
        f"{len({r.topic_code for r in recipes})} topics / {len({r.chapter_number for r in recipes})} chapters"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Build NanoBio's source-faithful meal catalog JSON from the approved Markdown.

The importer intentionally does not infer meal type, nutrition facts, allergens,
or condition suitability. Those fields remain unapproved until a trusted
nutrition workflow supplies them.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

CHAPTER_RE = re.compile(r"^##\s+Chương\s+(?P<number>\d+)\s*:\s*(?P<title>.+?)\s*$", re.I)
TOPIC_RE = re.compile(r"^###\s+(?P<title>.+?)\s*$")
RECIPE_RE = re.compile(r"^####\s+(?:(?P<number>\d+)\s*[.\-:]?\s*)?(?P<title>.+?)\s*$")
PAGE_RE = re.compile(r"^\*Trang PDF:\s*(?P<page>\d+)\*\s*$", re.I)
LIST_ITEM_RE = re.compile(r"^[-*]\s+(?P<text>.+?)\s*$")
STEP_RE = re.compile(r"^\d+[.)]\s+(?P<text>.+?)\s*$")


@dataclass(frozen=True)
class Recipe:
    code: str
    meal_type: str
    meal_name: str
    description: str
    health_topic_code: str
    health_topic_name: str
    health_topic_description: str
    chapter_number: int
    chapter_name: str
    ingredients: list[str]
    cooking_steps: list[str]
    benefits: str
    serving_size: str | None
    calories: int | None
    protein: float | None
    carbs: float | None
    fat: float | None
    fiber: float | None
    water_ml: int | None
    allergen_tags: list[str]
    avoid_condition_tags: list[str]
    nutrition_status: str
    constraint_metadata_status: str
    metadata_status: str
    is_plan_eligible: bool
    source_name: str
    source_page: int | None
    source_chapter: str
    source_topic: str
    source_recipe_order: int
    source_hash: str
    version: int
    is_active: bool


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
                if candidate.startswith("#### ") or candidate.startswith("### ") or candidate.startswith("## "):
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
            if candidate.startswith("#### ") or candidate.startswith("### ") or candidate.startswith("## "):
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
                item_match = LIST_ITEM_RE.match(candidate)
                if item_match:
                    ingredients.append(item_match.group("text").strip())
            elif section == "steps":
                step_match = STEP_RE.match(candidate)
                if step_match:
                    steps.append(step_match.group("text").strip())
                elif candidate and not candidate.startswith("*"):
                    # Preserve malformed source lines without inventing content.
                    steps.append(candidate)
            elif section == "benefits" and candidate:
                benefits_parts.append(candidate)
            cursor += 1

        if not ingredients:
            raise ValueError(f"Recipe has no ingredients: {title} (line {index + 1})")
        if not steps:
            raise ValueError(f"Recipe has no cooking steps: {title} (line {index + 1})")
        benefits = " ".join(nonempty(benefits_parts)).strip()
        if not benefits:
            raise ValueError(f"Recipe has no benefits: {title} (line {index + 1})")

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
                meal_type="unclassified",
                meal_name=title,
                description=topic_description,
                health_topic_code=topic_code,
                health_topic_name=topic_name,
                health_topic_description=topic_description,
                chapter_number=chapter_number,
                chapter_name=chapter_name,
                ingredients=ingredients,
                cooking_steps=steps,
                benefits=benefits,
                serving_size=None,
                calories=None,
                protein=None,
                carbs=None,
                fat=None,
                fiber=None,
                water_ml=None,
                allergen_tags=[],
                avoid_condition_tags=[],
                nutrition_status="missing_source_data",
                constraint_metadata_status="awaiting_professional_review",
                metadata_status="source_imported",
                is_plan_eligible=False,
                source_name=source.name,
                source_page=page,
                source_chapter=f"Chương {chapter_number}: {chapter_name}",
                source_topic=topic_name,
                source_recipe_order=topic_recipe_order,
                source_hash=source_hash,
                version=1,
                is_active=True,
            )
        )
        index = cursor

    codes = [recipe.code for recipe in recipes]
    if len(codes) != len(set(codes)):
        duplicates = sorted({code for code in codes if codes.count(code) > 1})
        raise ValueError(f"Duplicate generated codes: {duplicates}")
    return recipes


def build_payload(source: Path, recipes: list[Recipe]) -> dict[str, object]:
    topic_codes = sorted({recipe.health_topic_code for recipe in recipes})
    source_digest = hashlib.sha256(source.read_bytes()).hexdigest()
    return {
        "schema_version": 1,
        "catalog_version": 1,
        "source_name": source.name,
        "source_sha256": source_digest,
        "policy": {
            "source_fidelity": "verbatim_structured",
            "missing_metadata": "not_inferred",
            "plan_eligibility": "requires_metadata_approval",
            "benefits_disclaimer": "Theo tài liệu tham khảo, không thay thế tư vấn y tế cá nhân.",
        },
        "statistics": {
            "recipe_count": len(recipes),
            "topic_count": len(topic_codes),
            "chapter_count": len({recipe.chapter_number for recipe in recipes}),
            "plan_eligible_count": sum(1 for recipe in recipes if recipe.is_plan_eligible),
        },
        "recipes": [asdict(recipe) for recipe in recipes],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md"),
    )
    parser.add_argument(
        "--output", type=Path, default=Path("assets/data/meal_catalog_v1.json")
    )
    args = parser.parse_args()

    recipes = parse_markdown(args.source)
    payload = build_payload(args.source, recipes)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"Wrote {len(recipes)} recipes across "
        f"{payload['statistics']['topic_count']} topics to {args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

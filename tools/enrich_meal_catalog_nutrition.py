#!/usr/bin/env python3
"""Enrich source meal catalog nutrition and regenerate the SQL meal block.

Nutrition is estimated per serving from quantified recipe ingredients using
representative generic USDA FoodData Central values per 100 g. Unquantified
seasonings are intentionally ignored. The source recipe hash is preserved.
"""
from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

STATUS = "estimated_from_ingredients"
SERVING = "1 khẩu phần (ước tính)"

@dataclass(frozen=True)
class N:
    calories: float = 0
    protein: float = 0
    carbs: float = 0
    fat: float = 0
    fiber: float = 0
    sugar_g: float = 0
    saturated_fat_g: float = 0
    sodium_mg: float = 0
    cholesterol_mg: float = 0
    potassium_mg: float = 0
    calcium_mg: float = 0
    iron_mg: float = 0

    def scale(self, factor: float) -> "N":
        return N(**{k: v * factor for k, v in asdict(self).items()})

    def add(self, other: "N") -> "N":
        return N(**{k: getattr(self, k) + getattr(other, k) for k in asdict(self)})

@dataclass(frozen=True)
class Food:
    aliases: tuple[str, ...]
    n: N
    item_g: float | None = None
    density: float = 1.0

FOODS = (
    Food(("sữa hạnh nhân",), N(15,.6,.6,1.2,.3,.2,.1,72,0,67,184,.3)),
    Food(("dầu ô liu","dầu olive"), N(884,0,0,100,0,0,13.8), 15, .91),
    Food(("dầu ăn","dầu thực vật"), N(884,0,0,100,0,0,14), 15, .92),
    Food(("mật ong",), N(304,0,82.4,0,0,82.1,0,4,0,52,6,.4), 15, 1.42),
    Food(("hạt chia",), N(486,16.5,42.1,30.7,34.4,0,3.3,16,0,407,631,7.7), 12),
    Food(("hạnh nhân",), N(579,21.2,21.6,49.9,12.5,4.4,3.8,1,0,733,269,3.7), 1.2),
    Food(("hạt điều",), N(553,18.2,30.2,43.9,3.3,5.9,7.8,12,0,660,37,6.7), 1.6),
    Food(("óc chó","hạt óc chó"), N(654,15.2,13.7,65.2,6.7,2.6,6.1,2,0,441,98,2.9), 4),
    Food(("đậu phộng","lạc"), N(567,25.8,16.1,49.2,8.5,4.7,6.8,18,0,705,92,4.6)),
    Food(("thịt bò",), N(250,26,0,15,0,0,6,72,90,318,18,2.6)),
    Food(("ức gà","thịt gà"), N(165,31,0,3.6,0,0,1,74,85,256,15,1)),
    Food(("thịt heo","thịt lợn"), N(242,27.3,0,13.9,0,0,5.1,62,80,423,19,.9)),
    Food(("cá hồi",), N(208,20.4,0,13.4,0,0,3.1,59,55,363,9,.3)),
    Food(("cá thu",), N(205,18.6,0,13.9,0,0,3.3,90,70,314,12,1.6)),
    Food(("tôm",), N(99,24,.2,.3,0,0,0,111,189,259,70,.5)),
    Food(("trứng",), N(143,12.6,.7,9.5,0,.4,3.1,142,372,138,56,1.8), 50),
    Food(("đậu phụ","đậu hũ"), N(76,8.1,1.9,4.8,.3,.6,.7,7,0,121,350,5.4)),
    Food(("gạo lứt",), N(370,7.9,77.2,2.9,3.5,.9,0,7,0,223,23,1.5)),
    Food(("gạo nếp",), N(370,6.8,81.7,.6,2.8,0,0,7,0,77,11,1.2)),
    Food(("gạo trắng","gạo tẻ","gạo"), N(365,7.1,80,.7,1.3,.1,0,5,0,115,28,.8)),
    Food(("yến mạch",), N(389,16.9,66.3,6.9,10.6,1,1.2,2,0,429,54,4.7)),
    Food(("khoai lang",), N(86,1.6,20.1,.1,3,4.2,0,55,0,337,30,.6), 130),
    Food(("khoai tây",), N(77,2,17.5,.1,2.2,.8,0,6,0,425,12,.8), 170),
    Food(("đậu xanh",), N(347,23.9,62.6,1.2,16.3,6.6,.3,15,0,1246,132,6.7)),
    Food(("đậu đỏ",), N(329,19.9,62.9,.5,12.7,2.1,0,5,0,1254,66,5)),
    Food(("đậu đen",), N(341,21.6,62.4,1.4,15.5,2.1,0,5,0,1483,123,5)),
    Food(("hạt sen",), N(324,15.4,64.5,2,7.9,0,0,5,0,1368,163,3.5), 2.5),
    Food(("cải bó xôi","rau bina"), N(23,2.9,3.6,.4,2.2,.4,0,79,0,558,99,2.7)),
    Food(("bông cải xanh","súp lơ xanh"), N(34,2.8,6.6,.4,2.6,1.7,0,33,0,316,47,.7)),
    Food(("cà rốt",), N(41,.9,9.6,.2,2.8,4.7,0,69,0,320,33,.3), 61),
    Food(("củ dền",), N(43,1.6,9.6,.2,2.8,6.8,0,78,0,325,16,.8), 82),
    Food(("bí đỏ","bí ngô"), N(26,1,6.5,.1,.5,2.8,0,1,0,340,21,.8)),
    Food(("cà chua",), N(18,.9,3.9,.2,1.2,2.6,0,5,0,237,10,.3), 123),
    Food(("hành tím",), N(72,2.5,16.8,.1,3.2,7.9,0,12,0,334,37,1.2), 25),
    Food(("hành tây",), N(40,1.1,9.3,.1,1.7,4.2,0,4,0,146,23,.2), 110),
    Food(("chuối",), N(89,1.1,22.8,.3,2.6,12.2,0,1,0,358,5,.3), 118),
    Food(("táo",), N(52,.3,13.8,.2,2.4,10.4,0,1,0,107,6,.1), 182),
    Food(("đu đủ",), N(43,.5,10.8,.3,1.7,7.8,0,8,0,182,20,.3), 300),
    Food(("cam",), N(47,.9,11.8,.1,2.4,9.4,0,0,0,181,40,.1), 131),
    Food(("chanh",), N(29,1.1,9.3,.3,2.8,2.5,0,2,0,138,26,.6), 58),
    Food(("sữa chua",), N(61,3.5,4.7,3.3,0,4.7,2.1,46,13,155,121,.1), 100),
    Food(("nước dừa",), N(19,.7,3.7,.2,1.1,2.6,0,105,0,250,24,.3), density=1),
    Food(("nước",), N(), density=1),
    Food(("gừng",), N(80,1.8,17.8,.8,2,1.7,0,13,0,415,16,.6), 10),
)
FOODS = tuple(sorted(FOODS, key=lambda f: max(map(len, f.aliases)), reverse=True))

METRIC_RE = re.compile(r"(\d+(?:[\.,]\d+)?)\s*(kg|g|ml|l)\b")

def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip().lower().replace("–", "-").replace("—", "-"))

def find_food(text: str) -> Food | None:
    return next((f for f in FOODS if any(a in text for a in f.aliases)), None)

def count(text: str) -> float | None:
    text = text.replace("½", "0.5").replace("¼", "0.25").replace("¾", "0.75")
    m = re.match(r"\s*(\d+)\s*/\s*(\d+)", text)
    if m:
        d = float(m.group(2)); return float(m.group(1)) / d if d else None
    m = re.match(r"\s*(\d+(?:[\.,]\d+)?)", text)
    return float(m.group(1).replace(",", ".")) if m else None

def quantity(text: str, food: Food | None) -> tuple[float, float] | None:
    m = METRIC_RE.search(text)
    if m:
        v, unit = float(m.group(1).replace(",", ".")), m.group(2)
        if unit == "kg": return v * 1000, 0
        if unit == "g": return v, 0
        ml = v * 1000 if unit == "l" else v
        return ml * (food.density if food else 1), ml
    c = count(text)
    if c is None: return None
    item = food.item_g if food and food.item_g else None
    if item is None:
        if "thìa cà phê" in text or "muỗng cà phê" in text: item = 5
        elif "thìa" in text or "muỗng" in text: item = 15
        elif "chén" in text or "cốc" in text: item = 180
        elif "nắm" in text: item = 35
        elif "hộp" in text: item = 100
        elif "nhánh" in text: item = 10
    if item is None: return None
    liquid = c * item if any(x in text for x in ("thìa","muỗng","chén","cốc")) else 0
    return c * item * (food.density if food else 1), liquid

def estimate(ingredients: Iterable[str], meal_name: str) -> dict | None:
    total, matched, quantified, liquid = N(), 0.0, 0.0, 0.0
    for raw in ingredients:
        text = norm(raw)
        if not text or text.startswith("gia vị") or "vừa ăn" in text or "vừa đủ" in text: continue
        f = find_food(text); q = quantity(text, f)
        if not q: continue
        grams, ml = q; quantified += grams; liquid += ml
        if not f: continue
        matched += grams; total = total.add(f.n.scale(grams / 100))
    if matched <= 0: return None
    coverage = matched / quantified if quantified else 1
    if coverage < .45: return None
    name = norm(meal_name)
    drink = any(x in name for x in ("sinh tố","nước ép","trà ","sữa "))
    servings = 1 if drink or liquid >= 150 else min(4, max(1, math.ceil(matched / 350)))
    n = total.scale(1 / servings)
    if n.calories < 5: return None
    out = {k: round(v, 1) for k, v in asdict(n).items()}
    out["calories"] = round(n.calories)
    out["water_ml"] = round(liquid / servings)
    out["serving_size"] = SERVING
    out["nutrition_status"] = STATUS
    return out

def enrich(recipes: list[dict]) -> int:
    changed = 0
    for recipe in recipes:
        if recipe.get("nutrition_status") not in (None, "", "missing_source_data"): continue
        result = estimate(recipe.get("ingredients") or [], recipe.get("meal_name") or "")
        if not result: continue
        recipe.update(result); changed += 1
    return changed

def sql_literal(value) -> str:
    if value is None: return "null"
    if isinstance(value, bool): return "true" if value else "false"
    if isinstance(value, (int, float)): return str(value)
    if isinstance(value, (list, dict)):
        payload = json.dumps(value, ensure_ascii=False).replace("'", "''")
        return f"'{payload}'::jsonb"
    return "'" + str(value).replace("'", "''") + "'"

COLUMNS = [
    "code","meal_type","meal_name","description","cooking_instructions",
    "calories","protein","carbs","fat","fiber","water_ml","sugar_g",
    "saturated_fat_g","sodium_mg","cholesterol_mg","potassium_mg","calcium_mg","iron_mg",
    "health_topic_code","health_topic_name","health_topic_description","chapter_number","chapter_name",
    "ingredients_json","cooking_steps_json","benefits","serving_size","allergen_tags_json",
    "avoid_condition_tags_json","nutrition_status","constraint_metadata_status","metadata_status",
    "is_plan_eligible","source_name","source_page","source_chapter","source_topic","source_recipe_order",
    "source_hash","version","is_active"
]
JSON_KEY = {"ingredients_json":"ingredients", "cooking_steps_json":"cooking_steps",
            "allergen_tags_json":"allergen_tags", "avoid_condition_tags_json":"avoid_condition_tags"}

def column_value(recipe: dict, column: str):
    if column == "cooking_instructions":
        value = recipe.get(column)
        if value in (None, ""):
            value = "\n".join(recipe.get("cooking_steps") or [])
        return value
    key = JSON_KEY.get(column, column)
    value = recipe.get(key)
    if column in {"calories","protein","carbs","fat","fiber","water_ml"}:
        return 0 if value is None else value
    if column in {"ingredients_json","cooking_steps_json","allergen_tags_json","avoid_condition_tags_json"}:
        return [] if value is None else value
    if column == "meal_type":
        return value or "unclassified"
    if column == "nutrition_status":
        return value or "missing_source_data"
    if column == "constraint_metadata_status":
        return value or "awaiting_professional_review"
    if column == "metadata_status":
        return value or "source_imported"
    if column == "is_plan_eligible":
        return bool(value)
    if column == "is_active":
        return True if value is None else bool(value)
    if column == "version":
        return value or 1
    return value

def recipe_sql(recipe: dict) -> str:
    values = [sql_literal(column_value(recipe, c)) for c in COLUMNS]
    updates = [c for c in COLUMNS if c != "code"]
    return (f"insert into public.meal_catalog ({','.join(COLUMNS)}) values ({','.join(values)}) "
            f"on conflict (code) do update set " + ",".join(f"{c}=excluded.{c}" for c in updates) + ";")

def rewrite_seed(seed_path: Path, recipes: list[dict]) -> None:
    text = seed_path.read_text(encoding="utf-8")
    marker = "insert into public.meal_catalog ("
    start = text.find(marker)
    if start < 0: raise RuntimeError("meal_catalog seed marker not found")
    prefix = text[:start].rstrip()
    block = "\n".join(recipe_sql(r) for r in recipes)
    seed_path.write_text(prefix + "\n\n" + block + "\n\ncommit;\n", encoding="utf-8")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    asset = args.root / "assets/data/meal_catalog_v1.json"
    seed = args.root / "docs/supabase/seed_data.sql"
    doc = json.loads(asset.read_text(encoding="utf-8"))
    recipes = doc.get("recipes")
    if not isinstance(recipes, list): raise RuntimeError("recipes must be a list")
    changed = enrich(recipes)
    if args.check:
        missing = sum(1 for r in recipes if r.get("nutrition_status") == "missing_source_data")
        print(f"recipes={len(recipes)} estimated={changed} still_missing={missing}")
        return 0 if changed == 0 else 1
    asset.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rewrite_seed(seed, recipes)
    print(f"Enriched {changed}/{len(recipes)} recipes and regenerated meal_catalog SQL block.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

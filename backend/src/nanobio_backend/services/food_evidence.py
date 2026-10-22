import re
import unicodedata
from datetime import UTC, datetime
from typing import Any

import httpx

NIN_SEARCH_URL = "https://viendinhduong.vn/api/fe/foodNatunal/getPageFoodData"
NIN_LOOKUP_PAGE = "https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham"
NIN_SOURCE = "Viện Dinh dưỡng Quốc gia"
USDA_SOURCE = "USDA FoodData Central"


def retrieved_at() -> str:
    return datetime.now(UTC).isoformat()


def normalize_match(value: object) -> str:
    text = unicodedata.normalize("NFKD", str(value or ""))
    text = "".join(char for char in text if not unicodedata.combining(char)).casefold()
    return re.sub(r"[^a-z0-9]+", " ", text).strip()


def _unique_match(rows: object, ingredient: str, names: tuple[str, ...]) -> dict[str, Any] | None:
    if not isinstance(rows, list):
        return None
    query = normalize_match(ingredient)
    records = [row for row in rows if isinstance(row, dict)]
    exact = [row for row in records if any(normalize_match(row.get(key)) == query for key in names)]
    if not exact:
        exact = [
            row
            for row in records
            if any(normalize_match(row.get(key)).startswith(query + " ") for key in names)
        ]
    return exact[0] if len(exact) == 1 else None


def _number(value: object) -> float | None:
    try:
        result = float(str(value).replace(",", "."))
    except (TypeError, ValueError):
        return None
    return result if result >= 0 else None


def _national_map(payload: object, ingredient: str) -> dict[str, Any] | None:
    if not isinstance(payload, dict):
        return None
    food = _unique_match(payload.get("data"), ingredient, ("name_vi", "name_en"))
    if food is None or not food.get("code"):
        return None
    nutrients: dict[str, float | None] = {
        "energy_kcal_per_100g": _number(food.get("energy")),
        "protein_g_per_100g": None,
        "carbohydrate_g_per_100g": None,
        "fat_g_per_100g": None,
        "fiber_g_per_100g": None,
        "sugar_g_per_100g": None,
        "sodium_mg_per_100g": None,
        "saturated_fat_g_per_100g": None,
        "water_g_per_100g": None,
    }
    keys = {
        "protein": "protein_g_per_100g",
        "carbohydrate-by-difference": "carbohydrate_g_per_100g",
        "total-lipid-fat": "fat_g_per_100g",
        "fibre-total-dietary": "fiber_g_per_100g",
        "fiber-total-dietary": "fiber_g_per_100g",
        "sugars-total": "sugar_g_per_100g",
        "sodium": "sodium_mg_per_100g",
        "na": "sodium_mg_per_100g",
        "fatty-acids-total-saturated": "saturated_fat_g_per_100g",
        "water": "water_g_per_100g",
    }
    entries = food.get("nutrition")
    if isinstance(entries, list):
        for entry in entries:
            if isinstance(entry, dict):
                key = keys.get(str(entry.get("key", "")).casefold())
                value = _number(entry.get("value"))
                if key and value is not None:
                    unit = str(entry.get("unit") or entry.get("unitName") or "").casefold()
                    nutrients[key] = (
                        value * 1000 if key == "sodium_mg_per_100g" and unit == "g" else value
                    )
    if not any(value is not None for value in nutrients.values()):
        return None
    return {
        "queried_name": ingredient,
        "normalized_name": normalize_match(ingredient),
        "source_food_id": str(food["code"]),
        "description": " / ".join(
            str(food.get(key)) for key in ("name_vi", "name_en") if food.get(key)
        ),
        "data_type": "Vietnamese Food Composition Table",
        "nutrients": nutrients,
        "source_name": NIN_SOURCE,
        "source_url": NIN_LOOKUP_PAGE,
        "dataset_version": None,
        "retrieved_at": retrieved_at(),
        "evidence_status": "source_match",
    }


def _usda_map(payload: object, ingredient: str) -> dict[str, Any] | None:
    if not isinstance(payload, dict):
        return None
    food = _unique_match(payload.get("foods"), ingredient, ("description",))
    if food is None or not food.get("fdcId"):
        return None
    nutrient_keys = {
        "energy": "energy_kcal_per_100g",
        "protein": "protein_g_per_100g",
        "carbohydrate, by difference": "carbohydrate_g_per_100g",
        "total lipid (fat)": "fat_g_per_100g",
        "fiber, total dietary": "fiber_g_per_100g",
        "sugars, total including nlea": "sugar_g_per_100g",
        "sodium, na": "sodium_mg_per_100g",
        "fatty acids, total saturated": "saturated_fat_g_per_100g",
    }
    nutrients: dict[str, float | None] = {key: None for key in nutrient_keys.values()}
    values = food.get("foodNutrients")
    if isinstance(values, list):
        for item in values:
            if not isinstance(item, dict):
                continue
            nested = item.get("nutrient")
            info: dict[str, Any] = nested if isinstance(nested, dict) else item
            key = nutrient_keys.get(str(info.get("name", "")).casefold())
            if key:
                nutrients[key] = _number(item.get("amount"))
    if not any(value is not None for value in nutrients.values()):
        return None
    food_id = str(food["fdcId"])
    return {
        "queried_name": ingredient,
        "normalized_name": normalize_match(ingredient),
        "source_food_id": food_id,
        "description": food.get("description"),
        "data_type": food.get("dataType"),
        "nutrients": nutrients,
        "source_name": USDA_SOURCE,
        "source_url": f"https://fdc.nal.usda.gov/food/{food_id}",
        "dataset_version": food.get("publishedDate"),
        "retrieved_at": retrieved_at(),
        "evidence_status": "source_match",
    }


def lookup_food(ingredient: str, usda_api_key: str | None) -> dict[str, Any]:
    national_error: Exception | None = None
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.get(
                NIN_SEARCH_URL,
                params={"page": "1", "pageSize": "10", "name": ingredient},
                headers={
                    "accept": "application/json",
                    "referer": NIN_LOOKUP_PAGE,
                    "user-agent": "NanoBioAI food evidence lookup",
                },
            )
            response.raise_for_status()
            mapped = _national_map(response.json(), ingredient)
            if mapped:
                return mapped
    except (httpx.HTTPError, ValueError) as exc:
        national_error = exc
    if usda_api_key:
        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.post(
                    "https://api.nal.usda.gov/fdc/v1/foods/search",
                    params={"api_key": usda_api_key},
                    json={
                        "query": ingredient,
                        "pageSize": 10,
                        "dataType": ["Foundation", "SR Legacy", "Survey (FNDDS)"],
                    },
                )
                response.raise_for_status()
                mapped = _usda_map(response.json(), ingredient)
                if mapped:
                    return mapped
        except (httpx.HTTPError, ValueError) as exc:
            raise RuntimeError("food_sources_unavailable") from exc
    if national_error is not None and not usda_api_key:
        # Keep the edge function fallback when USDA is not configured.
        pass
    return {
        "queried_name": ingredient,
        "normalized_name": normalize_match(ingredient),
        "source_food_id": None,
        "description": None,
        "data_type": None,
        "nutrients": None,
        "source_name": NIN_SOURCE,
        "source_url": NIN_LOOKUP_PAGE,
        "dataset_version": None,
        "retrieved_at": retrieved_at(),
        "evidence_status": "not_found_or_ambiguous",
    }

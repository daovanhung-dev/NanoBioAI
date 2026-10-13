import {
  mapNationalNutritionFood,
  mapUsdaFoodSearchResult,
} from "./evidence_mapping.ts";

Deno.test("maps a unique national-table match with source identity and units", () => {
  const evidence = mapNationalNutritionFood(
    {
      data: [{
        code: "VN-FOOD-18",
        name_vi: "Gạo tẻ",
        name_en: "Regular rice",
        energy: 346,
        nutrition: [
          { key: "protein", value: "7.9", unit: "g" },
          { key: "sodium", value: 5, unit: "mg" },
          { key: "water", value: 20, unit: "unknown" },
        ],
      }],
    },
    "gao te",
    "2026-10-13T00:00:00.000Z",
  );

  if (!evidence) throw new Error("expected a unique source match");
  const nutrients = evidence.nutrients as Record<string, number | null>;
  if (evidence.source_food_id !== "VN-FOOD-18") {
    throw new Error("national source code was not preserved");
  }
  if (evidence.source_name !== "Viện Dinh dưỡng Quốc gia") {
    throw new Error("national source provenance was not preserved");
  }
  if (nutrients.energy_kcal_per_100g !== 346) {
    throw new Error("national energy was not mapped as kcal per 100 g");
  }
  if (nutrients.protein_g_per_100g !== 7.9) {
    throw new Error("protein unit was not retained");
  }
  if (nutrients.sodium_mg_per_100g !== 5) {
    throw new Error("sodium unit was not retained");
  }
  if (nutrients.water_g_per_100g !== null) {
    throw new Error("unknown units must remain unknown");
  }
});

Deno.test("rejects ambiguous national-table prefix matches", () => {
  const evidence = mapNationalNutritionFood(
    {
      data: [
        { code: "VN-1", name_vi: "Gạo tẻ", energy: 100 },
        { code: "VN-2", name_vi: "Gạo nếp", energy: 150 },
      ],
    },
    "gạo",
    "2026-10-13T00:00:00.000Z",
  );

  if (evidence !== null) {
    throw new Error("ambiguous matches must not be assigned a source code");
  }
});

Deno.test("matches a named synonym inside a national-table food name", () => {
  const mapped = mapNationalNutritionFood(
    {
      data: [{
        code: "1017",
        name_vi: "Bột gạo, gạo tẻ",
        energy: 360,
        nutrition: [{ key: "protein", value: 6.6, unit: "g" }],
      }],
    },
    "gạo tẻ",
    "2026-10-13T00:00:00.000Z",
  );

  if (mapped?.source_food_id !== "1017") {
    throw new Error("national table synonym was not matched");
  }
});

Deno.test("maps USDA values into stable units and preserves FDC provenance", () => {
  const evidence = mapUsdaFoodSearchResult(
    {
      foods: [{
        fdcId: 12345,
        description: "Rice, white, long-grain, regular, raw",
        dataType: "SR Legacy",
        publishedDate: "2019-04-01",
        foodNutrients: [
          { nutrientName: "Energy", value: 1432, unitName: "kJ" },
          { nutrientName: "Protein", value: 7.8, unitName: "g" },
          { nutrientName: "Sodium, Na", value: 0.005, unitName: "g" },
          { nutrientName: "Fiber, total dietary", value: 300, unitName: "mg" },
        ],
      }],
    },
    "rice, white",
    "2026-10-13T00:00:00.000Z",
  );

  if (!evidence) throw new Error("expected an exact USDA match");
  const nutrients = evidence.nutrients as Record<string, number | null>;
  if (evidence.source_food_id !== "12345") {
    throw new Error("FDC ID was not preserved");
  }
  if (evidence.source_name !== "USDA FoodData Central") {
    throw new Error("USDA provenance was not preserved");
  }
  if (evidence.dataset_version !== "2019-04-01") {
    throw new Error("USDA dataset version was not preserved");
  }
  if (Math.abs((nutrients.energy_kcal_per_100g ?? 0) - 342.256) > 0.001) {
    throw new Error("kilojoules were not converted into kilocalories");
  }
  if (nutrients.sodium_mg_per_100g !== 5) {
    throw new Error("sodium grams were not converted into milligrams");
  }
  if (nutrients.fiber_g_per_100g !== 0.3) {
    throw new Error("fiber milligrams were not converted into grams");
  }
});

const nationalSourceName = "Viện Dinh dưỡng Quốc gia";
const nationalSourceUrl =
  "https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham";
const usdaSourceName = "USDA FoodData Central";
const usdaSourceUrl = "https://fdc.nal.usda.gov/api-guide/";

const nutrientKeys = new Map<string, string>([
  ["protein", "protein_g_per_100g"],
  ["carbohydrate-by-difference", "carbohydrate_g_per_100g"],
  ["total-lipid-fat", "fat_g_per_100g"],
  ["fibre-total-dietary", "fiber_g_per_100g"],
  ["fiber-total-dietary", "fiber_g_per_100g"],
  ["sugars-total", "sugar_g_per_100g"],
  ["sodium", "sodium_mg_per_100g"],
  ["na", "sodium_mg_per_100g"],
  ["fatty-acids-total-saturated", "saturated_fat_g_per_100g"],
  ["water", "water_g_per_100g"],
]);

const usdaNutrientKeys = new Map<string, string>([
  ["energy", "energy_kcal_per_100g"],
  ["protein", "protein_g_per_100g"],
  ["carbohydrate, by difference", "carbohydrate_g_per_100g"],
  ["total lipid (fat)", "fat_g_per_100g"],
  ["fiber, total dietary", "fiber_g_per_100g"],
  ["sugars, total including nlea", "sugar_g_per_100g"],
  ["sodium, na", "sodium_mg_per_100g"],
  ["fatty acids, total saturated", "saturated_fat_g_per_100g"],
]);

export function mapNationalNutritionFood(
  value: unknown,
  ingredient: string,
  retrievedAt: string,
): Record<string, unknown> | null {
  if (!isRecord(value) || !Array.isArray(value.data)) return null;
  const food = uniqueMatch(value.data, ingredient, (item) => [
    item.name_vi,
    item.name_en,
  ]);
  if (!food) return null;

  const nutrients = extractNationalNutrients(food);
  const sourceFoodId = asText(food.code);
  if (!sourceFoodId || !Object.values(nutrients).some((item) => item != null)) {
    return null;
  }
  return {
    queried_name: ingredient,
    normalized_name: normalize(ingredient),
    source_food_id: sourceFoodId,
    description: [asText(food.name_vi), asText(food.name_en)]
      .filter(Boolean)
      .join(" / "),
    data_type: "Vietnamese Food Composition Table",
    nutrients,
    source_name: nationalSourceName,
    source_url: nationalSourceUrl,
    dataset_version: null,
    retrieved_at: retrievedAt,
    evidence_status: "source_match",
  };
}

export function mapUsdaFoodSearchResult(
  value: unknown,
  ingredient: string,
  retrievedAt: string,
): Record<string, unknown> | null {
  if (!isRecord(value) || !Array.isArray(value.foods)) return null;
  const food = uniqueMatch(
    value.foods,
    ingredient,
    (item) => [item.description],
  );
  if (!food) return null;

  const sourceFoodId = asText(food.fdcId);
  if (!sourceFoodId) return null;
  const nutrients = extractUsdaNutrients(food.foodNutrients);
  if (!Object.values(nutrients).some((item) => item != null)) return null;
  return {
    queried_name: ingredient,
    normalized_name: normalize(ingredient),
    source_food_id: sourceFoodId,
    description: asText(food.description),
    data_type: asText(food.dataType),
    nutrients,
    source_name: usdaSourceName,
    source_url: `https://fdc.nal.usda.gov/food/${
      encodeURIComponent(sourceFoodId)
    }`,
    dataset_version: asText(food.publishedDate) || null,
    retrieved_at: retrievedAt,
    evidence_status: "source_match",
  };
}

export function notFoundFoodEvidence(
  ingredient: string,
  retrievedAt: string,
): Record<string, unknown> {
  return {
    queried_name: ingredient,
    normalized_name: normalize(ingredient),
    source_food_id: null,
    description: null,
    data_type: null,
    nutrients: null,
    source_name: nationalSourceName,
    source_url: nationalSourceUrl,
    dataset_version: null,
    retrieved_at: retrievedAt,
    evidence_status: "not_found_or_ambiguous",
  };
}

function uniqueMatch(
  values: unknown[],
  query: string,
  namesOf: (record: Record<string, unknown>) => unknown[],
): Record<string, unknown> | null {
  const normalizedQuery = normalizeMatch(query);
  const records = values.filter(isRecord);
  const exact = records.filter((record) =>
    namesOf(record).some((name) =>
      nameVariants(name).some((variant) => variant === normalizedQuery) ||
      normalizeMatch(asText(name)) === normalizedQuery
    )
  );
  const matches = exact.length > 0
    ? exact
    : records.filter((record) =>
      namesOf(record).some((name) => {
        const normalizedName = normalizeMatch(asText(name));
        return nameVariants(name).some((variant) =>
          variant.startsWith(`${normalizedQuery} `)
        ) || normalizedName.startsWith(`${normalizedQuery} `) ||
          normalizedName.startsWith(`${normalizedQuery},`);
      })
    );
  return matches.length === 1 ? matches[0] : null;
}

function nameVariants(value: unknown): string[] {
  return asText(value)
    .split(/[,;|]/)
    .map(normalizeMatch)
    .filter(Boolean);
}

function extractNationalNutrients(
  food: Record<string, unknown>,
): Record<string, number | null> {
  const result: Record<string, number | null> = {
    // The National Institute table reports energy in kcal per 100 g.
    energy_kcal_per_100g: numericOrNull(food.energy),
    protein_g_per_100g: null,
    carbohydrate_g_per_100g: null,
    fat_g_per_100g: null,
    fiber_g_per_100g: null,
    sugar_g_per_100g: null,
    sodium_mg_per_100g: null,
    saturated_fat_g_per_100g: null,
    water_g_per_100g: null,
  };
  if (!Array.isArray(food.nutrition)) return result;
  for (const entry of food.nutrition) {
    if (!isRecord(entry)) continue;
    const key = nutrientKeys.get(asText(entry.key).toLowerCase());
    if (!key) continue;
    result[key] = normalizeNutrientUnit(
      key,
      numericOrNull(entry.value),
      asText(entry.unit ?? entry.unitName),
    );
  }
  return result;
}

function extractUsdaNutrients(value: unknown): Record<string, number | null> {
  const result: Record<string, number | null> = {
    energy_kcal_per_100g: null,
    protein_g_per_100g: null,
    carbohydrate_g_per_100g: null,
    fat_g_per_100g: null,
    fiber_g_per_100g: null,
    sugar_g_per_100g: null,
    sodium_mg_per_100g: null,
    saturated_fat_g_per_100g: null,
  };
  if (!Array.isArray(value)) return result;
  for (const entry of value) {
    if (!isRecord(entry)) continue;
    const key = usdaNutrientKeys.get(asText(entry.nutrientName).toLowerCase());
    if (!key) continue;
    result[key] = normalizeNutrientUnit(
      key,
      numericOrNull(entry.value),
      asText(entry.unitName),
    );
  }
  return result;
}

function normalizeNutrientUnit(
  target: string,
  value: number | null,
  unit: string,
): number | null {
  if (value == null) return null;
  const normalizedUnit = unit.trim().toLowerCase().replace(/\s+/g, " ");
  if (target === "energy_kcal_per_100g") {
    if (["kcal", "calorie", "kilocalorie"].includes(normalizedUnit)) {
      return value;
    }
    if (["kj", "kilojoule"].includes(normalizedUnit)) return value / 4.184;
    return null;
  }
  const gramTarget = target.endsWith("_g_per_100g");
  if (gramTarget) {
    if (["g", "gram", "grams"].includes(normalizedUnit)) return value;
    if (["mg", "milligram", "milligrams"].includes(normalizedUnit)) {
      return value / 1000;
    }
    if (["kg", "kilogram", "kilograms"].includes(normalizedUnit)) {
      return value * 1000;
    }
    return null;
  }
  if (target === "sodium_mg_per_100g") {
    if (["mg", "milligram", "milligrams"].includes(normalizedUnit)) {
      return value;
    }
    if (["g", "gram", "grams"].includes(normalizedUnit)) return value * 1000;
    if (["µg", "μg", "ug", "mcg"].includes(normalizedUnit)) return value / 1000;
    return null;
  }
  return null;
}

function normalizeMatch(value: string): string {
  return value
    .normalize("NFD")
    .toLowerCase()
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

function normalize(value: string): string {
  return value.trim().toLocaleLowerCase().replace(/\s+/g, " ");
}

function numericOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value.replace(",", "."));
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function asText(value: unknown): string {
  return value == null ? "" : String(value).trim();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

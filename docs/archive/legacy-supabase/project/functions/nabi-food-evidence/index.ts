import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  mapNationalNutritionFood,
  mapUsdaFoodSearchResult,
} from "./evidence_mapping.ts";
import { lookupFoodEvidence } from "./evidence_lookup.ts";
import { createNabiFoodEvidenceHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const fdcApiKey = Deno.env.get("USDA_FDC_API_KEY")?.trim() ?? "";
const ninSearchApi =
  "https://viendinhduong.vn/api/fe/foodNatunal/getPageFoodData";
const ninLookupPage =
  "https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham";
const requestWindowMs = 60 * 60 * 1000;
const maxRequestsPerWindow = 12;
const requestWindows = new Map<string, number[]>();

Deno.serve(createNabiFoodEvidenceHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const client = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  rateLimit: async (userId) => {
    const now = Date.now();
    const recent = (requestWindows.get(userId) || []).filter(
      (timestamp) => now - timestamp < requestWindowMs,
    );
    if (recent.length >= maxRequestsPerWindow) {
      requestWindows.set(userId, recent);
      return false;
    }
    recent.push(now);
    requestWindows.set(userId, recent);
    return true;
  },
  lookup: async (ingredient) => lookupFood(ingredient),
}));

async function lookupFood(
  ingredient: string,
): Promise<Record<string, unknown>> {
  return lookupFoodEvidence(ingredient, {
    nationalTable: lookupNationalNutritionTable,
    usda: lookupFoodDataCentral,
  });
}

async function lookupNationalNutritionTable(
  ingredient: string,
): Promise<Record<string, unknown> | null> {
  const url = new URL(ninSearchApi);
  url.searchParams.set("page", "1");
  url.searchParams.set("pageSize", "10");
  url.searchParams.set("name", ingredient);
  const response = await fetch(url, {
    headers: {
      accept: "application/json",
      referer: ninLookupPage,
      "user-agent": "NanoBioAI food evidence lookup",
    },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error("national_nutrition_source_failed");
  return mapNationalNutritionFood(
    await response.json(),
    ingredient,
    new Date().toISOString(),
  );
}

async function lookupFoodDataCentral(
  ingredient: string,
): Promise<Record<string, unknown> | null> {
  if (!fdcApiKey) return null;

  const response = await fetch(
    `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${
      encodeURIComponent(fdcApiKey)
    }`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        query: ingredient,
        pageSize: 10,
        dataType: ["Foundation", "SR Legacy", "Survey (FNDDS)"],
      }),
      signal: AbortSignal.timeout(10_000),
    },
  );
  if (!response.ok) throw new Error("usda_food_source_failed");
  return mapUsdaFoodSearchResult(
    await response.json(),
    ingredient,
    new Date().toISOString(),
  );
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

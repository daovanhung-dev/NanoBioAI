import { lookupFoodEvidence } from "./evidence_lookup.ts";

Deno.test("falls back to USDA when the national source is unavailable", async () => {
  let usdaCalls = 0;
  const result = await lookupFoodEvidence("yến mạch", {
    nationalTable: async () => {
      throw new Error("source unavailable");
    },
    usda: async (ingredient) => {
      usdaCalls++;
      return { queried_name: ingredient, source_name: "USDA FoodData Central" };
    },
    now: () => new Date("2026-10-13T00:00:00.000Z"),
  });

  if (
    usdaCalls !== 1 || result.source_name !== "USDA FoodData Central" ||
    result.queried_name !== "yến mạch"
  ) {
    throw new Error("USDA fallback was not used");
  }
});

Deno.test("returns unknown evidence when both approved sources have no match", async () => {
  const result = await lookupFoodEvidence("món không rõ", {
    nationalTable: async () => null,
    usda: async () => null,
    now: () => new Date("2026-10-13T00:00:00.000Z"),
  });

  if (
    result.evidence_status !== "not_found_or_ambiguous" ||
    result.nutrients !== null ||
    result.retrieved_at !== "2026-10-13T00:00:00.000Z"
  ) {
    throw new Error("missing source data was not kept unknown");
  }
});

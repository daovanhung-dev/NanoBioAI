import { notFoundFoodEvidence } from "./evidence_mapping.ts";

export type FoodEvidenceProviders = {
  nationalTable: (
    ingredient: string,
  ) => Promise<Record<string, unknown> | null>;
  usda: (ingredient: string) => Promise<Record<string, unknown> | null>;
  now?: () => Date;
};

export async function lookupFoodEvidence(
  ingredient: string,
  providers: FoodEvidenceProviders,
): Promise<Record<string, unknown>> {
  const retrievedAt = (providers.now ?? (() => new Date()))().toISOString();
  try {
    const national = await providers.nationalTable(ingredient);
    if (national) return national;
  } catch {
    // A temporary national-source outage still allows the approved USDA source
    // to provide evidence. Ingredient names and failures are never logged.
  }

  const usda = await providers.usda(ingredient);
  return usda ?? notFoundFoodEvidence(ingredient, retrievedAt);
}

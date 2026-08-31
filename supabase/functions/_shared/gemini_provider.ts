export type GeminiProviderRequest = {
  model: string;
  generationConfig: Record<string, unknown>;
  modelFallback: boolean;
};

export type GeminiModelInput = {
  model: string;
  generationConfig: Record<string, unknown>;
};

/**
 * Resolves the provider model and its compatible generation config together.
 * The Edge Function must never send a config authored for a rejected model to
 * the fallback model unchanged.
 */
export function resolveGeminiProviderRequest(
  input: GeminiModelInput,
  allowedModels: ReadonlySet<string>,
  defaultModel: string,
): GeminiProviderRequest {
  const model = allowedModels.has(input.model) ? input.model : defaultModel;
  return {
    model,
    generationConfig: normalizeGenerationConfigForModel(
      model,
      input.generationConfig,
    ),
    modelFallback: input.model !== model,
  };
}

/**
 * Removes only the Gemini 3 thinking-level setting when the final provider
 * model is Gemini 2.5. Generic generation fields and a compatible
 * thinkingBudget remain intact.
 */
export function normalizeGenerationConfigForModel(
  model: string,
  generationConfig: Record<string, unknown>,
): Record<string, unknown> {
  const normalizedModel = model.trim().replace(/^models\//, "");
  if (!normalizedModel.startsWith("gemini-2.5-")) return generationConfig;

  const thinkingConfig = generationConfig.thinkingConfig;
  if (thinkingConfig == null) return generationConfig;
  if (!isRecord(thinkingConfig)) {
    const normalized = { ...generationConfig };
    delete normalized.thinkingConfig;
    return normalized;
  }
  if (!("thinkingLevel" in thinkingConfig)) return generationConfig;

  const normalizedThinkingConfig = { ...thinkingConfig };
  delete normalizedThinkingConfig.thinkingLevel;
  const normalized = { ...generationConfig };
  if (Object.keys(normalizedThinkingConfig).length === 0) {
    delete normalized.thinkingConfig;
  } else {
    normalized.thinkingConfig = normalizedThinkingConfig;
  }
  return normalized;
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

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
 * Normalizes thinking settings for the selected model family. Gemini 2.5
 * uses thinkingBudget; Gemini 3 uses thinkingLevel.
 */
export function normalizeGenerationConfigForModel(
  model: string,
  generationConfig: Record<string, unknown>,
): Record<string, unknown> {
  const normalizedModel = model.trim().replace(/^models\//, "");
  const isGemini25 = normalizedModel.startsWith("gemini-2.5-");
  const isGemini3 = normalizedModel.startsWith("gemini-3.");
  if (!isGemini25 && !isGemini3) return generationConfig;

  const thinkingConfig = generationConfig.thinkingConfig;
  if (thinkingConfig == null) return generationConfig;
  if (!isRecord(thinkingConfig)) {
    const normalized = { ...generationConfig };
    delete normalized.thinkingConfig;
    return normalized;
  }
  const normalizedThinkingConfig = { ...thinkingConfig };
  if (isGemini25) delete normalizedThinkingConfig.thinkingLevel;
  if (isGemini3) {
    delete normalizedThinkingConfig.thinkingBudget;
    if (!normalizedThinkingConfig.thinkingLevel) {
      normalizedThinkingConfig.thinkingLevel = "medium";
    }
  }
  if (
    Object.keys(normalizedThinkingConfig).length ===
    Object.keys(thinkingConfig).length &&
    Object.keys(normalizedThinkingConfig).every((key) => key in thinkingConfig)
  ) {
    return generationConfig;
  }
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

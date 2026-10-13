export type GeminiContextPreflight = {
  inputTokens: number;
  inputTokenLimit: number;
  outputTokenLimit: number;
};

export class GeminiProviderHttpError extends Error {
  readonly providerStatus: string | null;

  constructor(statusCode: number, payload: unknown) {
    super(`provider_${statusCode}`);
    this.name = "GeminiProviderHttpError";
    this.providerStatus = safeGeminiProviderStatus(payload);
  }
}

type GeminiRequestContextArgs = {
  model: string;
  apiKey: string;
  contents: unknown[];
  generationConfig: Record<string, unknown>;
  systemInstruction: string | null;
  fetcher?: typeof fetch;
  onPhase?: (phase: "model_metadata" | "count_tokens") => void;
};

type GeminiModelLimits = {
  inputTokenLimit: number;
  outputTokenLimit: number;
  expiresAt: number;
};

const MODEL_LIMIT_CACHE_TTL_MS = 60 * 60 * 1000;
const modelLimitCache = new Map<string, GeminiModelLimits>();

export async function inspectGeminiRequestContext(
  args: GeminiRequestContextArgs,
): Promise<GeminiContextPreflight> {
  const fetcher = args.fetcher ?? fetch;
  const modelId = args.model.replace(/^models\//, "").trim();
  const modelUrl = `https://generativelanguage.googleapis.com/v1beta/models/${
    encodeURIComponent(modelId)
  }`;
  const headers = { "x-goog-api-key": args.apiKey };

  let cachedLimits = modelLimitCache.get(modelUrl);
  if (cachedLimits && cachedLimits.expiresAt <= Date.now()) {
    modelLimitCache.delete(modelUrl);
    cachedLimits = undefined;
  }
  if (!cachedLimits) {
    args.onPhase?.("model_metadata");
    let modelResponse: Response;
    try {
      modelResponse = await fetcher(modelUrl, { method: "GET", headers });
    } catch (error) {
      throw providerFetchError(error);
    }
    const modelPayload = await modelResponse.json().catch(() => null);
    if (!modelResponse.ok) {
      throw new GeminiProviderHttpError(modelResponse.status, modelPayload);
    }
    if (!isRecord(modelPayload)) {
      throw new Error("provider_invalid_model_metadata");
    }
    const inputTokenLimit = positiveInteger(modelPayload.inputTokenLimit);
    const outputTokenLimit = positiveInteger(modelPayload.outputTokenLimit);
    if (inputTokenLimit == null || outputTokenLimit == null) {
      throw new Error("provider_invalid_model_metadata");
    }
    cachedLimits = {
      inputTokenLimit,
      outputTokenLimit,
      expiresAt: Date.now() + MODEL_LIMIT_CACHE_TTL_MS,
    };
    modelLimitCache.set(modelUrl, cachedLimits);
  }

  const countUrl = `${modelUrl}:countTokens`;
  const generateContentRequest = {
    // CountTokensRequest requires the fully qualified model on its nested
    // GenerateContentRequest even though the endpoint already names the model.
    model: `models/${modelId}`,
    contents: args.contents,
    generationConfig: args.generationConfig,
    ...(args.systemInstruction
      ? { systemInstruction: { parts: [{ text: args.systemInstruction }] } }
      : {}),
  };
  args.onPhase?.("count_tokens");
  let countResponse: Response;
  try {
    countResponse = await fetcher(countUrl, {
      method: "POST",
      headers: { ...headers, "content-type": "application/json" },
      body: JSON.stringify({ generateContentRequest }),
    });
  } catch (error) {
    throw providerFetchError(error);
  }
  const countPayload = await countResponse.json().catch(() => null);
  if (!countResponse.ok) {
    throw new GeminiProviderHttpError(countResponse.status, countPayload);
  }
  const inputTokens = isRecord(countPayload)
    ? nonNegativeInteger(countPayload.totalTokens)
    : null;
  if (inputTokens == null) throw new Error("provider_invalid_token_count");

  return {
    inputTokens,
    inputTokenLimit: cachedLimits.inputTokenLimit,
    outputTokenLimit: cachedLimits.outputTokenLimit,
  };
}

function providerFetchError(error: unknown): Error {
  if (
    error instanceof Error &&
    /^provider_(?:network_error|timeout)$/.test(error.message)
  ) {
    return error;
  }
  return new Error("provider_network_error");
}

export function assertGeminiContextWithinLimits(
  context: GeminiContextPreflight,
  generationConfig: Record<string, unknown>,
): void {
  if (context.inputTokens > context.inputTokenLimit) {
    throw new Error("provider_input_token_limit");
  }
  const requestedOutputTokens = generationConfig.maxOutputTokens;
  if (
    typeof requestedOutputTokens === "number" &&
    Number.isInteger(requestedOutputTokens) &&
    requestedOutputTokens > context.outputTokenLimit
  ) {
    throw new Error("provider_output_token_limit");
  }
}

export function safeGeminiProviderStatus(payload: unknown): string | null {
  if (!isRecord(payload) || !isRecord(payload.error)) return null;
  const status = payload.error.status;
  return typeof status === "string" && /^[A-Z][A-Z0-9_]{0,63}$/.test(status)
    ? status
    : null;
}

function positiveInteger(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) && value > 0
    ? value
    : null;
}

function nonNegativeInteger(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) && value >= 0
    ? value
    : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

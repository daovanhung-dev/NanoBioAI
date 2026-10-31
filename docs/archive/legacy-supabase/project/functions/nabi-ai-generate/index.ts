import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { extractGeminiResponse } from "../_shared/gemini_response.ts";
import {
  assertGeminiContextWithinLimits,
  type GeminiContextPreflight,
  GeminiProviderHttpError,
  inspectGeminiRequestContext,
  safeGeminiProviderStatus,
} from "./gemini_context.ts";

import {
  createNabiAiGenerateHandler,
  NabiAiGenerateInput,
  resolveGeminiProviderRequest,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const geminiApiKey = requiredEnvironment("GEMINI_API_KEY");
const defaultModel = Deno.env.get("GEMINI_MODEL")?.trim() || "gemini-2.5-flash";
const configuredAllowedModels =
  Deno.env.get("GEMINI_ALLOWED_MODELS") || defaultModel;
const allowedModels = new Set([
  ...configuredAllowedModels
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean),
  // Always allow the stable escalation model used by v1 schedule generation.
  "gemini-3.8-flash",
]);
const rateWindowMs = 60 * 60 * 1000;
const rateLimitPerWindow = 300;
const rateWindows = new Map<string, number[]>();
const providerRequestTimeoutMs = 60_000;

Deno.serve(createNabiAiGenerateHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  rateLimit: async (key) => {
    const now = Date.now();
    const recent = (rateWindows.get(key) || []).filter(
      (timestamp) => now - timestamp < rateWindowMs,
    );
    if (recent.length >= rateLimitPerWindow) {
      rateWindows.set(key, recent);
      return false;
    }
    recent.push(now);
    rateWindows.set(key, recent);
    return true;
  },
  generate: generateWithGemini,
}));

async function generateWithGemini(input: NabiAiGenerateInput): Promise<string> {
  const startedAt = Date.now();
  const providerRequest = resolveGeminiProviderRequest(
    input,
    allowedModels,
    defaultModel,
  );
  const { model, generationConfig, modelFallback } = providerRequest;
  const providerFetch = createProviderFetch();
  let preflightPhase: "model_metadata" | "count_tokens" = "model_metadata";
  let context: GeminiContextPreflight;
  try {
    context = await inspectGeminiRequestContext({
      model,
      apiKey: geminiApiKey,
      contents: input.contents,
      generationConfig,
      systemInstruction: input.systemInstruction,
      fetcher: providerFetch,
      onPhase: (phase) => {
        preflightPhase = phase;
        console.info(JSON.stringify({
          component: "gemini-provider",
          event: "PROVIDER_PREFLIGHT_PHASE",
          traceId: input.traceId,
          model,
          stage: phase,
        }));
      },
    });
  } catch (error) {
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_PREFLIGHT_FAILURE",
      traceId: input.traceId,
      model,
      stage: preflightPhase,
      errorCode: safeProviderErrorCode(error),
    }));
    throw new ProviderFailure(
      safeProviderErrorCode(error),
      preflightPhase,
      error instanceof GeminiProviderHttpError ? error.providerStatus : null,
    );
  }
  console.info(JSON.stringify({
    component: "gemini-provider",
    event: "PROVIDER_CONTEXT_PREFLIGHT",
    traceId: input.traceId,
    model,
    inputTokens: context.inputTokens,
    inputTokenLimit: context.inputTokenLimit,
    outputTokenLimit: context.outputTokenLimit,
  }));
  assertGeminiContextWithinLimits(context, generationConfig);

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${
    encodeURIComponent(model)
  }:generateContent`;

  console.info(JSON.stringify({
    component: "gemini-provider",
    event: "PROVIDER_REQUEST_START",
    traceId: input.traceId,
    model,
    modelFallback,
  }));

  let response: Response;
  try {
    response = await providerFetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": geminiApiKey,
      },
      body: JSON.stringify({
        contents: input.contents,
        generationConfig,
        ...(input.systemInstruction
          ? {
            systemInstruction: { parts: [{ text: input.systemInstruction }] },
          }
          : {}),
      }),
    });
  } catch (error) {
    const errorCode = safeProviderErrorCode(error);
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_NETWORK_FAILURE",
      traceId: input.traceId,
      model,
      modelFallback,
      stage: "generate_content",
      errorCode,
      durationMs: Date.now() - startedAt,
    }));
    throw new ProviderFailure(errorCode, "generate_content");
  }

  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const errorCode = `provider_${response.status}`;
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_HTTP_FAILURE",
      traceId: input.traceId,
      model,
      modelFallback,
      statusCode: response.status,
      errorCode,
      durationMs: Date.now() - startedAt,
    }));
    throw new ProviderFailure(
      errorCode,
      "generate_content",
      safeGeminiProviderStatus(payload),
    );
  }

  const responseSummary = summarizeProviderPayload(payload);
  const extracted = extractGeminiResponse(payload);
  if (extracted.finishReason?.toUpperCase() === "MAX_TOKENS") {
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_OUTPUT_TRUNCATED",
      traceId: input.traceId,
      model,
      modelFallback,
      statusCode: response.status,
      errorCode: "provider_max_tokens",
      ...responseSummary,
      durationMs: Date.now() - startedAt,
    }));
    throw new Error("provider_max_tokens");
  }

  const text = extracted.text;
  if (!text) {
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_EMPTY_RESPONSE",
      traceId: input.traceId,
      model,
      modelFallback,
      statusCode: response.status,
      errorCode: "provider_empty_response",
      ...responseSummary,
      durationMs: Date.now() - startedAt,
    }));
    throw new Error("provider_empty_response");
  }

  console.info(JSON.stringify({
    component: "gemini-provider",
    event: "PROVIDER_REQUEST_SUCCESS",
    traceId: input.traceId,
    model,
    modelFallback,
    statusCode: response.status,
    responseLength: text.length,
    ...responseSummary,
    durationMs: Date.now() - startedAt,
  }));
  return text;
}

function createProviderFetch(): typeof fetch {
  return async (input, init = {}) => {
    try {
      return await fetch(input, {
        ...init,
        signal: AbortSignal.timeout(providerRequestTimeoutMs),
      });
    } catch (error) {
      if (error instanceof Error && error.name === "TimeoutError") {
        throw new Error("provider_timeout");
      }
      throw new Error("provider_network_error");
    }
  };
}

class ProviderFailure extends Error {
  constructor(
    code: string,
    readonly providerPhase:
      | "model_metadata"
      | "count_tokens"
      | "generate_content",
    readonly providerStatus: string | null = null,
  ) {
    super(code);
  }
}

function summarizeProviderPayload(payload: unknown): Record<string, unknown> {
  const candidates = isRecord(payload) && Array.isArray(payload.candidates)
    ? payload.candidates
    : [];
  let contentPartCount = 0;
  let textPartCount = 0;
  let thoughtPartCount = 0;
  let finishReason: string | null = null;

  for (const candidate of candidates) {
    if (!isRecord(candidate)) continue;
    const candidateFinishReason = safeProviderLabel(candidate.finishReason);
    if (
      finishReason == null ||
      candidateFinishReason?.toUpperCase() === "MAX_TOKENS"
    ) {
      finishReason = candidateFinishReason;
    }
    const content = candidate.content;
    if (!isRecord(content) || !Array.isArray(content.parts)) continue;
    for (const part of content.parts) {
      if (!isRecord(part)) continue;
      contentPartCount++;
      if (part.thought === true) thoughtPartCount++;
      if (typeof part.text === "string" && part.text.trim()) textPartCount++;
    }
  }

  const promptFeedback = isRecord(payload) && isRecord(payload.promptFeedback)
    ? payload.promptFeedback
    : null;
  return {
    candidateCount: candidates.length,
    contentPartCount,
    textPartCount,
    thoughtPartCount,
    finishReason,
    blockReason: promptFeedback == null
      ? null
      : safeProviderLabel(promptFeedback.blockReason),
  };
}

function safeProviderLabel(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return /^[A-Za-z][A-Za-z0-9_.-]{0,79}$/.test(normalized) ? normalized : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

function safeProviderErrorCode(error: unknown): string {
  const code = error instanceof Error ? error.message.trim() : "";
  return /^provider_(?:[1-5]\d\d|network_error|timeout|empty_response|invalid_response|max_tokens|input_token_limit|output_token_limit|invalid_model_metadata|invalid_token_count)$/
      .test(
        code,
      )
    ? code
    : "provider_unknown_error";
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    console.error(JSON.stringify({
      component: "nabi-ai-generate",
      event: "CONFIGURATION_FAILURE",
      errorCode: "missing_required_secret",
      secretName: name,
    }));
    throw new Error(`Missing required Edge Function secret: ${name}`);
  }
  return value;
}

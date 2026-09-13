import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { extractGeminiResponse } from "../_shared/gemini_response.ts";

import {
  createNabiAiGenerateHandler,
  NabiAiGenerateInput,
  resolveGeminiProviderRequest,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const geminiApiKey = requiredEnvironment("GEMINI_API_KEY");
const defaultModel = Deno.env.get("GEMINI_MODEL")?.trim() || "gemini-2.5-flash";
const allowedModels = new Set(
  (Deno.env.get("GEMINI_ALLOWED_MODELS") || defaultModel)
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean),
);
const rateWindowMs = 60 * 60 * 1000;
const rateLimitPerWindow = 30;
const rateWindows = new Map<string, number[]>();

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
    response = await fetch(url, {
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
  } catch {
    console.error(JSON.stringify({
      component: "gemini-provider",
      event: "PROVIDER_NETWORK_FAILURE",
      traceId: input.traceId,
      model,
      modelFallback,
      errorCode: "provider_network_error",
      durationMs: Date.now() - startedAt,
    }));
    throw new Error("provider_network_error");
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
    throw new Error(errorCode);
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

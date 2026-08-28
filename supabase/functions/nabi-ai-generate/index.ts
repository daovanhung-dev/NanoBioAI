import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createNabiAiGenerateHandler, NabiAiGenerateInput } from "./handler.ts";

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
    const recent = (rateWindows.get(key) || []).filter((timestamp) => now - timestamp < rateWindowMs);
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
  const model = allowedModels.has(input.model) ? input.model : defaultModel;
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-goog-api-key": geminiApiKey,
    },
    body: JSON.stringify({
      contents: input.contents,
      generationConfig: input.generationConfig,
      ...(input.systemInstruction
        ? { systemInstruction: { parts: [{ text: input.systemInstruction }] } }
        : {}),
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(`provider_${response.status}`);
  }
  const candidates = payload?.candidates;
  const fragments: string[] = [];
  if (Array.isArray(candidates)) {
    for (const candidate of candidates) {
      const parts = candidate?.content?.parts;
      if (!Array.isArray(parts)) continue;
      for (const part of parts) {
        if (part?.thought === true) continue;
        if (typeof part?.text === "string") fragments.push(part.text);
      }
    }
  }
  const text = fragments.join("").trim();
  if (!text) throw new Error("provider_empty_response");
  return text;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}


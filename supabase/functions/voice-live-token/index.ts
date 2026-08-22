import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createGeminiEphemeralTokenRequest,
  createVoiceLiveTokenHandler,
  defaultVoiceLiveModel,
  type EphemeralTokenInput,
  parseGeminiEphemeralTokenResponse,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const geminiApiKey = requiredEnvironment("GEMINI_API_KEY");

const handler = createVoiceLiveTokenHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const client = createUserClient(authorization);
    const { data, error } = await client.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  hasPaidAccess,
  createEphemeralToken: issueGeminiEphemeralToken,
  now: () => new Date(),
  model: optionalEnvironment("GEMINI_LIVE_MODEL") ?? defaultVoiceLiveModel,
  systemInstruction: optionalEnvironment("GEMINI_LIVE_SYSTEM_INSTRUCTION"),
});

Deno.serve(handler);

function createUserClient(authorization: string) {
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function hasPaidAccess(
  userId: string,
  authorization: string,
): Promise<boolean> {
  // This request deliberately stays scoped to the caller's JWT. The
  // security-invoker view/RLS then prevents a caller from checking or using
  // another account's paid access.
  const { data, error } = await createUserClient(authorization)
    .from("effective_user_access")
    .select("user_id,is_anonymous,membership_plan")
    .eq("user_id", userId)
    .maybeSingle();
  if (error != null) throw new Error("Membership access lookup failed.");

  if (data == null || typeof data !== "object") return false;
  const row = data as Record<string, unknown>;
  const membershipPlan = typeof row.membership_plan === "string"
    ? row.membership_plan.trim().toLowerCase()
    : "";
  return row.user_id === userId &&
    row.is_anonymous !== true &&
    (membershipPlan === "plus" || membershipPlan === "family_plus");
}

async function issueGeminiEphemeralToken(
  input: EphemeralTokenInput,
): Promise<{ value: string; expiresAt: string }> {
  const response = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/auth_tokens",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiApiKey,
      },
      body: JSON.stringify(createGeminiEphemeralTokenRequest(input)),
    },
  );
  if (!response.ok) throw new Error("Gemini ephemeral-token request failed.");
  const token = parseGeminiEphemeralTokenResponse(await response.json());
  if (token == null) throw new Error("Gemini token payload invalid.");
  return token;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

function optionalEnvironment(name: string): string | undefined {
  return Deno.env.get(name)?.trim() || undefined;
}

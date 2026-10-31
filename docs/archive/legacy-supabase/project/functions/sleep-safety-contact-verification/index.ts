import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createGenericHttpSleepSafetyProvider } from "../_shared/sleep_safety_provider.ts";
import { createSleepSafetyContactVerificationHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const supabaseServiceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const provider = createGenericHttpSleepSafetyProvider({
  baseUrl: requiredEnvironment("SLEEP_SAFETY_PROVIDER_BASE_URL"),
  token: requiredEnvironment("SLEEP_SAFETY_PROVIDER_TOKEN"),
});

const admin = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const handler = createSleepSafetyContactVerificationHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const user = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await user.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  getContact: async (userId, contactId) => {
    const { data, error } = await admin
      .from("sleep_safety_contacts")
      .select("id,user_id,phone_e164,active")
      .eq("id", contactId)
      .eq("user_id", userId)
      .maybeSingle();
    if (error || !data) return null;
    return {
      id: data.id,
      userId: data.user_id,
      phoneE164: data.phone_e164,
      active: data.active === true,
    };
  },
  countRecentChallenges: async (userId, contactId) => {
    const since = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { count, error } = await admin
      .from("sleep_safety_contact_verification_challenges")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("contact_id", contactId)
      .gte("created_at", since);
    if (error) throw error;
    return count ?? 0;
  },
  createChallenge: async (input) => {
    const { data, error } = await admin
      .from("sleep_safety_contact_verification_challenges")
      .insert({
        user_id: input.userId,
        contact_id: input.contactId,
        code_hash: input.codeHash,
        expires_at: input.expiresAt,
      })
      .select("id")
      .single();
    if (error) throw error;
    return data.id;
  },
  getActiveChallenge: async (userId, contactId) => {
    const { data, error } = await admin
      .from("sleep_safety_contact_verification_challenges")
      .select("id,contact_id,code_hash,attempt_count,expires_at,status")
      .eq("user_id", userId)
      .eq("contact_id", contactId)
      .eq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error || !data) return null;
    return {
      id: data.id,
      contactId: data.contact_id,
      codeHash: data.code_hash,
      attemptCount: data.attempt_count,
      expiresAt: data.expires_at,
      status: data.status,
    };
  },
  updateChallenge: async (id, values) => {
    const { error } = await admin
      .from("sleep_safety_contact_verification_challenges")
      .update(values)
      .eq("id", id);
    if (error) throw error;
  },
  markContactVerified: async (userId, contactId) => {
    const { error } = await admin
      .from("sleep_safety_contacts")
      .update({ verification_status: "verified", verified_at: new Date().toISOString() })
      .eq("id", contactId)
      .eq("user_id", userId);
    if (error) throw error;
  },
  sendCode: async ({ phoneE164, code, idempotencyKey }) => {
    const result = await provider.send("verification", {
      to: phoneE164,
      message: `Mã xác minh người liên hệ an toàn NanoBio của bạn là ${code}. Mã có hiệu lực trong 10 phút.`,
      idempotencyKey,
    });
    return result.status !== "failed" && result.status !== "no_answer";
  },
  hash: sha256,
  generateCode: () => String(crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000).padStart(6, "0"),
  now: () => new Date(),
  verificationTtlSeconds: async () => {
    const { data } = await admin
      .from("sleep_safety_runtime_config")
      .select("contact_verification_ttl_seconds")
      .eq("config_key", "default")
      .maybeSingle();
    return data?.contact_verification_ttl_seconds ?? 600;
  },
});

Deno.serve(handler);

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

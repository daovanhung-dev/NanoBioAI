import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createGenericHttpSleepSafetyProvider } from "../_shared/sleep_safety_provider.ts";
import { createSleepSafetyDispatchHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const supabaseServiceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const callbackToken = Deno.env.get("SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET")?.trim();
const admin = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const provider = createGenericHttpSleepSafetyProvider({
  baseUrl: requiredEnvironment("SLEEP_SAFETY_PROVIDER_BASE_URL"),
  token: requiredEnvironment("SLEEP_SAFETY_PROVIDER_TOKEN"),
  callbackUrl: `${supabaseUrl}/functions/v1/sleep-safety-provider-webhook`,
  callbackToken,
});

const handler = createSleepSafetyDispatchHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const user = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await user.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  getRuntimeConfig: async () => {
    const { data, error } = await admin
      .from("sleep_safety_runtime_config")
      .select("enabled,max_dispatches_per_hour,event_freshness_seconds")
      .eq("config_key", "default")
      .single();
    if (error) throw error;
    return {
      enabled: data.enabled === true,
      maxPerHour: data.max_dispatches_per_hour,
      freshnessSeconds: data.event_freshness_seconds,
    };
  },
  hasPaidAccess: async (userId) => {
    const { data, error } = await admin
      .from("effective_user_access")
      .select("membership_plan,is_anonymous")
      .eq("user_id", userId)
      .maybeSingle();
    if (error || !data || data.is_anonymous === true) return false;
    return data.membership_plan === "plus" || data.membership_plan === "family_plus";
  },
  getEvent: async (userId, eventId) => {
    const { data, error } = await admin
      .from("sleep_safety_events")
      .select("id,user_id,detected_at,response,escalation_required")
      .eq("id", eventId)
      .eq("user_id", userId)
      .maybeSingle();
    if (error || !data) return null;
    return {
      id: data.id,
      userId: data.user_id,
      detectedAt: data.detected_at,
      response: data.response,
      escalationRequired: data.escalation_required === true,
    };
  },
  getVerifiedContacts: async (userId) => {
    const { data, error } = await admin
      .from("sleep_safety_contacts")
      .select("id,phone_e164,priority")
      .eq("user_id", userId)
      .eq("active", true)
      .eq("verification_status", "verified")
      .order("priority", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((row) => ({
      id: row.id,
      phoneE164: row.phone_e164,
      priority: row.priority,
    }));
  },
  countRecentRequests: async (userId) => {
    const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { data, error } = await admin
      .from("sleep_safety_dispatches")
      .select("idempotency_key")
      .eq("user_id", userId)
      .gte("created_at", since);
    if (error) throw error;
    return new Set((data ?? []).map((row) => row.idempotency_key)).size;
  },
  getExisting: async (userId, idempotencyKey) => {
    const { data, error } = await admin
      .from("sleep_safety_dispatches")
      .select("id,contact_id,priority,channel,status,provider_external_id")
      .eq("user_id", userId)
      .eq("idempotency_key", idempotencyKey);
    if (error) throw error;
    return (data ?? []).map((row) => ({
      id: row.id,
      contactId: row.contact_id,
      priority: row.priority,
      channel: row.channel,
      status: row.status,
      providerExternalId: row.provider_external_id,
    }));
  },
  createDispatch: async (input) => {
    const { error } = await admin.from("sleep_safety_dispatches").insert({
      event_id: input.eventId,
      user_id: input.userId,
      contact_id: input.contactId,
      priority: input.priority,
      channel: input.channel,
      provider: "generic_http",
      provider_external_id: input.providerExternalId || null,
      status: input.status,
      idempotency_key: input.idempotencyKey,
    });
    if (error) throw error;
  },
  provider,
  now: () => new Date(),
  callbackUrl: `${supabaseUrl}/functions/v1/sleep-safety-provider-webhook`,
  callbackToken,
});

Deno.serve(handler);

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

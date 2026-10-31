import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { createEarlyAccessHandler, type EarlyAccessLead } from "./handler.ts";
import { hmacIpAddress } from "./rate_limit.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
});
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "").split(",").map((
  value,
) => value.trim()).filter(Boolean);
const appVersion = Deno.env.get("APP_VERSION")?.trim() || "1.0.1+4";

Deno.serve(createEarlyAccessHandler({
  allowedOrigins,
  appVersion,
  hmacIp: async (ip) => {
    const secret = Deno.env.get("EARLY_ACCESS_RATE_LIMIT_HMAC_KEY") ?? "";
    return await hmacIpAddress(ip, secret);
  },
  hmacPhone: async (phone) => {
    const secret = Deno.env.get("EARLY_ACCESS_PHONE_HMAC_KEY") ?? "";
    return await hmacIpAddress(`early-access-phone:${phone}`, secret);
  },
  consumeRateLimit: async (ipHash, windowStart) => {
    const { data, error } = await admin.rpc("consume_early_access_rate_limit", {
      p_ip_hash: ipHash,
      p_window_started_at: windowStart,
    });
    if (error) throw new Error("RATE_LIMIT_RPC_FAILED");
    return data === true;
  },
  saveLead: async (lead: EarlyAccessLead) => {
    const { error } = await admin.rpc("save_early_access_lead", {
      p_lead: lead,
    });
    if (error) {
      console.error("early_access_lead_insert_failed", {
        code: error.code ?? "unknown",
      });
      throw new Error("EARLY_ACCESS_INSERT_FAILED");
    }
  },
  getPublicDownloadUrl: async () => {
    const url = Deno.env.get("NANOBIO_APK_DOWNLOAD_URL")?.trim() ?? "";
    return url || null;
  },
}));

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment: ${name}`);
  return value;
}

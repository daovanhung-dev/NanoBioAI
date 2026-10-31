import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createFoodScanAnalyzeHandler,
  createGeminiFoodScanProvider,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const supabaseServiceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
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
const admin = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createFoodScanAnalyzeHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  hasPlusAccess: async (userId) => {
    const { data, error } = await admin
      .from("effective_user_access")
      .select("membership_plan,is_anonymous")
      .eq("user_id", userId)
      .maybeSingle();
    if (error || !data || data.is_anonymous === true) return false;
    return data.membership_plan === "plus" ||
      data.membership_plan === "family_plus";
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
  generate: createGeminiFoodScanProvider({
    apiKey: geminiApiKey,
    defaultModel,
    allowedModels,
  }),
}));

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    console.error(JSON.stringify({
      component: "food-scan-analyze",
      event: "CONFIGURATION_FAILURE",
      errorCode: "missing_required_secret",
      secretName: name,
    }));
    throw new Error(`Missing required Edge Function secret: ${name}`);
  }
  return value;
}

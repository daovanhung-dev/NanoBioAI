import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createReportAiContentHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const attempts = new Map<string, { count: number; resetAt: number }>();
const windowMs = 60 * 60 * 1000;
const maxReportsPerWindow = 10;

Deno.serve(createReportAiContentHandler({
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
    const previous = attempts.get(key);
    if (!previous || previous.resetAt <= now) {
      attempts.set(key, { count: 1, resetAt: now + windowMs });
      return true;
    }
    if (previous.count >= maxReportsPerWindow) return false;
    previous.count += 1;
    return true;
  },
  persist: async (input) => {
    const { data, error } = await admin
      .from("ai_content_reports")
      .insert({
        user_id: input.userId,
        installation_id: input.installationId,
        message_id: input.messageId,
        message_role: "assistant",
        reason_code: input.reasonCode,
        note: input.note,
        message_snapshot: input.messageSnapshot,
        app_version: input.appVersion,
        moderation_status: "pending",
      })
      .select("id")
      .single();
    if (error || !data?.id) throw error ?? new Error("REPORT_INSERT_FAILED");
    return data.id as string;
  },
}));

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment: ${name}`);
  return value;
}

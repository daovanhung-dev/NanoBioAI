import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  createEarlyAccessAdminHandler,
  type EarlyAccessAdminLead,
  type EarlyAccessLeadStatus,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const service = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "").split(",")
  .map((value) => value.trim()).filter(Boolean);
const allowedRoles = ["super_admin", "support_admin", "operations_admin"];

Deno.serve(createEarlyAccessAdminHandler({
  allowedOrigins,
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  isAllowedAdmin: async (actorId) => {
    const { data: actor, error: actorError } = await service.from("users")
      .select("admin_status").eq("id", actorId).maybeSingle();
    if (actorError || actor?.admin_status !== "active") return false;

    const { data: assignments, error: assignmentError } = await service
      .from("admin_user_roles").select("role_code")
      .eq("user_id", actorId).in("role_code", allowedRoles)
      .eq("is_active", true).is("revoked_at", null);
    if (assignmentError || !assignments?.length) return false;

    const assignedRoles = [...new Set(assignments.map((item) => item.role_code))];
    const { data: activeRoles, error: roleError } = await service
      .from("admin_roles").select("code").in("code", assignedRoles)
      .eq("is_active", true);
    return roleError == null && (activeRoles ?? []).some((role) =>
      allowedRoles.includes(role.code)
    );
  },
  listLeads: async (query, offset, pageSize) => {
    let request = service.from("early_access_leads").select(
      "id,phone_e164,phone_display,full_name,age,gender,address,status,created_at",
      { count: "exact" },
    ).order("created_at", { ascending: false }).range(offset, offset + pageSize - 1);
    if (query) {
      const pattern = `%${query}%`;
      request = request.or(
        `phone_display.ilike.${pattern},phone_e164.ilike.${pattern},full_name.ilike.${pattern},address.ilike.${pattern}`,
      );
    }
    const { data, count, error } = await request;
    if (error) throw error;
    return {
      rows: (data ?? []) as EarlyAccessAdminLead[],
      total: count ?? 0,
    };
  },
  updateStatus: async (input) => {
    const { data, error } = await service.rpc(
      "admin_update_early_access_lead_status",
      {
        p_lead_id: input.leadId,
        p_status: input.status as EarlyAccessLeadStatus,
        p_actor_id: input.actorId,
        p_reason: input.reason,
        p_idempotency_key: input.idempotencyKey,
      },
    );
    const result = data as { success?: unknown } | null;
    if (error || result?.success !== true) {
      throw error ?? new Error("EARLY_ACCESS_STATUS_UPDATE_FAILED");
    }
  },
}));

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment: ${name}`);
  return value;
}

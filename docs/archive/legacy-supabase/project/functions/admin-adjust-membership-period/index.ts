import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createAdminAdjustMembershipPeriodHandler,
  type MembershipPeriodAdjustment,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminAdjustMembershipPeriodHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  isAllowedAdmin: (actorId) => hasActiveAdminRole(actorId),
  adjust: async ({
    actorId,
    userId,
    subscriptionId,
    operation,
    days,
    endsAt,
    expectedEndsAt,
    reason,
    idempotencyKey,
  }) => {
    const { data, error } = await admin.rpc("admin_adjust_membership_period", {
      p_actor_id: actorId,
      p_user_id: userId,
      p_subscription_id: subscriptionId,
      p_operation: operation,
      p_days: days,
      p_ends_at: endsAt,
      p_expected_ends_at: expectedEndsAt,
      p_reason: reason,
      p_idempotency_key: idempotencyKey,
    });
    if (error) throw error;

    const row = firstRecord(data);
    if (!row) throw new Error("Membership adjustment returned no result");
    return {
      subscriptionId: textOrThrow(row.subscription_id),
      planCode: textOrThrow(row.plan_code),
      status: textOrThrow(row.status),
      startsAt: textOrThrow(row.starts_at),
      previousEndsAt: nullableText(row.previous_ends_at),
      endsAt: nullableText(row.ends_at),
      operation: textOrThrow(row.operation),
      deltaDays: nullableInteger(row.delta_days),
    } satisfies MembershipPeriodAdjustment;
  },
}));

async function hasActiveAdminRole(actorId: string): Promise<boolean> {
  const { data: assignments, error: assignmentError } = await admin
    .from("admin_user_roles")
    .select("role_code")
    .eq("user_id", actorId)
    .eq("role_code", "super_admin")
    .eq("is_active", true)
    .is("revoked_at", null)
    .limit(1);
  if (assignmentError || !assignments?.length) return false;

  const { data: role, error: roleError } = await admin
    .from("admin_roles")
    .select("code")
    .eq("code", "super_admin")
    .eq("is_active", true)
    .maybeSingle();
  if (roleError || role?.code !== "super_admin") return false;

  const { data: user, error: userError } = await admin
    .from("users")
    .select("admin_status")
    .eq("id", actorId)
    .maybeSingle();
  return userError == null && user?.admin_status === "active";
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

function firstRecord(value: unknown): Record<string, unknown> | null {
  if (Array.isArray(value) && value.length > 0) return record(value[0]);
  return record(value);
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function textOrThrow(value: unknown): string {
  if (typeof value === "string" && value.trim()) return value;
  throw new Error("Membership adjustment response incomplete");
}

function nullableText(value: unknown): string | null {
  return value === null || value === undefined ? null : textOrThrow(value);
}

function nullableInteger(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "number" && Number.isInteger(value)) return value;
  throw new Error("Membership adjustment response incomplete");
}

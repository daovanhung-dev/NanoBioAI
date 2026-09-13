import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  type BulkMembershipGrant,
  createAdminGrantMembershipBulkHandler,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminGrantMembershipBulkHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  isAllowedAdmin: (actorId) => hasActiveAdminRole(actorId, ["super_admin"]),
  findIdempotentResult: async (idempotencyKey) => {
    const { data, error } = await admin
      .from("admin_audit_events")
      .select("metadata")
      .eq("action", "admin_grant_membership_bulk")
      .eq("target_type", "membership_batch")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();
    if (error || !data?.metadata || typeof data.metadata !== "object") {
      return null;
    }

    const metadata = data.metadata as Record<string, unknown>;
    return readGrant(metadata, idempotencyKey);
  },
  grant: async ({
    actorId,
    scope,
    planCode,
    startsAt,
    endsAt,
    reason,
    idempotencyKey,
  }) => {
    const { data, error } = await admin.rpc("admin_grant_membership_bulk", {
      p_actor_id: actorId,
      p_scope: scope,
      p_plan_code: planCode,
      p_starts_at: startsAt,
      p_ends_at: endsAt,
      p_reason: reason,
      p_idempotency_key: idempotencyKey,
    });
    if (error) throw error;

    const row = firstRecord(data);
    if (!row) throw new Error("Bulk membership RPC returned no result");
    return {
      batchId: textOrThrow(row.batch_id),
      planCode: textOrThrow(row.plan_code ?? "plus"),
      startsAt,
      endsAt: null,
      targetCount: integer(row.target_count),
      grantedCount: integer(row.granted_count),
      alreadyGrantedCount: integer(row.already_granted_count),
      familyPlusCount: integer(row.family_plus_count),
    };
  },
}));

async function hasActiveAdminRole(
  actorId: string,
  allowedRoles: string[],
): Promise<boolean> {
  const { data: assignments, error: assignmentError } = await admin
    .from("admin_user_roles")
    .select("role_code")
    .eq("user_id", actorId)
    .eq("is_active", true)
    .is("revoked_at", null)
    .in("role_code", allowedRoles);
  if (assignmentError || !assignments?.length) return false;

  const assignedCodes = assignments
    .map((row) => row.role_code)
    .filter((value): value is string => typeof value === "string");
  if (!assignedCodes.length) return false;

  const { data: activeRoles, error: roleError } = await admin
    .from("admin_roles")
    .select("code")
    .eq("is_active", true)
    .in("code", assignedCodes)
    .limit(1);
  return roleError == null && (activeRoles?.length ?? 0) > 0;
}

function readGrant(
  metadata: Record<string, unknown>,
  fallbackBatchId: string,
): BulkMembershipGrant | null {
  const batchId = text(metadata.batch_id) ?? fallbackBatchId;
  const planCode = text(metadata.plan_code);
  const startsAt = text(metadata.starts_at);
  if (!planCode || !startsAt) return null;
  return {
    batchId,
    planCode,
    startsAt,
    endsAt: null,
    targetCount: integer(metadata.target_count),
    grantedCount: integer(metadata.granted_count),
    alreadyGrantedCount: integer(metadata.already_granted_count),
    familyPlusCount: integer(metadata.family_plus_count),
  };
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

function integer(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : 0;
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length === 0 ? null : result;
}

function textOrThrow(value: unknown): string {
  const result = text(value);
  if (!result) {
    throw new Error("Bulk membership RPC returned incomplete result");
  }
  return result;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

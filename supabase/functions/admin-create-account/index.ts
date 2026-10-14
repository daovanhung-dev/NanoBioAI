import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createAdminCreateAccountHandler } from "./handler.ts";
import {
  memberAuthEmail,
  normalizeVietnamPhone,
} from "../_shared/member_phone_identity.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminCreateAccountHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  isAllowedAdmin: (actorId) =>
    hasActiveAdminRole(actorId, ["super_admin", "support_admin"]),
  findIdempotentResult: async (idempotencyKey) => {
    const { data: audit } = await admin
      .from("admin_audit_events")
      .select("target_id")
      .eq("action", "admin_create_account")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();
    const userId = audit?.target_id?.toString();
    if (!userId) return null;
    const { data: user } = await admin
      .from("users")
      .select("id,email")
      .eq("id", userId)
      .maybeSingle();
    return user?.id
      ? {
        userId: user.id,
        email: typeof user.email === "string" ? user.email : null,
      }
      : null;
  },
  createUser: async ({ email, password, fullName, phone }) => {
    for (let from = 0;; from += 1000) {
      const { data: existingProfiles, error: profileLookupError } = await admin
        .from("users")
        .select("phone")
        .not("phone", "is", null)
        .range(from, from + 999);
      if (profileLookupError) throw profileLookupError;
      if (
        (existingProfiles ?? []).some((row) =>
          normalizeVietnamPhone(
            typeof row.phone === "string" ? row.phone : "",
          ) ===
            phone
        )
      ) {
        throw new Error("phone_exists");
      }
      if ((existingProfiles ?? []).length < 1000) break;
    }
    const { data, error } = await admin.auth.admin.createUser({
      email: memberAuthEmail(phone),
      email_confirm: true,
      password,
      user_metadata: {
        full_name: fullName,
        phone,
        auth_login_method: "member_phone_password",
        ...(email ? { contact_email: email } : {}),
      },
    });
    if (error || !data.user) {
      throw error ?? new Error("Account creation failed");
    }
    const { error: profileError } = await admin
      .from("users")
      .update({ email })
      .eq("id", data.user.id);
    if (profileError) {
      await admin.auth.admin.deleteUser(data.user.id);
      throw profileError;
    }
    return { userId: data.user.id, email };
  },
  deleteUser: async (userId) => {
    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) throw error;
  },
  writeAudit: async ({ actorId, userId, email, reason, idempotencyKey }) => {
    const { error } = await admin.from("admin_audit_events").insert({
      actor_id: actorId,
      action: "admin_create_account",
      target_type: "user",
      target_id: userId,
      reason,
      idempotency_key: idempotencyKey,
      metadata: { email },
    });
    if (error) throw error;
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

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

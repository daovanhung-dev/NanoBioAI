import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createAdminUserManagementHandler,
  type UserManagementDetails,
  type UserManagementIdempotency,
  UserManagementRequestError,
  type UserProfileChanges,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminUserManagementHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  isAllowedAdmin: (actorId) => hasActiveSuperAdmin(actorId),
  findIdempotency: async (action, idempotencyKey) => {
    const { data, error } = await admin
      .from("admin_audit_events")
      .select("target_id,metadata")
      .eq("action", action)
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();
    if (error) throw error;
    if (!data?.target_id) return null;
    const metadata = record(data.metadata);
    return {
      targetId: String(data.target_id),
      status: metadata?.status === "started" ? "started" : "completed",
      changedFields: arrayOfStrings(metadata?.changed_fields),
    } satisfies UserManagementIdempotency;
  },
  getDetails: (userId) => getUserDetails(userId),
  updateProfile: ({ userId, changes }) => updateUserProfile(userId, changes),
  writeAudit: (input) => writeAudit(input),
  resetPassword: (input) => resetUserPassword(input),
}));

async function hasActiveSuperAdmin(actorId: string): Promise<boolean> {
  const { data: actor, error: actorError } = await admin
    .from("users")
    .select("admin_status")
    .eq("id", actorId)
    .maybeSingle();
  if (actorError || actor?.admin_status !== "active") return false;

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
  return roleError == null && role?.code === "super_admin";
}

async function getUserDetails(userId: string): Promise<UserManagementDetails> {
  const { data: user, error: userError } = await admin
    .from("users")
    .select(
      "id,email,full_name,phone,gender,birth_year,avatar_url,admin_status,created_at,updated_at,is_anonymous,product_access_status",
    )
    .eq("id", userId)
    .maybeSingle();
  if (userError) throw userError;
  if (!user) {
    throw new UserManagementRequestError(404, "Không tìm thấy tài khoản.");
  }

  const { data: subject, error: subjectError } = await admin
    .from("health_subjects")
    .select("id,display_name,relationship,gender,birth_year")
    .eq("owner_user_id", userId)
    .eq("subject_type", "self")
    .eq("is_active", true)
    .maybeSingle();
  if (subjectError) throw subjectError;

  const subjectId = typeof subject?.id === "string" ? subject.id : null;
  const [
    profile,
    lifestyle,
    goals,
    conditions,
    allergies,
    treatments,
    surveyAnswers,
  ] = await Promise.all([
    readSingle("health_profiles", subjectId),
    readSingle("lifestyle_habits", subjectId),
    readMany("health_goals", subjectId),
    readMany("health_conditions", subjectId),
    readMany("food_allergies", subjectId),
    readMany("medical_treatments", subjectId),
    readMany("survey_answers", subjectId),
  ]);

  const membership = await readCurrentMembership(userId, user);
  return {
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      phone: user.phone,
      gender: user.gender,
      birth_year: user.birth_year,
      avatar_url: user.avatar_url,
      admin_status: user.admin_status,
      created_at: user.created_at,
      updated_at: user.updated_at,
    },
    health: {
      subject,
      profile,
      lifestyle,
      goals,
      conditions,
      allergies,
      treatments,
      survey_answers: surveyAnswers,
    },
    membership,
  };
}

async function readSingle(
  table: string,
  subjectId: string | null,
): Promise<Record<string, unknown> | null> {
  if (!subjectId) return null;
  const { data, error } = await admin
    .from(table)
    .select("*")
    .eq("subject_id", subjectId)
    .maybeSingle();
  if (error) throw error;
  return record(data);
}

async function readMany(
  table: string,
  subjectId: string | null,
): Promise<Array<Record<string, unknown>>> {
  if (!subjectId) return [];
  const { data, error } = await admin
    .from(table)
    .select("*")
    .eq("subject_id", subjectId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return Array.isArray(data)
    ? data.map(record).filter((row): row is Record<string, unknown> =>
      row !== null
    )
    : [];
}

async function readCurrentMembership(
  userId: string,
  user: Record<string, unknown>,
) {
  const { data: subscriptions, error } = await admin
    .from("membership_subscriptions")
    .select("id,plan_code,status,source,starts_at,ends_at")
    .eq("user_id", userId)
    .in("status", ["trialing", "active"]);
  if (error) throw error;

  const now = Date.now();
  const current = (subscriptions ?? [])
    .filter((row) => {
      const startsAt = Date.parse(String(row.starts_at ?? ""));
      const endsAt = row.ends_at == null
        ? Infinity
        : Date.parse(String(row.ends_at));
      return Number.isFinite(startsAt) && startsAt <= now &&
        (endsAt === Infinity || endsAt > now);
    })
    .sort((left, right) => {
      const rank = (value: unknown) =>
        value === "family_plus" ? 3 : value === "plus" ? 2 : 1;
      return rank(right.plan_code) - rank(left.plan_code) ||
        Date.parse(String(right.starts_at ?? "")) -
          Date.parse(String(left.starts_at ?? ""));
    })[0];

  if (current) {
    return {
      plan_code: normalizePlanCode(current.plan_code),
      status: String(current.status),
      source: current.source,
      starts_at: current.starts_at,
      ends_at: current.ends_at,
    };
  }

  if (user.is_anonymous === true && user.product_access_status === "guest") {
    return {
      plan_code: "guest",
      status: "guest",
      source: null,
      starts_at: null,
      ends_at: null,
    };
  }
  return {
    plan_code: "free",
    status: "none",
    source: null,
    starts_at: null,
    ends_at: null,
  };
}

async function updateUserProfile(
  userId: string,
  changes: UserProfileChanges,
): Promise<void> {
  const update: Record<string, unknown> = {};
  if ("fullName" in changes) update.full_name = changes.fullName;
  if ("phone" in changes) update.phone = changes.phone;
  if ("gender" in changes) update.gender = changes.gender;
  if ("birthYear" in changes) update.birth_year = changes.birthYear;

  const { data: user, error: userError } = await admin
    .from("users")
    .update(update)
    .eq("id", userId)
    .select("id")
    .maybeSingle();
  if (userError) throw userError;
  if (!user) {
    throw new UserManagementRequestError(404, "Không tìm thấy tài khoản.");
  }

  const subjectUpdate: Record<string, unknown> = {};
  if ("fullName" in changes) subjectUpdate.display_name = changes.fullName;
  if ("gender" in changes) subjectUpdate.gender = changes.gender;
  if ("birthYear" in changes) subjectUpdate.birth_year = changes.birthYear;
  if (Object.keys(subjectUpdate).length > 0) {
    const { error } = await admin
      .from("health_subjects")
      .update(subjectUpdate)
      .eq("owner_user_id", userId)
      .eq("subject_type", "self");
    if (error) throw error;
  }

  const { data: authData, error: authReadError } = await admin.auth.admin
    .getUserById(userId);
  if (authReadError || !authData.user) {
    throw authReadError ?? new Error("User not found");
  }
  const metadata = record(authData.user.user_metadata) ?? {};
  if ("fullName" in changes) metadata.full_name = changes.fullName;
  if ("phone" in changes) {
    if (changes.phone) metadata.phone = changes.phone;
    else delete metadata.phone;
  }
  const { error: authUpdateError } = await admin.auth.admin.updateUserById(
    userId,
    {
      user_metadata: metadata,
    },
  );
  if (authUpdateError) throw authUpdateError;
}

async function writeAudit(input: {
  actorId: string;
  action: string;
  userId: string;
  reason: string;
  idempotencyKey?: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  const { error } = await admin.from("admin_audit_events").upsert({
    actor_id: input.actorId,
    action: input.action,
    target_type: "user",
    target_id: input.userId,
    reason: input.reason,
    idempotency_key: input.idempotencyKey ?? null,
    metadata: input.metadata ?? {},
  }, {
    onConflict: "action,idempotency_key",
    ignoreDuplicates: true,
  });
  if (error) throw error;
}

async function resetUserPassword(input: {
  actorId: string;
  userId: string;
  reason: string;
  idempotencyKey: string;
}): Promise<{ password: string }> {
  const { data: current, error: readError } = await admin.auth.admin
    .getUserById(input.userId);
  if (readError || !current.user) {
    throw readError ??
      new UserManagementRequestError(404, "Không tìm thấy tài khoản.");
  }

  const { data: marker, error: markerError } = await admin.from(
    "admin_audit_events",
  ).insert({
    actor_id: input.actorId,
    action: "admin_reset_user_password",
    target_type: "user",
    target_id: input.userId,
    reason: input.reason,
    idempotency_key: input.idempotencyKey,
    metadata: { status: "started" },
  }).select("id").single();
  if (markerError) {
    if (markerError.code === "23505") {
      throw new UserManagementRequestError(
        409,
        "Mã thao tác đã được xử lý trước đó. Không tạo mật khẩu mới.",
      );
    }
    throw markerError;
  }

  const password = generateTemporaryPassword();
  const metadata = record(current.user.user_metadata) ?? {};
  metadata.must_change_password = false;
  const { error: updateError } = await admin.auth.admin.updateUserById(
    input.userId,
    {
      password,
      user_metadata: metadata,
    },
  );
  if (updateError) throw updateError;

  const { error: completeError } = await admin
    .from("admin_audit_events")
    .update({ metadata: { status: "completed", password_reset: true } })
    .eq("id", marker.id);
  if (completeError) throw completeError;
  return { password };
}

function generateTemporaryPassword(): string {
  const alphabet =
    "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%*+-_";
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join("");
}

function normalizePlanCode(
  value: unknown,
): "guest" | "free" | "plus" | "family_plus" {
  const normalized = String(value ?? "").trim().toLowerCase();
  if (
    normalized === "guest" || normalized === "plus" ||
    normalized === "family_plus"
  ) return normalized;
  return "free";
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function arrayOfStrings(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) return undefined;
  return value.filter((item): item is string => typeof item === "string");
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

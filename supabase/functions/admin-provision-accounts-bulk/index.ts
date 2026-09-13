import {
  createClient,
  type User,
} from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  type BulkPreview,
  type BulkPreviewCandidate,
  type BulkProvisionAccount,
  BulkProvisionExecutionError,
  type BulkProvisionResult,
  createAdminProvisionAccountsBulkHandler,
} from "./handler.ts";
import {
  chooseCurrentPaidSubscription,
  type ExistingMembership,
} from "../admin-grant-membership/membership-guard.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminProvisionAccountsBulkHandler({
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
  inspect: async ({ accounts, planCode, durationMonths }) =>
    inspectAccounts({ accounts, planCode, durationMonths }),
  findCompletedBatch: async (idempotencyKey) => {
    const { data, error } = await admin
      .from("admin_audit_events")
      .select("target_id,metadata")
      .eq("action", "admin_provision_accounts_bulk")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();
    if (error || !data) return null;
    return resultFromMetadata(data.target_id, data.metadata);
  },
  execute: async (
    {
      actorId,
      accounts,
      password,
      planCode,
      durationMonths,
      reason,
      idempotencyKey,
      preview,
    },
  ) =>
    executeProvision({
      actorId,
      accounts,
      password,
      planCode,
      durationMonths,
      reason,
      idempotencyKey,
      preview,
    }),
}));

async function inspectAccounts(input: {
  accounts: BulkProvisionAccount[];
  planCode: "plus" | "family_plus";
  durationMonths: 1 | 3 | 6 | 12;
}): Promise<BulkPreview> {
  const { accounts, planCode, durationMonths } = input;
  const usersByEmail = await listAuthUsersByEmail();

  const userIds = accounts
    .map((account) => usersByEmail.get(account.email)?.id)
    .filter((id): id is string => Boolean(id));
  const memberships = await listMemberships(userIds);

  const candidates: BulkPreviewCandidate[] = accounts.map((account, offset) => {
    const user = usersByEmail.get(account.email);
    const current = user
      ? chooseCurrentPaidSubscription(memberships.get(user.id) ?? [])
      : null;
    return {
      index: offset + 1,
      email: account.email,
      fullName: account.fullName,
      status: !user ? "new" : current ? "paid_preserved" : "existing",
      ...(user ? { userId: user.id } : {}),
      ...(current ? { currentPlan: current.plan_code } : {}),
    };
  });

  return {
    fingerprint: await fingerprint(candidates, planCode, durationMonths),
    candidateCount: candidates.length,
    candidates,
  };
}

async function executeProvision(input: {
  actorId: string;
  accounts: BulkProvisionAccount[];
  password: string;
  planCode: "plus" | "family_plus";
  durationMonths: 1 | 3 | 6 | 12;
  reason: string;
  idempotencyKey: string;
  preview: BulkPreview;
}): Promise<BulkProvisionResult> {
  const startsAt = new Date();
  const endsAt = addCalendarMonths(startsAt, input.durationMonths);
  const usersByEmail = await listAuthUsersByEmail();
  const result: BulkProvisionResult = {
    batchId: input.idempotencyKey,
    processedCount: 0,
    createdCount: 0,
    grantedCount: 0,
    skippedCount: 0,
  };

  for (const candidate of input.preview.candidates) {
    try {
      const rowKey = await rowIdempotencyKey(input.idempotencyKey, candidate);
      const prior = await findCompletedRow(rowKey);
      if (prior) {
        countRow(result, prior);
        continue;
      }

      let userId = candidate.userId;
      let created = false;
      if (!userId) {
        const existing = usersByEmail.get(candidate.email);
        if (existing) {
          userId = existing.id;
        } else {
          const provisioned = await createUser(
            candidate,
            input.password,
            usersByEmail,
          );
          userId = provisioned.user.id;
          created = provisioned.created;
        }
      }

      const membership = await grantMembership({
        actorId: input.actorId,
        userId,
        planCode: input.planCode,
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        reason: input.reason,
        idempotencyKey: rowKey,
      });

      const outcome = membership.skipped ? "skipped" : "granted";
      const { error: auditError } = await admin
        .from("admin_audit_events")
        .upsert({
          actor_id: input.actorId,
          action: "admin_provision_account",
          target_type: "user",
          target_id: userId,
          reason: input.reason,
          idempotency_key: rowKey,
          metadata: {
            row_index: candidate.index,
            created,
            outcome,
            plan_code: membership.planCode,
            starts_at: membership.startsAt,
            ends_at: membership.endsAt,
            subscription_id: membership.subscriptionId,
          },
        }, { onConflict: "action,idempotency_key", ignoreDuplicates: true });
      if (auditError) throw auditError;

      result.processedCount += 1;
      if (created) result.createdCount += 1;
      if (membership.skipped) result.skippedCount += 1;
      else result.grantedCount += 1;
    } catch {
      throw new BulkProvisionExecutionError({
        ...result,
        failedIndex: candidate.index,
      });
    }
  }

  const { error: batchAuditError } = await admin
    .from("admin_audit_events")
    .upsert({
      actor_id: input.actorId,
      action: "admin_provision_accounts_bulk",
      target_type: "bulk_accounts",
      target_id: result.batchId,
      reason: input.reason,
      idempotency_key: input.idempotencyKey,
      metadata: {
        candidate_count: input.preview.candidateCount,
        processed_count: result.processedCount,
        created_count: result.createdCount,
        granted_count: result.grantedCount,
        skipped_count: result.skippedCount,
        plan_code: input.planCode,
        duration_months: input.durationMonths,
        fingerprint: input.preview.fingerprint,
      },
    }, { onConflict: "action,idempotency_key", ignoreDuplicates: true });
  if (batchAuditError) throw batchAuditError;

  return result;
}

async function createUser(
  candidate: BulkPreviewCandidate,
  password: string,
  usersByEmail: Map<string, User>,
): Promise<{ user: User; created: boolean }> {
  const { data, error } = await admin.auth.admin.createUser({
    email: candidate.email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: candidate.fullName,
      must_change_password: true,
    },
  });
  if (!error && data.user) {
    usersByEmail.set(candidate.email, data.user);
    return { user: data.user, created: true };
  }

  // A concurrent operator may have created the same email after preview. The
  // existing account is reused without ever updating its password.
  const existing = await findAuthUser(candidate.email);
  if (existing) {
    usersByEmail.set(candidate.email, existing);
    return { user: existing, created: false };
  }
  throw error ?? new Error("Account creation failed");
}

async function grantMembership(input: {
  actorId: string;
  userId: string;
  planCode: "plus" | "family_plus";
  startsAt: string;
  endsAt: string;
  reason: string;
  idempotencyKey: string;
}): Promise<{
  subscriptionId: string;
  planCode: string;
  startsAt: string;
  endsAt: string;
  skipped: boolean;
}> {
  const { data: previous, error: previousError } = await admin
    .from("membership_subscriptions")
    .select("id,plan_code,status,starts_at,ends_at")
    .eq("user_id", input.userId)
    .in("status", ["trialing", "active"]);
  if (previousError) throw previousError;

  const { data: priorCreated, error: priorCreatedError } = await admin
    .from("membership_subscriptions")
    .select("id,plan_code,starts_at,ends_at")
    .eq("provider", "admin_manual")
    .eq("provider_subscription_id", input.idempotencyKey)
    .maybeSingle();
  if (priorCreatedError) throw priorCreatedError;

  const existingPaid = chooseCurrentPaidSubscription(previous ?? []);
  if (!priorCreated && existingPaid) {
    return {
      subscriptionId: existingPaid.id,
      planCode: existingPaid.plan_code,
      startsAt: existingPaid.starts_at,
      endsAt: existingPaid.ends_at ?? input.endsAt,
      skipped: true,
    };
  }

  let created = priorCreated;
  let createdNow = false;
  if (!created) {
    const { data, error } = await admin
      .from("membership_subscriptions")
      .insert({
        user_id: input.userId,
        plan_code: input.planCode,
        status: "active",
        source: "manual",
        starts_at: input.startsAt,
        ends_at: input.endsAt,
        current_period_start: input.startsAt,
        current_period_end: input.endsAt,
        provider: "admin_manual",
        provider_subscription_id: input.idempotencyKey,
        metadata: {
          actor_id: input.actorId,
          reason: input.reason,
          admin_manual: true,
        },
      })
      .select("id,plan_code,starts_at,ends_at")
      .single();
    if (error || !data) throw error ?? new Error("Membership grant failed");
    created = data;
    createdNow = true;
  }
  if (
    !created?.id || !created.plan_code || !created.starts_at || !created.ends_at
  ) {
    throw new Error("Membership result incomplete");
  }

  const previousIds = (previous ?? [])
    .map((row) => row.id)
    .filter((id): id is string => typeof id === "string" && id !== created.id);
  try {
    if (previousIds.length > 0) {
      const { error } = await admin
        .from("membership_subscriptions")
        .update({ status: "canceled" })
        .in("id", previousIds);
      if (error) throw error;
    }
  } catch (error) {
    if (createdNow) {
      for (const row of previous ?? []) {
        if (typeof row.id !== "string" || row.id === created.id) continue;
        if (row.status !== "active" && row.status !== "trialing") continue;
        await admin.from("membership_subscriptions").update({
          status: row.status,
        }).eq("id", row.id);
      }
      await admin.from("membership_subscriptions").delete().eq(
        "id",
        created.id,
      );
    }
    throw error;
  }

  return {
    subscriptionId: created.id,
    planCode: created.plan_code,
    startsAt: created.starts_at,
    endsAt: created.ends_at,
    skipped: false,
  };
}

async function findCompletedRow(idempotencyKey: string): Promise<
  {
    created: boolean;
    skipped: boolean;
  } | null
> {
  const { data, error } = await admin
    .from("admin_audit_events")
    .select("metadata")
    .eq("action", "admin_provision_account")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();
  if (error || !data) return null;
  const metadata = record(data.metadata);
  if (!metadata || !["granted", "skipped"].includes(String(metadata.outcome))) {
    return null;
  }
  return {
    created: metadata.created === true,
    skipped: metadata.outcome === "skipped",
  };
}

function countRow(
  result: BulkProvisionResult,
  row: { created: boolean; skipped: boolean },
) {
  result.processedCount += 1;
  if (row.created) result.createdCount += 1;
  if (row.skipped) result.skippedCount += 1;
  else result.grantedCount += 1;
}

async function listAuthUsers(): Promise<User[]> {
  const users: User[] = [];
  for (let page = 1; page <= 100; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage: 1000,
    });
    if (error) throw error;
    users.push(...data.users);
    if (data.users.length < 1000) break;
  }
  return users;
}

async function listAuthUsersByEmail(): Promise<Map<string, User>> {
  const usersByEmail = new Map<string, User>();
  for (const user of await listAuthUsers()) {
    const email = user.email?.trim().toLowerCase();
    if (email) usersByEmail.set(email, user);
  }
  return usersByEmail;
}

async function findAuthUser(email: string): Promise<User | null> {
  const users = await listAuthUsers();
  return users.find((user) => user.email?.trim().toLowerCase() === email) ??
    null;
}

async function listMemberships(
  userIds: string[],
): Promise<Map<string, ExistingMembership[]>> {
  const result = new Map<string, ExistingMembership[]>();
  if (userIds.length === 0) return result;
  const { data, error } = await admin
    .from("membership_subscriptions")
    .select("id, user_id, plan_code, status, starts_at, ends_at")
    .in("user_id", userIds)
    .in("status", ["trialing", "active"]);
  if (error) throw error;
  for (const row of data ?? []) {
    const userId = typeof row.user_id === "string" ? row.user_id : "";
    if (!userId) continue;
    const membership: ExistingMembership = {
      id: String(row.id ?? ""),
      plan_code: String(row.plan_code ?? ""),
      status: String(row.status ?? ""),
      starts_at: String(row.starts_at ?? ""),
      ends_at: row.ends_at == null ? null : String(row.ends_at),
    };
    result.set(userId, [...(result.get(userId) ?? []), membership]);
  }
  return result;
}

async function fingerprint(
  candidates: BulkPreviewCandidate[],
  planCode: "plus" | "family_plus",
  durationMonths: 1 | 3 | 6 | 12,
): Promise<string> {
  const stable = candidates.map((candidate) => ({
    index: candidate.index,
    email: candidate.email,
    user_id: candidate.userId ?? null,
    status: candidate.status,
    current_plan: candidate.currentPlan ?? null,
  }));
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(
      JSON.stringify({
        plan_code: planCode,
        duration_months: durationMonths,
        candidates: stable,
      }),
    ),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function rowIdempotencyKey(
  batchKey: string,
  candidate: BulkPreviewCandidate,
): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(
      `${batchKey}:${candidate.index}:${candidate.email}`,
    ),
  );
  return `bulk-provision-${candidate.index}-${
    [...new Uint8Array(digest)]
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("")
      .slice(0, 24)
  }`;
}

function addCalendarMonths(value: Date, months: number): Date {
  const result = new Date(value);
  const originalDay = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(
    Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0),
  ).getUTCDate();
  result.setUTCDate(Math.min(originalDay, lastDay));
  return result;
}

function resultFromMetadata(
  targetId: unknown,
  value: unknown,
): BulkProvisionResult | null {
  const metadata = record(value);
  if (!metadata || typeof targetId !== "string") return null;
  const processedCount = integer(metadata.processed_count);
  const createdCount = integer(metadata.created_count);
  const grantedCount = integer(metadata.granted_count);
  const skippedCount = integer(metadata.skipped_count);
  if (
    processedCount === null || createdCount === null || grantedCount === null ||
    skippedCount === null
  ) return null;
  return {
    batchId: targetId,
    processedCount,
    createdCount,
    grantedCount,
    skippedCount,
  };
}

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

function integer(value: unknown): number | null {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : null;
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

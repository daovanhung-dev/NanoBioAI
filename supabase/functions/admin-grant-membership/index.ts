import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createAdminGrantMembershipHandler } from "./handler.ts";
import { chooseCurrentPaidSubscription } from "./membership-guard.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createAdminGrantMembershipHandler({
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
    const { data: audit, error: auditError } = await admin
      .from("admin_audit_events")
      .select("id,target_id,metadata")
      .eq("action", "admin_grant_membership")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();
    if (auditError) return null;

    const auditMetadata = record(audit?.metadata);
    if (audit?.id && auditMetadata?.skipped === true) {
      const targetId = text(audit.target_id);
      const planCode = text(auditMetadata.plan_code);
      const startsAt = text(auditMetadata.starts_at);
      const subscriptionId = text(auditMetadata.existing_subscription_id);
      if (targetId && planCode && startsAt && subscriptionId) {
        return {
          subscriptionId,
          planCode,
          startsAt,
          endsAt: nullableText(auditMetadata.ends_at),
          skipped: true,
        };
      }
    }

    const { data: subscription, error: subscriptionError } = await admin
      .from("membership_subscriptions")
      .select("id,plan_code,starts_at,ends_at")
      .eq("provider", "admin_manual")
      .eq("provider_subscription_id", idempotencyKey)
      .maybeSingle();
    if (subscriptionError ||
        !subscription?.id ||
        !subscription.plan_code ||
        !subscription.starts_at ||
        !subscription.ends_at) {
      return null;
    }

    // A request is considered fully completed only after its audit row exists.
    // If a previous run stopped after subscription creation, `grant` below
    // resumes cleanup/audit instead of hiding that partial state as success.
    if (auditError || !audit?.id) return null;

    return {
      subscriptionId: subscription.id,
      planCode: subscription.plan_code,
      startsAt: subscription.starts_at,
      endsAt: subscription.ends_at,
    };
  },
  userExists: async (userId) => {
    const { data, error } = await admin
      .from("users")
      .select("id")
      .eq("id", userId)
      .maybeSingle();
    return error == null && data?.id != null;
  },
  grant: async ({
    actorId,
    userId,
    planCode,
    startsAt,
    endsAt,
    reason,
    idempotencyKey,
    preserveExistingPaidPlan,
  }) => {
    const { data: previous, error: previousError } = await admin
      .from("membership_subscriptions")
      .select("id,plan_code,status,starts_at,ends_at")
      .eq("user_id", userId)
      .in("status", ["trialing", "active"]);
    if (previousError) throw previousError;

    const { data: priorCreated, error: priorCreatedError } = await admin
      .from("membership_subscriptions")
      .select("id,plan_code,starts_at,ends_at")
      .eq("provider", "admin_manual")
      .eq("provider_subscription_id", idempotencyKey)
      .maybeSingle();
    if (priorCreatedError) throw priorCreatedError;

    // A prior subscription with this idempotency key is a partial/completed
    // grant that must finish its normal cleanup and audit path before we
    // consider preserving another paid subscription.
    if (preserveExistingPaidPlan && !priorCreated) {
      const existingPaid = chooseCurrentPaidSubscription(previous ?? []);
      if (existingPaid) {
        const { error: auditError } = await admin
          .from("admin_audit_events")
          .upsert({
            actor_id: actorId,
            action: "admin_grant_membership",
            target_type: "user",
            target_id: userId,
            reason,
            idempotency_key: idempotencyKey,
            metadata: {
              skipped: true,
              preserve_existing_paid_plan: true,
              plan_code: existingPaid.plan_code,
              starts_at: existingPaid.starts_at,
              ends_at: existingPaid.ends_at,
              existing_subscription_id: existingPaid.id,
            },
          }, {
            onConflict: "action,idempotency_key",
            ignoreDuplicates: true,
          });
        if (auditError) throw auditError;

        return {
          subscriptionId: existingPaid.id,
          planCode: existingPaid.plan_code,
          startsAt: existingPaid.starts_at,
          endsAt: existingPaid.ends_at,
          skipped: true,
        };
      }
    }

    let created = priorCreated;
    let createdNow = false;
    if (!created) {
      const result = await admin
        .from("membership_subscriptions")
        .insert({
          user_id: userId,
          plan_code: planCode,
          status: "active",
          // `source` is constrained by the canonical schema. Manual Admin
          // grants use the existing trusted `manual` value and a dedicated
          // provider/idempotency pair for provenance.
          source: "manual",
          starts_at: startsAt,
          ends_at: endsAt,
          current_period_start: startsAt,
          current_period_end: endsAt,
          provider: "admin_manual",
          provider_subscription_id: idempotencyKey,
          metadata: {
            actor_id: actorId,
            reason,
            admin_manual: true,
          },
        })
        .select("id,plan_code,starts_at,ends_at")
        .single();
      if (result.error || !result.data) {
        throw result.error ?? new Error("Grant failed");
      }
      created = result.data;
      createdNow = true;
    }

    if (!created?.id ||
        !created.plan_code ||
        !created.starts_at ||
        !created.ends_at) {
      throw new Error("Grant result incomplete");
    }

    const previousIds = (previous ?? [])
      .map((row) => row.id)
      .filter((id): id is string => typeof id === "string" && id !== created.id);
    try {
      if (previousIds.length > 0) {
        // Do not rewrite `ends_at`: a future/trial record could otherwise violate
        // the canonical `ends_at > starts_at` constraint. Status is authoritative.
        const { error: cancelError } = await admin
          .from("membership_subscriptions")
          .update({ status: "canceled" })
          .in("id", previousIds);
        if (cancelError) throw cancelError;
      }

      const { error: auditError } = await admin
        .from("admin_audit_events")
        .upsert({
          actor_id: actorId,
          action: "admin_grant_membership",
          target_type: "user",
          target_id: userId,
          reason,
          idempotency_key: idempotencyKey,
          metadata: {
            plan_code: planCode,
            starts_at: startsAt,
            ends_at: endsAt,
            subscription_id: created.id,
            replaced_subscription_ids: previousIds,
          },
        }, {
          onConflict: "action,idempotency_key",
          ignoreDuplicates: true,
        });
      if (auditError) throw auditError;
    } catch (error) {
      // Best-effort compensation for a newly-created grant. A retry with the
      // same idempotency key also repairs older partial grants because
      // `findIdempotentResult` requires both subscription and audit evidence.
      if (createdNow) {
        for (const row of previous ?? []) {
          if (typeof row.id !== "string" || row.id === created.id) continue;
          if (row.status !== "active" && row.status !== "trialing") continue;
          await admin
            .from("membership_subscriptions")
            .update({ status: row.status })
            .eq("id", row.id);
        }
        await admin
          .from("membership_subscriptions")
          .delete()
          .eq("id", created.id);
      }
      throw error;
    }

    return {
      subscriptionId: created.id,
      planCode: created.plan_code,
      startsAt: created.starts_at,
      endsAt: created.ends_at,
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

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 ? result : null;
}

function nullableText(value: unknown): string | null {
  return value === null ? null : text(value);
}

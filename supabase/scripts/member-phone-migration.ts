// Dry-run by default. Applying gives eligible members an internal Auth email
// alias derived from their phone while preserving IDs, passwords and contacts.
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  type AuthUser,
  maskPhone,
  memberAuthEmail,
  normalizeVietnamPhone,
  type PublicUser,
  reviewMemberAccounts,
} from "./member-phone-migration-core.ts";

type AdminClient = SupabaseClient<any, "public", any>;

if (import.meta.main) await runMigrationReview();

async function runMigrationReview(): Promise<void> {
  const apply = Deno.args.includes("--apply");
  if (apply) assertSandboxTarget();
  const supabaseUrl = requiredEnvironment("SUPABASE_URL");
  const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const [publicUsers, authUsers, adminAssignments] = await Promise.all([
    listPublicUsers(supabase),
    listAuthUsers(supabase),
    listAdminAssignments(supabase),
  ]);
  const review = reviewMemberAccounts(publicUsers, authUsers, adminAssignments);
  const rows = new Map(review.rows.map((row) => [row.user_id, row]));
  let failed = false;

  if (apply) {
    const authById = new Map(authUsers.map((user) => [user.id, user]));
    for (const candidate of review.candidates) {
      const authUser = authById.get(candidate.userId);
      try {
        if (!authUser) throw new Error("auth_user_missing");
        const userMetadata = { ...(authUser.user_metadata ?? {}) };
        userMetadata.phone = candidate.phone;
        userMetadata.auth_login_method = "member_phone_password";
        if (candidate.contactEmail) {
          userMetadata.contact_email = candidate.contactEmail;
        }
        const { error: authUpdateError } = await supabase.auth.admin
          .updateUserById(candidate.userId, {
            email: candidate.authEmail,
            email_confirm: true,
            user_metadata: userMetadata,
          });
        if (authUpdateError) throw new Error("auth_alias_update_failed");
        const { data: profile, error: profileReadError } = await supabase
          .from("users")
          .select("phone")
          .eq("id", candidate.userId)
          .maybeSingle();
        if (profileReadError || !profile) {
          throw new Error("profile_read_failed");
        }
        const { data, error: profileUpdateError } = await supabase
          .from("users")
          .update({ phone: candidate.phone, email: candidate.contactEmail })
          .eq("id", candidate.userId)
          .eq("phone", profile.phone)
          .select("id")
          .maybeSingle();
        if (profileUpdateError || !data) {
          throw new Error("profile_phone_update_failed");
        }
        rows.set(candidate.userId, {
          user_id: candidate.userId,
          status: "already_phone_login_enabled",
          phone: maskPhone(candidate.phone),
        });
      } catch {
        failed = true;
        rows.set(candidate.userId, {
          user_id: candidate.userId,
          status: "manual_review",
          reason: "migration_write_failed_review_required",
          phone: maskPhone(candidate.phone),
        });
      }
    }
  }

  const finalRows = [...rows.values()];
  const summary = finalRows.reduce<Record<string, number>>((counts, row) => {
    counts[row.status] = (counts[row.status] ?? 0) + 1;
    return counts;
  }, {});
  console.log(JSON.stringify(
    {
      mode: apply ? "sandbox_apply" : "read_only_review",
      summary,
      rows: finalRows,
    },
    null,
    2,
  ));
  if (failed) Deno.exitCode = 1;
}

function assertSandboxTarget(): void {
  const environment = requiredEnvironment("SUPABASE_ENVIRONMENT");
  const requestedRef = requiredArgument("--sandbox-project-ref");
  const confirmedRef = requiredArgument("--confirm-project-ref");
  const expectedRef = requiredEnvironment(
    "SUPABASE_EXPECTED_SANDBOX_PROJECT_REF",
  );
  if (environment !== "sandbox" && environment !== "local") {
    throw new Error(
      "Apply mode is restricted to a local or sandbox environment.",
    );
  }
  if (requestedRef !== confirmedRef || requestedRef !== expectedRef) {
    throw new Error("Sandbox project confirmation does not match.");
  }
  const url = new URL(requiredEnvironment("SUPABASE_URL"));
  if (environment === "local") {
    if (
      requestedRef !== "local" ||
      !["localhost", "127.0.0.1"].includes(url.hostname)
    ) {
      throw new Error("Local apply requires the local Supabase URL and ref.");
    }
    return;
  }
  if (
    !url.hostname.endsWith(".supabase.co") ||
    url.hostname.split(".")[0] !== requestedRef
  ) {
    throw new Error("Sandbox URL project ref does not match the confirmation.");
  }
}

async function listPublicUsers(
  supabase: AdminClient,
): Promise<PublicUser[]> {
  const rows: PublicUser[] = [];
  for (let from = 0;; from += 1000) {
    const { data, error } = await supabase
      .from("users")
      .select("id,email,phone,app_access_mode")
      .order("id")
      .range(from, from + 999);
    if (error) {
      throw new Error("Unable to read public user migration inventory.");
    }
    const page = (data ?? []).flatMap((row) => {
      if (typeof row.id !== "string") return [];
      return [{
        id: row.id,
        email: typeof row.email === "string" ? row.email : null,
        phone: typeof row.phone === "string" ? row.phone : null,
        app_access_mode: typeof row.app_access_mode === "string"
          ? row.app_access_mode
          : null,
      }];
    });
    rows.push(...page);
    if (page.length < 1000) return rows;
  }
}

async function listAdminAssignments(
  supabase: AdminClient,
): Promise<Set<string>> {
  const assignments = new Set<string>();
  for (let from = 0;; from += 1000) {
    const { data, error } = await supabase
      .from("admin_user_roles")
      .select("user_id")
      .eq("is_active", true)
      .is("revoked_at", null)
      .range(from, from + 999);
    if (error) throw new Error("Unable to read Admin account exclusions.");
    for (const row of data ?? []) {
      if (typeof row.user_id === "string") assignments.add(row.user_id);
    }
    if ((data ?? []).length < 1000) return assignments;
  }
}

async function listAuthUsers(
  supabase: AdminClient,
): Promise<AuthUser[]> {
  const users: AuthUser[] = [];
  for (let page = 1; page <= 1000; page += 1) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage: 1000,
    });
    if (error) throw new Error("Unable to read Auth user migration inventory.");
    users.push(...data.users);
    if (data.users.length < 1000) return users;
  }
  throw new Error("Auth user inventory exceeded the supported page limit.");
}

function requiredArgument(name: string): string {
  const index = Deno.args.indexOf(name);
  const value = index >= 0 ? Deno.args[index + 1]?.trim() : null;
  if (!value) throw new Error(`Missing required argument: ${name}`);
  return value;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

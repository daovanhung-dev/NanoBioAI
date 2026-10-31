import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { createMemberChangePasswordHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createMemberChangePasswordHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const client = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.auth.getUser();
    return error ? null : data.user?.id ?? null;
  },
  changePassword: async (userId, password) => {
    const { data: profile, error: profileError } = await admin
      .from("users")
      .select("phone,app_access_mode")
      .eq("id", userId)
      .maybeSingle();
    if (profileError) throw profileError;
    if (
      typeof profile?.phone !== "string" ||
      profile.app_access_mode === "admin" ||
      profile.app_access_mode === "both"
    ) throw new Error("Member account required.");

    const { data: assignments, error: assignmentError } = await admin
      .from("admin_user_roles")
      .select("role_code")
      .eq("user_id", userId)
      .eq("is_active", true)
      .is("revoked_at", null)
      .limit(1);
    if (assignmentError) throw assignmentError;
    if (assignments?.length) throw new Error("Member account required.");

    const { data, error: readError } = await admin.auth.admin.getUserById(
      userId,
    );
    if (readError || !data.user) throw readError ?? new Error("User missing.");
    const appMetadata = { ...(data.user.app_metadata ?? {}) };
    appMetadata.must_change_password = false;
    const { error } = await admin.auth.admin.updateUserById(userId, {
      password,
      app_metadata: appMetadata,
    });
    if (error) throw error;
  },
}));

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

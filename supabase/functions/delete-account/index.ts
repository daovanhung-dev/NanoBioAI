import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import { createDeleteAccountHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const supabaseServiceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");

const handler = createDeleteAccountHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const { data, error } = await createUserClient(authorization).auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  deleteAccount: async (userId) => {
    const { error } = await createAdminClient().auth.admin.deleteUser(userId);
    if (error != null) throw new Error("Account deletion failed.");
  },
});

Deno.serve(handler);

function createUserClient(authorization: string) {
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function createAdminClient() {
  return createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

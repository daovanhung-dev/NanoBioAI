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
  deleteOwnedStorage: async (userId) => {
    const admin = createAdminClient();
    await removeOwnedObjects(admin, "schedule-completion-proofs", userId);
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

/**
 * Remove every file below an account-owned prefix. Supabase Storage lists
 * folders and files separately, so recurse through folders and delete files in
 * bounded batches. The prefix is derived from the authenticated UUID only;
 * no client-supplied path is accepted.
 */
async function removeOwnedObjects(
  client: ReturnType<typeof createAdminClient>,
  bucket: string,
  userId: string,
): Promise<void> {
  const paths = await listFilePaths(client, bucket, userId);
  for (let offset = 0; offset < paths.length; offset += 1000) {
    const { error } = await client.storage
      .from(bucket)
      .remove(paths.slice(offset, offset + 1000));
    if (error != null) throw new Error("Account storage cleanup failed.");
  }
}

async function listFilePaths(
  client: ReturnType<typeof createAdminClient>,
  bucket: string,
  prefix: string,
): Promise<string[]> {
  const files: string[] = [];
  for (let offset = 0; ; offset += 100) {
    const { data, error } = await client.storage.from(bucket).list(prefix, {
      limit: 100,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error != null) throw new Error("Account storage listing failed.");
    if (!data || data.length === 0) break;
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`;
      if (entry.id == null) {
        files.push(...await listFilePaths(client, bucket, path));
      } else {
        files.push(path);
      }
    }
    if (data.length < 100) break;
  }
  return files;
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

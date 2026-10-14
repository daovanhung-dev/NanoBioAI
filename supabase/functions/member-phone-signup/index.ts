import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  memberAuthEmail,
  normalizeVietnamPhone,
} from "../_shared/member_phone_identity.ts";
import { createMemberPhoneSignupHandler } from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const hmacSecret = requiredEnvironment("EARLY_ACCESS_RATE_LIMIT_HMAC_KEY");
if (hmacSecret.length < 32) {
  throw new Error("EARLY_ACCESS_RATE_LIMIT_HMAC_KEY must be at least 32 characters");
}
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createMemberPhoneSignupHandler({
  isRateLimited: async (ip) => {
    const ipHash = await hmac(hmacSecret, `signup-ip:${ip}`);
    const { data, error } = await admin.rpc(
      "consume_member_phone_signup_rate_limit",
      { p_ip_hash: ipHash },
    );
    if (error) throw error;
    return data !== true;
  },
  phoneExists: async (phone) => {
    for (let from = 0;; from += 1000) {
      const { data, error } = await admin
        .from("users")
        .select("phone")
        .not("phone", "is", null)
        .range(from, from + 999);
      if (error) throw error;
      if (
        (data ?? []).some((row) =>
          normalizeVietnamPhone(
            typeof row.phone === "string" ? row.phone : "",
          ) ===
            phone
        )
      ) return true;
      if ((data ?? []).length < 1000) return false;
    }
  },
  createUser: async (input) => {
    const { data, error } = await admin.auth.admin.createUser({
      email: input.email,
      email_confirm: true,
      password: input.password,
      user_metadata: {
        full_name: input.fullName,
        phone: input.phone,
        auth_login_method: "member_phone_password",
        ...(input.referralCode ? { referral_code: input.referralCode } : {}),
        ...(input.deviceFingerprint
          ? { device_fingerprint: input.deviceFingerprint }
          : {}),
      },
    });
    if (error || !data.user) {
      throw error ?? new Error("account_creation_failed");
    }
    const { error: profileError } = await admin
      .from("users")
      .update({ email: null })
      .eq("id", data.user.id);
    if (profileError) {
      await admin.auth.admin.deleteUser(data.user.id);
      throw profileError;
    }
  },
}));

async function hmac(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value)),
  );
  return Array.from(signature, (byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createGooglePlayVerifyPurchaseHandler,
  sha256,
} from "./handler.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const serviceAccount = parseServiceAccount(requiredEnvironment("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"));
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createGooglePlayVerifyPurchaseHandler({
  authenticate: async (authorization) => {
    if (!authorization?.startsWith("Bearer ")) return null;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await userClient.auth.getUser();
    return error == null ? data.user?.id ?? null : null;
  },
  verifySubscription: async ({ packageName, productId, purchaseToken }) => {
    const accessToken = await googleAccessToken(serviceAccount);
    const response = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!response.ok) throw new Error(`GOOGLE_PLAY_HTTP_${response.status}`);
    const payload = await response.json() as Record<string, unknown>;
    const items = Array.isArray(payload.lineItems) ? payload.lineItems : [];
    const item = items.find((entry) => {
      return entry && typeof entry === "object" &&
        (entry as Record<string, unknown>).productId === productId;
    }) as Record<string, unknown> | undefined;
    return {
      subscriptionState: String(payload.subscriptionState ?? ""),
      productId: typeof item?.productId === "string" ? item.productId : null,
      orderId: typeof item?.latestSuccessfulOrderId === "string" ? item.latestSuccessfulOrderId : null,
      startTime: typeof payload.startTime === "string" ? payload.startTime : null,
      expiryTime: typeof item?.expiryTime === "string" ? item.expiryTime : null,
      acknowledgementState: typeof payload.acknowledgementState === "string" ? payload.acknowledgementState : null,
    };
  },
  finalizePurchase: async ({
    userId,
    packageName,
    productId,
    purchaseTokenHash,
    orderId,
    purchaseState,
    purchaseStartedAt,
    entitlementEndsAt,
    acknowledged,
  }) => {
    const { data, error } = await admin.rpc("finalize_google_play_purchase", {
      p_user_id: userId,
      p_package_name: packageName,
      p_product_id: productId,
      p_purchase_token_hash: purchaseTokenHash,
      p_order_id: orderId,
      p_purchase_state: purchaseState,
      p_purchase_started_at: purchaseStartedAt,
      p_entitlement_ends_at: entitlementEndsAt,
      p_acknowledged: acknowledged,
    });
    if (error) throw new Error(error.message);
    const row = Array.isArray(data) ? data[0] : data;
    return {
      status: row?.status === "verified" ? "verified" : "pending",
      plan_code: typeof row?.plan_code === "string" ? row.plan_code : null,
      expires_at: typeof row?.expires_at === "string" ? row.expires_at : null,
    } as const;
  },
  hashPurchaseToken: sha256,
}));

type ServiceAccount = { client_email: string; private_key: string };

function parseServiceAccount(raw: string): ServiceAccount {
  const parsed = JSON.parse(raw) as Partial<ServiceAccount>;
  if (typeof parsed.client_email !== "string" || typeof parsed.private_key !== "string") {
    throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_INVALID");
  }
  return { client_email: parsed.client_email, private_key: parsed.private_key.replace(/\\n/g, "\n") };
}

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 300,
  }));
  const signingInput = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${signingInput}.${base64url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error(`GOOGLE_OAUTH_HTTP_${response.status}`);
  const payload = await response.json() as { access_token?: unknown };
  if (typeof payload.access_token !== "string" || payload.access_token.length === 0) {
    throw new Error("GOOGLE_OAUTH_TOKEN_MISSING");
  }
  return payload.access_token;
}

function pemToBytes(pem: string): ArrayBuffer {
  const base64 = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const bytes = Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
  return bytes.buffer;
}

function base64url(value: string | ArrayBuffer): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : new Uint8Array(value);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment: ${name}`);
  return value;
}

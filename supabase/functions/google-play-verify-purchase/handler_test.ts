import {
  createGooglePlayVerifyPurchaseHandler,
  GOOGLE_PLAY_PACKAGE_NAME,
} from "./handler.ts";

const snapshot = (state: string, productId = "nanobio_plus_monthly") => ({
  subscriptionState: state,
  productId,
  orderId: "GPA.TEST-ORDER",
  startTime: "2026-08-01T00:00:00Z",
  expiryTime: "2026-09-01T00:00:00Z",
  acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
});

function handlerFor(snapshotValue: ReturnType<typeof snapshot>, finalizeError?: Error) {
  const planCode = snapshotValue.productId?.includes("family_plus") ? "family_plus" : "plus";
  return createGooglePlayVerifyPurchaseHandler({
    authenticate: async () => "user-a",
    verifySubscription: async () => snapshotValue,
    finalizePurchase: async () => {
      if (finalizeError) throw finalizeError;
      return { status: snapshotValue.subscriptionState.endsWith("PENDING") ? "pending" : "verified", plan_code: planCode, expires_at: snapshotValue.expiryTime };
    },
    hashPurchaseToken: async () => "hash-token",
  });
}

function request(body: Record<string, unknown>) {
  return new Request("https://example.test/google-play-verify-purchase", {
    method: "POST",
    headers: { Authorization: "Bearer test-user" },
    body: JSON.stringify(body),
  });
}

Deno.test("rejects unknown products and package mismatches", async () => {
  const handler = handlerFor(snapshot("SUBSCRIPTION_STATE_ACTIVE"));
  const unknown = await handler(request({ package_name: GOOGLE_PLAY_PACKAGE_NAME, product_id: "other", purchase_token: "token" }));
  if (unknown.status !== 400) throw new Error(`expected 400, got ${unknown.status}`);

  const wrongPackage = await handler(request({ package_name: "wrong.package", product_id: "nanobio_plus_monthly", purchase_token: "token" }));
  if (wrongPackage.status !== 400) throw new Error(`expected 400, got ${wrongPackage.status}`);
});

Deno.test("does not grant membership while Google purchase is pending", async () => {
  const handler = handlerFor(snapshot("SUBSCRIPTION_STATE_PENDING"));
  const response = await handler(request({ package_name: GOOGLE_PLAY_PACKAGE_NAME, product_id: "nanobio_plus_monthly", purchase_token: "token" }));
  if (response.status !== 202) throw new Error(`expected 202, got ${response.status}`);
  const body = await response.json();
  if (body.status !== "pending" || body.retryable !== true) throw new Error("pending response was not retryable");
});

Deno.test("returns verified only after the trusted finalizer succeeds", async () => {
  const handler = handlerFor(snapshot("SUBSCRIPTION_STATE_ACTIVE", "nanobio_family_plus_yearly"));
  const response = await handler(request({ package_name: GOOGLE_PLAY_PACKAGE_NAME, product_id: "nanobio_family_plus_yearly", purchase_token: "token" }));
  if (response.status !== 200) throw new Error(`expected 200, got ${response.status}`);
  const body = await response.json();
  if (body.status !== "verified" || body.plan_code !== "family_plus") throw new Error("verification response was not normalized");
});

Deno.test("maps a replay bound to another user to forbidden", async () => {
  const handler = handlerFor(snapshot("SUBSCRIPTION_STATE_ACTIVE"), new Error("GOOGLE_PLAY_PURCHASE_USER_MISMATCH"));
  const response = await handler(request({ package_name: GOOGLE_PLAY_PACKAGE_NAME, product_id: "nanobio_plus_monthly", purchase_token: "token" }));
  if (response.status !== 403) throw new Error(`expected 403, got ${response.status}`);
});

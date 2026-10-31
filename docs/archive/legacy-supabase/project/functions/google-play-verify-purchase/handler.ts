export type GooglePlaySubscriptionSnapshot = {
  subscriptionState: string;
  productId: string | null;
  orderId: string | null;
  startTime: string | null;
  expiryTime: string | null;
  acknowledgementState: string | null;
};

export type GooglePlayFinalizeResult = {
  status: "verified" | "pending";
  plan_code: string | null;
  expires_at: string | null;
};

export type GooglePlayVerifyPurchaseDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  verifySubscription: (input: {
    packageName: string;
    productId: string;
    purchaseToken: string;
  }) => Promise<GooglePlaySubscriptionSnapshot>;
  finalizePurchase: (input: {
    userId: string;
    packageName: string;
    productId: string;
    purchaseTokenHash: string;
    orderId: string | null;
    purchaseState: "pending" | "verified" | "canceled" | "expired" | "refunded" | "revoked" | "rejected";
    purchaseStartedAt: string | null;
    entitlementEndsAt: string | null;
    acknowledged: boolean;
  }) => Promise<GooglePlayFinalizeResult>;
  hashPurchaseToken?: (token: string) => Promise<string>;
};

export const GOOGLE_PLAY_PACKAGE_NAME = "com.nanobioai.app";

const PRODUCTS: Record<string, { planCode: "plus" | "family_plus" }> = {
  nanobio_plus_monthly: { planCode: "plus" },
  nanobio_plus_yearly: { planCode: "plus" },
  nanobio_family_plus_monthly: { planCode: "family_plus" },
  nanobio_family_plus_yearly: { planCode: "family_plus" },
};

export function createGooglePlayVerifyPurchaseHandler(
  deps: GooglePlayVerifyPurchaseDeps,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json(405, { status: "rejected", message: "Phương thức không được hỗ trợ." });
    }

    const userId = await deps.authenticate(request.headers.get("Authorization"));
    if (!userId) {
      return json(401, { status: "rejected", message: "Phiên đăng nhập không hợp lệ." });
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json(400, { status: "rejected", message: "Dữ liệu giao dịch chưa hợp lệ." });
    }

    const packageName = text(body.package_name, 160);
    const productId = text(body.product_id, 160);
    const purchaseToken = text(body.purchase_token, 4096);
    if (!packageName || !productId || !purchaseToken) {
      return json(400, { status: "rejected", message: "Dữ liệu giao dịch chưa đầy đủ." });
    }
    if (packageName !== GOOGLE_PLAY_PACKAGE_NAME) {
      return json(400, { status: "rejected", message: "Ứng dụng không khớp với giao dịch." });
    }
    const product = PRODUCTS[productId];
    if (!product) {
      return json(400, { status: "rejected", message: "Gói đăng ký không hợp lệ." });
    }

    let snapshot: GooglePlaySubscriptionSnapshot;
    try {
      snapshot = await deps.verifySubscription({ packageName, productId, purchaseToken });
    } catch {
      return json(502, {
        status: "pending",
        retryable: true,
        message: "Chưa thể xác minh giao dịch với Google Play. Bạn hãy thử lại sau.",
      });
    }

    if (snapshot.productId !== productId) {
      return json(409, { status: "rejected", message: "Gói đăng ký không khớp với giao dịch." });
    }

    const state = snapshot.subscriptionState.trim().toUpperCase();
    const purchaseState = stateToPurchaseState(state);
    const tokenHash = await (deps.hashPurchaseToken ?? sha256)(purchaseToken);
    const expiry = validIsoDate(snapshot.expiryTime);
    const started = validIsoDate(snapshot.startTime);

    try {
      const result = await deps.finalizePurchase({
        userId,
        packageName,
        productId,
        purchaseTokenHash: tokenHash,
        orderId: text(snapshot.orderId, 256),
        purchaseState,
        purchaseStartedAt: started,
        entitlementEndsAt: expiry,
        acknowledged: snapshot.acknowledgementState === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
      });

      if (result.status === "verified" && purchaseState === "verified") {
        return json(200, {
          status: "verified",
          plan_code: result.plan_code ?? product.planCode,
          expires_at: result.expires_at ?? expiry,
          message: "Giao dịch đã được xác minh.",
        });
      }
      if (purchaseState === "pending") {
        return json(202, {
          status: "pending",
          retryable: true,
          message: "Giao dịch đang chờ Google Play hoàn tất.",
        });
      }
      return json(409, {
        status: "rejected",
        message: "Giao dịch chưa đủ điều kiện để cập nhật gói.",
      });
    } catch (error) {
      const code = error instanceof Error ? error.message : "";
      if (code.includes("USER_MISMATCH")) {
        return json(403, { status: "rejected", message: "Giao dịch không thuộc tài khoản này." });
      }
      return json(500, {
        status: "pending",
        retryable: true,
        message: "Chưa lưu được kết quả xác minh. Bạn hãy thử lại sau.",
      });
    }
  };
}

function stateToPurchaseState(
  state: string,
): "pending" | "verified" | "canceled" | "expired" | "refunded" | "revoked" | "rejected" {
  if (state === "SUBSCRIPTION_STATE_ACTIVE" || state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
    return "verified";
  }
  if (state === "SUBSCRIPTION_STATE_PENDING" || state === "SUBSCRIPTION_STATE_PAUSED") {
    return "pending";
  }
  if (state.includes("EXPIRED")) return "expired";
  if (state.includes("CANCELED")) return "canceled";
  if (state.includes("REVOKED")) return "revoked";
  if (state.includes("REFUND")) return "refunded";
  return "rejected";
}

function text(value: unknown, maxLength: number): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 && result.length <= maxLength ? result : null;
}

function validIsoDate(value: string | null): string | null {
  if (!value) return null;
  const time = Date.parse(value);
  return Number.isFinite(time) ? new Date(time).toISOString() : null;
}

export async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

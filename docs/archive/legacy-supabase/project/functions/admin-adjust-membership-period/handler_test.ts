import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AdminAdjustMembershipPeriodDeps,
  createAdminAdjustMembershipPeriodHandler,
} from "./handler.ts";

Deno.test("admin-adjust-membership-period answers browser CORS preflight", async () => {
  const response = await createAdminAdjustMembershipPeriodHandler(deps())(
    new Request("https://example.test/admin-adjust-membership-period", {
      method: "OPTIONS",
    }),
  );
  assertEquals(response.status, 200);
  assertEquals(
    response.headers.get("Access-Control-Allow-Methods"),
    "POST, OPTIONS",
  );
});

Deno.test("admin-adjust-membership-period rejects missing JWT and non-Super Admin", async () => {
  let adjustments = 0;
  const missingJwt = createAdminAdjustMembershipPeriodHandler(deps({
    authenticate: () => Promise.resolve(null),
    adjust: () => {
      adjustments++;
      return Promise.resolve(adjustmentResult());
    },
  }));
  assertEquals(
    (await missingJwt(request({ authorization: null }))).status,
    401,
  );

  const nonAdmin = createAdminAdjustMembershipPeriodHandler(deps({
    isAllowedAdmin: () => Promise.resolve(false),
    adjust: () => {
      adjustments++;
      return Promise.resolve(adjustmentResult());
    },
  }));
  assertEquals((await nonAdmin(request())).status, 403);
  assertEquals(adjustments, 0);
});

Deno.test("admin-adjust-membership-period validates operation, days and expected end", async () => {
  let adjustments = 0;
  const handler = createAdminAdjustMembershipPeriodHandler(deps({
    adjust: () => {
      adjustments++;
      return Promise.resolve(adjustmentResult());
    },
  }));

  for (
    const body of [
      validBody({ operation: "unknown" }),
      validBody({ operation: "add_days", days: 0 }),
      validBody({ operation: "set_end_at", ends_at: null }),
      validBody({ expected_ends_at: undefined }),
    ]
  ) {
    assertEquals((await handler(request({ body }))).status, 400);
  }
  assertEquals(adjustments, 0);
});

Deno.test("admin-adjust-membership-period forwards normalized adjustment input", async () => {
  const received: Array<Record<string, unknown>> = [];
  const handler = createAdminAdjustMembershipPeriodHandler(deps({
    adjust: (input) => {
      received.push(input);
      return Promise.resolve(adjustmentResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(received[0], {
    actorId: "admin-user",
    userId: "user-1",
    subscriptionId: "subscription-1",
    operation: "add_days",
    days: 7,
    endsAt: null,
    expectedEndsAt: "2026-10-13T00:00:00.000Z",
    reason: "Gia hạn theo phê duyệt.",
    idempotencyKey: "adjust-1",
  });
  assertEquals((await response.json()).ends_at, "2026-10-20T00:00:00.000Z");
});

Deno.test("admin-adjust-membership-period keeps backend failures private", async () => {
  const handler = createAdminAdjustMembershipPeriodHandler(deps({
    adjust: () => Promise.reject(new Error("service-role-secret-detail")),
  }));
  const response = await handler(request());
  const body = await response.text();
  assertEquals(response.status, 500);
  assertFalse(body.includes("service-role-secret-detail"));
});

function deps(
  overrides: Partial<AdminAdjustMembershipPeriodDeps> = {},
): AdminAdjustMembershipPeriodDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(
        authorization === "Bearer valid-jwt" ? "admin-user" : null,
      ),
    isAllowedAdmin: () => Promise.resolve(true),
    adjust: () => Promise.resolve(adjustmentResult()),
    ...overrides,
  };
}

function request({
  authorization = "Bearer valid-jwt",
  body = validBody(),
}: {
  authorization?: string | null;
  body?: Record<string, unknown>;
} = {}): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authorization != null) headers.set("Authorization", authorization);
  return new Request("https://example.test/admin-adjust-membership-period", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function validBody(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    user_id: "user-1",
    subscription_id: "subscription-1",
    operation: "add_days",
    days: 7,
    ends_at: null,
    expected_ends_at: "2026-10-13T00:00:00.000Z",
    reason: "Gia hạn theo phê duyệt.",
    idempotency_key: "adjust-1",
    ...overrides,
  };
}

function adjustmentResult() {
  return {
    subscriptionId: "subscription-1",
    planCode: "plus",
    status: "active",
    startsAt: "2026-09-13T00:00:00.000Z",
    previousEndsAt: "2026-10-13T00:00:00.000Z",
    endsAt: "2026-10-20T00:00:00.000Z",
    operation: "add_days",
    deltaDays: 7,
  };
}

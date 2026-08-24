import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createAdminGrantMembershipHandler,
  type AdminGrantMembershipDeps,
} from "./handler.ts";

Deno.test("admin-grant-membership rejects missing JWT before privileged work", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipHandler(deps({
    authenticate: () => Promise.resolve(null),
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request({ authorization: null }));
  assertEquals(response.status, 401);
  assertEquals(grants, 0);
});

Deno.test("admin-grant-membership is Super Admin only", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipHandler(deps({
    isAllowedAdmin: () => Promise.resolve(false),
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 403);
  assertEquals(grants, 0);
});

Deno.test("admin-grant-membership validates plan and time range", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipHandler(deps({
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  for (const body of [
    validBody({ plan_code: "free" }),
    validBody({ ends_at: "2026-01-01T00:00:00.000Z" }),
  ]) {
    const response = await handler(request({ body }));
    assertEquals(response.status, 400);
  }
  assertEquals(grants, 0);
});

Deno.test("admin-grant-membership returns completed idempotent grant without a second write", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipHandler(deps({
    findIdempotentResult: () => Promise.resolve(grantResult()),
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(grants, 0);
  assertEquals((await response.json()).message, "Gói đã được cấp ở lần gửi trước.");
});

Deno.test("admin-grant-membership rejects an unknown target account", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipHandler(deps({
    userExists: () => Promise.resolve(false),
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 404);
  assertEquals(grants, 0);
});

Deno.test("admin-grant-membership forwards trusted normalized input", async () => {
  const received: Array<Record<string, unknown>> = [];
  const handler = createAdminGrantMembershipHandler(deps({
    grant: (input) => {
      received.push(input);
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(received.length, 1);
  assertEquals(received[0].actorId, "admin-user");
  assertEquals(received[0].planCode, "plus");
  assertEquals(received[0].idempotencyKey, "grant-membership-1");
});

Deno.test("admin-grant-membership keeps backend failures private", async () => {
  const handler = createAdminGrantMembershipHandler(deps({
    grant: () => Promise.reject(new Error("service-role-secret-detail")),
  }));

  const response = await handler(request());
  const text = await response.text();
  assertEquals(response.status, 500);
  assertFalse(text.includes("service-role-secret-detail"));
});

function deps(overrides: Partial<AdminGrantMembershipDeps> = {}): AdminGrantMembershipDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(authorization === "Bearer valid-jwt" ? "admin-user" : null),
    isAllowedAdmin: () => Promise.resolve(true),
    findIdempotentResult: () => Promise.resolve(null),
    userExists: () => Promise.resolve(true),
    grant: () => Promise.resolve(grantResult()),
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
  return new Request("https://example.test/admin-grant-membership", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function validBody(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    user_id: "user-1",
    plan_code: "plus",
    starts_at: "2026-08-24T03:00:00.000Z",
    ends_at: "2026-09-24T03:00:00.000Z",
    reason: "Cấp quyền Plus thủ công theo phê duyệt.",
    idempotency_key: "grant-membership-1",
    ...overrides,
  };
}

function grantResult() {
  return {
    subscriptionId: "subscription-1",
    planCode: "plus",
    startsAt: "2026-08-24T03:00:00.000Z",
    endsAt: "2026-09-24T03:00:00.000Z",
  };
}

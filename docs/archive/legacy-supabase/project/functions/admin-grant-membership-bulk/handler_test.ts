import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AdminGrantMembershipBulkDeps,
  createAdminGrantMembershipBulkHandler,
} from "./handler.ts";

Deno.test("bulk grant rejects missing JWT before privileged work", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipBulkHandler(deps({
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

Deno.test("bulk grant is Super Admin only", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipBulkHandler(deps({
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

Deno.test("bulk grant requires the registered-user scope and Plus", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipBulkHandler(deps({
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  for (
    const body of [
      validBody({ scope: "all_users" }),
      validBody({ plan_code: "family_plus" }),
      validBody({ ends_at: "2027-01-01T00:00:00.000Z" }),
    ]
  ) {
    const response = await handler(request({ body }));
    assertEquals(response.status, 400);
  }
  assertEquals(grants, 0);
});

Deno.test("bulk grant returns a completed idempotent result without a second write", async () => {
  let grants = 0;
  const handler = createAdminGrantMembershipBulkHandler(deps({
    findIdempotentResult: () => Promise.resolve(grantResult()),
    grant: () => {
      grants++;
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(grants, 0);
  assertEquals(
    (await response.json()).message,
    "Batch đã hoàn tất ở lần gửi trước.",
  );
});

Deno.test("bulk grant forwards normalized permanent input", async () => {
  const received: Array<Record<string, unknown>> = [];
  const handler = createAdminGrantMembershipBulkHandler(deps({
    grant: (input) => {
      received.push(input);
      return Promise.resolve(grantResult());
    },
  }));

  const response = await handler(request({
    body: validBody({
      starts_at: "2026-09-13T10:11:12+07:00",
      ends_at: null,
      reason: "  Cấp Plus vĩnh viễn theo phê duyệt.  ",
    }),
  }));
  assertEquals(response.status, 200);
  assertEquals(received.length, 1);
  assertEquals(received[0].actorId, "admin-user");
  assertEquals(received[0].scope, "all_registered");
  assertEquals(received[0].planCode, "plus");
  assertEquals(received[0].startsAt, "2026-09-13T03:11:12.000Z");
  assertEquals(received[0].endsAt, null);
});

Deno.test("bulk grant keeps backend failures private", async () => {
  const handler = createAdminGrantMembershipBulkHandler(deps({
    grant: () => Promise.reject(new Error("service-role-secret-detail")),
  }));

  const response = await handler(request());
  const text = await response.text();
  assertEquals(response.status, 500);
  assertFalse(text.includes("service-role-secret-detail"));
});

function deps(
  overrides: Partial<AdminGrantMembershipBulkDeps> = {},
): AdminGrantMembershipBulkDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(
        authorization === "Bearer valid-jwt" ? "admin-user" : null,
      ),
    isAllowedAdmin: () => Promise.resolve(true),
    findIdempotentResult: () => Promise.resolve(null),
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
  return new Request("https://example.test/admin-grant-membership-bulk", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function validBody(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    scope: "all_registered",
    plan_code: "plus",
    starts_at: "2026-09-13T03:00:00.000Z",
    ends_at: null,
    reason: "Cấp Plus vĩnh viễn theo phê duyệt.",
    idempotency_key: "bulk-plus-2026-09-13",
    ...overrides,
  };
}

function grantResult() {
  return {
    batchId: "bulk-plus-2026-09-13",
    planCode: "plus",
    startsAt: "2026-09-13T03:00:00.000Z",
    endsAt: null,
    targetCount: 3,
    grantedCount: 2,
    alreadyGrantedCount: 1,
    familyPlusCount: 1,
  };
}

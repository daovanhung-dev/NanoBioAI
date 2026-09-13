import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AdminProvisionAccountsBulkDeps,
  type BulkPreview,
  BulkProvisionExecutionError,
  createAdminProvisionAccountsBulkHandler,
} from "./handler.ts";

Deno.test("bulk account provisioning answers CORS preflight", async () => {
  const response = await createAdminProvisionAccountsBulkHandler(deps())(
    new Request("https://example.test/admin-provision-accounts-bulk", {
      method: "OPTIONS",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
  assertEquals(
    response.headers.get("Access-Control-Allow-Methods"),
    "POST, OPTIONS",
  );
});

Deno.test("bulk account provisioning requires JWT and Super Admin", async () => {
  let inspectCalls = 0;
  const missingJwt = createAdminProvisionAccountsBulkHandler(deps({
    authenticate: () => Promise.resolve(null),
    inspect: () => {
      inspectCalls += 1;
      return Promise.resolve(preview());
    },
  }));
  assertEquals((await missingJwt(request())).status, 401);

  const forbidden = createAdminProvisionAccountsBulkHandler(deps({
    isAllowedAdmin: () => Promise.resolve(false),
  }));
  assertEquals((await forbidden(request())).status, 403);
  assertEquals(inspectCalls, 0);
});

Deno.test("bulk account provisioning validates Gmail rows, plan and limit", async () => {
  let inspectCalls = 0;
  const handler = createAdminProvisionAccountsBulkHandler(deps({
    inspect: () => {
      inspectCalls += 1;
      return Promise.resolve(preview());
    },
  }));

  for (
    const body of [
      validBody({
        accounts: [{ email: "person@example.com", full_name: "Person" }],
      }),
      validBody({ plan_code: "free" }),
      validBody({
        accounts: Array.from(
          { length: 101 },
          (_, index) => ({
            email: `u${index}@gmail.com`,
            full_name: `User ${index}`,
          }),
        ),
      }),
    ]
  ) {
    assertEquals((await requestResponse(handler, body)).status, 400);
  }
  assertEquals(inspectCalls, 0);
});

Deno.test("bulk preview returns only sanitized row metadata", async () => {
  const handler = createAdminProvisionAccountsBulkHandler(deps({
    inspect: () =>
      Promise.resolve({
        ...preview(),
        candidates: [
          {
            index: 1,
            email: "new@gmail.com",
            fullName: "New User",
            status: "new",
          },
          {
            index: 2,
            email: "old@gmail.com",
            fullName: "Old User",
            status: "paid_preserved",
            userId: "old-user",
            currentPlan: "family_plus",
          },
        ],
        candidateCount: 2,
      }),
  }));

  const response = await requestResponse(
    handler,
    validBody({ mode: "preview" }),
  );
  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    fingerprint: "fingerprint-1",
    candidate_count: 2,
    rows: [
      { index: 1, status: "new" },
      { index: 2, status: "paid_preserved", current_plan: "family_plus" },
    ],
  });
});

Deno.test("bulk execute rejects stale preview or wrong confirmation before writes", async () => {
  let executeCalls = 0;
  const handler = createAdminProvisionAccountsBulkHandler(deps({
    execute: () => {
      executeCalls += 1;
      return Promise.resolve(result());
    },
  }));

  const stale = await requestResponse(
    handler,
    validBody({ preview_fingerprint: "stale" }),
  );
  assertEquals(stale.status, 409);
  const wrongConfirmation = await requestResponse(
    handler,
    validBody({ confirmation: "TAO TAI KHOAN 9" }),
  );
  assertEquals(wrongConfirmation.status, 400);
  assertEquals(executeCalls, 0);
});

Deno.test("bulk execute keeps idempotency and does not return the password", async () => {
  let executeCalls = 0;
  const handler = createAdminProvisionAccountsBulkHandler(deps({
    execute: () => {
      executeCalls += 1;
      return Promise.resolve(result());
    },
  }));

  const response = await requestResponse(
    handler,
    validBody({ password: "StrongPassword123!" }),
  );
  const text = await response.text();
  assertEquals(response.status, 200);
  assertEquals(executeCalls, 1);
  assertFalse(text.includes("StrongPassword123!"));

  const replay = createAdminProvisionAccountsBulkHandler(deps({
    findCompletedBatch: () => Promise.resolve(result()),
    execute: () => {
      executeCalls += 1;
      return Promise.resolve(result());
    },
  }));
  assertEquals((await requestResponse(replay, validBody())).status, 200);
  assertEquals(executeCalls, 1);
});

Deno.test("bulk execute reports partial failure without leaking backend details", async () => {
  const handler = createAdminProvisionAccountsBulkHandler(deps({
    execute: () =>
      Promise.reject(
        new BulkProvisionExecutionError({
          ...result(),
          processedCount: 1,
          createdCount: 1,
          grantedCount: 1,
          skippedCount: 0,
          failedIndex: 2,
        }),
      ),
  }));

  const response = await requestResponse(handler, validBody());
  const text = await response.text();
  assertEquals(response.status, 200);
  assertEquals(text.includes("failedIndex"), false);
  assertEquals(text.includes("service-role-secret"), false);
  assertEquals(JSON.parse(text).failed_index, 2);
});

function deps(
  overrides: Partial<AdminProvisionAccountsBulkDeps> = {},
): AdminProvisionAccountsBulkDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(
        authorization === "Bearer valid-jwt" ? "admin-user" : null,
      ),
    isAllowedAdmin: () => Promise.resolve(true),
    inspect: () => Promise.resolve(preview()),
    findCompletedBatch: () => Promise.resolve(null),
    execute: () => Promise.resolve(result()),
    ...overrides,
  };
}

function requestResponse(
  handler: (request: Request) => Promise<Response>,
  body: Record<string, unknown>,
) {
  return handler(request({ body }));
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
  return new Request("https://example.test/admin-provision-accounts-bulk", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function validBody(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    mode: "execute",
    accounts: [{ email: "new@gmail.com", full_name: "New User" }],
    password: "StrongPassword123!",
    plan_code: "plus",
    duration_months: 1,
    reason: "Cấp gói theo danh sách được phê duyệt.",
    idempotency_key: "bulk-provision-1",
    preview_fingerprint: "fingerprint-1",
    confirmation: "TAO TAI KHOAN 1",
    ...overrides,
  };
}

function preview(): BulkPreview {
  return {
    fingerprint: "fingerprint-1",
    candidateCount: 1,
    candidates: [{
      index: 1,
      email: "new@gmail.com",
      fullName: "New User",
      status: "new",
    }],
  };
}

function result(): {
  batchId: string;
  processedCount: number;
  createdCount: number;
  grantedCount: number;
  skippedCount: number;
} {
  return {
    batchId: "bulk-provision-1",
    processedCount: 1,
    createdCount: 1,
    grantedCount: 1,
    skippedCount: 0,
  };
}

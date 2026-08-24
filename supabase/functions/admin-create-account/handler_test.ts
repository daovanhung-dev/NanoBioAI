import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createAdminCreateAccountHandler,
  type AdminCreateAccountDeps,
} from "./handler.ts";

Deno.test("admin-create-account rejects missing JWT before any privileged work", async () => {
  let createCalls = 0;
  const handler = createAdminCreateAccountHandler(deps({
    authenticate: () => Promise.resolve(null),
    createUser: () => {
      createCalls++;
      return Promise.resolve({ userId: "new-user", email: "new@example.com" });
    },
  }));

  const response = await handler(request({ authorization: null }));
  assertEquals(response.status, 401);
  assertEquals(createCalls, 0);
});

Deno.test("admin-create-account allows only the approved Admin roles", async () => {
  let createCalls = 0;
  const handler = createAdminCreateAccountHandler(deps({
    isAllowedAdmin: () => Promise.resolve(false),
    createUser: () => {
      createCalls++;
      return Promise.resolve({ userId: "new-user", email: "new@example.com" });
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 403);
  assertEquals(createCalls, 0);
});

Deno.test("admin-create-account validates account data before Auth Admin API", async () => {
  let createCalls = 0;
  const handler = createAdminCreateAccountHandler(deps({
    createUser: () => {
      createCalls++;
      return Promise.resolve({ userId: "new-user", email: "new@example.com" });
    },
  }));

  const response = await handler(request({ body: validBody({ password: "short" }) }));
  assertEquals(response.status, 400);
  assertEquals(createCalls, 0);
});

Deno.test("admin-create-account returns an idempotent success without creating twice", async () => {
  let createCalls = 0;
  const handler = createAdminCreateAccountHandler(deps({
    findIdempotentResult: () =>
      Promise.resolve({ userId: "existing-user", email: "existing@example.com" }),
    createUser: () => {
      createCalls++;
      return Promise.resolve({ userId: "new-user", email: "new@example.com" });
    },
  }));

  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(createCalls, 0);
  assertEquals(await response.json(), {
    success: true,
    user_id: "existing-user",
    email: "existing@example.com",
    message: "Tài khoản đã được tạo ở lần gửi trước.",
  });
});

Deno.test("admin-create-account audits a successful creation and never returns the password", async () => {
  const audits: string[] = [];
  const handler = createAdminCreateAccountHandler(deps({
    writeAudit: ({ userId }) => {
      audits.push(userId);
      return Promise.resolve();
    },
  }));

  const response = await handler(request());
  const text = await response.text();
  assertEquals(response.status, 200);
  assertEquals(audits, ["new-user"]);
  assertFalse(text.includes("StrongPassword123!"));
});

Deno.test("admin-create-account compensates when the audit write fails", async () => {
  const deleted: string[] = [];
  const handler = createAdminCreateAccountHandler(deps({
    writeAudit: () => Promise.reject(new Error("private-audit-detail")),
    deleteUser: (userId) => {
      deleted.push(userId);
      return Promise.resolve();
    },
  }));

  const response = await handler(request());
  const text = await response.text();
  assertEquals(response.status, 500);
  assertEquals(deleted, ["new-user"]);
  assertFalse(text.includes("private-audit-detail"));
});

function deps(overrides: Partial<AdminCreateAccountDeps> = {}): AdminCreateAccountDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(authorization === "Bearer valid-jwt" ? "admin-user" : null),
    isAllowedAdmin: () => Promise.resolve(true),
    findIdempotentResult: () => Promise.resolve(null),
    createUser: ({ email }) => Promise.resolve({ userId: "new-user", email }),
    deleteUser: () => Promise.resolve(),
    writeAudit: () => Promise.resolve(),
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
  return new Request("https://example.test/admin-create-account", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function validBody(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    full_name: "Nguyen Van A",
    email: "new@example.com",
    password: "StrongPassword123!",
    phone: "0912345678",
    reason: "Tạo tài khoản hỗ trợ khách hàng.",
    idempotency_key: "create-account-1",
    ...overrides,
  };
}

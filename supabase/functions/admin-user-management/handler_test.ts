import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AdminUserManagementDeps,
  createAdminUserManagementHandler,
  type UserManagementDetails,
} from "./handler.ts";

Deno.test("user management answers CORS preflight", async () => {
  const response = await createAdminUserManagementHandler(deps())(
    new Request("https://example.test/admin-user-management", {
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

Deno.test("user management requires JWT and active Super Admin", async () => {
  const missingJwt = createAdminUserManagementHandler(deps({
    authenticate: () => Promise.resolve(null),
  }));
  assertEquals((await missingJwt(request())).status, 401);

  const forbidden = createAdminUserManagementHandler(deps({
    isAllowedAdmin: () => Promise.resolve(false),
  }));
  assertEquals((await forbidden(request())).status, 403);
});

Deno.test("detail returns structured data and audits health access without raw health metadata", async () => {
  const audits: Array<Record<string, unknown>> = [];
  const handler = createAdminUserManagementHandler(deps({
    writeAudit: (input) => {
      audits.push(input as unknown as Record<string, unknown>);
      return Promise.resolve();
    },
  }));

  const response = await responseFor(handler, {
    operation: "detail",
    user_id: "user-1",
    reason: "Kiểm tra hồ sơ hỗ trợ.",
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.success, true);
  assertEquals(body.health.profile.occupation, "Teacher");
  assertEquals(audits[0]?.action, "admin_view_user_health");
  assertEquals(audits[0]?.metadata, {
    scope: "self_health_and_current_membership",
  });
  assertFalse(JSON.stringify(audits[0]).includes("Teacher"));
});

Deno.test("profile update rejects forbidden fields and records changed field names only", async () => {
  let updateCalls = 0;
  const audits: Array<Record<string, unknown>> = [];
  const handler = createAdminUserManagementHandler(deps({
    updateProfile: () => {
      updateCalls += 1;
      return Promise.resolve();
    },
    writeAudit: (input) => {
      audits.push(input as unknown as Record<string, unknown>);
      return Promise.resolve();
    },
  }));

  assertEquals(
    (await responseFor(handler, {
      ...validBody("update_profile"),
      email: "not-allowed@example.com",
    })).status,
    400,
  );
  assertEquals(updateCalls, 0);

  const response = await responseFor(handler, {
    ...validBody("update_profile"),
    full_name: "Người dùng mới",
    phone: "0900000000",
    gender: "female",
    birth_year: 1990,
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.changed_fields, [
    "full_name",
    "phone",
    "gender",
    "birth_year",
  ]);
  assertEquals(audits[0]?.metadata, {
    status: "completed",
    changed_fields: ["full_name", "phone", "gender", "birth_year"],
  });
  assertFalse(JSON.stringify(audits[0]).includes("Người dùng mới"));
});

Deno.test("password reset cannot target the actor and returns a one-time password", async () => {
  let resetCalls = 0;
  const handler = createAdminUserManagementHandler(deps({
    authenticate: () => Promise.resolve("admin-1"),
    resetPassword: () => {
      resetCalls += 1;
      return Promise.resolve({ password: "Random16Chars!" });
    },
  }));

  assertEquals(
    (await responseFor(handler, {
      ...validBody("reset_password"),
      user_id: "admin-1",
    })).status,
    400,
  );
  assertEquals(resetCalls, 0);

  const response = await responseFor(handler, validBody("reset_password"));
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.status, "password_reset");
  assertEquals(body.temporary_password, "Random16Chars!");
  assertEquals(body.password_visible_once, true);
  assertEquals(resetCalls, 1);
});

Deno.test("password reset replay does not generate or return a second password", async () => {
  let resetCalls = 0;
  const handler = createAdminUserManagementHandler(deps({
    findIdempotency: () =>
      Promise.resolve({ targetId: "user-1", status: "completed" }),
    resetPassword: () => {
      resetCalls += 1;
      return Promise.resolve({ password: "should-not-run" });
    },
  }));

  const response = await responseFor(handler, validBody("reset_password"));
  const text = await response.text();
  assertEquals(response.status, 200);
  assertEquals(JSON.parse(text).password_visible_once, false);
  assertFalse(text.includes("should-not-run"));
  assertEquals(resetCalls, 0);
});

Deno.test("user management hides backend errors", async () => {
  const handler = createAdminUserManagementHandler(deps({
    updateProfile: () => Promise.reject(new Error("service-role-secret")),
  }));
  const response = await responseFor(handler, validBody("update_profile"));
  const text = await response.text();
  assertEquals(response.status, 500);
  assertFalse(text.includes("service-role-secret"));
});

function deps(
  overrides: Partial<AdminUserManagementDeps> = {},
): AdminUserManagementDeps {
  return {
    authenticate: (authorization) =>
      Promise.resolve(authorization === "Bearer valid-jwt" ? "admin-1" : null),
    isAllowedAdmin: () => Promise.resolve(true),
    findIdempotency: () => Promise.resolve(null),
    getDetails: () => Promise.resolve(details()),
    updateProfile: () => Promise.resolve(),
    writeAudit: () => Promise.resolve(),
    resetPassword: () => Promise.resolve({ password: "Random16Chars!" }),
    ...overrides,
  };
}

function request(body: Record<string, unknown> = validBody("detail")): Request {
  return new Request("https://example.test/admin-user-management", {
    method: "POST",
    headers: {
      Authorization: "Bearer valid-jwt",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

async function responseFor(
  handler: (request: Request) => Promise<Response>,
  body: Record<string, unknown>,
): Promise<Response> {
  return handler(request(body));
}

function validBody(
  operation: "detail" | "update_profile" | "reset_password",
): Record<string, unknown> {
  return {
    operation,
    user_id: "user-1",
    full_name: "Người dùng",
    phone: null,
    gender: null,
    birth_year: null,
    reason: "Xử lý yêu cầu người dùng.",
    idempotency_key: "user-management-1",
  };
}

function details(): UserManagementDetails {
  return {
    user: { id: "user-1", email: "user@example.com", full_name: "Người dùng" },
    health: {
      subject: { display_name: "Người dùng" },
      profile: { occupation: "Teacher" },
      lifestyle: {},
      goals: [],
      conditions: [],
      allergies: [],
      treatments: [],
      survey_answers: [],
    },
    membership: { plan_code: "free", status: "none" },
  };
}

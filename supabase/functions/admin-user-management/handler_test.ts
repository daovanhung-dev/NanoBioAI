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

  assertEquals(
    (await responseFor(handler, {
      ...validBody("update_profile"),
      phone: "+84900000000",
    })).status,
    400,
  );
  assertEquals(updateCalls, 0);

  const response = await responseFor(handler, {
    ...validBody("update_profile"),
    full_name: "Người dùng mới",
    gender: "female",
    birth_year: 1990,
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.changed_fields, [
    "full_name",
    "gender",
    "birth_year",
  ]);
  assertEquals(audits[0]?.metadata, {
    status: "completed",
    changed_fields: ["full_name", "gender", "birth_year"],
  });
  assertFalse(JSON.stringify(audits[0]).includes("Người dùng mới"));
});

Deno.test("member reset needs a reason and returns the default password", async () => {
  let resetCalls = 0;
  const audits: Array<Record<string, unknown>> = [];
  const handler = createAdminUserManagementHandler(deps({
    resetMemberPassword: ({ userId }) => {
      resetCalls += 1;
      assertEquals(userId, "user-1");
      return Promise.resolve();
    },
    writeAudit: (input) => {
      audits.push(input as unknown as Record<string, unknown>);
      return Promise.resolve();
    },
  }));

  const missingReason = await responseFor(handler, {
    operation: "reset_member_password",
    user_id: "user-1",
    idempotency_key: "reset-1",
  });
  assertEquals(missingReason.status, 400);
  assertEquals(resetCalls, 0);

  const response = await responseFor(handler, {
    operation: "reset_member_password",
    user_id: "user-1",
    reason: "Đã xác minh số điện thoại.",
    idempotency_key: "reset-1",
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.reset_password, "12345678");
  assertEquals(resetCalls, 1);
  assertEquals(audits[0]?.action, "admin_reset_member_password");
  assertEquals(audits[0]?.metadata, {
    status: "completed",
    must_change_password: true,
  });
  assertFalse(JSON.stringify(audits).includes("service-role-secret"));
});

Deno.test("reset idempotency replay does not reset a second time", async () => {
  let resetCalls = 0;
  const handler = createAdminUserManagementHandler(deps({
    findIdempotency: () =>
      Promise.resolve({ targetId: "user-1", status: "completed" }),
    resetMemberPassword: () => {
      resetCalls += 1;
      return Promise.resolve();
    },
  }));
  const response = await responseFor(handler, {
    operation: "reset_member_password",
    user_id: "user-1",
    reason: "Đã xác minh số điện thoại.",
    idempotency_key: "reset-1",
  });
  assertEquals(response.status, 200);
  assertEquals((await response.json()).reset_password, "12345678");
  assertEquals(resetCalls, 0);
});

Deno.test("old request workflow is no longer supported", async () => {
  const handler = createAdminUserManagementHandler(deps());
  assertEquals(
    (await responseFor(handler, { operation: "list_password_requests" }))
      .status,
    400,
  );
  assertEquals(
    (await responseFor(handler, { operation: "approve_password_change" }))
      .status,
    400,
  );
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
    resetMemberPassword: () => Promise.resolve(),
    writeAudit: () => Promise.resolve(),
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
  operation: "detail" | "update_profile",
): Record<string, unknown> {
  return {
    operation,
    user_id: "user-1",
    full_name: "Người dùng",
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

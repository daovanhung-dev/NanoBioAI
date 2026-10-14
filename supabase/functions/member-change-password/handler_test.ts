import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createMemberChangePasswordHandler,
  type MemberChangePasswordDeps,
} from "./handler.ts";

Deno.test("member password change requires an authenticated session", async () => {
  const handler = createMemberChangePasswordHandler(deps({
    authenticate: () => Promise.resolve(null),
  }));
  const response = await handler(request());
  assertEquals(response.status, 401);
});

Deno.test("member password change validates length and hides password", async () => {
  let savedPassword = "";
  const handler = createMemberChangePasswordHandler(deps({
    changePassword: (_userId, password) => {
      savedPassword = password;
      return Promise.resolve();
    },
  }));
  const invalid = await handler(request({ new_password: "short" }));
  assertEquals(invalid.status, 400);

  const password = "A new strong password 42!";
  const response = await handler(request({ new_password: password }));
  assertEquals(response.status, 200);
  assertEquals(savedPassword, password);
  assertEquals((await response.text()).includes(password), false);
});

function deps(
  overrides: Partial<MemberChangePasswordDeps> = {},
): MemberChangePasswordDeps {
  return {
    authenticate: () => Promise.resolve("member-1"),
    changePassword: () => Promise.resolve(),
    ...overrides,
  };
}

function request(body: Record<string, unknown> = {}): Request {
  return new Request("https://example.test/member-change-password", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: "Bearer valid",
    },
    body: JSON.stringify({ new_password: "StrongPassword123!", ...body }),
  });
}

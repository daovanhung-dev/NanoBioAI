import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createDeleteAccountHandler,
  type DeleteAccountDependencies,
} from "./handler.ts";

Deno.test("rejects a missing or invalid JWT before account deletion", async () => {
  let deleteCalls = 0;
  const handler = createDeleteAccountHandler(dependencies({
    deleteAccount: () => {
      deleteCalls++;
      return Promise.resolve();
    },
  }));

  for (const authorization of [null, "Bearer forged-jwt"]) {
    const response = await handler(request({ authorization }));
    assertEquals(response.status, 401);
    assertEquals(await response.json(), { error: "unauthorized" });
  }
  assertEquals(deleteCalls, 0);
});

Deno.test("requires an explicit confirmation before deleting", async () => {
  let deleteCalls = 0;
  const handler = createDeleteAccountHandler(dependencies({
    deleteAccount: () => {
      deleteCalls++;
      return Promise.resolve();
    },
  }));

  for (const body of [{}, { confirm: false }, null]) {
    const response = await handler(request({ body }));
    assertEquals(response.status, 400);
    assertEquals(await response.json(), { error: "confirmation_required" });
  }
  assertEquals(deleteCalls, 0);
});

Deno.test("deletes only the authenticated account and returns no account data", async () => {
  const deletedUsers: string[] = [];
  const handler = createDeleteAccountHandler(dependencies({
    deleteAccount: (userId) => {
      deletedUsers.push(userId);
      return Promise.resolve();
    },
  }));

  const response = await handler(request({ body: { confirm: true } }));
  const responseText = await response.text();

  assertEquals(response.status, 200);
  assertEquals(deletedUsers, ["user-1"]);
  assertEquals(responseText, '{"deleted":true}');
  assertFalse(responseText.includes("user-1"));
});

Deno.test("keeps service-role failures private", async () => {
  const handler = createDeleteAccountHandler(dependencies({
    deleteAccount: () => Promise.reject(new Error("service-role-must-not-leak")),
  }));

  const response = await handler(request({ body: { confirm: true } }));
  const responseText = await response.text();

  assertEquals(response.status, 503);
  assertEquals(responseText, '{"error":"account_deletion_unavailable"}');
  assertFalse(responseText.includes("service-role-must-not-leak"));
});

function dependencies(
  overrides: Partial<DeleteAccountDependencies> = {},
): DeleteAccountDependencies {
  return {
    authenticate: (authorization) =>
      Promise.resolve(authorization == "Bearer valid-jwt" ? "user-1" : null),
    deleteAccount: () => Promise.resolve(),
    ...overrides,
  };
}

function request({
  authorization = "Bearer valid-jwt",
  body = { confirm: true },
}: {
  authorization?: string | null;
  body?: Record<string, unknown> | null;
} = {}): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authorization != null) headers.set("Authorization", authorization);
  return new Request("https://example.test/delete-account", {
    method: "POST",
    headers,
    body: body == null ? null : JSON.stringify(body),
  });
}

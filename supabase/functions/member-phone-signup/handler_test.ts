import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createMemberPhoneSignupHandler,
  type MemberPhoneSignupDeps,
} from "./handler.ts";

Deno.test("member-phone-signup normalizes phone before creating the Auth alias", async () => {
  let createdPhone = "";
  let createdEmail = "";
  const handler = createMemberPhoneSignupHandler(deps({
    createUser: (input) => {
      createdPhone = input.phone;
      createdEmail = input.email;
      return Promise.resolve();
    },
  }));
  const response = await handler(request({ phone: "0912 345 678" }));
  assertEquals(response.status, 201);
  assertEquals(createdPhone, "+84912345678");
  assertEquals(createdEmail, "member-84912345678@phone.nanobio.invalid");
});

Deno.test("member-phone-signup reports duplicate numbers", async () => {
  const handler = createMemberPhoneSignupHandler(deps({
    phoneExists: () => Promise.resolve(true),
  }));
  const response = await handler(request());
  assertEquals(response.status, 409);
  assertEquals((await response.json()).code, "phone_exists");
});

Deno.test("member-phone-signup limits public account creation before privileged writes", async () => {
  let createCalls = 0;
  const handler = createMemberPhoneSignupHandler(deps({
    isRateLimited: () => Promise.resolve(true),
    createUser: () => {
      createCalls++;
      return Promise.resolve();
    },
  }));
  const response = await handler(request());
  assertEquals(response.status, 429);
  assertEquals(createCalls, 0);
});

Deno.test("member-phone-signup validates phone and password", async () => {
  const handler = createMemberPhoneSignupHandler(deps());
  assertEquals((await handler(request({ phone: "bad" }))).status, 400);
  assertEquals((await handler(request({ password: "short" }))).status, 400);
});

function deps(
  overrides: Partial<MemberPhoneSignupDeps> = {},
): MemberPhoneSignupDeps {
  return {
    isRateLimited: () => Promise.resolve(false),
    phoneExists: () => Promise.resolve(false),
    createUser: () => Promise.resolve(),
    ...overrides,
  };
}

function request(overrides: Record<string, unknown> = {}): Request {
  return new Request("https://example.test/member-phone-signup", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "cf-connecting-ip": "203.0.113.9",
    },
    body: JSON.stringify({
      phone: "+84912345678",
      password: "StrongPassword123!",
      full_name: "Nguyen Van A",
      ...overrides,
    }),
  });
}

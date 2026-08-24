import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createSleepSafetyContactVerificationHandler } from "./handler.ts";

Deno.test("verification request never returns OTP", async () => {
  const handler = createSleepSafetyContactVerificationHandler({
    authenticate: async () => "u1",
    getContact: async () => ({ id: "c1", userId: "u1", phoneE164: "+84901234567", active: true }),
    countRecentChallenges: async () => 0,
    createChallenge: async () => "ch1",
    getActiveChallenge: async () => null,
    updateChallenge: async () => {},
    markContactVerified: async () => {},
    sendCode: async () => true,
    hash: async (v) => `hash:${v}`,
    generateCode: () => "123456",
    now: () => new Date("2026-08-24T00:00:00Z"),
    verificationTtlSeconds: async () => 600,
  });
  const response = await handler(new Request("https://x", {
    method: "POST",
    headers: { authorization: "Bearer x", "content-type": "application/json" },
    body: JSON.stringify({ action: "request", contact_id: "c1" }),
  }));
  const body = await response.json();
  assertEquals(response.status, 202);
  assertEquals(body.accepted, true);
  assertEquals("code" in body, false);
});

Deno.test("verification confirm marks matching code", async () => {
  let verified = false;
  const handler = createSleepSafetyContactVerificationHandler({
    authenticate: async () => "u1",
    getContact: async () => ({ id: "c1", userId: "u1", phoneE164: "+84901234567", active: true }),
    countRecentChallenges: async () => 0,
    createChallenge: async () => "ch1",
    getActiveChallenge: async () => ({ id: "ch1", contactId: "c1", codeHash: "hash:123456", attemptCount: 0, expiresAt: "2026-08-24T00:10:00Z", status: "pending" }),
    updateChallenge: async () => {},
    markContactVerified: async () => { verified = true; },
    sendCode: async () => true,
    hash: async (v) => `hash:${v}`,
    generateCode: () => "123456",
    now: () => new Date("2026-08-24T00:00:00Z"),
    verificationTtlSeconds: async () => 600,
  });
  const response = await handler(new Request("https://x", {
    method: "POST",
    headers: { authorization: "Bearer x", "content-type": "application/json" },
    body: JSON.stringify({ action: "confirm", contact_id: "c1", code: "123456" }),
  }));
  assertEquals(response.status, 200);
  assertEquals(verified, true);
});

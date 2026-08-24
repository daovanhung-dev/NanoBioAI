import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createSleepSafetyDispatchHandler } from "./handler.ts";

Deno.test("dispatch fails closed when rollout is disabled", async () => {
  const handler = createSleepSafetyDispatchHandler({
    authenticate: async () => "u1",
    getRuntimeConfig: async () => ({ enabled: false, maxPerHour: 3, freshnessSeconds: 600 }),
    hasPaidAccess: async () => true,
    getEvent: async () => null,
    getVerifiedContacts: async () => [],
    countRecentRequests: async () => 0,
    getExisting: async () => [],
    createDispatch: async () => {},
    provider: { send: async () => ({ id: "p1", status: "submitted" }) },
    now: () => new Date("2026-08-24T00:00:00Z"),
  });
  const response = await handler(request({ event_id: "e1", idempotency_key: "k1" }));
  assertEquals(response.status, 503);
});

Deno.test("dispatch tries next contact after immediate voice and sms failure", async () => {
  const attempts: string[] = [];
  const handler = createSleepSafetyDispatchHandler({
    authenticate: async () => "u1",
    getRuntimeConfig: async () => ({ enabled: true, maxPerHour: 3, freshnessSeconds: 600 }),
    hasPaidAccess: async () => true,
    getEvent: async () => ({ id: "e1", userId: "u1", detectedAt: "2026-08-24T00:00:00Z", response: "noResponse", escalationRequired: true }),
    getVerifiedContacts: async () => [
      { id: "c1", phoneE164: "+84901111111", priority: 1 },
      { id: "c2", phoneE164: "+84902222222", priority: 2 },
    ],
    countRecentRequests: async () => 0,
    getExisting: async () => [],
    createDispatch: async (value) => { attempts.push(`${value.contactId}:${value.channel}:${value.status}`); },
    provider: {
      send: async (channel, value) => value.to.endsWith("111111")
        ? { id: "bad", status: channel === "voice" ? "no_answer" : "failed" }
        : { id: "ok", status: "submitted" },
    },
    now: () => new Date("2026-08-24T00:01:00Z"),
  });
  const response = await handler(request({ event_id: "e1", idempotency_key: "k1" }));
  const body = await response.json();
  assertEquals(response.status, 202);
  assertEquals(body.priority, 2);
  assertEquals(attempts, ["c1:voice:noAnswer", "c1:sms:failed", "c2:voice:submitted"]);
});

function request(body: Record<string, unknown>): Request {
  return new Request("https://x", {
    method: "POST",
    headers: { authorization: "Bearer x", "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

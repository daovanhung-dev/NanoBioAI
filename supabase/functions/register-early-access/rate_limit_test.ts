import { clientIp, hmacIpAddress, rateWindowStart } from "./rate_limit.ts";

Deno.test("HMAC IP hashes are stable, opaque, and distinct per IP", async () => {
  const first = await hmacIpAddress(
    "203.0.113.12",
    "test-hmac-secret-that-is-long-enough-32-bytes",
  );
  const repeated = await hmacIpAddress(
    "203.0.113.12",
    "test-hmac-secret-that-is-long-enough-32-bytes",
  );
  const other = await hmacIpAddress(
    "203.0.113.13",
    "test-hmac-secret-that-is-long-enough-32-bytes",
  );
  if (first !== repeated || first === other || !/^[0-9a-f]{64}$/.test(first)) {
    throw new Error("HMAC IP hash contract failed");
  }
  if (first.includes("203.0.113.12")) {
    throw new Error("raw IP appeared in the persisted key");
  }
});

Deno.test("uses the first forwarded address and rounds to an hourly window", () => {
  const request = new Request("https://example.test", {
    headers: { "x-forwarded-for": "203.0.113.12, 10.0.0.1" },
  });
  if (clientIp(request) !== "203.0.113.12") {
    throw new Error("forwarded client address was not selected");
  }
  if (clientIp(new Request("https://example.test")) !== null) {
    throw new Error("missing forwarded address was accepted");
  }
  if (
    rateWindowStart(new Date("2026-10-06T10:37:18.000Z")) !==
      "2026-10-06T10:00:00.000Z"
  ) throw new Error("hour window was not stable");
});

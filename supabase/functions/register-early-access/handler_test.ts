import { createEarlyAccessHandler, type EarlyAccessLead } from "./handler.ts";

const allowedOrigin = "https://daovanhung-dev.github.io";
const testNow = new Date("2026-10-06T10:37:00.000Z");

function validRequest(payload: Record<string, unknown> = {}) {
  return new Request(
    "https://project.example/functions/v1/register-early-access",
    {
      method: "POST",
      headers: {
        origin: allowedOrigin,
        "content-type": "application/json",
        "x-forwarded-for": "203.0.113.12, 10.0.0.1",
        referer:
          "https://daovanhung-dev.github.io/NanoBioAI/?utm_source=secret#private",
        "user-agent": "NanoBio test browser",
      },
      body: JSON.stringify({
        phone: "0912 345 678",
        full_name: "Nguyễn An",
        age: 24,
        gender: "prefer_not_to_say",
        address: "Quận 1, Thành phố Hồ Chí Minh",
        privacy_consent: true,
        landing_path: "/nanobio",
        ...payload,
      }),
    },
  );
}

function handler(overrides: Partial<{
  allowedOrigins: readonly string[];
  withinLimit: boolean;
  saveLead: (lead: EarlyAccessLead) => Promise<void>;
  downloadUrl: string | null;
  hmacIp: (ip: string) => Promise<string>;
}> = {}) {
  const captured: { lead?: EarlyAccessLead; ip?: string; window?: string } = {};
  const run = createEarlyAccessHandler({
    allowedOrigins: overrides.allowedOrigins ??
      [allowedOrigin, "http://localhost:5173"],
    appVersion: "1.0.1+4",
    hmacIp: overrides.hmacIp ?? (async (ip) => `hash:${ip}`),
    hmacPhone: async () => "a".repeat(64),
    consumeRateLimit: async (ip, window) => {
      captured.ip = ip;
      captured.window = window;
      return overrides.withinLimit ?? true;
    },
    saveLead: async (lead) => {
      captured.lead = lead;
      await overrides.saveLead?.(lead);
    },
    getPublicDownloadUrl: async () => overrides.downloadUrl ?? null,
    now: () => testNow,
  });
  return { run, captured };
}

Deno.test("persists only server-owned promotion fields and sanitized attribution", async () => {
  const { run, captured } = handler();
  const response = await run(validRequest({
    source: "spoofed",
    promotion_code: "other",
    requested_plan: "family_plus",
    vip_duration_days: 900,
    vip_grant_status: "active",
    status: "converted",
    full_name: "Đặng An",
    utm_source: "campaign 2026",
    utm_medium: "email/newsletter",
    utm_campaign: "launch#1",
    landing_path: "/nanobio?phone=123#fragment",
  }));
  const body = await response.json();
  if (response.status !== 200 || body.success !== true) {
    throw new Error("valid request was not accepted");
  }
  if (
    captured.lead?.phone_e164 !== "+84912345678" ||
    captured.lead.phone_display !== "0912 345 678"
  ) throw new Error("phone was not normalized");
  if (
    captured.lead.promotion_code !== "EARLY_ACCESS_PLUS_30D" ||
    captured.lead.requested_plan !== "plus" ||
    captured.lead.vip_duration_days !== 30
  ) throw new Error("client changed promotion values");
  if (
    captured.lead.vip_grant_status !== "pending_account_link" ||
    captured.lead.status !== "new" || captured.lead.full_name !== "Đặng An"
  ) throw new Error("client changed lead state");
  if (
    captured.lead.age !== 24 ||
    captured.lead.gender !== "prefer_not_to_say" ||
    captured.lead.address !== "Quận 1, Thành phố Hồ Chí Minh" ||
    captured.lead.phone_hash !== "a".repeat(64)
  ) throw new Error("customer data was not persisted safely");
  if (
    captured.lead.source !== "nanobio_web" ||
    captured.lead.utm_source !== "campaign2026" ||
    captured.lead.utm_medium !== "emailnewsletter" ||
    captured.lead.utm_campaign !== "launch1"
  ) throw new Error("source metadata was not sanitized");
  if (
    captured.lead.referrer !== "https://daovanhung-dev.github.io/NanoBioAI/" ||
    captured.lead.landing_path !== "/nanobio" ||
    captured.lead.user_agent !== "NanoBio test browser"
  ) throw new Error("request metadata was not sanitized");
  if (
    captured.ip !== "hash:203.0.113.12" ||
    captured.window !== "2026-10-06T10:00:00.000Z"
  ) throw new Error("rate limit did not use the forwarded IP and fixed window");
  if ("vip_grant_status" in body || "duplicate" in body) {
    throw new Error("response exposed lead or duplicate state");
  }
});

Deno.test("requires a valid Vietnamese mobile number and explicit consent", async () => {
  const { run } = handler();
  const invalidPhone = await run(validRequest({ phone: "0123 456 789" }));
  if (
    invalidPhone.status !== 400 ||
    (await invalidPhone.json()).code !== "INVALID_PHONE"
  ) throw new Error("invalid phone was accepted");
  const noConsent = await run(validRequest({ privacy_consent: false }));
  if (
    noConsent.status !== 400 ||
    (await noConsent.json()).code !== "CONSENT_REQUIRED"
  ) throw new Error("missing consent was accepted");
  const underAge = await run(validRequest({ age: 17 }));
  if (underAge.status !== 400 || (await underAge.json()).code !== "INVALID_AGE") {
    throw new Error("underage customer was accepted");
  }
  const missingName = await run(validRequest({ full_name: " " }));
  if (missingName.status !== 400 || (await missingName.json()).code !== "INVALID_FULL_NAME") {
    throw new Error("missing customer name was accepted");
  }
  const badGender = await run(validRequest({ gender: "admin" }));
  if (badGender.status !== 400 || (await badGender.json()).code !== "INVALID_GENDER") {
    throw new Error("unsupported gender was accepted");
  }
  const missingAddress = await run(validRequest({ address: " " }));
  if (missingAddress.status !== 400 || (await missingAddress.json()).code !== "INVALID_ADDRESS") {
    throw new Error("missing address was accepted");
  }
});

Deno.test("rejects unapproved origins and handles preflight without writing", async () => {
  const { run, captured } = handler();
  const wrongOrigin = new Request(
    "https://project.example/functions/v1/register-early-access",
    {
      method: "POST",
      headers: { origin: "https://evil.example" },
      body: "{}",
    },
  );
  if ((await run(wrongOrigin)).status !== 403) {
    throw new Error("unapproved origin was accepted");
  }
  const preflight = new Request(
    "https://project.example/functions/v1/register-early-access",
    {
      method: "OPTIONS",
      headers: { origin: allowedOrigin },
    },
  );
  const response = await run(preflight);
  if (
    response.status !== 204 ||
    response.headers.get("access-control-allow-origin") !== allowedOrigin ||
    captured.lead
  ) throw new Error("CORS preflight was not safe");
});

Deno.test("fails closed when rate limiting is unavailable and rejects the eleventh request", async () => {
  const limited = handler({ withinLimit: false });
  const limitedResponse = await limited.run(validRequest());
  if (limitedResponse.status !== 429 || limited.captured.lead) {
    throw new Error("rate limited request was persisted");
  }
  const unavailable = handler({
    hmacIp: async () => {
      throw new Error("missing secret");
    },
  });
  if ((await unavailable.run(validRequest())).status !== 503) {
    throw new Error("missing HMAC secret did not fail closed");
  }
});

Deno.test("duplicate phones return generic success and preserve an existing grant state", async () => {
  let persisted = {
    phone_e164: "+84912345678",
    vip_grant_status: "active",
    status: "converted",
  };
  const duplicate = handler({
    saveLead: async (lead) => {
      if (persisted.phone_e164 !== lead.phone_e164) {
        persisted = {
          phone_e164: lead.phone_e164,
          vip_grant_status: lead.vip_grant_status,
          status: lead.status,
        };
      }
    },
  });
  const body = await (await duplicate.run(validRequest())).json();
  if (
    body.success !== true || "vip_grant_status" in body || "duplicate" in body
  ) {
    throw new Error("duplicate response revealed lead state");
  }
  if (
    persisted.vip_grant_status !== "active" || persisted.status !== "converted"
  ) {
    throw new Error("duplicate reset an existing promotion or lead state");
  }
});

Deno.test("returns a truthful success when the APK is not available", async () => {
  const { run } = handler();
  const response = await run(validRequest());
  const body = await response.json();
  if (
    body.success !== true || body.download_available !== false ||
    body.download_url !== ""
  ) throw new Error("missing APK was reported as downloadable");
});

Deno.test("returns the approved public release URL only after saving the lead", async () => {
  let saved = false;
  const run = createEarlyAccessHandler({
    allowedOrigins: [allowedOrigin],
    appVersion: "1.0.1+4",
    hmacIp: async (ip) => `hash:${ip}`,
    hmacPhone: async () => "b".repeat(64),
    consumeRateLimit: async () => true,
    saveLead: async () => { saved = true; },
    getPublicDownloadUrl: async () => "https://github.com/daovanhung-dev/NanoBioAI/releases/download/nanobio-early-access-v1.0.1-build4/app-release.apk",
    now: () => testNow,
  });
  const body = await (await run(validRequest())).json();
  if (!saved || body.download_available !== true || !String(body.download_url).endsWith("/app-release.apk")) {
    throw new Error("download URL was not returned after persisting a valid lead");
  }
});

export type EarlyAccessLead = {
  phone_e164: string;
  phone_display: string;
  source: "nanobio_web";
  app_version: string;
  vip_support_requested: true;
  privacy_consent: true;
  promotion_code: "EARLY_ACCESS_PLUS_30D";
  requested_plan: "plus";
  vip_duration_days: 30;
  vip_grant_status: "pending_account_link";
  phone_hash: string;
  full_name: string;
  age: number;
  gender: "male" | "female" | "other" | "prefer_not_to_say";
  address: string;
  status: "new";
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  referrer: string | null;
  landing_path: string;
  user_agent: string | null;
};

export type EarlyAccessHandlerDependencies = {
  allowedOrigins: readonly string[];
  appVersion: string;
  hmacIp: (ip: string) => Promise<string>;
  hmacPhone: (phone: string) => Promise<string>;
  consumeRateLimit: (ipHash: string, windowStart: string) => Promise<boolean>;
  saveLead: (lead: EarlyAccessLead) => Promise<void>;
  getPublicDownloadUrl: () => Promise<string | null>;
  now?: () => Date;
};

const PROMOTION_CODE = "EARLY_ACCESS_PLUS_30D";
const REQUESTED_PLAN = "plus";
const VIP_DURATION_DAYS = 30;
const MAX_BODY_BYTES = 8192;
const RELEASE_APK_URL = "https://github.com/daovanhung-dev/NanoBioAI/releases/download/nanobio-early-access-v1.0.1-build4/app-release.apk";
const ALLOWED_GENDERS = new Set([
  "male",
  "female",
  "other",
  "prefer_not_to_say",
]);

export function createEarlyAccessHandler(deps: EarlyAccessHandlerDependencies) {
  return async (request: Request): Promise<Response> => {
    const origin = request.headers.get("origin");
    if (!origin || !deps.allowedOrigins.includes(origin)) {
      return jsonResponse(403, {
        success: false,
        code: "ORIGIN_NOT_ALLOWED",
        message: "Trang đăng ký hiện không khả dụng.",
      });
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }
    if (request.method !== "POST") {
      return jsonResponse(405, {
        success: false,
        code: "METHOD_NOT_ALLOWED",
        message: "Phương thức không được hỗ trợ.",
      }, origin);
    }

    let rawBody: string;
    try {
      rawBody = await request.text();
    } catch {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_JSON",
        message: "Dữ liệu gửi lên chưa đúng định dạng.",
      }, origin);
    }
    if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
      return jsonResponse(413, {
        success: false,
        code: "PAYLOAD_TOO_LARGE",
        message: "Dữ liệu gửi lên quá lớn.",
      }, origin);
    }

    const ip = clientIp(request);
    if (!ip) {
      return jsonResponse(503, {
        success: false,
        code: "RATE_LIMIT_UNAVAILABLE",
        message: "Đăng ký tạm thời chưa khả dụng. Vui lòng thử lại sau.",
      }, origin);
    }

    let ipHash: string;
    let withinLimit: boolean;
    try {
      ipHash = await deps.hmacIp(ip);
      const now = (deps.now ?? (() => new Date()))();
      const windowStart = rateWindowStart(now);
      withinLimit = await deps.consumeRateLimit(ipHash, windowStart);
    } catch {
      return jsonResponse(503, {
        success: false,
        code: "RATE_LIMIT_UNAVAILABLE",
        message: "Đăng ký tạm thời chưa khả dụng. Vui lòng thử lại sau.",
      }, origin);
    }
    if (!withinLimit) {
      return jsonResponse(429, {
        success: false,
        code: "RATE_LIMITED",
        message: "Bạn gửi yêu cầu hơi nhanh. Vui lòng thử lại sau.",
      }, origin);
    }

    let body: unknown;
    try {
      body = JSON.parse(rawBody);
    } catch {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_JSON",
        message: "Dữ liệu gửi lên chưa đúng định dạng.",
      }, origin);
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_BODY",
        message: "Dữ liệu gửi lên chưa đúng định dạng.",
      }, origin);
    }

    const input = body as Record<string, unknown>;
    const phoneE164 = normalizeVietnamPhone(input.phone);
    if (!phoneE164) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_PHONE",
        message: "Số điện thoại chưa đúng định dạng.",
      }, origin);
    }
    if (input.privacy_consent !== true) {
      return jsonResponse(400, {
        success: false,
        code: "CONSENT_REQUIRED",
        message: "Bạn cần xác nhận đồng ý trước khi tiếp tục.",
      }, origin);
    }

    const fullName = requiredText(input.full_name, 120);
    if (!fullName) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_FULL_NAME",
        message: "Vui lòng nhập họ tên hợp lệ.",
      }, origin);
    }
    const age = input.age;
    if (typeof age !== "number" || !Number.isInteger(age) || age < 18 || age > 120) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_AGE",
        message: "NanoBio Early Access hiện dành cho người từ 18 tuổi trở lên.",
      }, origin);
    }
    if (typeof input.gender !== "string" || !ALLOWED_GENDERS.has(input.gender)) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_GENDER",
        message: "Vui lòng chọn giới tính hoặc “Không muốn trả lời”.",
      }, origin);
    }
    const address = requiredText(input.address, 512);
    if (!address) {
      return jsonResponse(400, {
        success: false,
        code: "INVALID_ADDRESS",
        message: "Vui lòng nhập địa chỉ hợp lệ.",
      }, origin);
    }

    let phoneHash: string;
    try {
      phoneHash = await deps.hmacPhone(phoneE164);
      if (!/^[0-9a-f]{64}$/.test(phoneHash)) throw new Error("PHONE_HMAC_INVALID");
    } catch {
      return jsonResponse(503, {
        success: false,
        code: "REGISTRATION_UNAVAILABLE",
        message: "Đăng ký tạm thời chưa khả dụng. Vui lòng thử lại sau.",
      }, origin);
    }

    const lead: EarlyAccessLead = {
      phone_e164: phoneE164,
      phone_display: displayVietnamPhone(phoneE164),
      source: "nanobio_web",
      app_version: boundedText(deps.appVersion, 50) ?? "1.0.1+4",
      vip_support_requested: true,
      privacy_consent: true,
      promotion_code: PROMOTION_CODE,
      requested_plan: REQUESTED_PLAN,
      vip_duration_days: VIP_DURATION_DAYS,
      vip_grant_status: "pending_account_link",
      phone_hash: phoneHash,
      full_name: fullName,
      age,
      gender: input.gender as EarlyAccessLead["gender"],
      address,
      status: "new",
      utm_source: campaignValue(input.utm_source),
      utm_medium: campaignValue(input.utm_medium),
      utm_campaign: campaignValue(input.utm_campaign),
      referrer: sanitizeReferrer(request.headers.get("referer")),
      landing_path: sanitizeLandingPath(input.landing_path),
      user_agent: boundedText(request.headers.get("user-agent"), 512),
    };

    try {
      await deps.saveLead(lead);
    } catch {
      return jsonResponse(500, {
        success: false,
        code: "INTERNAL_ERROR",
        message: "Chưa thể ghi nhận đăng ký. Vui lòng thử lại sau.",
      }, origin);
    }

    let downloadUrl: string | null = null;
    try {
      const configuredUrl = await deps.getPublicDownloadUrl();
      downloadUrl = configuredUrl === RELEASE_APK_URL ? configuredUrl : null;
    } catch {
      downloadUrl = null;
    }

    return jsonResponse(200, {
      success: true,
      message: "Đã ghi nhận yêu cầu của bạn.",
      download_url: downloadUrl ?? "",
      download_available: downloadUrl !== null,
      expires_at: null,
      app_version: boundedText(deps.appVersion, 50) ?? "1.0.1+4",
      promotion_code: PROMOTION_CODE,
      vip_plan: REQUESTED_PLAN,
      vip_duration_days: VIP_DURATION_DAYS,
    }, origin);
  };
}

export function normalizeVietnamPhone(value: unknown): string | null {
  let raw = typeof value === "string"
    ? value.trim().replace(/[\s.()-]/g, "")
    : "";
  if (raw.startsWith("+84")) raw = `0${raw.slice(3)}`;
  else if (raw.startsWith("84") && raw.length >= 11) raw = `0${raw.slice(2)}`;
  if (!/^0(3|5|7|8|9)\d{8}$/.test(raw)) return null;
  return `+84${raw.slice(1)}`;
}

function displayVietnamPhone(e164: string): string {
  const local = `0${e164.slice(3)}`;
  return `${local.slice(0, 4)} ${local.slice(4, 7)} ${local.slice(7)}`;
}

function campaignValue(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/[^a-zA-Z0-9._~-]/g, "").slice(
    0,
    100,
  );
  return normalized || null;
}

function boundedText(value: unknown, maximum: number): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/[\u0000-\u001f\u007f]/g, "");
  return normalized ? normalized.slice(0, maximum) : null;
}

function requiredText(value: unknown, maximum: number): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/[\u0000-\u001f\u007f]/g, "");
  return normalized && normalized.length <= maximum ? normalized : null;
}

function sanitizeReferrer(value: string | null): string | null {
  if (!value) return null;
  try {
    const url = new URL(value);
    if (!["http:", "https:"].includes(url.protocol)) return null;
    return `${url.origin}${url.pathname}`.slice(0, 512);
  } catch {
    return null;
  }
}

function sanitizeLandingPath(value: unknown): string {
  return value === "/nanobio/privacy" ? "/nanobio/privacy" : "/nanobio";
}

function corsHeaders(origin: string): HeadersInit {
  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers":
      "authorization, x-client-info, apikey, content-type",
    "access-control-max-age": "86400",
    "content-type": "application/json; charset=utf-8",
    vary: "Origin",
  };
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  origin?: string,
): Response {
  const headers = origin
    ? corsHeaders(origin)
    : { "content-type": "application/json; charset=utf-8" };
  return new Response(JSON.stringify(body), { status, headers });
}
import { clientIp, rateWindowStart } from "./rate_limit.ts";

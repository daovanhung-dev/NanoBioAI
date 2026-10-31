import {
  memberAuthEmail,
  normalizeVietnamPhone,
} from "../_shared/member_phone_identity.ts";

export type MemberPhoneSignupDeps = {
  isRateLimited: (ip: string) => Promise<boolean>;
  phoneExists: (phone: string) => Promise<boolean>;
  createUser: (input: {
    email: string;
    phone: string;
    password: string;
    fullName: string;
    referralCode?: string;
    deviceFingerprint?: string;
  }) => Promise<void>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function createMemberPhoneSignupHandler(deps: MemberPhoneSignupDeps) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 200, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json(405, "method_not_allowed", "Phương thức không được hỗ trợ.");
    }

    let body: Record<string, unknown>;
    try {
      const parsed: unknown = await request.json();
      if (!isRecord(parsed)) {
        return json(400, "invalid_request", "Dữ liệu chưa hợp lệ.");
      }
      body = parsed;
    } catch {
      return json(400, "invalid_request", "Dữ liệu chưa hợp lệ.");
    }

    const phone = normalizeVietnamPhone(text(body.phone) ?? "");
    const password = typeof body.password === "string" ? body.password : "";
    const fullName = text(body.full_name) ?? "";
    const referralCode = text(body.referral_code)?.toUpperCase();
    const deviceFingerprint = text(body.device_fingerprint);
    if (!phone) return json(400, "invalid_phone", "Số điện thoại chưa hợp lệ.");
    if (password.length < 8 || password.length > 128) {
      return json(400, "weak_password", "Mật khẩu cần từ 8 đến 128 ký tự.");
    }
    if (fullName.length < 2 || fullName.length > 120) {
      return json(400, "invalid_name", "Họ và tên chưa hợp lệ.");
    }
    if (referralCode && !deviceFingerprint) {
      return json(400, "referral_device_missing", "Thiếu thông tin thiết bị.");
    }

    const ip = request.headers.get("cf-connecting-ip") ??
      request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
      "unknown";
    let limited: boolean;
    try {
      limited = await deps.isRateLimited(ip);
    } catch {
      return json(503, "signup_unavailable", "Chưa thể tạo tài khoản lúc này.");
    }
    if (limited) {
      return json(
        429,
        "rate_limited",
        "Bạn đã gửi quá nhiều yêu cầu. Hãy thử lại sau.",
      );
    }

    try {
      if (await deps.phoneExists(phone)) {
        return json(409, "phone_exists", "Số điện thoại này đã có tài khoản.");
      }
      await deps.createUser({
        email: memberAuthEmail(phone),
        phone,
        password,
        fullName,
        ...(referralCode ? { referralCode } : {}),
        ...(deviceFingerprint ? { deviceFingerprint } : {}),
      });
      return json(201, "created", "Đã tạo tài khoản.");
    } catch (error) {
      const message = String(error).toLowerCase();
      if (
        message.includes("already") || message.includes("registered") ||
        message.includes("exists") || message.includes("duplicate")
      ) {
        return json(409, "phone_exists", "Số điện thoại này đã có tài khoản.");
      }
      return json(500, "signup_unavailable", "Chưa thể tạo tài khoản lúc này.");
    }
  };
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length ? normalized : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function json(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ success: status < 400, code, message }),
    {
      status,
      headers: {
        ...corsHeaders,
        "content-type": "application/json; charset=utf-8",
      },
    },
  );
}

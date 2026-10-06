export type EarlyAccessLeadStatus =
  | "new"
  | "contacted"
  | "registered"
  | "converted"
  | "rejected";

export type EarlyAccessAdminLead = {
  id: string;
  phone_e164: string;
  phone_display: string | null;
  full_name: string | null;
  age: number | null;
  gender: string | null;
  address: string | null;
  status: EarlyAccessLeadStatus;
  created_at: string;
};

export type EarlyAccessAdminHandlerDependencies = {
  allowedOrigins: readonly string[];
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  listLeads: (
    query: string,
    offset: number,
    pageSize: number,
  ) => Promise<{ rows: EarlyAccessAdminLead[]; total: number }>;
  updateStatus: (input: {
    leadId: string;
    status: EarlyAccessLeadStatus;
    actorId: string;
    reason: string;
    idempotencyKey: string;
  }) => Promise<void>;
};

const STATUS_VALUES = new Set<EarlyAccessLeadStatus>([
  "new",
  "contacted",
  "registered",
  "converted",
  "rejected",
]);
const MAX_BODY_BYTES = 8192;

export function createEarlyAccessAdminHandler(
  deps: EarlyAccessAdminHandlerDependencies,
) {
  return async (request: Request): Promise<Response> => {
    const origin = request.headers.get("origin");
    if (!origin || !deps.allowedOrigins.includes(origin)) {
      return jsonResponse(403, {
        success: false,
        code: "ORIGIN_NOT_ALLOWED",
        message: "Yêu cầu không được phép.",
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

    let actorId: string | null;
    try {
      actorId = await deps.authenticate(request.headers.get("authorization"));
    } catch {
      actorId = null;
    }
    if (!actorId) {
      return jsonResponse(401, {
        success: false,
        code: "AUTH_REQUIRED",
        message: "Phiên quản trị đã hết hạn. Vui lòng đăng nhập lại.",
      }, origin);
    }

    let allowed: boolean;
    try {
      allowed = await deps.isAllowedAdmin(actorId);
    } catch {
      allowed = false;
    }
    if (!allowed) {
      return jsonResponse(403, {
        success: false,
        code: "ADMIN_ROLE_REQUIRED",
        message: "Tài khoản chưa được cấp quyền xem thông tin sự kiện.",
      }, origin);
    }

    let rawBody: string;
    try {
      rawBody = await request.text();
    } catch {
      return invalidRequest(origin);
    }
    if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
      return invalidRequest(origin);
    }

    let input: Record<string, unknown>;
    try {
      const body: unknown = JSON.parse(rawBody);
      if (!body || typeof body !== "object" || Array.isArray(body)) {
        return invalidRequest(origin);
      }
      input = body as Record<string, unknown>;
    } catch {
      return invalidRequest(origin);
    }

    if (input.action === "list") {
      const page = integerInRange(input.page, 0, 10000, 0);
      const pageSize = integerInRange(input.page_size, 1, 50, 25);
      if (page === null || pageSize === null) return invalidRequest(origin);
      const query = normalizeQuery(input.query);
      try {
        const result = await deps.listLeads(query, page * pageSize, pageSize);
        return jsonResponse(200, {
          success: true,
          rows: result.rows,
          total: result.total,
          page,
          page_size: pageSize,
        }, origin);
      } catch {
        return jsonResponse(500, {
          success: false,
          code: "LEAD_LIST_FAILED",
          message: "Chưa tải được danh sách thông tin sự kiện. Vui lòng thử lại.",
        }, origin);
      }
    }

    if (input.action === "update_status") {
      const leadId = typeof input.lead_id === "string" ? input.lead_id : "";
      const status = input.status;
      const reason = boundedText(input.reason, 300);
      const idempotencyKey = boundedText(input.idempotency_key, 120);
      if (
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(leadId) ||
        typeof status !== "string" || !STATUS_VALUES.has(status as EarlyAccessLeadStatus) ||
        !reason || reason.length < 5 || !idempotencyKey || idempotencyKey.length < 8
      ) return invalidRequest(origin);
      try {
        await deps.updateStatus({
          leadId,
          status: status as EarlyAccessLeadStatus,
          actorId,
          reason,
          idempotencyKey,
        });
        return jsonResponse(200, {
          success: true,
          message: "Đã cập nhật trạng thái hồ sơ.",
        }, origin);
      } catch {
        return jsonResponse(500, {
          success: false,
          code: "LEAD_STATUS_UPDATE_FAILED",
          message: "Chưa cập nhật được trạng thái. Vui lòng tải lại rồi thử lại.",
        }, origin);
      }
    }

    return invalidRequest(origin);
  };
}

function normalizeQuery(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.replace(/[^\p{L}\p{N}\s+]/gu, " ").replace(/\s+/g, " ")
    .trim().slice(0, 100);
}

function integerInRange(
  value: unknown,
  minimum: number,
  maximum: number,
  fallback: number,
): number | null {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isInteger(value)) return null;
  return value >= minimum && value <= maximum ? value : null;
}

function boundedText(value: unknown, maximum: number): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/[\u0000-\u001f\u007f]/g, "");
  return normalized && normalized.length <= maximum ? normalized : null;
}

function invalidRequest(origin: string): Response {
  return jsonResponse(400, {
    success: false,
    code: "INVALID_REQUEST",
    message: "Thông tin gửi lên chưa hợp lệ.",
  }, origin);
}

function corsHeaders(origin: string): HeadersInit {
  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers":
      "authorization, apikey, x-client-info, content-type",
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
  return new Response(JSON.stringify(body), {
    status,
    headers: origin ? corsHeaders(origin) : { "content-type": "application/json; charset=utf-8" },
  });
}

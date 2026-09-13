export type MembershipPeriodAdjustment = {
  subscriptionId: string;
  planCode: string;
  status: string;
  startsAt: string;
  previousEndsAt: string | null;
  endsAt: string | null;
  operation: string;
  deltaDays: number | null;
};

export type AdminAdjustMembershipPeriodDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  adjust: (input: {
    actorId: string;
    userId: string;
    subscriptionId: string;
    operation: "add_days" | "subtract_days" | "set_end_at";
    days: number | null;
    endsAt: string | null;
    expectedEndsAt: string | null;
    reason: string;
    idempotencyKey: string;
  }) => Promise<MembershipPeriodAdjustment>;
};

export function createAdminAdjustMembershipPeriodHandler(
  deps: AdminAdjustMembershipPeriodDeps,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 200, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json(405, {
        success: false,
        message: "Phương thức không được hỗ trợ.",
      });
    }

    const actorId = await deps.authenticate(
      request.headers.get("Authorization"),
    );
    if (!actorId) {
      return json(401, {
        success: false,
        message: "Phiên đăng nhập không hợp lệ.",
      });
    }
    if (!await deps.isAllowedAdmin(actorId)) {
      return json(403, {
        success: false,
        message: "Chỉ Super Admin được điều chỉnh thời hạn gói.",
      });
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json(400, {
        success: false,
        message: "Dữ liệu gửi lên chưa hợp lệ.",
      });
    }

    const userId = text(body.user_id);
    const subscriptionId = text(body.subscription_id);
    const operation = text(body.operation);
    const reason = text(body.reason);
    const idempotencyKey = text(body.idempotency_key);
    const expectedEndsAt = parseNullableDate(body.expected_ends_at);
    const endsAt = parseNullableDate(body.ends_at);
    const days = parseDays(body.days);

    if (!userId || !subscriptionId) {
      return json(400, {
        success: false,
        message: "Chưa chọn gói cần điều chỉnh.",
      });
    }
    if (
      operation !== "add_days" &&
      operation !== "subtract_days" &&
      operation !== "set_end_at"
    ) {
      return json(400, {
        success: false,
        message: "Cách điều chỉnh thời hạn chưa hợp lệ.",
      });
    }
    if (expectedEndsAt.invalid || endsAt.invalid || Number.isNaN(days)) {
      return json(400, {
        success: false,
        message: "Thời điểm gói chưa hợp lệ.",
      });
    }
    if (expectedEndsAt.missing) {
      return json(400, {
        success: false,
        message: "Thiếu thời điểm hiện tại của gói.",
      });
    }
    if (operation === "set_end_at") {
      if (endsAt.value === null || days !== null) {
        return json(400, {
          success: false,
          message: "Cần chọn ngày kết thúc mới.",
        });
      }
    } else if (endsAt.value !== null || days === null) {
      return json(400, {
        success: false,
        message: "Cần nhập số ngày lớn hơn 0.",
      });
    }
    if (!reason) {
      return json(400, {
        success: false,
        message: "Cần nhập lý do điều chỉnh.",
      });
    }
    if (!idempotencyKey) {
      return json(400, {
        success: false,
        message: "Thiếu mã chống gửi trùng.",
      });
    }

    try {
      const adjustment = await deps.adjust({
        actorId,
        userId,
        subscriptionId,
        operation,
        days,
        endsAt: endsAt.value,
        expectedEndsAt: expectedEndsAt.value,
        reason,
        idempotencyKey,
      });
      return json(200, {
        success: true,
        message: "Đã cập nhật thời hạn gói.",
        subscription_id: adjustment.subscriptionId,
        plan_code: adjustment.planCode,
        status: adjustment.status,
        starts_at: adjustment.startsAt,
        previous_ends_at: adjustment.previousEndsAt,
        ends_at: adjustment.endsAt,
        operation: adjustment.operation,
        delta_days: adjustment.deltaDays,
      });
    } catch (error) {
      return requestError(error);
    }
  };
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function requestError(error: unknown): Response {
  const source = error as { code?: unknown; message?: unknown };
  const code = String(source?.code ?? "").toUpperCase();
  const message = String(source?.message ?? "").toUpperCase();
  const token = `${code} ${message}`;

  if (token.includes("MEMBERSHIP_NOT_FOUND") || code === "P0002") {
    return json(404, {
      success: false,
      message: "Không tìm thấy gói cần điều chỉnh.",
    });
  }
  if (
    token.includes("MEMBERSHIP_PERIOD_STALE") ||
    token.includes("IDEMPOTENCY_KEY_REUSED") ||
    code === "40001" ||
    code === "23505"
  ) {
    return json(409, {
      success: false,
      message:
        "Gói đã thay đổi hoặc mã thao tác đã được dùng. Hãy tải lại dữ liệu.",
    });
  }
  if (token.includes("ADMIN_PERMISSION_REQUIRED")) {
    return json(403, {
      success: false,
      message: "Tài khoản chưa được cấp quyền cho thao tác này.",
    });
  }
  if (
    token.includes("MEMBERSHIP_ADJUSTMENT") ||
    token.includes("IDEMPOTENCY_KEY_REQUIRED")
  ) {
    return json(400, {
      success: false,
      message: "Thời hạn gói chưa hợp lệ hoặc chưa đủ thông tin.",
    });
  }
  return json(500, {
    success: false,
    message: "Chưa thể cập nhật thời hạn gói lúc này.",
  });
}

function parseDays(value: unknown): number | null {
  if (value === undefined || value === null) return null;
  return typeof value === "number" && Number.isInteger(value) && value > 0
    ? value
    : Number.NaN;
}

function parseNullableDate(value: unknown): {
  value: string | null;
  invalid: boolean;
  missing?: boolean;
} {
  if (value === undefined) {
    return { value: null, invalid: false, missing: true };
  }
  if (value === null) return { value: null, invalid: false };
  const normalized = text(value);
  if (!normalized) return { value: null, invalid: true };
  const timestamp = Date.parse(normalized);
  return Number.isFinite(timestamp)
    ? { value: new Date(timestamp).toISOString(), invalid: false }
    : { value: null, invalid: true };
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 ? result : null;
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders,
    },
  });
}

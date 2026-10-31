export type BulkMembershipGrant = {
  batchId: string;
  planCode: string;
  startsAt: string;
  endsAt: null;
  targetCount: number;
  grantedCount: number;
  alreadyGrantedCount: number;
  familyPlusCount: number;
};

export type AdminGrantMembershipBulkDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  findIdempotentResult: (
    idempotencyKey: string,
  ) => Promise<BulkMembershipGrant | null>;
  grant: (input: {
    actorId: string;
    scope: string;
    planCode: string;
    startsAt: string;
    endsAt: null;
    reason: string;
    idempotencyKey: string;
  }) => Promise<BulkMembershipGrant>;
};

export function createAdminGrantMembershipBulkHandler(
  deps: AdminGrantMembershipBulkDeps,
) {
  return async (request: Request): Promise<Response> => {
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
        message: "Chỉ Super Admin được cấp gói hàng loạt.",
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

    const scope = text(body.scope);
    const planCode = text(body.plan_code);
    const startsAt = text(body.starts_at) ?? new Date().toISOString();
    const reason = text(body.reason);
    const idempotencyKey = text(body.idempotency_key);

    if (scope !== "all_registered") {
      return json(400, {
        success: false,
        message: "Phạm vi cấp gói không hợp lệ.",
      });
    }
    if (planCode !== "plus") {
      return json(400, {
        success: false,
        message: "Gói cấp hàng loạt không hợp lệ.",
      });
    }
    if (body.ends_at !== undefined && body.ends_at !== null) {
      return json(400, {
        success: false,
        message: "Cấp gói hàng loạt chỉ hỗ trợ gói vĩnh viễn.",
      });
    }

    const start = Date.parse(startsAt);
    if (!Number.isFinite(start)) {
      return json(400, {
        success: false,
        message: "Thời điểm bắt đầu cấp gói không hợp lệ.",
      });
    }
    if (!reason) {
      return json(400, {
        success: false,
        message: "Cần lý do cấp gói.",
      });
    }
    if (!idempotencyKey) {
      return json(400, {
        success: false,
        message: "Thiếu mã chống gửi trùng.",
      });
    }

    const existing = await deps.findIdempotentResult(idempotencyKey);
    if (existing) {
      return success(existing, "Batch đã hoàn tất ở lần gửi trước.");
    }

    try {
      const grant = await deps.grant({
        actorId,
        scope,
        planCode,
        startsAt: new Date(start).toISOString(),
        endsAt: null,
        reason,
        idempotencyKey,
      });
      return success(grant, "Đã cấp Plus vĩnh viễn cho các tài khoản phù hợp.");
    } catch {
      return json(500, {
        success: false,
        message: "Chưa thể hoàn tất cấp gói hàng loạt lúc này.",
      });
    }
  };
}

function success(grant: BulkMembershipGrant, message: string) {
  return json(200, {
    success: true,
    message,
    batch_id: grant.batchId,
    plan_code: grant.planCode,
    starts_at: grant.startsAt,
    ends_at: grant.endsAt,
    target_count: grant.targetCount,
    granted_count: grant.grantedCount,
    already_granted_count: grant.alreadyGrantedCount,
    family_plus_count: grant.familyPlusCount,
  });
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length === 0 ? null : result;
}

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

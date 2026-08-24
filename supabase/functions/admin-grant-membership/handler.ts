export type MembershipGrant = {
  subscriptionId: string;
  planCode: string;
  startsAt: string;
  endsAt: string;
};

export type AdminGrantMembershipDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  findIdempotentResult: (idempotencyKey: string) => Promise<MembershipGrant | null>;
  userExists: (userId: string) => Promise<boolean>;
  grant: (input: {
    actorId: string;
    userId: string;
    planCode: string;
    startsAt: string;
    endsAt: string;
    reason: string;
    idempotencyKey: string;
  }) => Promise<MembershipGrant>;
};

export function createAdminGrantMembershipHandler(deps: AdminGrantMembershipDeps) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") return json(405, { success: false, message: "Phương thức không được hỗ trợ." });
    const actorId = await deps.authenticate(request.headers.get("Authorization"));
    if (!actorId) return json(401, { success: false, message: "Phiên đăng nhập không hợp lệ." });
    if (!await deps.isAllowedAdmin(actorId)) {
      return json(403, { success: false, message: "Chỉ Super Admin được cấp gói thủ công." });
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json(400, { success: false, message: "Dữ liệu gửi lên chưa hợp lệ." });
    }

    const userId = text(body.user_id);
    const planCode = text(body.plan_code);
    const startsAt = text(body.starts_at);
    const endsAt = text(body.ends_at);
    const reason = text(body.reason);
    const idempotencyKey = text(body.idempotency_key);

    if (!userId) return json(400, { success: false, message: "Chưa chọn tài khoản." });
    if (planCode !== "plus" && planCode !== "family_plus") {
      return json(400, { success: false, message: "Gói thành viên không hợp lệ." });
    }
    const start = startsAt ? Date.parse(startsAt) : NaN;
    const end = endsAt ? Date.parse(endsAt) : NaN;
    if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) {
      return json(400, { success: false, message: "Thời hạn cấp gói không hợp lệ." });
    }
    if (!reason) return json(400, { success: false, message: "Cần lý do cấp gói." });
    if (!idempotencyKey) return json(400, { success: false, message: "Thiếu mã chống gửi trùng." });

    const existing = await deps.findIdempotentResult(idempotencyKey);
    if (existing) return success(existing, "Gói đã được cấp ở lần gửi trước.");
    if (!await deps.userExists(userId)) {
      return json(404, { success: false, message: "Không tìm thấy tài khoản cần nâng cấp." });
    }

    try {
      const grant = await deps.grant({
        actorId,
        userId,
        planCode,
        startsAt: new Date(start).toISOString(),
        endsAt: new Date(end).toISOString(),
        reason,
        idempotencyKey,
      });
      return success(grant, "Đã cập nhật gói thành viên.");
    } catch {
      return json(500, { success: false, message: "Chưa thể cập nhật gói thành viên lúc này." });
    }
  };
}

function success(grant: MembershipGrant, message: string) {
  return json(200, {
    success: true,
    message,
    plan_code: grant.planCode,
    starts_at: grant.startsAt,
    ends_at: grant.endsAt,
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

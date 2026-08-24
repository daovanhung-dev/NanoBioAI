export type CreatedAccount = { userId: string; email: string };

export type AdminCreateAccountDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  findIdempotentResult: (idempotencyKey: string) => Promise<CreatedAccount | null>;
  createUser: (input: {
    email: string;
    password: string;
    fullName: string;
    phone: string | null;
  }) => Promise<CreatedAccount>;
  deleteUser: (userId: string) => Promise<void>;
  writeAudit: (input: {
    actorId: string;
    userId: string;
    email: string;
    reason: string;
    idempotencyKey: string;
  }) => Promise<void>;
};

export function createAdminCreateAccountHandler(deps: AdminCreateAccountDeps) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") return json(405, { success: false, message: "Phương thức không được hỗ trợ." });

    const actorId = await deps.authenticate(request.headers.get("Authorization"));
    if (!actorId) return json(401, { success: false, message: "Phiên đăng nhập không hợp lệ." });
    if (!await deps.isAllowedAdmin(actorId)) {
      return json(403, { success: false, message: "Tài khoản quản trị chưa được phép tạo tài khoản." });
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json(400, { success: false, message: "Dữ liệu gửi lên chưa hợp lệ." });
    }

    const fullName = text(body.full_name);
    const email = text(body.email)?.toLowerCase();
    const password = typeof body.password === "string" ? body.password : "";
    const phone = text(body.phone);
    const reason = text(body.reason);
    const idempotencyKey = text(body.idempotency_key);

    if (!fullName || fullName.length < 2) return json(400, { success: false, message: "Họ và tên chưa hợp lệ." });
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json(400, { success: false, message: "Email chưa đúng định dạng." });
    }
    if (password.length < 8) return json(400, { success: false, message: "Mật khẩu cần ít nhất 8 ký tự." });
    if (!reason) return json(400, { success: false, message: "Cần lý do tạo tài khoản." });
    if (!idempotencyKey) return json(400, { success: false, message: "Thiếu mã chống gửi trùng." });

    const existing = await deps.findIdempotentResult(idempotencyKey);
    if (existing) {
      return json(200, {
        success: true,
        user_id: existing.userId,
        email: existing.email,
        message: "Tài khoản đã được tạo ở lần gửi trước.",
      });
    }

    let created: CreatedAccount;
    try {
      created = await deps.createUser({ email, password, fullName, phone });
    } catch (error) {
      const message = String(error).toLowerCase();
      if (message.includes("already") || message.includes("registered") || message.includes("exists")) {
        return json(409, { success: false, message: "Email này đã có tài khoản." });
      }
      return json(500, { success: false, message: "Chưa thể tạo tài khoản lúc này." });
    }

    try {
      await deps.writeAudit({
        actorId,
        userId: created.userId,
        email: created.email,
        reason,
        idempotencyKey,
      });
    } catch {
      try {
        await deps.deleteUser(created.userId);
      } catch {
        // Không ghi log dữ liệu nhạy cảm. Backend operator xử lý bằng audit/runtime monitoring.
      }
      return json(500, { success: false, message: "Chưa thể hoàn tất tạo tài khoản an toàn." });
    }

    return json(200, {
      success: true,
      user_id: created.userId,
      email: created.email,
      message: "Đã tạo tài khoản.",
    });
  };
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

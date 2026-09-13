export type UserManagementOperation =
  | "detail"
  | "update_profile"
  | "reset_password";

export type UserProfileChanges = {
  fullName?: string;
  phone?: string | null;
  gender?: string | null;
  birthYear?: number | null;
};

export type UserManagementIdempotency = {
  targetId: string;
  status: "started" | "completed";
  changedFields?: string[];
};

export type UserManagementDetails = {
  user: Record<string, unknown>;
  health: Record<string, unknown>;
  membership: Record<string, unknown>;
};

export type AdminUserManagementDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  findIdempotency: (
    action: "admin_update_user_profile" | "admin_reset_user_password",
    idempotencyKey: string,
  ) => Promise<UserManagementIdempotency | null>;
  getDetails: (userId: string) => Promise<UserManagementDetails>;
  updateProfile: (input: {
    userId: string;
    changes: UserProfileChanges;
  }) => Promise<void>;
  writeAudit: (input: {
    actorId: string;
    action: string;
    userId: string;
    reason: string;
    idempotencyKey?: string;
    metadata?: Record<string, unknown>;
  }) => Promise<void>;
  resetPassword: (input: {
    actorId: string;
    userId: string;
    reason: string;
    idempotencyKey: string;
  }) => Promise<{ password: string }>;
};

export class UserManagementRequestError extends Error {
  constructor(readonly status: 400 | 404 | 409, message: string) {
    super(message);
    this.name = "UserManagementRequestError";
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function createAdminUserManagementHandler(
  deps: AdminUserManagementDeps,
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
        message: "Chỉ Super Admin được quản lý thông tin người dùng.",
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

    const operation = text(body.operation);
    const userId = text(body.user_id);
    const reason = text(body.reason);
    if (!operation || !isOperation(operation)) {
      return json(400, {
        success: false,
        message: "Thao tác quản lý người dùng chưa hợp lệ.",
      });
    }
    if (!userId) {
      return json(400, {
        success: false,
        message: "Chưa chọn tài khoản.",
      });
    }
    if (!reason) {
      return json(400, {
        success: false,
        message: "Cần nhập lý do cho thao tác này.",
      });
    }

    if (operation === "detail") {
      try {
        const details = await deps.getDetails(userId);
        await deps.writeAudit({
          actorId,
          action: "admin_view_user_health",
          userId,
          reason,
          metadata: { scope: "self_health_and_current_membership" },
        });
        return json(200, { success: true, ...details });
      } catch (error) {
        return requestError(error, "Chưa tải được thông tin chi tiết.");
      }
    }

    const idempotencyKey = text(body.idempotency_key);
    if (!idempotencyKey) {
      return json(400, {
        success: false,
        message: "Thiếu mã chống gửi trùng.",
      });
    }

    if (operation === "update_profile") {
      const changes = parseProfileChanges(body);
      if (changes.error) {
        return json(400, { success: false, message: changes.error });
      }

      try {
        const previous = await deps.findIdempotency(
          "admin_update_user_profile",
          idempotencyKey,
        );
        if (previous) {
          if (previous.targetId !== userId) {
            return json(409, {
              success: false,
              message: "Mã thao tác đã được dùng cho tài khoản khác.",
            });
          }
          return json(200, {
            success: true,
            message: "Thông tin người dùng đã được cập nhật trước đó.",
            changed_fields: previous.changedFields ?? [],
          });
        }

        await deps.updateProfile({ userId, changes: changes.value });
        const changedFields = Object.keys(changes.value).map((key) =>
          key.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)
        );
        await deps.writeAudit({
          actorId,
          action: "admin_update_user_profile",
          userId,
          reason,
          idempotencyKey,
          metadata: { status: "completed", changed_fields: changedFields },
        });
        return json(200, {
          success: true,
          message: "Đã cập nhật thông tin người dùng.",
          changed_fields: changedFields,
        });
      } catch (error) {
        return requestError(error, "Chưa cập nhật được thông tin người dùng.");
      }
    }

    if (actorId === userId) {
      return json(400, {
        success: false,
        message: "Không thể đổi mật khẩu của tài khoản đang quản trị.",
      });
    }

    try {
      const previous = await deps.findIdempotency(
        "admin_reset_user_password",
        idempotencyKey,
      );
      if (previous) {
        if (previous.targetId !== userId) {
          return json(409, {
            success: false,
            message: "Mã thao tác đã được dùng cho tài khoản khác.",
          });
        }
        if (previous.status === "started") {
          return json(409, {
            success: false,
            message:
              "Thao tác đổi mật khẩu trước đó chưa có kết quả. Không tạo mật khẩu mới.",
          });
        }
        return json(200, {
          success: true,
          status: "already_processed",
          password_visible_once: false,
          message: "Mật khẩu đã được đổi trước đó và không thể hiển thị lại.",
        });
      }

      const result = await deps.resetPassword({
        actorId,
        userId,
        reason,
        idempotencyKey,
      });
      return json(200, {
        success: true,
        status: "password_reset",
        temporary_password: result.password,
        password_visible_once: true,
        message:
          "Đã đổi mật khẩu. Hãy lưu lại mật khẩu này và gửi cho người dùng qua kênh an toàn.",
      });
    } catch (error) {
      return requestError(error, "Chưa đổi được mật khẩu người dùng.");
    }
  };
}

function parseProfileChanges(body: Record<string, unknown>): {
  value: UserProfileChanges;
  error?: string;
} {
  for (
    const forbidden of [
      "email",
      "avatar_url",
      "password",
      "plan_code",
      "membership",
      "health",
    ]
  ) {
    if (forbidden in body) {
      return {
        value: {},
        error: "Chỉ được sửa thông tin cơ bản được cho phép.",
      };
    }
  }

  const changes: UserProfileChanges = {};
  if ("full_name" in body) {
    const value = text(body.full_name);
    if (!value || value.length < 2 || value.length > 120) {
      return { value: {}, error: "Họ và tên chưa hợp lệ." };
    }
    changes.fullName = value;
  }
  if ("phone" in body) {
    const value = nullableText(body.phone);
    if (value !== null && value.length > 32) {
      return { value: {}, error: "Số điện thoại chưa hợp lệ." };
    }
    changes.phone = value;
  }
  if ("gender" in body) {
    const value = nullableText(body.gender);
    if (value !== null && value.length > 64) {
      return { value: {}, error: "Thông tin giới tính chưa hợp lệ." };
    }
    changes.gender = value;
  }
  if ("birth_year" in body) {
    const value = body.birth_year === null || body.birth_year === ""
      ? null
      : typeof body.birth_year === "number"
      ? body.birth_year
      : Number(body.birth_year);
    if (
      value !== null &&
      (!Number.isInteger(value) || value < 1900 ||
        value > new Date().getFullYear())
    ) {
      return { value: {}, error: "Năm sinh chưa hợp lệ." };
    }
    changes.birthYear = value;
  }

  if (Object.keys(changes).length === 0) {
    return { value: {}, error: "Chưa có thông tin cần cập nhật." };
  }
  return { value: changes };
}

function requestError(error: unknown, fallback: string): Response {
  if (error instanceof UserManagementRequestError) {
    return json(error.status, { success: false, message: error.message });
  }
  return json(500, { success: false, message: fallback });
}

function isOperation(value: string): value is UserManagementOperation {
  return value === "detail" || value === "update_profile" ||
    value === "reset_password";
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 ? result : null;
}

function nullableText(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  return text(value);
}

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders,
    },
  });
}

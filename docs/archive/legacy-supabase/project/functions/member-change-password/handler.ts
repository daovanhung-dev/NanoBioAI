export type MemberChangePasswordDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  changePassword: (userId: string, password: string) => Promise<void>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function createMemberChangePasswordHandler(
  deps: MemberChangePasswordDeps,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 200, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json(405, false, "Phương thức không được hỗ trợ.");
    }

    const userId = await deps.authenticate(
      request.headers.get("Authorization"),
    );
    if (!userId) {
      return json(401, false, "Phiên đăng nhập không hợp lệ.");
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return json(400, false, "Dữ liệu chưa hợp lệ.");
    }
    if (!isRecord(body) || typeof body.new_password !== "string") {
      return json(400, false, "Dữ liệu chưa hợp lệ.");
    }
    const password = body.new_password;
    if (password.length < 8 || password.length > 128) {
      return json(400, false, "Mật khẩu cần từ 8 đến 128 ký tự.");
    }

    try {
      await deps.changePassword(userId, password);
      return json(200, true, "Đã cập nhật mật khẩu.");
    } catch {
      return json(409, false, "Chưa cập nhật được mật khẩu. Hãy thử lại.");
    }
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function json(status: number, success: boolean, message: string): Response {
  return new Response(JSON.stringify({ success, message }), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json; charset=utf-8",
    },
  });
}

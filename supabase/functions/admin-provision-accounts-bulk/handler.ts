export type BulkProvisionAccount = {
  email: string;
  fullName: string;
};

export type BulkPreviewCandidate = BulkProvisionAccount & {
  index: number;
  status: "new" | "existing" | "paid_preserved";
  userId?: string;
  currentPlan?: string;
};

export type BulkPreview = {
  fingerprint: string;
  candidateCount: number;
  candidates: BulkPreviewCandidate[];
};

export type BulkProvisionResult = {
  batchId: string;
  processedCount: number;
  createdCount: number;
  grantedCount: number;
  skippedCount: number;
  failedIndex?: number;
};

export class BulkProvisionExecutionError extends Error {
  constructor(readonly result: BulkProvisionResult) {
    super("Bulk provisioning stopped after a row failed.");
    this.name = "BulkProvisionExecutionError";
  }
}

export type AdminProvisionAccountsBulkDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  isAllowedAdmin: (actorId: string) => Promise<boolean>;
  inspect: (input: {
    accounts: BulkProvisionAccount[];
    planCode: "plus" | "family_plus";
    durationMonths: 1 | 3 | 6 | 12;
  }) => Promise<BulkPreview>;
  findCompletedBatch: (
    idempotencyKey: string,
  ) => Promise<BulkProvisionResult | null>;
  execute: (input: {
    actorId: string;
    accounts: BulkProvisionAccount[];
    password: string;
    planCode: "plus" | "family_plus";
    durationMonths: 1 | 3 | 6 | 12;
    reason: string;
    idempotencyKey: string;
    preview: BulkPreview;
  }) => Promise<BulkProvisionResult>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function createAdminProvisionAccountsBulkHandler(
  deps: AdminProvisionAccountsBulkDeps,
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
        message: "Chỉ Super Admin được tạo tài khoản hàng loạt.",
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

    const mode = text(body.mode);
    const parsed = parseAccounts(body.accounts);
    const planCode = text(body.plan_code);
    const durationMonths = parseDuration(body.duration_months);
    const reason = text(body.reason);
    const idempotencyKey = text(body.idempotency_key);

    if (mode !== "preview" && mode !== "execute") {
      return json(400, {
        success: false,
        message: "Chế độ xử lý không hợp lệ.",
      });
    }
    if (!parsed.accounts || parsed.issues.length > 0) {
      return json(400, {
        success: false,
        message: "Danh sách tài khoản chưa hợp lệ.",
        invalid_indices: parsed.issues,
      });
    }
    if (planCode !== "plus" && planCode !== "family_plus") {
      return json(400, {
        success: false,
        message: "Gói thành viên không hợp lệ.",
      });
    }
    if (!durationMonths) {
      return json(400, {
        success: false,
        message: "Thời hạn cấp gói không hợp lệ.",
      });
    }
    if (!reason) {
      return json(400, { success: false, message: "Cần lý do cho batch." });
    }
    if (!idempotencyKey) {
      return json(400, {
        success: false,
        message: "Thiếu mã chống gửi trùng.",
      });
    }

    if (mode === "preview") {
      try {
        const preview = await deps.inspect({
          accounts: parsed.accounts,
          planCode,
          durationMonths,
        });
        return json(200, {
          success: true,
          fingerprint: preview.fingerprint,
          candidate_count: preview.candidateCount,
          rows: publicPreviewRows(preview),
        });
      } catch {
        return json(500, {
          success: false,
          message: "Chưa tạo được bản xem trước an toàn.",
        });
      }
    }

    const password = typeof body.password === "string" ? body.password : "";
    if (password.length < 8) {
      return json(400, {
        success: false,
        message: "Mật khẩu tạm thời cần ít nhất 8 ký tự.",
      });
    }

    const completed = await deps.findCompletedBatch(idempotencyKey);
    if (completed) {
      return success(completed, "Batch đã hoàn tất ở lần gửi trước.");
    }

    let preview: BulkPreview;
    try {
      preview = await deps.inspect({
        accounts: parsed.accounts,
        planCode,
        durationMonths,
      });
    } catch {
      return json(500, {
        success: false,
        message: "Chưa kiểm tra được trạng thái tài khoản.",
      });
    }

    const expectedFingerprint = text(body.preview_fingerprint);
    if (!expectedFingerprint || expectedFingerprint !== preview.fingerprint) {
      return json(409, {
        success: false,
        message: "Dữ liệu tài khoản đã thay đổi. Hãy tạo bản xem trước mới.",
      });
    }

    const confirmation = text(body.confirmation);
    if (confirmation !== `TAO TAI KHOAN ${preview.candidateCount}`) {
      return json(400, {
        success: false,
        message: "Chuỗi xác nhận chưa đúng.",
      });
    }

    try {
      const result = await deps.execute({
        actorId,
        accounts: parsed.accounts,
        password,
        planCode,
        durationMonths,
        reason,
        idempotencyKey,
        preview,
      });
      return success(result, "Đã tạo tài khoản và cấp gói.");
    } catch (error) {
      if (error instanceof BulkProvisionExecutionError) {
        return json(200, {
          success: false,
          message:
            "Batch đã dừng tại một tài khoản. Hãy giữ nguyên mã thao tác để tiếp tục kiểm tra.",
          ...publicResult(error.result),
        });
      }
      return json(500, {
        success: false,
        message: "Chưa thể hoàn tất batch lúc này.",
      });
    }
  };
}

function parseAccounts(value: unknown): {
  accounts?: BulkProvisionAccount[];
  issues: number[];
} {
  if (!Array.isArray(value) || value.length === 0 || value.length > 100) {
    return { issues: [0] };
  }

  const accounts: BulkProvisionAccount[] = [];
  const issues: number[] = [];
  const seen = new Set<string>();
  value.forEach((raw, offset) => {
    const row = record(raw);
    const email = text(row?.email)?.toLowerCase();
    const fullName = text(row?.full_name);
    if (
      !email || !/^[^\s@|]+@gmail\.com$/i.test(email) || !fullName ||
      fullName.length < 2 || fullName.includes("|")
    ) {
      issues.push(offset + 1);
      return;
    }
    if (seen.has(email)) {
      issues.push(offset + 1);
      return;
    }
    seen.add(email);
    accounts.push({ email, fullName });
  });

  return issues.length > 0 ? { issues } : { accounts, issues };
}

function parseDuration(value: unknown): 1 | 3 | 6 | 12 | null {
  const number = typeof value === "number" ? value : Number(value);
  return number === 1 || number === 3 || number === 6 || number === 12
    ? number
    : null;
}

function publicPreviewRows(preview: BulkPreview) {
  return preview.candidates.map((candidate) => ({
    index: candidate.index,
    status: candidate.status,
    ...(candidate.currentPlan ? { current_plan: candidate.currentPlan } : {}),
  }));
}

function publicResult(result: BulkProvisionResult) {
  return {
    batch_id: result.batchId,
    processed_count: result.processedCount,
    created_count: result.createdCount,
    granted_count: result.grantedCount,
    skipped_count: result.skippedCount,
    ...(result.failedIndex ? { failed_index: result.failedIndex } : {}),
  };
}

function success(result: BulkProvisionResult, message: string) {
  return json(200, { success: true, message, ...publicResult(result) });
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length > 0 ? result : null;
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
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

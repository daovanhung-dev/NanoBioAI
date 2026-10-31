export type AiContentReportInput = {
  message_id: string;
  message_role: string;
  reason_code: string;
  note?: string | null;
  message_snapshot: string;
  app_version: string;
  installation_id?: string | null;
};

export type ReportAiContentDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  rateLimit: (key: string) => Promise<boolean>;
  persist: (input: {
    userId: string | null;
    installationId: string | null;
    messageId: string;
    reasonCode: string;
    note: string | null;
    messageSnapshot: string;
    appVersion: string;
  }) => Promise<string>;
};

const REASONS = new Set(["incorrect", "unsafe", "inappropriate", "privacy", "other"]);

export function createReportAiContentHandler(deps: ReportAiContentDeps) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json(405, { accepted: false, message: "Phương thức không được hỗ trợ." });
    }

    const userId = await deps.authenticate(request.headers.get("Authorization"));
    const address = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "anonymous";
    const rateKey = userId ? `user:${userId}` : `ip:${address}`;
    if (!await deps.rateLimit(rateKey)) {
      return json(429, { accepted: false, message: "Bạn đã gửi hơi nhiều báo cáo. Hãy thử lại sau nhé." });
    }

    let body: Partial<AiContentReportInput>;
    try {
      body = await request.json();
    } catch {
      return json(400, { accepted: false, message: "Báo cáo chưa đúng định dạng." });
    }

    const messageId = boundedText(body.message_id, 160);
    const role = boundedText(body.message_role, 32);
    const reasonCode = boundedText(body.reason_code, 32);
    const messageSnapshot = boundedText(body.message_snapshot, 4000);
    const appVersion = boundedText(body.app_version, 64);
    const note = optionalBoundedText(body.note, 500);
    const installationId = optionalBoundedText(body.installation_id, 128);
    if (!messageId || role !== "assistant" || !reasonCode || !REASONS.has(reasonCode) || !messageSnapshot || !appVersion) {
      return json(400, { accepted: false, message: "Báo cáo cần có đủ thông tin để kiểm tra." });
    }

    try {
      const reportId = await deps.persist({
        userId,
        installationId,
        messageId,
        reasonCode,
        note,
        messageSnapshot,
        appVersion,
      });
      return json(200, { accepted: true, report_id: reportId });
    } catch {
      return json(500, { accepted: false, message: "Chưa lưu được báo cáo. Bạn hãy thử lại sau." });
    }
  };
}

function boundedText(value: unknown, maxLength: number): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length > 0 && normalized.length <= maxLength ? normalized : null;
}

function optionalBoundedText(value: unknown, maxLength: number): string | null {
  if (value == null) return null;
  return boundedText(value, maxLength);
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

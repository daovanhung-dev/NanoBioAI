export type NabiAiGenerateInput = {
  model: string;
  contents: unknown[];
  generationConfig: Record<string, unknown>;
  systemInstruction: string | null;
  userId: string | null;
  ip: string;
};

export type NabiAiGenerateDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  rateLimit: (key: string) => Promise<boolean>;
  generate: (input: NabiAiGenerateInput) => Promise<string>;
};

const MAX_REQUEST_BYTES = 1_500_000;
const MAX_CONTENTS = 24;
const MAX_TEXT = 40_000;
const MAX_SYSTEM_INSTRUCTION = 12_000;
const MAX_RESPONSE = 40_000;

export function createNabiAiGenerateHandler(deps: NabiAiGenerateDeps) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json(405, { success: false, message: "Phương thức không được hỗ trợ." });
    }

    const userId = await deps.authenticate(request.headers.get("Authorization"));
    const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";
    const rateKey = userId ? `user:${userId}` : `ip:${ip}`;
    if (!await deps.rateLimit(rateKey)) {
      return json(429, { success: false, message: "Bạn đã dùng hết lượt AI tạm thời. Hãy thử lại sau." });
    }

    let raw: string;
    try {
      raw = await request.text();
    } catch {
      return json(400, { success: false, message: "Dữ liệu AI chưa hợp lệ." });
    }
    if (raw.length > MAX_REQUEST_BYTES) {
      return json(413, { success: false, message: "Yêu cầu AI vượt quá giới hạn an toàn." });
    }

    let body: Record<string, unknown>;
    try {
      const decoded = JSON.parse(raw);
      if (decoded == null || typeof decoded !== "object" || Array.isArray(decoded)) throw new Error("object required");
      body = decoded as Record<string, unknown>;
    } catch {
      return json(400, { success: false, message: "Dữ liệu AI chưa hợp lệ." });
    }

    const model = text(body.model);
    const contents = body.contents;
    const generationConfig = body.generation_config;
    const systemInstruction = body.system_instruction == null ? null : text(body.system_instruction);
    if (!model || model.length > 120 || !Array.isArray(contents) || contents.length === 0 || contents.length > MAX_CONTENTS) {
      return json(400, { success: false, message: "Yêu cầu AI chưa đủ nội dung." });
    }
    if (systemInstruction != null && systemInstruction.length > MAX_SYSTEM_INSTRUCTION) {
      return json(400, { success: false, message: "Chỉ dẫn AI vượt quá giới hạn an toàn." });
    }
    if (generationConfig == null || typeof generationConfig !== "object" || Array.isArray(generationConfig)) {
      return json(400, { success: false, message: "Cấu hình sinh AI chưa hợp lệ." });
    }
    if (JSON.stringify(contents).length > MAX_TEXT) {
      return json(413, { success: false, message: "Nội dung AI vượt quá giới hạn an toàn." });
    }

    try {
      const generated = (await deps.generate({
        model,
        contents,
        generationConfig: generationConfig as Record<string, unknown>,
        systemInstruction,
        userId,
        ip,
      })).trim();
      if (!generated || generated.length > MAX_RESPONSE) {
        return json(502, { success: false, message: "AI chưa trả về câu trả lời hợp lệ." });
      }
      return json(200, { success: true, text: generated });
    } catch (error) {
      console.error("nabi-ai-generate failed", error instanceof Error ? error.name : "unknown");
      return json(502, { success: false, message: "Dịch vụ AI tạm thời chưa sẵn sàng." });
    }
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


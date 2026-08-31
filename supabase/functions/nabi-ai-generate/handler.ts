import {
  normalizeGenerationConfigForModel as normalizeProviderConfig,
  resolveGeminiProviderRequest as resolveProviderRequest,
} from "../_shared/gemini_provider.ts";

export type NabiAiGenerateInput = {
  model: string;
  contents: unknown[];
  generationConfig: Record<string, unknown>;
  systemInstruction: string | null;
  userId: string | null;
  ip: string;
  traceId: string;
};

export type NabiAiGenerateDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  rateLimit: (key: string) => Promise<boolean>;
  generate: (input: NabiAiGenerateInput) => Promise<string>;
};

export type NabiAiProviderRequest = {
  model: string;
  generationConfig: Record<string, unknown>;
  modelFallback: boolean;
};

/**
 * Resolves the provider model and its compatible generation config together.
 * The Edge Function must never send a config authored for a rejected model to
 * the fallback model unchanged.
 */
export function resolveGeminiProviderRequest(
  input: NabiAiGenerateInput,
  allowedModels: ReadonlySet<string>,
  defaultModel: string,
): NabiAiProviderRequest {
  return resolveProviderRequest(input, allowedModels, defaultModel);
}

/**
 * Removes only the Gemini 3 thinking-level setting when the final provider
 * model is Gemini 2.5. Generic generation fields and a compatible
 * thinkingBudget remain intact.
 */
export function normalizeGenerationConfigForModel(
  model: string,
  generationConfig: Record<string, unknown>,
): Record<string, unknown> {
  return normalizeProviderConfig(model, generationConfig);
}

const MAX_REQUEST_BYTES = 1_500_000;
const MAX_CONTENTS = 24;
const MAX_TEXT = 40_000;
const MAX_SYSTEM_INSTRUCTION = 12_000;
const MAX_RESPONSE = 40_000;
const MAX_TRACE_ID = 100;
const TRACE_ID_PATTERN = /^[A-Za-z0-9._:-]+$/;
const SAFE_PROVIDER_ERROR_PATTERN =
  /^provider_(?:[1-5]\d{2}|network_error|empty_response|invalid_response)$/;

export function createNabiAiGenerateHandler(deps: NabiAiGenerateDeps) {
  return async (request: Request): Promise<Response> => {
    const startedAt = Date.now();
    const traceId = resolveTraceId(request);
    logEvent("info", traceId, "REQUEST_START", startedAt, {
      method: request.method,
    });

    try {
      if (request.method !== "POST") {
        return failure(
          405,
          "Phương thức không được hỗ trợ.",
          traceId,
          startedAt,
          "METHOD_NOT_ALLOWED",
        );
      }

      const userId = await deps.authenticate(
        request.headers.get("Authorization"),
      );
      const ip =
        request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
        "unknown";
      const rateKey = userId ? `user:${userId}` : `ip:${ip}`;
      if (!await deps.rateLimit(rateKey)) {
        return failure(
          429,
          "Bạn đã dùng hết lượt AI tạm thời. Hãy thử lại sau.",
          traceId,
          startedAt,
          "RATE_LIMITED",
          { actorMode: userId ? "member" : "guest" },
        );
      }

      let raw: string;
      try {
        raw = await request.text();
      } catch {
        return failure(
          400,
          "Dữ liệu AI chưa hợp lệ.",
          traceId,
          startedAt,
          "REQUEST_BODY_READ_FAILED",
        );
      }
      if (raw.length > MAX_REQUEST_BYTES) {
        return failure(
          413,
          "Yêu cầu AI vượt quá giới hạn an toàn.",
          traceId,
          startedAt,
          "REQUEST_TOO_LARGE",
          { requestBytes: raw.length },
        );
      }

      let body: Record<string, unknown>;
      try {
        const decoded = JSON.parse(raw);
        if (
          decoded == null || typeof decoded !== "object" ||
          Array.isArray(decoded)
        ) {
          throw new Error("object required");
        }
        body = decoded as Record<string, unknown>;
      } catch {
        return failure(
          400,
          "Dữ liệu AI chưa hợp lệ.",
          traceId,
          startedAt,
          "INVALID_JSON",
        );
      }

      const model = text(body.model);
      const contents = body.contents;
      const generationConfig = body.generation_config;
      const systemInstruction = body.system_instruction == null
        ? null
        : text(body.system_instruction);
      if (
        !model ||
        model.length > 120 ||
        !Array.isArray(contents) ||
        contents.length === 0 ||
        contents.length > MAX_CONTENTS
      ) {
        return failure(
          400,
          "Yêu cầu AI chưa đủ nội dung.",
          traceId,
          startedAt,
          "INVALID_REQUEST_CONTENT",
        );
      }
      if (
        systemInstruction != null &&
        systemInstruction.length > MAX_SYSTEM_INSTRUCTION
      ) {
        return failure(
          400,
          "Chỉ dẫn AI vượt quá giới hạn an toàn.",
          traceId,
          startedAt,
          "SYSTEM_INSTRUCTION_TOO_LARGE",
        );
      }
      if (
        generationConfig == null ||
        typeof generationConfig !== "object" ||
        Array.isArray(generationConfig)
      ) {
        return failure(
          400,
          "Cấu hình sinh AI chưa hợp lệ.",
          traceId,
          startedAt,
          "INVALID_GENERATION_CONFIG",
        );
      }
      if (JSON.stringify(contents).length > MAX_TEXT) {
        return failure(
          413,
          "Nội dung AI vượt quá giới hạn an toàn.",
          traceId,
          startedAt,
          "CONTENT_TOO_LARGE",
        );
      }

      try {
        const generated = (await deps.generate({
          model,
          contents,
          generationConfig: generationConfig as Record<string, unknown>,
          systemInstruction,
          userId,
          ip,
          traceId,
        })).trim();
        if (!generated || generated.length > MAX_RESPONSE) {
          return failure(
            502,
            "AI chưa trả về câu trả lời hợp lệ.",
            traceId,
            startedAt,
            "INVALID_GENERATED_RESPONSE",
            { model, responseLength: generated.length },
          );
        }
        logEvent("info", traceId, "REQUEST_SUCCESS", startedAt, {
          statusCode: 200,
          model,
          responseLength: generated.length,
        });
        return json(200, { success: true, text: generated }, traceId);
      } catch (error) {
        const errorCode = safeProviderErrorCode(error);
        logEvent("error", traceId, "PROVIDER_FAILURE", startedAt, {
          statusCode: 502,
          model,
          errorCode,
        });
        return json(
          502,
          { success: false, message: "Dịch vụ AI tạm thời chưa sẵn sàng." },
          traceId,
        );
      }
    } catch (error) {
      logEvent("error", traceId, "UNEXPECTED_HANDLER_FAILURE", startedAt, {
        statusCode: 500,
        errorCode: safeUnexpectedErrorCode(error),
      });
      return json(
        500,
        { success: false, message: "Dịch vụ AI tạm thời chưa sẵn sàng." },
        traceId,
      );
    }
  };
}

function failure(
  status: number,
  message: string,
  traceId: string,
  startedAt: number,
  event: string,
  data: Record<string, unknown> = {},
): Response {
  logEvent(status >= 500 ? "error" : "warning", traceId, event, startedAt, {
    statusCode: status,
    ...data,
  });
  return json(status, { success: false, message }, traceId);
}

function resolveTraceId(request: Request): string {
  const candidate = request.headers.get("x-ai-trace-id")?.trim();
  if (
    candidate &&
    candidate.length <= MAX_TRACE_ID &&
    TRACE_ID_PATTERN.test(candidate)
  ) {
    return candidate;
  }
  return crypto.randomUUID();
}

function safeProviderErrorCode(error: unknown): string {
  if (error instanceof Error) {
    const code = error.message.trim();
    if (SAFE_PROVIDER_ERROR_PATTERN.test(code)) return code;
  }
  return "provider_unknown_error";
}

function safeUnexpectedErrorCode(error: unknown): string {
  if (error instanceof Error) {
    const name = error.name.trim();
    if (/^[A-Za-z][A-Za-z0-9_]{0,79}$/.test(name)) return name;
  }
  return "unexpected_error";
}

function logEvent(
  level: "info" | "warning" | "error",
  traceId: string,
  event: string,
  startedAt: number,
  data: Record<string, unknown> = {},
) {
  const record = JSON.stringify({
    component: "nabi-ai-generate",
    event,
    traceId,
    durationMs: Math.max(0, Date.now() - startedAt),
    ...data,
  });
  if (level === "error") {
    console.error(record);
  } else if (level === "warning") {
    console.warn(record);
  } else {
    console.info(record);
  }
}

function text(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const result = value.trim();
  return result.length === 0 ? null : result;
}

function json(status: number, body: Record<string, unknown>, traceId: string) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "x-ai-trace-id": traceId,
    },
  });
}

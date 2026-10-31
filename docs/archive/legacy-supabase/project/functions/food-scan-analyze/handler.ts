import {
  isRecord,
  resolveGeminiProviderRequest,
} from "../_shared/gemini_provider.ts";
import { extractGeminiResponse } from "../_shared/gemini_response.ts";

export type FoodScanOperation = "vision" | "health";

export type FoodScanAnalyzeInput = {
  operation: FoodScanOperation;
  model: string;
  contents: unknown[];
  generationConfig: Record<string, unknown>;
  systemInstruction: string | null;
  userId: string;
  ip: string;
  traceId: string;
};

export type FoodScanAnalyzeDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  hasPlusAccess: (userId: string) => Promise<boolean>;
  rateLimit: (key: string) => Promise<boolean>;
  generate: (input: FoodScanAnalyzeInput) => Promise<string>;
};

const MAX_REQUEST_BYTES = 1_500_000;
const MAX_CONTENTS = 4;
const MAX_TEXT = 40_000;
const MAX_IMAGE_DATA = 1_300_000;
const MAX_SYSTEM_INSTRUCTION = 12_000;
const MAX_RESPONSE = 40_000;
const MAX_TRACE_ID = 100;
const TRACE_ID_PATTERN = /^[A-Za-z0-9._:-]+$/;
const SAFE_PROVIDER_ERROR_PATTERN =
  /^provider_(?:[1-5]\d{2}|network_error|empty_response|invalid_response|max_tokens)$/;

export function createFoodScanAnalyzeHandler(deps: FoodScanAnalyzeDeps) {
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
          "METHOD_NOT_ALLOWED",
          traceId,
          startedAt,
        );
      }

      const userId = await deps.authenticate(
        request.headers.get("Authorization"),
      );
      if (!userId) {
        return failure(
          401,
          "Bạn cần đăng nhập để quét món ăn.",
          "AUTHENTICATION_REQUIRED",
          traceId,
          startedAt,
        );
      }

      if (!await deps.hasPlusAccess(userId)) {
        return failure(
          403,
          "Quét món ăn là quyền lợi dành riêng cho gói Plus hoặc FamilyPlus.",
          "PLUS_REQUIRED",
          traceId,
          startedAt,
        );
      }

      if (!await deps.rateLimit(`user:${userId}`)) {
        return failure(
          429,
          "Bạn đã dùng hết lượt AI tạm thời. Hãy thử lại sau.",
          "RATE_LIMITED",
          traceId,
          startedAt,
        );
      }

      let raw: string;
      try {
        raw = await request.text();
      } catch {
        return failure(
          400,
          "Dữ liệu quét món ăn chưa hợp lệ.",
          "REQUEST_BODY_READ_FAILED",
          traceId,
          startedAt,
        );
      }
      const requestBytes = new TextEncoder().encode(raw).byteLength;
      if (requestBytes > MAX_REQUEST_BYTES) {
        return failure(
          413,
          "Ảnh hoặc dữ liệu quét món ăn vượt quá giới hạn an toàn.",
          "REQUEST_TOO_LARGE",
          traceId,
          startedAt,
          { requestBytes },
        );
      }

      let body: Record<string, unknown>;
      try {
        const decoded = JSON.parse(raw);
        if (!isRecord(decoded)) throw new Error("object required");
        body = decoded;
      } catch {
        return failure(
          400,
          "Dữ liệu quét món ăn chưa hợp lệ.",
          "INVALID_JSON",
          traceId,
          startedAt,
        );
      }

      const operation = text(body.operation);
      const model = text(body.model);
      const contents = body.contents;
      const generationConfig = body.generation_config;
      const systemInstruction = body.system_instruction == null
        ? null
        : text(body.system_instruction);

      if (
        (operation !== "vision" && operation !== "health") ||
        !model ||
        model.length > 120 ||
        !Array.isArray(contents) ||
        contents.length === 0 ||
        contents.length > MAX_CONTENTS
      ) {
        return failure(
          400,
          "Yêu cầu quét món ăn chưa đủ nội dung.",
          operation !== "vision" && operation !== "health"
            ? "INVALID_OPERATION"
            : "INVALID_REQUEST_CONTENT",
          traceId,
          startedAt,
        );
      }
      if (
        systemInstruction != null &&
        systemInstruction.length > MAX_SYSTEM_INSTRUCTION
      ) {
        return failure(
          413,
          "Chỉ dẫn AI vượt quá giới hạn an toàn.",
          "SYSTEM_INSTRUCTION_TOO_LARGE",
          traceId,
          startedAt,
        );
      }
      if (
        generationConfig == null ||
        !isRecord(generationConfig)
      ) {
        return failure(
          400,
          "Cấu hình AI chưa hợp lệ.",
          "INVALID_GENERATION_CONFIG",
          traceId,
          startedAt,
        );
      }

      const shape = inspectContents(contents);
      if (
        shape.textLength > MAX_TEXT ||
        shape.imageDataLength > MAX_IMAGE_DATA ||
        !shape.hasText ||
        (operation === "vision" &&
          (shape.imageCount !== 1 ||
            !shape.hasImageMimeType ||
            !shape.hasImageData)) ||
        (operation === "health" && shape.imageCount !== 0)
      ) {
        return failure(
          shape.imageDataLength > MAX_IMAGE_DATA || shape.textLength > MAX_TEXT
            ? 413
            : 400,
          "Nội dung quét món ăn chưa hợp lệ.",
          shape.imageDataLength > MAX_IMAGE_DATA || shape.textLength > MAX_TEXT
            ? "CONTENT_TOO_LARGE"
            : "INVALID_CONTENT_SHAPE",
          traceId,
          startedAt,
          {
            operation,
            imageCount: shape.imageCount,
          },
        );
      }

      try {
        const generated = (await deps.generate({
          operation,
          model,
          contents,
          generationConfig,
          systemInstruction,
          userId,
          ip: resolveIp(request),
          traceId,
        })).trim();
        if (!generated || generated.length > MAX_RESPONSE) {
          return failure(
            502,
            "AI chưa trả về kết quả quét món ăn hợp lệ.",
            "INVALID_GENERATED_RESPONSE",
            traceId,
            startedAt,
            { operation, responseLength: generated.length },
          );
        }
        logEvent("info", traceId, "REQUEST_SUCCESS", startedAt, {
          statusCode: 200,
          operation,
          model,
          responseLength: generated.length,
        });
        return json(200, { success: true, text: generated }, traceId);
      } catch (error) {
        const errorCode = safeProviderErrorCode(error);
        logEvent("error", traceId, "PROVIDER_FAILURE", startedAt, {
          statusCode: 502,
          operation,
          model,
          errorCode,
        });
        return failure(
          502,
          "Dịch vụ AI tạm thời chưa sẵn sàng.",
          errorCode === "provider_max_tokens"
            ? "OUTPUT_TRUNCATED"
            : "PROVIDER_FAILURE",
          traceId,
          startedAt,
        );
      }
    } catch (error) {
      logEvent("error", traceId, "UNEXPECTED_HANDLER_FAILURE", startedAt, {
        statusCode: 500,
        errorCode: safeUnexpectedErrorCode(error),
      });
      return failure(
        500,
        "Dịch vụ AI tạm thời chưa sẵn sàng.",
        "UNEXPECTED_FAILURE",
        traceId,
        startedAt,
      );
    }
  };
}

export type FoodScanContentShape = {
  hasText: boolean;
  textLength: number;
  imageCount: number;
  imageDataLength: number;
  hasImageMimeType: boolean;
  hasImageData: boolean;
};

export function inspectContents(contents: unknown[]): FoodScanContentShape {
  let hasText = false;
  let textLength = 0;
  let imageCount = 0;
  let imageDataLength = 0;
  let hasImageMimeType = false;
  let hasImageData = false;

  for (const content of contents) {
    if (!isRecord(content) || !Array.isArray(content.parts)) continue;
    for (const part of content.parts) {
      if (!isRecord(part)) continue;
      if (typeof part.text === "string" && part.text.trim()) {
        hasText = true;
        textLength += part.text.length;
      }
      const inlineData = part.inlineData;
      if (!isRecord(inlineData)) continue;
      imageCount++;
      if (typeof inlineData.data === "string" && inlineData.data.trim()) {
        hasImageData = true;
        imageDataLength += inlineData.data.length;
      }
      if (
        typeof inlineData.mimeType === "string" &&
        inlineData.mimeType.trim().toLowerCase().startsWith("image/")
      ) {
        hasImageMimeType = true;
      }
    }
  }

  return {
    hasText,
    textLength,
    imageCount,
    imageDataLength,
    hasImageMimeType,
    hasImageData,
  };
}

function resolveIp(request: Request): string {
  return request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "unknown";
}

function failure(
  status: number,
  message: string,
  code: string,
  traceId: string,
  startedAt: number,
  data: Record<string, unknown> = {},
): Response {
  logEvent(status >= 500 ? "error" : "warning", traceId, code, startedAt, {
    statusCode: status,
    ...data,
  });
  return json(status, { success: false, code, message }, traceId);
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
    component: "food-scan-analyze",
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

export function createGeminiFoodScanProvider(
  options: {
    apiKey: string;
    defaultModel: string;
    allowedModels: ReadonlySet<string>;
  },
) {
  return async (input: FoodScanAnalyzeInput): Promise<string> => {
    const startedAt = Date.now();
    const providerRequest = resolveGeminiProviderRequest(
      input,
      options.allowedModels,
      options.defaultModel,
    );
    const { model, generationConfig, modelFallback } = providerRequest;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${
      encodeURIComponent(model)
    }:generateContent`;

    console.info(JSON.stringify({
      component: "food-scan-gemini-provider",
      event: "PROVIDER_REQUEST_START",
      traceId: input.traceId,
      operation: input.operation,
      model,
      modelFallback,
    }));

    let response: Response;
    try {
      response = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": options.apiKey,
        },
        body: JSON.stringify({
          contents: input.contents,
          generationConfig,
          ...(input.systemInstruction
            ? {
              systemInstruction: { parts: [{ text: input.systemInstruction }] },
            }
            : {}),
        }),
      });
    } catch {
      console.error(JSON.stringify({
        component: "food-scan-gemini-provider",
        event: "PROVIDER_NETWORK_FAILURE",
        traceId: input.traceId,
        operation: input.operation,
        model,
        modelFallback,
        errorCode: "provider_network_error",
        durationMs: Date.now() - startedAt,
      }));
      throw new Error("provider_network_error");
    }

    const payload = await response.json().catch(() => null);
    if (!response.ok) {
      const errorCode = `provider_${response.status}`;
      console.error(JSON.stringify({
        component: "food-scan-gemini-provider",
        event: "PROVIDER_HTTP_FAILURE",
        traceId: input.traceId,
        operation: input.operation,
        model,
        modelFallback,
        statusCode: response.status,
        errorCode,
        durationMs: Date.now() - startedAt,
      }));
      throw new Error(errorCode);
    }

    const extracted = extractGeminiResponse(payload);
    if (extracted.finishReason?.toUpperCase() === "MAX_TOKENS") {
      console.error(JSON.stringify({
        component: "food-scan-gemini-provider",
        event: "PROVIDER_OUTPUT_TRUNCATED",
        traceId: input.traceId,
        operation: input.operation,
        model,
        modelFallback,
        statusCode: response.status,
        errorCode: "provider_max_tokens",
        durationMs: Date.now() - startedAt,
      }));
      throw new Error("provider_max_tokens");
    }

    const generated = extracted.text;
    if (!generated) {
      console.error(JSON.stringify({
        component: "food-scan-gemini-provider",
        event: "PROVIDER_EMPTY_RESPONSE",
        traceId: input.traceId,
        operation: input.operation,
        model,
        modelFallback,
        statusCode: response.status,
        errorCode: "provider_empty_response",
        durationMs: Date.now() - startedAt,
      }));
      throw new Error("provider_empty_response");
    }

    console.info(JSON.stringify({
      component: "food-scan-gemini-provider",
      event: "PROVIDER_REQUEST_SUCCESS",
      traceId: input.traceId,
      operation: input.operation,
      model,
      modelFallback,
      statusCode: response.status,
      responseLength: generated.length,
      durationMs: Date.now() - startedAt,
    }));
    return generated;
  };
}

export const defaultVoiceLiveModel = "gemini-3.1-flash-live-preview";

const defaultSystemInstruction =
  "Bạn là Nabi, trợ lý sức khỏe thân thiện của chị Thủy Tiên. ";
"Trò chuyện bằng tiếng Việt, ngắn gọn, rõ ràng, không chẩn đoán thay bác sĩ. ";
"Khi có dấu hiệu khẩn cấp, hãy khuyên người dùng liên hệ cơ sở y tế phù hợp.";

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

export type LiveTokenDependencies = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  hasPaidAccess: (userId: string, authorization: string) => Promise<boolean>;
  createEphemeralToken: (input: EphemeralTokenInput) => Promise<EphemeralToken>;
  now: () => Date;
  model?: string;
  systemInstruction?: string;
};

export type EphemeralTokenInput = {
  model: string;
  now: Date;
  systemInstruction: string;
};

export type EphemeralToken = {
  value: string;
  expiresAt: string;
};

export function createVoiceLiveTokenHandler(
  dependencies: LiveTokenDependencies,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: jsonHeaders });
    }
    if (request.method !== "POST") {
      return errorResponse(405, "method_not_allowed");
    }

    const authorization = request.headers.get("Authorization");
    const userId = await dependencies.authenticate(authorization);
    if (userId == null) return errorResponse(401, "unauthorized");
    if (authorization == null) return errorResponse(401, "unauthorized");

    const now = dependencies.now();

    try {
      if (!await dependencies.hasPaidAccess(userId, authorization)) {
        return errorResponse(403, "plus_required");
      }

      const model = dependencies.model ?? defaultVoiceLiveModel;
      const token = await dependencies.createEphemeralToken({
        model,
        now,
        systemInstruction: dependencies.systemInstruction ??
          defaultSystemInstruction,
      });
      if (!token.value || !token.expiresAt) {
        return errorResponse(502, "token_unavailable");
      }

      return jsonResponse({
        token: token.value,
        model,
        expiresAt: token.expiresAt,
      });
    } catch (_) {
      // Deliberately keep provider/JWT/token details out of client responses
      // and Edge logs. The caller only needs a retry-safe category.
      return errorResponse(503, "voice_live_unavailable");
    }
  };
}

export function createGeminiEphemeralTokenRequest({
  model,
  now,
  systemInstruction,
}: EphemeralTokenInput): Record<string, unknown> {
  // New connections must be established promptly; a running 15-minute Live
  // conversation retains a longer send window without exposing the API key.
  const newSessionExpiresAt = new Date(now.getTime() + 60_000).toISOString();
  const tokenExpiresAt = new Date(now.getTime() + 15 * 60_000).toISOString();
  const normalizedModel = model.replace(/^models\//, "");
  return {
    uses: 1,
    newSessionExpireTime: newSessionExpiresAt,
    expireTime: tokenExpiresAt,
    fieldMask: "model,generationConfig,systemInstruction",
    bidiGenerateContentSetup: {
      model: `models/${normalizedModel}`,
      generationConfig: {
        responseModalities: ["AUDIO"],
      },
      systemInstruction: {
        parts: [{ text: systemInstruction }],
      },
    },
  };
}

/// Maps Gemini's AuthToken response to the credential intentionally returned
/// to the app. `name` is the opaque ephemeral credential; legacy `token`
/// fields are deliberately not accepted.
export function parseGeminiEphemeralTokenResponse(
  body: unknown,
): EphemeralToken | null {
  if (body == null || typeof body !== "object" || Array.isArray(body)) {
    return null;
  }
  const record = body as Record<string, unknown>;
  const value = stringValue(record.name);
  const expiresAt = stringValue(record.expireTime);
  return value != null && expiresAt != null ? { value, expiresAt } : null;
}

function jsonResponse(body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: jsonHeaders,
  });
}

function errorResponse(status: number, code: string): Response {
  return new Response(JSON.stringify({ error: code }), {
    status,
    headers: jsonHeaders,
  });
}

function stringValue(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}
